//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.03 
//Created Time: 2022-03-10 11:23:44
create_clock -name CLK_IN -period 83.333 -waveform {0 41.67} [get_ports {CLK_IN}]
//create_clock -name IIS_BCLK_INPUT -period 122.07 -waveform {0 61.035} [get_ports {IIS_BCLK_I}]
create_clock -name I2S_FCLK -period 10.173 -waveform {0 5.087} [get_pins {u_iis_rPLL/rpll_inst/CLKOUT}]
create_clock -name USB_FCLK -period 2.083 -waveform {0 1.042} [get_pins {u_pll/rpll_inst/CLKOUT}]
create_clock -name USB_PCLK -period 16.667 -waveform {0 8.334} [get_pins {u_pll/rpll_inst/CLKOUTD}]
create_clock -name I2S_BCLK_OUTPUT -period 76.923 -waveform {0 38.462} [get_ports {IIS_BCLK_O}]
create_clock -name USB_CLKDIV -period 8.333 -waveform {0 4.167} [get_pins {u_USB_SoftPHY_Top/u_usb2_0_softphy/u_usb_phy_hs/clkdiv_inst/CLKOUT}]
set_false_path -from [get_clocks {USB_PCLK}] -to [get_clocks {USB_CLKDIV}] 