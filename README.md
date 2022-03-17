# UAC (USB Audio Class) to I2S Audio Card Reference Design

## Introduction
The USB Audio Class to I2S Audio Card Reference Design provides an example of using various IPs to play and record Audio from a PC using GOWIN FPGAs.  The reference design connects GOWIN Semiconductors USB 2.0 PHY, Device Controller, I2S RX and TX IP Cores as well as provides some basic control logic via USB HID (Human Interface Device).  This provides a starting point to develop custom USB Audio solutions on GOWIN FPGAs.

## Key Features
Basically just bullet points of what the design does

## Top Level Port List
Make a table of the top level ports, if they’re input, output or inout and a brief description

## FPGA Project
Briefly describe the FPGA project and show project directory and Verilog file structure

## Resource Utilization
Review resource utilization report
Make a table to key resources in the design (LUT, REG, DSP, PLL, BSRAM)

## Fabric Clocks FMAX
Review the timing report of the design, clean up any timing errors or issues with asynchronous signals like reset, etc
Put major fpga design clocks in a table with the maximum speed they can run at
Note the speed grade of the device used for these timing numbers

## Demo Setup
### We are in the process of replacing the GOWIN EVAL-AUDIO Board with readily available I2S amplifier and microphone modules.  More instructions to follow, but here is the expected component list

1. GOWIN DK-USB Board

2. MAX98357A Amplifier Module

3. SPH0645LM4H I2S Microphone module

4. Small 4 ohm speaker (or cheap headphones and cut off jack) 

5. Connectivity between boards

   1. QTY 10 - Dupont Flywires

      ​	***OR***

   2. 1x7 female 0.1" header (Amplifier) & 1x6 female 0.1" header (Microphone)
##

### Current Demonstration Setup with GOWIN DK-USB2.0 + MAX98357A I2S Amplifier Boards
![Demo_Setup_Diagram](doc/DKUSB2_to_amplifier_setup.jpg)
### Current Demonstration Setup with GOWIN DK-USB2.0 + GOWIN EVAL_AUDIO Boards
![Demo_Setup_Diagram](doc/Demo_Setup_Diagram.png)

