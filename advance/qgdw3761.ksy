meta:
  id: qgdw3761
  imports:
    - bcd
  file-extension: 3761
  endian: le
seq:
  - id: start_sign
    contents: [0x68]
  - id: l
    type: u2
  - id: l_2
    type: u2
  - id: start_sign_2
    contents: [0x68]
  - id: c
    type: u1
  - id: a1
    type: bcd(4,4,false)
  - id: a2
    type: u2
  - id: a3
    type: u1
  - id: afn
    type: u1
  - id: seq
    type: u1
  - id: data
    size: user_data_length - 6 - 2 - (has_pw ? 16:0) - (has_tp ? 6:0) - (has_ec ? 2:0)
    type:
      switch-on: afn
      cases:
        0x0: ack_nak
        0x2: link_interface_detection
        0xC: request_type_one_data
        0xD: request_type_two_data
        0x10: data_forwarding
  - id: pw
    size: 16
    if: has_pw
  - id: ec
    type: ec
    if: has_ec
  - id: tp
    type: tp
    if: has_tp
  - id: cs
    type: u1
  - id: end_sign
    contents: [0x16]
instances:
  user_data_length:
    value: l >> 2
  protocal:
    value: l & 0b11
  dir:
    value: c & 0x80 > 0 ? dir::up:dir::down
  prm:
    value: c & 0x40 > 0 ? prm::master:prm::slave
  fcb:
    value: c & 0x20 > 0 ? 1:0
    if: dir == dir::down
  fcv:
    value: c & 0x10 > 0 ? 1:0
    if: dir == dir::down
  acd:
    value: c & 0x20 > 0 ? 1:0
    if: dir == dir::up
  function_code:
    value: c & 0xf
  a2_type:
    value: "a3 & 0b1  == 0 ? a2_type::single_address : a2_type::group_address"
  msa:
    value: a3 >> 1
  tpv:
    value: seq & 0x80 > 0 ? 1:0
  has_tp:
    value: tpv == 1 ? true:false
  has_ec:
    value: acd == 1 ? true:false
  has_pw:
    value: (dir == dir::down) and (afn == 1 or afn == 4 or afn == 5 or afn == 6 or afn == 15 or afn == 16) ? true:false
  fir:
    value: seq & 0x40 > 0 ? 1:0
  fin:
    value: seq & 0x20 > 0 ? 1:0
  con:
    value: seq & 0x10 > 0 ? 1:0
  pesq_rseq:
    value: seq & 0xf
