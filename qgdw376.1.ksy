meta:
  id: qgdw3761
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
    size: 2
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
  protocal_identification:
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
  terminal_group_address_flag:
    value: "a3 & 0b1  == 0 ? terminal_address_type::single_address : terminal_address_type::group_address"
  msa:
    value: a3 >> 1
  tpv:
    value: seq & 0x80 > 0 ? 1:0
  has_tp:
    value: tpv == 1 ? true:false
  has_ec:
    value: acd == 1 ? true:false
  has_pw:
    value: afn == 1 or afn == 4 or afn == 5 or afn == 6 or afn == 15 or afn == 16 ? true:false
  fir:
    value: seq & 0x40 > 0 ? 1:0
  fin:
    value: seq & 0x20 > 0 ? 1:0
  con:
    value: seq & 0x10 > 0 ? 1:0
  prseq:
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
        size: 4
        doc: 启动帧发送时标
      - id: allow_delay
        type: u1
        doc: 允许发送传输延迟时间，时间单位分钟。
enums:
  dir:
    0: down
    1: up
  prm:
    0: slave
    1: master
  terminal_address_type:
    0: single_address
    1: group_address
