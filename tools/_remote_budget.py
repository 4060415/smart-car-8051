# -*- coding: utf-8 -*-
"""按功能给 remote.LST 的标号分组求和，算清"正式固件要复用什么、能砍掉什么"。

用法: python _remote_budget.py <file.LST>
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lst_sizes import parse, LABEL, DATADIR  # noqa: E402

GROUPS = {
    '串口调试_字符串': ['MSG_BOOT', 'MSG_RELEASE', 'MSG_UNK', 'MSG_IRERR'],
    '串口调试_打印程序': ['PUTCHAR', 'PRINT_STR', 'PUT_HEX', 'PRT_ACTNAME', 'REPORT_KEY',
                          'L_ERRPR', 'BS_LOOP'],
    '红外_NEC解码': ['IR_EDGE', 'IRW_EDGE', 'IR_RECV', 'IR_BITLOOP', 'IR_NEXTBIT',
                     'IR_MIDBIT', 'IR_SETBIT', 'ISB_1', 'ISB_2', 'ISB_3', 'ISB_NEXT',
                     'IR_START', 'IR_REPEAT', 'IR_REJECT', 'IR_BAD', 'MEAS_LEVEL',
                     'ML_LOOP', 'ML_LEVEL', 'ML_WAIT_HI', 'ML_DEFCAP', 'ML_TIMEOUT'],
    '电机_MotorSet': ['MOTOR_SET_ACT', 'MSA_1', 'MSA_2', 'MSA_3', 'MSA_DO',
                      'PAN_1', 'PAN_2', 'PAN_3', 'PAN_PR'],
    '时基_Timer0': ['T0_ISR', 'T0I_RET', 'TICK_GET', 'STAMP_NOW'],
    '按键映射': ['KEY2ACT', 'K2A_1', 'K2A_2', 'K2A_3', 'K2A_4', 'K2A_NONE', 'RK_KNOWN'],
    '主循环与松键': ['MAIN', 'LOOP', 'LOOP_CHK', 'L_NOTRPT', 'L_TIMEOUT', 'L_FULL',
                     'L_NEWKEY', 'D500'],
}


def main():
    rows = parse(sys.argv[1])
    marks = [(loc, LABEL.match(s).group(1)) for loc, _n, _ln, s in rows
             if loc is not None and LABEL.match(s)]
    blocks = {}
    for i, (loc, name) in enumerate(marks):
        nxt = next((marks[j][0] for j in range(i + 1, len(marks)) if marks[j][0] > loc), None)
        if nxt is not None and nxt > loc:
            blocks[name] = nxt - loc

    explained = set()
    total = 0
    print('%-22s %6s  %s' % ('功能块', '字节', '包含的标号'))
    print('-' * 78)
    for gname, names in GROUPS.items():
        s = sum(blocks.get(n, 0) for n in names)
        got = [n for n in names if n in blocks]
        total += s
        explained.update(got)
        print('%-22s %6d  %s' % (gname, s, ' '.join(got)))
    print('-' * 78)
    print('%-22s %6d' % ('以上合计', total))

    rest = {n: s for n, s in blocks.items() if n not in explained}
    rs = sum(rest.values())
    print('%-22s %6d  (%d 个未归类标号)' % ('其它/未归类', rs, len(rest)))
    print('%-22s %6d  <- 应与链接器 code= 接近' % ('总计', total + rs))
    print()
    print('未归类明细:', ', '.join('%s=%d' % (n, s) for n, s in
                                   sorted(rest.items(), key=lambda kv: -kv[1])))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
