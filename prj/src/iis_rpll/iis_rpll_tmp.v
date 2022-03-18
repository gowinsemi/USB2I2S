//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.05
//Part Number: GW2AR-LV18QN88PC7/I6
//Device: GW2AR-18C
//Created Time: Mon Mar 14 20:23:05 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    iis_rPLL your_instance_name(
        .clkout(clkout_o), //output clkout
        .clkoutd(clkoutd_o), //output clkoutd
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
