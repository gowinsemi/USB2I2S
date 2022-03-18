//Copyright (C)2014-2021 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.7.03 Beta
//Created Time: 2021-05-11 14:39:56
create_clock -name CLK_IN -period 83.333 -waveform {0 41.67} [get_ports {CLK_IN}]