types:
  ec:
    seq:
      - id: important_event_counter
        type: u1
      - id: normal_event_counter
        type: u1
  tp:
    seq:
      - id: pfc
        type: u1
        doc: 启动帧帧序号计数器
      - id: time_stamp
        type: a16
        doc: 启动帧发送时标
      - id: allow_delay
        type: u1
        doc: 允许发送传输延时时间。单位：分钟
  data_unit_identify:
    seq:
      - id: da
        type: u2
      - id: dt
        type: u2
  ack_nak:
    doc: 确认∕否认
    doc-ref: Q／GDW 376.1-2009 5.1
    seq:
      - id: identify
        type: data_unit_identify
      - id: data_unit
        type: afn0_f3
        if: identify.dt == 4
  link_interface_detection:
    seq:
      - id: identify
        type: data_unit_identify
  request_type_one_data:
    doc: 请求 1 类数据（AFN=0CH）
    doc-ref: Q／GDW 376.1-2009 5.12
    seq:
      - id: contents
        type: type_one_data
        repeat: eos
  request_type_two_data:
    doc: 请求 2 类数据（AFN=0DH）
    doc-ref: Q／GDW 376.1-2009 5.13
    seq:
      - id: contents
        type: type_two_data
        repeat: eos
  data_forwarding:
    doc: 数据转发（AFN=10H）
    doc-ref: Q／GDW 376.1-2009 5.16
    seq:
      - id: identify
        type: data_unit_identify
      - id: data_unit
        type:
          switch-on: identify.dt
          cases:
            0x1: afn16_f1
            0x101: afn16_f9
            0x102: afn16_f10
            0x104: afn16_f11
  separate_confirmation:
    seq:
      - id: identify
        type: data_unit_identify
      - id: err
        type: u1
        enum: d
  type_one_data:
    seq:
      - id: identify
        type: data_unit_identify
      - id: data_unit
        type:
          switch-on: identify.dt
          cases:
            0x301: afn12_f25
            0x401: afn12_f33
            0x402: afn12_f34
            0x1001: afn12_f129
            0x1440: afn12_f167
            0x1480: afn12_f168
  type_two_data:
    seq:
      - id: identify
        type: data_unit_identify
      - id: data_unit
        type:
          switch-on: identify.dt
          cases:
            0x1: afn13_f1
            0x2: afn13_f2
            0x201: afn13_f17
            0x202: afn13_f18
  afn0_f3:
    doc: 按数据单元标识确认和否认
    doc-ref: 5.1.3.3
    seq:
      - id: need_confirmed_afn
        type: u1
      - id: contents
        type: separate_confirmation
        repeat: eos
  afn12_f25:
    doc: 当前三相及总有/无功功率、功率因数，三相电压、电流、零序电流、视在功率
    doc-ref: 5.12.2.4.19
    seq:
      - id: terminal_reading_time
        doc: 终端抄表时间
        type: a15
      - id: total_active_power
        doc: 当前总有功功率
        type: a9
      - id: a_pharse_active_power
        doc: 当前 A 相有功功率
        type: a9
      - id: b_pharse_active_power
        doc: 当前 B 相有功功率
        type: a9
      - id: c_pharse_active_power
        doc: 当前 C 相有功功率
        type: a9
      - id: total_reactive_power
        doc: 当前总无功功率
        type: a9
      - id: a_pharse_reactive_power
        doc: 当前 A 相无功功率
        type: a9
      - id: b_pharse_reactive_power
        doc: 当前 B 相无功功率
        type: a9
      - id: c_pharse_reactive_power
        doc: 当前 C 相无功功率
        type: a9
      - id: total_power_factor
        doc: 当前总功率因数
        type: a5
      - id: a_pharse_power_factor
        doc: 当前 A 相功率因数
        type: a5
      - id: b_pharse_power_factor
        doc: 当前 B 相功率因数
        type: a5
      - id: c_pharse_power_factor
        doc: 当前 C 相功率因数
        type: a5
      - id: a_pharse_voltage
        doc: 当前 A 相电压
        type: a7
      - id: b_pharse_voltage
        doc: 当前 B 相电压
        type: a7
      - id: c_pharse_voltage
        doc: 当前 C 相电压
        type: a7
      - id: a_pharse_electric_current
        doc: 当前 A 相电流
        type: a25
      - id: b_pharse_electric_current
        doc: 当前 B 相电流
        type: a25
      - id: c_pharse_electric_current
        doc: 当前 C 相电流
        type: a25
      - id: zero_sequence_electric_current
        doc: 当前零序电流
        type: a25
      - id: total_apparent_power
        doc: 当前总视在功率
        type: a9
      - id: a_pharse_apparent_power
        doc: 当前 A 相视在功率
        type: a9
      - id: b_pharse_apparent_power
        doc: 当前 B 相视在功率
        type: a9
      - id: c_pharse_apparent_power
        doc: 当前 C 相视在功率
        type: a9
  afn12_f33:
    doc: 当前正向有/无功电能示值、一/四象限无功电能示值（总、费率 1～M，1≤M≤12）
    doc-ref: 5.12.2.4.27
    seq:
      - id: positive_indication
        type: positive_indication
  afn12_f34:
    doc: 当前反向有/无功电能示值、二/三象限无功电能示值（总、费率 1～M，1≤M≤12）
    doc-ref: 5.12.2.4.28
    seq:
      - id: reverse_indication
        type: reverse_indication
  afn12_f129:
    doc: 当前正向有功电能示值（总、费率 1～M）
    doc-ref: 5.12.2.4.82
    seq:
      - id: terminal_reading_time
        type: a15
      - id: m
        type: u1
      - id: total_positive_active_energy_indicated_value
        type: a14
      - id: rate_positive_active_energy_indicated_value
        type: a14
        repeat: expr
        repeat-expr: m
  afn12_f167:
    doc: 电能表购、用电信息
    doc-ref: 5.12.2.4.117
    seq:
      - id: terminal_reading_time
        doc: 终端抄表时间
        type: a15
      - id: purchase_times
        doc: 购电次数
        type: a8
      - id: balance
        doc: 剩余金额
        type: a14
      - id: cumulative_purchase_amount
        doc: 累计购电金额
        type: a14
      - id: remaining_energy
        doc: 剩余电量
        type: a11
      - id: overdraft_energy
        doc: 透支电量
        type: a11
      - id: cumulative_purchase_energy
        doc: 累计购电量
        type: a11
      - id: max_overdraft_energy
        doc: 赊欠门限电量
        type: a11
      - id: alarm_energy
        doc: 报警电量
        type: a11
      - id: fault_energy
        doc: 故障电量
        type: a11
  afn12_f168:
    doc: 电能表结算信息
    doc-ref: 5.12.2.4.118
    seq:
      - id: terminal_reading_time
        doc: 终端抄表时间
        type: a15
      - id: m
        doc: 费率数
        type: a8
      - id: total_settled_active_energy
        doc: 已结有功总电能
        type: a14
      - id: settled_rate_active_energies
        doc: 已结费率正向有功总电能
        type: a14
        repeat: expr
        repeat-expr: m.value
      - id: total_unsettled_active_energy
        doc: 未结有功总电能
        type: a14
      - id: unsettled_rate_active_energies
        doc: 终端抄表时间
        type: a14
        repeat: expr
        repeat-expr: m.value
  afn13_f1:
    doc: 日冻结正向有/无功电能示值、一/四象限无功电能示值（总、费率 1～M，1≤M≤12）
    doc-ref: 5.13.2.4.1
    seq:
      - id: td_d
        type: a20
      - id: positive_indication
        type: positive_indication
  afn13_f2:
    doc: 日冻结反向有/无功电能示值、二/三象限无功电能示值（总、费率 1～M，1≤M≤12）
    doc-ref: 5.13.2.4.2
    seq:
      - id: td_d
        type: a20
      - id: reverse_indication
        type: reverse_indication
  afn13_f17:
    doc: 月冻结正向有/无功电能示值、一/四象限无功电能示值（总、费率1～M，1≤M≤12）
    doc-ref: 5.13.2.4.13
    seq:
      - id: td_m
        type: a21
      - id: positive_indication
        type: positive_indication
  afn13_f18:
    doc: 月冻结反向有/无功电能示值、二/三象限无功电能示值（总、费率1～M，1≤M≤12）
    doc-ref: 5.13.2.4.14
    seq:
      - id: td_m
        type: a21
      - id: reverse_indication
        type: reverse_indication
  afn16_f1:
    doc: 透明转发应答
    doc-ref: 5.16.2.2.1
    seq:
      - id: terminal_communication_port
        type: u1
      - id: data_length
        type: u2
      - id: content
        size: data_length
  afn16_f9:
    doc: 转发主站直接对电表的抄读数据命令的应答
    doc-ref: 5.16.2.2.2
    seq:
      - id: terminal_communication_port
        type: u1
      - id: target_address
        type: a12
      - id: result_sign
        type: u1
      - id: data_length
        type: u1
      - id: reading_sign
        type: u2
      - id: content
        size: data_length - 2
  afn16_f10:
    doc: 转发主站直接对电表的遥控跳闸/允许合闸命令的应答
    doc-ref: 5.16.2.2.3
    seq:
      - id: terminal_communication_port
        type: u1
      - id: target_address
        type: a12
      - id: result_sign
        type: u1
      - id: remote_trip_sign
        type: u1
  afn16_f11:
    doc: 转发主站直接对电表的遥控送电命令的应答
    doc-ref: 5.16.2.2.4
    seq:
      - id: terminal_communication_port
        type: u1
      - id: target_address
        type: a12
      - id: result_sign
        type: u1
      - id: remote_power_transmission_sign
        type: u1
  positive_indication:
    seq:
      - id: terminal_reading_time
        type: a15
      - id: m
        type: u1
      - id: total_positive_active_energy_indicated_value
        type: a14
      - id: rate_positive_active_energy_indicated_values
        type: a14
        repeat: expr
        repeat-expr: m
      - id: total_positive_reactive_energy_indicated_value
        type: a11
      - id: rate_positive_reactive_energy_indicated_values
        type: a11
        repeat: expr
        repeat-expr: m
      - id: total_one_quadrant_reactive_energy_indicated_value
        type: a11
      - id: rate_one_quadrant_reactive_energy_indicated_values
        type: a11
        repeat: expr
        repeat-expr: m
      - id: total_four_quadrant_reactive_energy_indicated_value
        type: a11
      - id: rate_four_quadrant_reactive_energy_indicated_values
        type: a11
        repeat: expr
        repeat-expr: m
  reverse_indication:
    seq:
      - id: terminal_reading_time
        type: a15
      - id: m
        type: u1
      - id: total_reverse_active_energy_indicated_value
        type: a14
      - id: rate_reverse_active_energy_indicated_values
        type: a14
        repeat: expr
        repeat-expr: m
      - id: total_reverse_reactive_energy_indicated_value
        type: a11
      - id: rate_reverse_reactive_energy_indicated_values
        type: a11
        repeat: expr
        repeat-expr: m
      - id: total_two_quadrant_reactive_energy_indicated_value
        type: a11
      - id: rate_two_quadrant_reactive_energy_indicated_values
        type: a11
        repeat: expr
        repeat-expr: m
      - id: total_three_quadrant_reactive_energy_indicated_value
        type: a11
      - id: rate_three_quadrant_reactive_energy_indicated_values
        type: a11
        repeat: expr
        repeat-expr: m
  a5:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
    instances:
      value:
        value: ((byte2.as_int & 0x7f) * 10.0 + byte1.as_int / 10.0) * (byte2.as_int > 0x7f ? -1.0:1.0)
  a7:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
    instances:
      value:
        value: byte2.as_int * 10.0 + byte1.as_int / 10.0
  a8:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
    instances:
      value:
        value: byte2.as_int * 100 + byte1.as_int
  a9:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
      - id: byte3
        type: bcd(2,4,false)
    instances:
      value:
        value: ((byte3.as_int & 0x7f) + byte2.as_int / 100.0+ byte1.as_int / 10000.0) * (byte3.as_int > 0x7f ? -1.0:1.0)
  a11:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
      - id: byte3
        type: bcd(2,4,false)
      - id: byte4
        type: bcd(2,4,false)
    instances:
      value:
        value: byte4.as_int *10000 + byte3.as_int *100 + byte2.as_int + byte1.as_int /100.0
  a12:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
      - id: byte3
        type: bcd(2,4,false)
      - id: byte4
        type: bcd(2,4,false)
      - id: byte5
        type: bcd(2,4,false)
      - id: byte6
        type: bcd(2,4,false)
    instances:
      value:
        value: byte6.as_int*10_000_000_000 + byte5.as_int*100_000_000 + byte4.as_int*1_000_000 + byte3.as_int*10_000 + byte2.as_int*100 + byte1.as_int
  a14:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
      - id: byte3
        type: bcd(2,4,false)
      - id: byte4
        type: bcd(2,4,false)
      - id: byte5
        type: bcd(2,4,false)
    instances:
      value:
        value: byte1.as_int / 10000.0 + byte2.as_int / 100.0 + byte3.as_int + byte4.as_int * 100.0 + byte5.as_int * 10000.0
  a15:
    seq:
      - id: minute
        type: bcd(2,4,false)
      - id: hour
        type: bcd(2,4,false)
      - id: day
        type: bcd(2,4,false)
      - id: month
        type: bcd(2,4,false)
      - id: year
        type: bcd(2,4,false)
  a16:
    seq:
      - id: second
        type: bcd(2,4,false)
      - id: minute
        type: bcd(2,4,false)
      - id: hour
        type: bcd(2,4,false)
      - id: day
        type: bcd(2,4,false)
  a20:
    seq:
      - id: day
        type: bcd(2,4,false)
      - id: month
        type: bcd(2,4,false)
      - id: year
        type: bcd(2,4,false)
  a21:
    seq:
      - id: month
        type: bcd(2,4,false)
      - id: year
        type: bcd(2,4,false)
  a25:
    seq:
      - id: byte1
        type: bcd(2,4,false)
      - id: byte2
        type: bcd(2,4,false)
      - id: byte3
        type: bcd(2,4,false)
    instances:
      value:
        value: ((byte3.as_int & 0x7f) * 10.0+ byte2.as_int / 10.0+ byte1.as_int / 1000.0) * (byte3.as_int > 0x7f ? -1.0:1.0)
enums:
  d:
    0: correct
    1: error
  dir:
    0: down
    1: up
  prm:
    0: slave
    1: master
  afn:
    0x0: ack_nak
    0x1: reset
    0x2: link_interface_detection
    0x3: relay_station_command
    0x4: setting_parameters
    0x5: control_command
    0x6: identity_authentication_and_key_agreement
    0x8: request_cascade_terminal_active_report
    0x9: request_terminal_configuration
    0xA: query_parameter
    0xB: request_task_data
    0xC: request_type_one_data
    0xD: request_type_two_data
    0xE: request_type_three_data
    0xF: file_transfer
    0x10: data_forwarding
  a2_type:
    0: single_address
    1: group_address
