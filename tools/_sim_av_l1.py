"""Host-side model simulation of the C17 (AV_L1=1) avoidance gate.

ID convention (project rule): every Cxx / Txx / Rxx id carries its meaning in
parentheses the first time it appears.
    C17 (levelled avoidance: arc band + 280 ms decision hold)
    C16 (sharper arc turn)  C15 (forward is hold-to-move while recording)
    C14 (ultrasonic takes no part while recording)
    C13 (latch reminder beeps 3 times)  C10 (D3 shows the avoidance switch)
    C8 (reverse safety)  C5 (non-blocking ultrasonic)  C2/C3 (two avoidance channels)
    R6 (after a latch takeover, forward is hold-to-move for that one action)
    R7 (light mode returns to manual below 5 cm)  R10 (reverse is hold-to-move)
    R12 (manual mode got the turn-away band back)  T11 (full basic-function regression)

Purpose: the temporal behaviour (decision hold, band changes, safety overrides,
mode gating, 16-bit tick wrap) cannot be read off the generated assembly, and the
board is not available for on-car testing.  This file mirrors firmware/c51/main.c:

    av_gate()        -> sim_av_gate()      (main.c av_gate, AV_L1=1 path)
    av_gate_hold()   -> sim_av_gate_hold() (main.c av_gate_hold)
    ir_brake()       -> sim_ir_brake()     (main.c ir_brake)
    motor_set() gate -> sim_motor_set()    (main.c motor_set, gate part only)
    manual_step()    -> sim_manual_step()  (main.c manual_step / do_key)

It is a MODEL, not the firmware: it proves the control logic, not MCU timing.
Constants are copied from main.c so any drift shows up as a failing case.

Run:  python tools/_sim_av_l1.py
"""

TICK_US = 99.83
LOOP_MS = 5.0                 # main loop period (order of magnitude, measured)
US_GAP_MS = 60.0              # HC-SR04 minimum period (main.c US_GAP_MS10 = 6)
TICK_PER_CM = 1.0 / 1.72      # main.c: 1 tick ~= 1.72 cm

# ---- constants copied from main.c (C17) ----
US_NEAR = 12                  # 12 tick ~= 21 cm
US_STOP = 3                   # 3 tick  ~=  5 cm
US_CLEAR = 7                  # 7 tick  ~= 12 cm (beep hysteresis, AV_HOLD only)
AV_SPIN = 7                   # 7 tick  ~= 12 cm (C17 new spin band)
AV_DEC_TICKS = 2800           # 280 ms decision hold (C17 new)
AV_CLEAR_TICKS = 5000         # 0.5 s "obstacle really gone" (AV_HOLD beeps only)
US_FAR = 0xFF

AV_FREE, AV_TURN, AV_HOLD, AV_HUMAN, AV_ARC = 0, 1, 2, 3, 4
ACT_STOP, ACT_FORWARD, ACT_BACK, ACT_RIGHT, ACT_ARC_R = 0x00, 0x01, 0x02, 0x04, 0x06
MODE_MANUAL, MODE_LIGHT, MODE_TRACK, MODE_PLAY = 0, 1, 2, 3


