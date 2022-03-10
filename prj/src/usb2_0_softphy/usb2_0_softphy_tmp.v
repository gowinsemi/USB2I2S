//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.05
//Part Number: GW2AR-LV18QN88PC7/I6
//Device: GW2AR-18C
//Created Time: Fri Mar 04 10:05:09 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	USB2_0_SoftPHY_Top your_instance_name(
		.clk_i(clk_i_i), //input clk_i
		.rst_i(rst_i_i), //input rst_i
		.fclk_i(fclk_i_i), //input fclk_i
		.pll_locked_i(pll_locked_i_i), //input pll_locked_i
		.utmi_data_out_i(utmi_data_out_i_i), //input [7:0] utmi_data_out_i
		.utmi_txvalid_i(utmi_txvalid_i_i), //input utmi_txvalid_i
		.utmi_op_mode_i(utmi_op_mode_i_i), //input [1:0] utmi_op_mode_i
		.utmi_xcvrselect_i(utmi_xcvrselect_i_i), //input [1:0] utmi_xcvrselect_i
		.utmi_termselect_i(utmi_termselect_i_i), //input utmi_termselect_i
		.utmi_data_in_o(utmi_data_in_o_o), //output [7:0] utmi_data_in_o
		.utmi_txready_o(utmi_txready_o_o), //output utmi_txready_o
		.utmi_rxvalid_o(utmi_rxvalid_o_o), //output utmi_rxvalid_o
		.utmi_rxactive_o(utmi_rxactive_o_o), //output utmi_rxactive_o
		.utmi_rxerror_o(utmi_rxerror_o_o), //output utmi_rxerror_o
		.utmi_linestate_o(utmi_linestate_o_o), //output [1:0] utmi_linestate_o
		.usb_dxp_io(usb_dxp_io_io), //inout usb_dxp_io
		.usb_dxn_io(usb_dxn_io_io), //inout usb_dxn_io
		.usb_rxdp_i(usb_rxdp_i_i), //input usb_rxdp_i
		.usb_rxdn_i(usb_rxdn_i_i), //input usb_rxdn_i
		.usb_pullup_en_o(usb_pullup_en_o_o), //output usb_pullup_en_o
		.usb_term_dp_io(usb_term_dp_io_io), //inout usb_term_dp_io
		.usb_term_dn_io(usb_term_dn_io_io) //inout usb_term_dn_io
	);

//--------Copy end-------------------