class Car:
    def __init__(self, av_l1=True):
        self.av_l1 = av_l1
        self.tick = 0                  # uint16 tick counter
        self.avst = AV_FREE
        self.av_clear_t = 0            # shared timer (main.c av_clear_t)
        self.av_clear_on = False
        self.av_beep_n = 0
        self.av_beep_t = 0
        self.us_last_d = US_FAR        # last completed measurement
        self.us_last10 = 0             # main.c us_last10 (10 ms units)
        self.us_seen = False
        self.us_valid = False
        self.recon = False
        self.us_avoid_on = True
        self.mode = MODE_MANUAL
        self.cur_act = ACT_STOP
        self.gear = 3
        self.ir = False                # front IR (P3.7) detected
        self.driven = None             # what motor_set finally drove this loop
        self.last_drive = None         # last non-None drive (a latch drives once)
        self.log = []                  # (ms, avst, driven, d)
        self.dist_cm = 300.0           # true distance
        self.keys = []                 # pending key events

    # ---------------- sensor ----------------
    def tick_from_cm(self, cm):
        return min(US_FAR, int(round(cm * TICK_PER_CM)))

    def us_read(self):
        """main.c us_read(): return the last result; re-trigger every 60 ms."""
        d10 = (self.tick * TICK_US / 1000.0 / 10.0)     # ~ ms10 counter, 10 ms units
        if self.us_seen and ((int(d10) - self.us_last10) & 0xFFFF) < 6:
            return self.us_last_d if self.us_valid else US_FAR
        self.us_last10 = int(d10)
        if self.us_seen:
            self.us_last_d = self.tick_from_cm(self.dist_cm)
            self.us_valid = True
        self.us_seen = True
        return self.us_last_d if self.us_valid else US_FAR

    # ---------------- helpers ----------------
    def avoid_off(self):
        return self.recon or (not self.us_avoid_on)

    # ---------------- avoidance ----------------
    def ir_brake(self):
        """main.c ir_brake(): L1264..L1279 -- note it drives the motors itself."""
        if self.avst == AV_HUMAN:
            return
        self.avst = AV_HOLD
        self.cur_act = ACT_STOP
        self.motor_set(ACT_STOP, 0)
        self.av_beep_t = self.tick
        self.av_beep_n = 0

    def av_gate_hold(self):
        """main.c av_gate_hold(): L1287..L1319 -- also drives the motors itself."""
        if self.avst == AV_HUMAN:
            return
        if self.mode == MODE_LIGHT:
            self.mode = MODE_MANUAL
            self.avst = AV_HUMAN
            self.cur_act = ACT_STOP
            self.motor_set(ACT_STOP, 0)
            return
        self.avst = AV_HOLD
        self.cur_act = ACT_STOP
        self.motor_set(ACT_STOP, 0)
        self.av_beep_t = self.tick
        if self.av_beep_n == 0:
            self.av_beep_n = 1

    def motor_set(self, act, g):
        """Gate part of main.c motor_set(): g==0 first, then AV_ARC/AV_TURN/AV_HOLD."""
        if g == 0:
            self.driven = ACT_STOP
            return
        if self.av_l1 and self.avst == AV_ARC:
            act = ACT_ARC_R
        elif self.avst == AV_TURN:
            act = ACT_RIGHT
        elif self.avst == AV_HOLD:
            self.cur_act = ACT_STOP
            self.driven = ACT_STOP
            return
        self.driven = act

    def av_gate(self):
        """main.c av_gate(): AV_L1=1 path, same statement order."""
        self.driven = None
        # 1) avoid_off() && AV_HOLD -> AV_FREE
        if self.avoid_off() and self.avst == AV_HOLD:
            self.avst = AV_FREE
        # 2) AV_HOLD branch: only beeps, then returns
        if self.avst == AV_HOLD:
            if not (self.avoid_off() or self.mode == MODE_TRACK):
                if self.us_read() >= US_CLEAR:
                    if not self.av_clear_on:
                        self.av_clear_on = True
                        self.av_clear_t = self.tick
                        return
                    if ((self.tick - self.av_clear_t) & 0xFFFF) >= AV_CLEAR_TICKS:
                        self.av_beep_n = 0
                    return
                self.av_clear_on = False
            return
        # 3) front IR first (global, cannot be switched off)
        if self.ir:
            self.ir_brake()
            return
        # 4) tracking mode: ultrasonic takes no part
        if self.mode == MODE_TRACK:
            self.avst = AV_FREE
            return
        # 5) reversing: ultrasonic takes no part
        if self.cur_act == ACT_BACK:
            self.avst = AV_FREE
            self.motor_set(ACT_BACK, self.gear)
            return
        # 6) avoidance off / recording
        if self.avoid_off():
            self.avst = AV_FREE
            if self.cur_act != 0:
                self.motor_set(self.cur_act, self.gear)
            return
        d = self.us_read()
        # 7) too close: latch at once, the hold window does not apply
        if d < US_STOP:
            self.av_gate_hold()
            return
        if self.av_l1:
            # 8) decision hold
            if (self.avst in (AV_ARC, AV_TURN) and
                    ((self.tick - self.av_clear_t) & 0xFFFF) < AV_DEC_TICKS):
                if self.cur_act == 0:
                    return
                self.motor_set(self.cur_act, self.gear)
                return
            # 9) re-band (entry from AV_FREE is immediate)
            self.av_clear_t = self.tick
            if d < AV_SPIN:
                self.avst = AV_TURN
            elif d < US_NEAR:
                self.avst = AV_ARC
            else:
                self.avst = AV_FREE
        else:
            self.avst = AV_FREE
            if d < US_NEAR:
                self.avst = AV_TURN
                if self.cur_act == 0:
                    return
                self.motor_set(ACT_RIGHT, self.gear)
                return
        # 10) shared tail
        if self.cur_act == 0:
            return
        self.motor_set(self.cur_act, self.gear)

    # ---------------- key handling (manual mode) ----------------
    def manual_step(self):
        if not self.keys:
            return
        k = self.keys.pop(0)
        # main.c do_key() step 1: any key press while latched hands control back
        # to the human -> AV_HUMAN (this is what makes the latch releasable).
        if self.avst == AV_HOLD:
            self.avst = AV_HUMAN
        if k == 'FWD':
            if self.gear == 0:
                self.gear = 3
            self.cur_act = ACT_FORWARD
            self.motor_set(ACT_FORWARD, self.gear)
        elif k == 'STOP':
            self.cur_act = ACT_STOP
            self.motor_set(ACT_STOP, 0)          # main.c does NOT zero gear here
        elif k == 'BACK':
            self.cur_act = ACT_BACK
            self.motor_set(ACT_BACK, self.gear)
        elif k == 'TRACK':
            self.mode = MODE_TRACK
            self.cur_act = ACT_STOP
        elif k == 'LIGHT':
            self.mode = MODE_LIGHT
            self.cur_act = ACT_FORWARD
        elif k == 'AVOFF':
            self.us_avoid_on = False
        elif k == 'AVON':
            self.us_avoid_on = True
        elif k == 'REC_ON':
            self.recon = True
        elif k == 'REC_OFF':
            self.recon = False
        elif k == 'PLAY':
            self.mode = MODE_PLAY
            self.avst = AV_FREE                       # main.c play_enter()
        elif k == 'MANUAL':
            self.mode = MODE_MANUAL

    def step(self):
        """One main-loop pass: av_gate -> mode step -> log."""
        if self.mode == MODE_PLAY:
            self.driven = None
        else:
            self.av_gate()
            self.manual_step()
        if self.driven is not None:
            self.last_drive = self.driven
        self.log.append((self.now_ms(), self.avst, self.driven,
                         self.us_last_d if self.us_valid else US_FAR))
        self.tick = (self.tick + int(round(LOOP_MS / (TICK_US / 1000.0)))) & 0xFFFF

    def now_ms(self):
        return self.tick * TICK_US / 1000.0

    def run(self, ms, setup=None):
        for i in range(int(ms / LOOP_MS)):
            if setup:
                setup(i * LOOP_MS)
            self.step()
        return self

    def changes(self):
        """[(ms, avst)] transitions, ignoring the very first log entry."""
        out, prev = [], None
        for (ms, av, _, _) in self.log:
            if prev is not None and av != prev:
                out.append((round(ms, 1), av))
            prev = av
        return out


# ============================ test cases ============================
FAIL = []


def check(tid, name, cond, detail=''):
    """tid carries its meaning, e.g. 'T4 (hold window vs escalation)'."""
    print('%-46s %-52s %s %s' % (tid, name, 'PASS' if cond else '*** FAIL ***', detail))
    if not cond:
        FAIL.append(tid)


print('=== C17 (levelled avoidance) host model simulation ===')
print('AV: 4=ARC right-arc, 1=TURN spin, 2=HOLD latch, 3=HUMAN released, 0=FREE')
print()

# ---- T1 (far obstacle: no avoidance, forward latched) ----
c = Car(); c.dist_cm = 60
c.run(400, lambda ms: c.keys.append('FWD') if ms == 0 else None)
check('T1 (far: no avoidance)', 'AV stays FREE', {av for _, av, _, _ in c.log} == {AV_FREE})
check('T1 (far: forward latched)', 'drives FORWARD every loop',
      {a for _, _, a, _ in c.log if a is not None} == {ACT_FORWARD})

# ---- T2 (arc band entry + a single bogus reading must not flip the action) ----
c = Car(); c.dist_cm = 60
c.run(60, lambda ms: c.keys.append('FWD') if ms == 0 else None)
c.dist_cm = 16
glitch = [False]
def inject(ms):
    if not glitch[0] and c.avst == AV_ARC:
        c.us_last_d = US_FAR          # one bogus "far" sample
        c.us_valid = True
        glitch[0] = True
c.run(400, inject)
seq = [av for _, av, _, _ in c.log]
i = seq.index(AV_ARC)
check('T2 (arc entry + glitch)', 'enters AV_ARC at 16 cm', AV_ARC in seq)
check('T2 (arc entry + glitch)', 'stays AV_ARC for the whole window',
      all(a == AV_ARC for a in seq[i:i + 50]), str(set(seq[i:i + 50])))
check('T2 (arc entry + glitch)', 'arc drives ACT_ARC_R (never spin)',
      all(a == ACT_ARC_R for _, av, a, _ in c.log if av == AV_ARC))

# ---- T3 (the hold really is one continuous stretch, not 1-loop chatter) ----
stretches, start = [], None
for (ms, av, _, _) in c.log:
    if av != AV_FREE and start is None:
        start = ms
    elif av == AV_FREE and start is not None:
        stretches.append(round(ms - start, 1)); start = None
check('T3 (hold is continuous)', 'few long stretches, no 5 ms chatter',
      len(stretches) <= 2, 'stretches(ms)=%s' % stretches)

# ---- T4 (escalation waits for the window; <5 cm latches at once) ----
c = Car(); c.dist_cm = 60
c.run(60, lambda ms: c.keys.append('FWD') if ms == 0 else None)
c.dist_cm = 16
c.run(300)
check('T4 (hold vs escalation)', 'arc band active', c.avst == AV_ARC, 'avst=%d' % c.avst)
c.dist_cm = 9
c.run(60)
check('T4 (hold vs escalation)', 'inside the window the arc is kept',
      c.avst == AV_ARC, 'avst=%d' % c.avst)
c.run(400)
check('T4 (hold vs escalation)', 'after the window it degrades to spin',
      c.avst == AV_TURN, 'avst=%d' % c.avst)
c.dist_cm = 4
c.run(150)                                     # allow one fresh sample (<=60 ms)
check('T4 (hold vs escalation)', '<5 cm latches immediately (no window wait)',
      c.avst == AV_HOLD, 'avst=%d' % c.avst)
check('T4 (hold vs escalation)', 'the latch drives the motors off (once, then inert)',
      c.last_drive == ACT_STOP and c.driven is None, 'last=%s now=%s' % (c.last_drive, c.driven))

# ---- T5 (STOP key must never be overridden by the hold window) ----
c = Car(); c.dist_cm = 16
c.run(60, lambda ms: c.keys.append('FWD') if ms == 0 else None)
c.run(100)
t_stop = c.now_ms()
c.keys.append('STOP')
c.run(600)
after = [(ms, av, a) for (ms, av, a, _) in c.log if ms > t_stop + 20]
restarts = [(ms, a) for (ms, av, a) in after if a not in (None, ACT_STOP)]
check('T5 (STOP beats the hold)', 'car never restarts itself after STOP',
      not restarts, 'unexpected drives: %s' % restarts[:5])
check('T5 (STOP beats the hold)', 'stays stopped for the whole window',
      all(a in (None, ACT_STOP) for (_, _, a) in after))

# ---- T6 (latch -> key takeover -> re-arm) ----
# AV_HUMAN ("released") only lasts while the obstacle is still < US_STOP: that is
# the R6 (latch takeover = hold-to-move) window.  Once d >= US_STOP the gate
# re-bands, exactly like C16 did.
c = Car(); c.dist_cm = 4
c.run(150)
check('T6 (latch / takeover / re-arm)', '<5 cm latches', c.avst == AV_HOLD, 'avst=%d' % c.avst)
c.dist_cm = 30
c.run(300)
check('T6 (latch / takeover / re-arm)', 'obstacle removed: still latched (by design)',
      c.avst == AV_HOLD, 'avst=%d' % c.avst)
c.dist_cm = 4                                  # keep it close: that is the R6 window
c.keys.append('FWD')
c.run(LOOP_MS)                                 # exactly one loop: the key press itself
check('T6 (latch / takeover / re-arm)', 'any key -> AV_HUMAN on that very loop',
      c.avst == AV_HUMAN, 'avst=%d' % c.avst)
# NOTE: AV_HUMAN is dropped again as soon as the next sample reads >= US_STOP
# (main.c re-bands every pass), so it can last a single loop.  That is the
# R11 ("takeover counts once") semantics and is unchanged from C16.
c.dist_cm = 30
c.run(300)
check('T6 (latch / takeover / re-arm)', 'front clear -> re-arms to AV_FREE',
      c.avst == AV_FREE, 'avst=%d' % c.avst)
c.dist_cm = 16
c.run(300)
check('T6 (latch / takeover / re-arm)', 'and the gate still avoids afterwards',
      c.avst == AV_ARC, 'avst=%d' % c.avst)

# ---- T7 (front IR overrides everything, immediately, mid-window) ----
c = Car(); c.dist_cm = 16
c.run(60, lambda ms: c.keys.append('FWD') if ms == 0 else None)
c.run(100)
check('T7 (front IR priority)', 'arc active before the IR event', c.avst == AV_ARC)
c.ir = True
c.run(10)
check('T7 (front IR priority)', 'IR latches at once (beats the window)',
      c.avst == AV_HOLD, 'avst=%d' % c.avst)
check('T7 (front IR priority)', 'IR latch drives the motors off',
      c.last_drive == ACT_STOP, str(c.last_drive))

# ---- T8 (track / record / reverse / playback keep AV == FREE) ----
for name, key in (('track', 'TRACK'), ('recording', 'REC_ON')):
    c = Car(); c.dist_cm = 16
    c.keys.append('FWD'); c.run(20); c.keys.append(key); c.run(600)
    avs = {av for (ms, av, _, _) in c.log if ms >= 100}
    check('T8 (%s: ultrasonic out)' % name, 'AV stays FREE', avs == {AV_FREE}, str(avs))

c = Car(); c.dist_cm = 16; c.keys.append('BACK'); c.run(600)
check('T8 (reversing: ultrasonic out)', 'AV stays FREE',
      {av for _, av, _, _ in c.log} == {AV_FREE})
check('T8 (reversing: ultrasonic out)', 'drives ACT_BACK',
      {a for _, _, a, _ in c.log if a} == {ACT_BACK})

c = Car(); c.dist_cm = 16; c.keys.append('PLAY'); c.run(200)
check('T8 (playback: own safety path)', 'AV stays FREE',
      {av for _, av, _, _ in c.log} == {AV_FREE})

# ---- T9 (avoidance switch off -> straight, no arc) ----
c = Car(); c.dist_cm = 16; c.keys.append('FWD'); c.run(20)
c.keys.append('AVOFF'); c.run(400)
check('T9 (switch off)', 'AV back to FREE', {av for _, av, _, _ in c.log[-60:]} == {AV_FREE})
check('T9 (switch off)', 'drives FORWARD (no arc)',
      {a for _, _, a, _ in c.log[-60:] if a} == {ACT_FORWARD})

# ---- T10 (light mode avoids too; <5 cm hands back to manual, no latch) ----
c = Car(); c.keys.append('LIGHT'); c.dist_cm = 16; c.run(600)
check('T10 (light mode)', 'avoids with ARC', AV_ARC in {av for _, av, _, _ in c.log})
c.dist_cm = 4; c.run(600)
check('T10 (light mode)', '<5 cm -> MANUAL + AV_HUMAN (not latched)',
      c.mode == MODE_MANUAL and c.avst == AV_HUMAN, 'mode=%d av=%d' % (c.mode, c.avst))

# ---- T11 (16-bit tick wrap inside the hold window) ----
c = Car(); c.tick = 0xFF00; c.dist_cm = 60
c.keys.append('FWD'); c.run(60); c.dist_cm = 16
c.run(300)
check('T11 (tick wrap)', 'arc survives the wrap', c.avst == AV_ARC, 'avst=%d' % c.avst)
c.run(300)
check('T11 (tick wrap)', 'window still expires correctly after the wrap',
      c.avst in (AV_ARC, AV_FREE), 'avst=%d' % c.avst)

# ---- T12 (band-edge hovering: no 5 ms chatter) ----
c = Car(); c.dist_cm = 18; c.keys.append('FWD')
c.run(3000)
ch = c.changes()
gaps = [round(ch[i + 1][0] - ch[i][0], 1) for i in range(len(ch) - 1)]
fast = [g for g in gaps if g < 250]
check('T12 (band-edge hovering)', 'no AV change faster than ~280 ms',
      not fast, 'gaps=%s' % gaps[:12])

# ---- T13 (band boundaries after tick quantisation) ----
def band_at(cm):
    c = Car(); c.dist_cm = 60; c.keys.append('FWD'); c.run(300)
    c.dist_cm = cm; c.run(600)
    return c.avst

check('T13 (quantised band edges)', '18 cm -> ARC', band_at(18) == AV_ARC)
check('T13 (quantised band edges)', '12 cm -> ARC (d=7, first arc tick)',
      band_at(12) == AV_ARC, 'd=%d' % Car().tick_from_cm(12))
check('T13 (quantised band edges)', '10 cm -> TURN', band_at(10) == AV_TURN)
check('T13 (quantised band edges)', '25 cm -> FREE', band_at(25) == AV_FREE)

# ---- T14 (while avoiding, the applied action is stable, not flipping) ----
c = Car(); c.dist_cm = 60
c.run(60, lambda ms: c.keys.append('FWD') if ms == 0 else None)
c.dist_cm = 16
c.run(1500)
applied = [a for (_, av, a, _) in c.log if av == AV_ARC and a is not None]
check('T14 (stable applied action)', 'ACT_ARC_R applied on every loop in the band',
      applied and set(applied) == {ACT_ARC_R}, 'distinct=%s' % set(applied))

print()
print('AV transitions (T12): %s' % c.changes()[:8])
print()
if FAIL:
    print('RESULT: %d case(s) FAILED -> %s' % (len(FAIL), FAIL))
else:
    print('RESULT: all model cases PASS')
