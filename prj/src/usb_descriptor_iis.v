/******************************************************************************
Copyright 2022 GOWIN SEMICONDUCTOR CORPORATION

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

The Software is used with products manufacturered by GOWIN Semconductor only
unless otherwise authorized by GOWIN Semiconductor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
******************************************************************************/
module usb_desc #(
        // Vendor ID to report in device descriptor.
        parameter VENDORID = 16'h0403,//fb9a;//16'hfb9a;//16'h08bb;
        // Product ID to report in device descriptor.
        parameter PRODUCTID = 16'h6010,//fb9a;//16'hfb9a;//16'h27c6;
        // Product version to report in device descriptor.
        parameter VERSIONBCD = 16'h0100,//16'h0100;
        // Optional description of manufacturer (max 126 characters).
        parameter VENDORSTR = "Gowin UAC2",
        parameter VENDORSTR_LEN = 10,//66;
        // Optional description of product (max 126 characters).
        parameter PRODUCTSTR = "Gowin UAC2",
        parameter PRODUCTSTR_LEN = 10,//34;
        // Optional product serial number (max 126 characters).
        parameter SERIALSTR = "Gwoin UAC2",
        parameter SERIALSTR_LEN = 10,
        parameter STR4 = "Gowin UAC2",
        parameter STR4_LEN = 10,
        parameter STR5 = "Gowin UAC2",
        parameter STR5_LEN = 10,
        parameter STR6 = "Gowin UAC2",
        parameter STR6_LEN = 10,
        parameter STR7 = "HID Interface",
        parameter STR7_LEN = 13,
        // Support high speed mode.
        parameter HSSUPPORT = 0,
        // Set to true if the device never draws power from the USB bus.
        parameter SELFPOWERED = 0
)
(

        input         CLK                    ,
        input         RESET                  ,
        input  [15:0] i_descrom_raddr        ,
        output [ 7:0] o_descrom_rdat         ,
        input  [ 7:0] i_desc_index_o         ,
        input  [ 7:0] i_desc_type_o          ,
        output [15:0] o_desc_dev_addr        ,
        output [15:0] o_desc_dev_len         ,
        output [15:0] o_desc_qual_addr       ,
        output [15:0] o_desc_qual_len        ,
        output [15:0] o_desc_fscfg_addr      ,
        output [15:0] o_desc_fscfg_len       ,
        output [15:0] o_desc_hscfg_addr      ,
        output [15:0] o_desc_hscfg_len       ,
        output [15:0] o_desc_hidrpt_addr     ,
        output [15:0] o_desc_hidrpt_len      ,
        output [15:0] o_desc_oscfg_addr      ,
        output [15:0] o_desc_strlang_addr    ,
        output [15:0] o_desc_strvendor_addr  ,
        output [15:0] o_desc_strvendor_len   ,
        output [15:0] o_desc_strproduct_addr ,
        output [15:0] o_desc_strproduct_len  ,
        output [15:0] o_desc_strserial_addr  ,
        output [15:0] o_desc_strserial_len   ,
        output        o_descrom_have_strings
);

    // Truncate descriptor data to keep only the necessary pieces;
    // either just the full-speed stuff, || full-speed plus high-speed,
    // || full-speed plus high-speed plus string descriptors.


    // Descriptor ROM
    //   addr   0 ..  17 : device descriptor
    //   addr  20 ..  29 : device qualifier
    //   addr  32 ..  98 : full speed configuration descriptor 
    //   addr 112 .. 178 : high speed configuration descriptor
    //   addr 179 :        other_speed_configuration hack
    //   addr 192 .. 195 : string descriptor 0 = supported languages
    //   addr 196 ..     : 3 string descriptors: vendor, product, serial
    localparam  DESC_DEV_ADDR         = 16'd0;
    localparam  DESC_DEV_LEN          = 16'd18;
    localparam  DESC_QUAL_ADDR        = 16'd20;
    localparam  DESC_QUAL_LEN         = 16'd10;
    localparam  DESC_FSCFG_ADDR       = 16'd32;
    localparam  DESC_FSCFG_LEN        = 16'd190;
    localparam  DESC_HSCFG_ADDR       = DESC_FSCFG_ADDR + DESC_FSCFG_LEN;
    //localparam  DESC_HSCFG_LEN        = 16'd343;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd646;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd442;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd435;//16'd343;
    localparam  DESC_HSCFG_LEN        = 16'd268 + 16'd106;//- 16'd8;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd181;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd243;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd434;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd601;//16'd343;
    //localparam  DESC_HSCFG_LEN        = 16'd563;//16'd343;
    localparam  DESC_OSCFG_ADDR       = DESC_HSCFG_ADDR + DESC_HSCFG_LEN;
    localparam  DESC_OSCFG_LEN        = 16'd1;
    localparam  DESC_HIDRPT_ADDR      = DESC_OSCFG_ADDR + DESC_OSCFG_LEN;
    localparam  DESC_HIDRPT_LEN       = 16'd43;
    localparam  DESC_STRLANG_ADDR     = DESC_HIDRPT_ADDR + DESC_HIDRPT_LEN;
    localparam  DESC_STRVENDOR_ADDR   = DESC_STRLANG_ADDR + 4;
    localparam  DESC_STRVENDOR_LEN    = 16'd2 + 2*VENDORSTR_LEN;
    localparam  DESC_STRPRODUCT_ADDR  = DESC_STRVENDOR_ADDR + DESC_STRVENDOR_LEN;
    localparam  DESC_STRPRODUCT_LEN   = 16'd2 + 2*PRODUCTSTR_LEN;
    localparam  DESC_STRSERIAL_ADDR   = DESC_STRPRODUCT_ADDR + DESC_STRPRODUCT_LEN;
    localparam  DESC_STRSERIAL_LEN    = 16'd2 + 2*SERIALSTR_LEN;
    localparam  DESC_STR4_ADDR        = DESC_STRSERIAL_ADDR + DESC_STRSERIAL_LEN;
    localparam  DESC_STR4_LEN         = 16'd2 + 2*STR4_LEN;
    localparam  DESC_STR5_ADDR        = DESC_STR4_ADDR + DESC_STR4_LEN;
    localparam  DESC_STR5_LEN         = 16'd2 + 2*STR5_LEN;
    localparam  DESC_STR6_ADDR        = DESC_STR5_ADDR + DESC_STR5_LEN;
    localparam  DESC_STR6_LEN         = 16'd2 + 2*STR6_LEN;
    localparam  DESC_STR7_ADDR        = DESC_STR6_ADDR + DESC_STR6_LEN;
    localparam  DESC_STR7_LEN         = 16'd2 + 2*STR7_LEN;
    localparam  DESC_END_ADDR         = DESC_STR7_ADDR + DESC_STR7_LEN;
 
    assign  o_desc_dev_addr        = DESC_DEV_ADDR        ;
    assign  o_desc_dev_len         = DESC_DEV_LEN         ;
    assign  o_desc_qual_addr       = DESC_QUAL_ADDR       ;
    assign  o_desc_qual_len        = DESC_QUAL_LEN        ;
    assign  o_desc_fscfg_addr      = DESC_FSCFG_ADDR      ;
    assign  o_desc_fscfg_len       = DESC_FSCFG_LEN       ;
    assign  o_desc_hscfg_addr      = DESC_HSCFG_ADDR      ;
    assign  o_desc_hscfg_len       = DESC_HSCFG_LEN       ;
    assign  o_desc_oscfg_addr      = DESC_OSCFG_ADDR      ;
    assign  o_desc_hidrpt_addr     = DESC_HIDRPT_ADDR     ;
    assign  o_desc_hidrpt_len      = DESC_HIDRPT_LEN      ;
    assign  o_desc_strlang_addr    = DESC_STRLANG_ADDR    ;
    assign  o_desc_strvendor_addr  = DESC_STRVENDOR_ADDR  ;
    assign  o_desc_strvendor_len   = DESC_STRVENDOR_LEN   ;
    assign  o_desc_strproduct_addr = DESC_STRPRODUCT_ADDR ;
    assign  o_desc_strproduct_len  = DESC_STRPRODUCT_LEN  ;
    assign  o_desc_strserial_addr  = (i_desc_index_o == 3) ? DESC_STRSERIAL_ADDR :
                                     (i_desc_index_o == 4) ? DESC_STR4_ADDR :
                                     (i_desc_index_o == 5) ? DESC_STR5_ADDR :
                                     (i_desc_index_o == 6) ? DESC_STR6_ADDR : DESC_STR7_ADDR;
    assign  o_desc_strserial_len   = (i_desc_index_o == 3) ? DESC_STRSERIAL_LEN :
                                     (i_desc_index_o == 4) ? DESC_STR4_LEN :
                                     (i_desc_index_o == 5) ? DESC_STR5_LEN :
                                     (i_desc_index_o == 6) ? DESC_STR6_LEN : DESC_STR7_LEN;


    // Truncate descriptor data to keep only the necessary pieces;
    // either just the full-speed stuff, || full-speed plus high-speed,
    // || full-speed plus high-speed plus string descriptors.
    localparam descrom_have_strings = (VENDORSTR_LEN > 0 || PRODUCTSTR_LEN > 0 || SERIALSTR_LEN > 0);
    localparam descrom_len = (HSSUPPORT || descrom_have_strings)?((descrom_have_strings)? DESC_END_ADDR : DESC_OSCFG_ADDR + DESC_OSCFG_LEN) : DESC_FSCFG_ADDR + DESC_FSCFG_LEN;
    assign o_descrom_have_strings = descrom_have_strings;
    reg [7:0] descrom [0 : descrom_len-1];
    integer i;
    integer z;
    
    always @(posedge CLK or posedge RESET)
      if(RESET) begin
        // 18 bytes device descriptor
        descrom[0]  <= 8'h12;// bLength = 18 bytes
        descrom[1]  <= 8'h01;// bDescriptorType = device descriptor
        descrom[2]  <= (HSSUPPORT)? 8'h00 :8'h10;// bcdUSB = 1.10 || 2.00
        descrom[3]  <= (HSSUPPORT)? 8'h02 :8'h01;
        descrom[4]  <= 8'hEF;// bDeviceClass = USB Miscellaneous Class
        descrom[5]  <= 8'h02;// bDeviceSubClass = Common Class
        descrom[6]  <= 8'h01;// bDeviceProtocol = Interface Association Descriptor
        descrom[7]  <= 8'h40;// 08: 40:bMaxPacketSize0 = 64 bytes
        descrom[8]  <= VENDORID[7 : 0];// idVendor
        descrom[9]  <= VENDORID[15 :8];
        descrom[10] <= PRODUCTID[7 :0];// idProduct
        descrom[11] <= PRODUCTID[15 :8];
        descrom[12] <= VERSIONBCD[7 : 0];// bcdDevice
        descrom[13] <= VERSIONBCD[15 : 8];
        descrom[14] <= (VENDORSTR_LEN > 0)?  8'h01: 8'h00;// iManufacturer
        descrom[15] <= (PRODUCTSTR_LEN > 0)? 8'h02: 8'h00;// iProduct
        descrom[16] <= (SERIALSTR_LEN > 0)?  8'h03: 8'h00;// iSerialNumber
        descrom[17] <= 8'h01;                  // bNumConfigurations = 1
        // 2 bytes padding
        descrom[18] <= 8'h00;
        descrom[19] <= 8'h00;
//======USB Device Qualifier Configuration Descriptor
        // 10 bytes device qualifier
        descrom[DESC_QUAL_ADDR + 0] <= 8'h0A;// bLength = 10 bytes
        descrom[DESC_QUAL_ADDR + 1] <= 8'h06;// bDescriptorType = device qualifier
        descrom[DESC_QUAL_ADDR + 2] <= 8'h00;
        descrom[DESC_QUAL_ADDR + 3] <= 8'h02;// bcdUSB = 2.0
        descrom[DESC_QUAL_ADDR + 4] <= 8'hEF;// bDeviceClass = Communication Device Class
        descrom[DESC_QUAL_ADDR + 5] <= 8'h02;// bDeviceSubClass = none
        descrom[DESC_QUAL_ADDR + 6] <= 8'h01;// bDeviceProtocol = none
        descrom[DESC_QUAL_ADDR + 7] <= 8'h40;// bMaxPacketSize0 = 64 bytes
        descrom[DESC_QUAL_ADDR + 8] <= 8'h01;// bNumConfigurations = 0
        descrom[DESC_QUAL_ADDR + 9] <= 8'h00;// bReserved
         // 2 bytes padding
        descrom[DESC_QUAL_ADDR + 10] <= 8'h00;
        descrom[DESC_QUAL_ADDR + 11] <= 8'h00;
//======USB Device FS Configuration Descriptor
        descrom[DESC_FSCFG_ADDR+ 0]  <= 8'h09;//bLength         : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 1]  <= 8'h02;//bDescriptorType : 0x07 (Other_speed_configuration Descriptor)
        descrom[DESC_FSCFG_ADDR+ 2]  <= DESC_FSCFG_LEN[7:0];///wTotalLength  : 0x00BE (190 bytes)
        descrom[DESC_FSCFG_ADDR+ 3]  <= DESC_FSCFG_LEN[15:8];//wTotalLength  : 0x00BE (190 bytes)
        descrom[DESC_FSCFG_ADDR+ 4]  <= 8'h02;//bNumInterfaces      : 0x02 (2 Interfaces)
        descrom[DESC_FSCFG_ADDR+ 5]  <= 8'h01;//bConfigurationValue : 0x01 (Configuration 1)
        descrom[DESC_FSCFG_ADDR+ 6]  <= 8'h00;//iConfiguration      : 0x00 (No String Descriptor)
        descrom[DESC_FSCFG_ADDR+ 7]  <= 8'hC0;//bmAttributes        : 0xC0
           // D7: Reserved, set 1     : 0x01
           // D6: Self Powered        : 0x01 (yes)
           // D5: Remote Wakeup       : 0x00 (no)
           // D4..0: Reserved, set 0  : 0x00
        descrom[DESC_FSCFG_ADDR+ 8]  <= 8'h00;//MaxPower            : 0x00 (0 mA)
        //---------------- Interface Descriptor -----------------
        descrom[DESC_FSCFG_ADDR+ 9 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 9 + 1] <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 9 + 2] <= 8'h00;//bInterfaceNumber   : 0x00
        descrom[DESC_FSCFG_ADDR+ 9 + 3] <= 8'h00;//bAlternateSetting  : 0x00
        descrom[DESC_FSCFG_ADDR+ 9 + 4] <= 8'h00;//bNumEndpoints      : 0x00 (Default Control Pipe only)
        descrom[DESC_FSCFG_ADDR+ 9 + 5] <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_FSCFG_ADDR+ 9 + 6] <= 8'h01;//bInterfaceSubClass : 0x01 (Audio Control)
        descrom[DESC_FSCFG_ADDR+ 9 + 7] <= 8'h00;//bInterfaceProtocol : 0x00
        descrom[DESC_FSCFG_ADDR+ 9 + 8] <= 8'h00;//iInterface         : 0x00 (No String Descriptor)

        //------ Audio Control Interface Header Descriptor ------
        descrom[DESC_FSCFG_ADDR+ 18 + 0] <= 8'h0A;//bLength            : 0x0A (10 bytes)
        descrom[DESC_FSCFG_ADDR+ 18 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 18 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (Header)
        descrom[DESC_FSCFG_ADDR+ 18 + 3] <= 8'h00;//bcdADC             : 0x0100
        descrom[DESC_FSCFG_ADDR+ 18 + 4] <= 8'h01;//bcdADC             : 0x0100
        descrom[DESC_FSCFG_ADDR+ 18 + 5] <= 8'h3E;//wTotalLength       : 0x003E (62 bytes)
        descrom[DESC_FSCFG_ADDR+ 18 + 6] <= 8'h00;//wTotalLength       : 0x003E (62 bytes)
        descrom[DESC_FSCFG_ADDR+ 18 + 7] <= 8'h02;//bInCollection      : 0x02
        descrom[DESC_FSCFG_ADDR+ 18 + 8] <= 8'h01;//baInterfaceNr[1 + 3] : 0x01
        descrom[DESC_FSCFG_ADDR+ 18 + 9] <= 8'h02;//baInterfaceNr[2 + 3] : 0x02

        //------- Audio Control Input Terminal Descriptor -------
        descrom[DESC_FSCFG_ADDR+ 28 + 0]  <= 8'h0C;//bLength             : 0x0C (12 bytes)
        descrom[DESC_FSCFG_ADDR+ 28 + 1]  <= 8'h24;//bDescriptorType     : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 28 + 2]  <= 8'h02;//bDescriptorSubtype  : 0x02 (Input Terminal)
        descrom[DESC_FSCFG_ADDR+ 28 + 3]  <= 8'h01;//bTerminalID         : 0x01
        descrom[DESC_FSCFG_ADDR+ 28 + 4]  <= 8'h01;//wTerminalType       : 0x0101 (USB streaming)
        descrom[DESC_FSCFG_ADDR+ 28 + 5]  <= 8'h01;//wTerminalType       : 0x0101 (USB streaming)
        descrom[DESC_FSCFG_ADDR+ 28 + 6]  <= 8'h00;//bAssocTerminal      : 0x00
        descrom[DESC_FSCFG_ADDR+ 28 + 7]  <= 8'h02;//bNrChannels         : 0x02 (2 channels)
        descrom[DESC_FSCFG_ADDR+ 28 + 8]  <= 8'h03;//wChannelConfig      : 0x0003 (L, R)
        descrom[DESC_FSCFG_ADDR+ 28 + 9]  <= 8'h00;//wChannelConfig      : 0x0003 (L, R)
        descrom[DESC_FSCFG_ADDR+ 28 + 10] <= 8'h00;//iChannelNames       : 0x00 (No String Descriptor)
        descrom[DESC_FSCFG_ADDR+ 28 + 11] <= 8'h00;//iTerminal           : 0x00 (No String Descriptor)

        //-------- Audio Control Feature Unit Descriptor --------
        descrom[DESC_FSCFG_ADDR+ 40 + 0]  <= 8'h0A;//bLength            : 0x0A (10 bytes)
        descrom[DESC_FSCFG_ADDR+ 40 + 1]  <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 40 + 2]  <= 8'h06;//bDescriptorSubtype : 0x06 (Feature Unit)
        descrom[DESC_FSCFG_ADDR+ 40 + 3]  <= 8'h03;//bUnitID            : 0x03 (3)
        descrom[DESC_FSCFG_ADDR+ 40 + 4]  <= 8'h01;//bSourceID          : 0x01 (1)
        descrom[DESC_FSCFG_ADDR+ 40 + 5]  <= 8'h01;//bControlSize       : 0x01 (1 byte per control)
        descrom[DESC_FSCFG_ADDR+ 40 + 6]  <= 8'h03;//bmaControls[0 + 3] : 0x03
           // D0: Mute                : 1
           // D1: Volume              : 1
           // D2: Bass                : 0
           // D3: Mid                 : 0
           // D4: Treble              : 0
           // D5: Graphic Equalizer   : 0
           // D6: Automatic Gain      : 0
           // D7: Delay               : 0
        descrom[DESC_FSCFG_ADDR+ 40 + 7]  <= 8'h02;//bmaControls[1 + 3] : 0x02
           // D0: Mute                : 0
           // D1: Volume              : 1
           // D2: Bass                : 0
           // D3: Mid                 : 0
           // D4: Treble              : 0
           // D5: Graphic Equalizer   : 0
           // D6: Automatic Gain      : 0
           // D7: Delay               : 0
        descrom[DESC_FSCFG_ADDR+ 40 + 8]  <= 8'h02;//bmaControls[2 + 3] : 0x02
           // D0: Mute                : 0
           // D1: Volume              : 1
           // D2: Bass                : 0
           // D3: Mid                 : 0
           // D4: Treble              : 0
           // D5: Graphic Equalizer   : 0
           // D6: Automatic Gain      : 0
           // D7: Delay               : 0
        descrom[DESC_FSCFG_ADDR+ 40 + 9]  <= 8'h00;//iFeature                 : 0x00 (No String Descriptor)

        //------- Audio Control Output Terminal Descriptor ------
        descrom[DESC_FSCFG_ADDR+ 50 + 0]  <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 50 + 1]  <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 50 + 2]  <= 8'h03;//bDescriptorSubtype : 0x03 (Output Terminal)
        descrom[DESC_FSCFG_ADDR+ 50 + 3]  <= 8'h04;//bTerminalID        : 0x04
        descrom[DESC_FSCFG_ADDR+ 50 + 4]  <= 8'h01;//wTerminalType      : 0x0301 (Speaker)
        descrom[DESC_FSCFG_ADDR+ 50 + 5]  <= 8'h03;//wTerminalType      : 0x0301 (Speaker)
        descrom[DESC_FSCFG_ADDR+ 50 + 6]  <= 8'h00;//bAssocTerminal     : 0x00 (0)
        descrom[DESC_FSCFG_ADDR+ 50 + 7]  <= 8'h03;//bSourceID          : 0x03 (3)
        descrom[DESC_FSCFG_ADDR+ 50 + 8]  <= 8'h00;//iTerminal          : 0x00 (No String Descriptor)
        //------- Audio Control Input Terminal Descriptor -------
        descrom[DESC_FSCFG_ADDR+ 59 + 0]  <= 8'h0C;//bLength            : 0x0C (12 bytes)
        descrom[DESC_FSCFG_ADDR+ 59 + 1]  <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 59 + 2]  <= 8'h02;//bDescriptorSubtype : 0x02 (Input Terminal)
        descrom[DESC_FSCFG_ADDR+ 59 + 3]  <= 8'h0A;//bTerminalID        : 0x0A
        descrom[DESC_FSCFG_ADDR+ 59 + 4]  <= 8'h01;//wTerminalType      : 0x0201 (Microphone)
        descrom[DESC_FSCFG_ADDR+ 59 + 5]  <= 8'h02;//wTerminalType      : 0x0201 (Microphone)
        descrom[DESC_FSCFG_ADDR+ 59 + 6]  <= 8'h00;//bAssocTerminal     : 0x00
        descrom[DESC_FSCFG_ADDR+ 59 + 7]  <= 8'h02;//bNrChannels        : 0x02 (2 channels)
        descrom[DESC_FSCFG_ADDR+ 59 + 8]  <= 8'h03;//wChannelConfig     : 0x0003 (L, R)
        descrom[DESC_FSCFG_ADDR+ 59 + 9]  <= 8'h00;//wChannelConfig     : 0x0003 (L, R)
        descrom[DESC_FSCFG_ADDR+ 59 + 10] <= 8'h00;//iChannelNames      : 0x00 (No String Descriptor)
        descrom[DESC_FSCFG_ADDR+ 59 + 11] <= 8'h00;//iTerminal          : 0x00 (No String Descriptor)

        //------- Audio Control Output Terminal Descriptor ------
        descrom[DESC_FSCFG_ADDR+ 71 + 0]  <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 71 + 1]  <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 71 + 2]  <= 8'h03;//bDescriptorSubtype : 0x03 (Output Terminal)
        descrom[DESC_FSCFG_ADDR+ 71 + 3]  <= 8'h0D;//bTerminalID        : 0x0D
        descrom[DESC_FSCFG_ADDR+ 71 + 4]  <= 8'h01;//wTerminalType      : 0x0101 (USB streaming)
        descrom[DESC_FSCFG_ADDR+ 71 + 5]  <= 8'h01;//wTerminalType      : 0x0101 (USB streaming)
        descrom[DESC_FSCFG_ADDR+ 71 + 6]  <= 8'h00;//bAssocTerminal     : 0x00 (0)
        descrom[DESC_FSCFG_ADDR+ 71 + 7]  <= 8'h0A;//bSourceID          : 0x0A (10)
        descrom[DESC_FSCFG_ADDR+ 71 + 8]  <= 8'h00;//iTerminal          : 0x00 (No String Descriptor)

        //---------------- Interface Descriptor -----------------
        descrom[DESC_FSCFG_ADDR+ 80 + 0]  <= 8'h09;//bLength              : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 80 + 1]  <= 8'h04;//bDescriptorType      : 0x04 (Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 80 + 2]  <= 8'h01;//bInterfaceNumber     : 0x01
        descrom[DESC_FSCFG_ADDR+ 80 + 3]  <= 8'h00;//bAlternateSetting    : 0x00
        descrom[DESC_FSCFG_ADDR+ 80 + 4]  <= 8'h00;//bNumEndpoints        : 0x00 (Default Control Pipe only)
        descrom[DESC_FSCFG_ADDR+ 80 + 5]  <= 8'h01;//bInterfaceClass      : 0x01 (Audio)
        descrom[DESC_FSCFG_ADDR+ 80 + 6]  <= 8'h02;//bInterfaceSubClass   : 0x02 (Audio Streaming)
        descrom[DESC_FSCFG_ADDR+ 80 + 7]  <= 8'h00;//bInterfaceProtocol   : 0x00
        descrom[DESC_FSCFG_ADDR+ 80 + 8]  <= 8'h04;//iInterface           : 0x04 (String Descriptor 4)
        //---------------- Interface Descriptor -----------------
        descrom[DESC_FSCFG_ADDR+ 89 + 0]  <= 8'h09;//bLength              : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 89 + 1]  <= 8'h04;//bDescriptorType      : 0x04 (Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 89 + 2]  <= 8'h01;//bInterfaceNumber     : 0x01
        descrom[DESC_FSCFG_ADDR+ 89 + 3]  <= 8'h01;//bAlternateSetting    : 0x01
        descrom[DESC_FSCFG_ADDR+ 89 + 4]  <= 8'h01;//bNumEndpoints        : 0x01 (1 Endpoint)
        descrom[DESC_FSCFG_ADDR+ 89 + 5]  <= 8'h01;//bInterfaceClass      : 0x01 (Audio)
        descrom[DESC_FSCFG_ADDR+ 89 + 6]  <= 8'h02;//bInterfaceSubClass   : 0x02 (Audio Streaming)
        descrom[DESC_FSCFG_ADDR+ 89 + 7]  <= 8'h00;//bInterfaceProtocol   : 0x00
        descrom[DESC_FSCFG_ADDR+ 89 + 8]  <= 8'h00;//iInterface           : 0x00 (No String Descriptor)

        //-------- Audio Streaming Interface Descriptor ---------
        descrom[DESC_FSCFG_ADDR+ 98 + 0]  <= 8'h07;//bLength              : 0x07 (7 bytes)
        descrom[DESC_FSCFG_ADDR+ 98 + 1]  <= 8'h24;//bDescriptorType      : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 98 + 2]  <= 8'h01;//bDescriptorSubtype   : 0x01
        descrom[DESC_FSCFG_ADDR+ 98 + 3]  <= 8'h01;//bTerminalLink        : 0x01
        descrom[DESC_FSCFG_ADDR+ 98 + 4]  <= 8'h01;//bDelay               : 0x01
        descrom[DESC_FSCFG_ADDR+ 98 + 5]  <= 8'h01;//wFormatTag           : 0x0001 (PCM)
        descrom[DESC_FSCFG_ADDR+ 98 + 6]  <= 8'h00;//wFormatTag           : 0x0001 (PCM)

        //------- Audio Streaming Format Type Descriptor --------
        descrom[DESC_FSCFG_ADDR+ 105 + 0]  <= 8'h0E;//bLength          : 0x0E (14 bytes)
        descrom[DESC_FSCFG_ADDR+ 105 + 1]  <= 8'h24;//bDescriptorType  : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 105 + 2]  <= 8'h02;//bDescriptorSubtype : 0x02 (Format Type)
        descrom[DESC_FSCFG_ADDR+ 105 + 3]  <= 8'h01;//bFormatType     : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_FSCFG_ADDR+ 105 + 4]  <= 8'h02;//bNrChannels     : 0x02 (2 channels)
        descrom[DESC_FSCFG_ADDR+ 105 + 5]  <= 8'h02;//bSubframeSize   : 0x02 (2 bytes per subframe)
        descrom[DESC_FSCFG_ADDR+ 105 + 6]  <= 8'h10;//bBitResolution  : 0x10 (16 bits per sample)
        descrom[DESC_FSCFG_ADDR+ 105 + 7]  <= 8'h02;//bSamFreqType    : 0x02 (supports 2 sample frequencies)
        descrom[DESC_FSCFG_ADDR+ 105 + 8]  <= 8'h44;//tSamFreq[1 + 3] : 0x0AC44 (44100 Hz)
        descrom[DESC_FSCFG_ADDR+ 105 + 9]  <= 8'hAC;//tSamFreq[1 + 3] : 0x0AC44 (44100 Hz)
        descrom[DESC_FSCFG_ADDR+ 105 + 10] <= 8'h00;//tSamFreq[1 + 3] : 0x0AC44 (44100 Hz)
        descrom[DESC_FSCFG_ADDR+ 105 + 11] <= 8'h80;//tSamFreq[2 + 3] : 0x0BB80 (48000 Hz)
        descrom[DESC_FSCFG_ADDR+ 105 + 12] <= 8'hBB;//tSamFreq[2 + 3] : 0x0BB80 (48000 Hz)
        descrom[DESC_FSCFG_ADDR+ 105 + 13] <= 8'h00;//tSamFreq[2 + 3] : 0x0BB80 (48000 Hz)

        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_FSCFG_ADDR+ 119 + 0]  <= 8'h09;//bLength          : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 119 + 1]  <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_FSCFG_ADDR+ 119 + 2]  <= 8'h01;//bEndpointAddress : 0x01 (Direction=OUT EndpointID=1)
        descrom[DESC_FSCFG_ADDR+ 119 + 3]  <= 8'h09;//bmAttributes     : 0x09 (TransferType=Isochronous  SyncType=Adaptive  EndpointType=Data)
        descrom[DESC_FSCFG_ADDR+ 119 + 4]  <= 8'hF0;//wMaxPacketSize   : 0x00F0
        descrom[DESC_FSCFG_ADDR+ 119 + 5]  <= 8'h00;//wMaxPacketSize   : 0x00F0
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0xF0 (240 bytes per packet)
        descrom[DESC_FSCFG_ADDR+ 119 + 6]  <= 8'h01;//bInterval        : 0x01 (1 ms)
        descrom[DESC_FSCFG_ADDR+ 119 + 7]  <= 8'h00;//bRefresh         : 0x00
        descrom[DESC_FSCFG_ADDR+ 119 + 8]  <= 8'h00;//bSynchAddress    : 0x00

        //----------- Audio Data Endpoint Descriptor ------------
        descrom[DESC_FSCFG_ADDR+ 128 + 0]  <= 8'h07;//bLength            : 0x07 (7 bytes)
        descrom[DESC_FSCFG_ADDR+ 128 + 1]  <= 8'h25;//bDescriptorType    : 0x25 (Audio Endpoint Descriptor)
        descrom[DESC_FSCFG_ADDR+ 128 + 2]  <= 8'h01;//bDescriptorSubtype : 0x01 (General)
        descrom[DESC_FSCFG_ADDR+ 128 + 3]  <= 8'h01;//bmAttributes       : 0x01
        descrom[DESC_FSCFG_ADDR+ 128 + 4]  <= 8'h00;//bLockDelayUnits    : 0x00
        descrom[DESC_FSCFG_ADDR+ 128 + 5]  <= 8'h01;//wLockDelay         : 0x0001
        descrom[DESC_FSCFG_ADDR+ 128 + 6]  <= 8'h00;//wLockDelay         : 0x0001

        //---------------- Interface Descriptor -----------------
        descrom[DESC_FSCFG_ADDR+ 135 + 0]  <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 135 + 1]  <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 135 + 2]  <= 8'h02;//bInterfaceNumber   : 0x02
        descrom[DESC_FSCFG_ADDR+ 135 + 3]  <= 8'h00;//bAlternateSetting  : 0x00
        descrom[DESC_FSCFG_ADDR+ 135 + 4]  <= 8'h00;//bNumEndpoints      : 0x00 (Default Control Pipe only)
        descrom[DESC_FSCFG_ADDR+ 135 + 5]  <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_FSCFG_ADDR+ 135 + 6]  <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_FSCFG_ADDR+ 135 + 7]  <= 8'h00;//bInterfaceProtocol : 0x00
        descrom[DESC_FSCFG_ADDR+ 135 + 8]  <= 8'h05;//iInterface         : 0x05 (String Descriptor 5)
        //---------------- Interface Descriptor -----------------
        descrom[DESC_FSCFG_ADDR+ 144 + 0]  <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 144 + 1]  <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 144 + 2]  <= 8'h02;//bInterfaceNumber   : 0x02
        descrom[DESC_FSCFG_ADDR+ 144 + 3]  <= 8'h01;//bAlternateSetting  : 0x01
        descrom[DESC_FSCFG_ADDR+ 144 + 4]  <= 8'h01;//bNumEndpoints      : 0x01 (1 Endpoint)
        descrom[DESC_FSCFG_ADDR+ 144 + 5]  <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_FSCFG_ADDR+ 144 + 6]  <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_FSCFG_ADDR+ 144 + 7]  <= 8'h00;//bInterfaceProtocol : 0x00
        descrom[DESC_FSCFG_ADDR+ 144 + 8]  <= 8'h00;//iInterface         : 0x00 (No String Descriptor)

        //-------- Audio Streaming Interface Descriptor ---------
        descrom[DESC_FSCFG_ADDR+ 153 + 0]  <= 8'h07;//bLength            : 0x07 (7 bytes)
        descrom[DESC_FSCFG_ADDR+ 153 + 1]  <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 153 + 2]  <= 8'h01;//bDescriptorSubtype : 0x01
        descrom[DESC_FSCFG_ADDR+ 153 + 3]  <= 8'h0D;//bTerminalLink      : 0x0D
        descrom[DESC_FSCFG_ADDR+ 153 + 4]  <= 8'h01;//bDelay             : 0x01
        descrom[DESC_FSCFG_ADDR+ 153 + 5]  <= 8'h01;//wFormatTag         : 0x0001 (PCM)
        descrom[DESC_FSCFG_ADDR+ 153 + 6]  <= 8'h00;//wFormatTag         : 0x0001 (PCM)

        //------- Audio Streaming Format Type Descriptor --------
        descrom[DESC_FSCFG_ADDR+ 160 + 0]  <= 8'h0E;//bLength            : 0x0E (14 bytes)
        descrom[DESC_FSCFG_ADDR+ 160 + 1]  <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_FSCFG_ADDR+ 160 + 2]  <= 8'h02;//bDescriptorSubtype : 0x02 (Format Type)
        descrom[DESC_FSCFG_ADDR+ 160 + 3]  <= 8'h01;//bFormatType     : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_FSCFG_ADDR+ 160 + 4]  <= 8'h02;//bNrChannels     : 0x02 (2 channels)
        descrom[DESC_FSCFG_ADDR+ 160 + 5]  <= 8'h02;//bSubframeSize   : 0x02 (2 bytes per subframe)
        descrom[DESC_FSCFG_ADDR+ 160 + 6]  <= 8'h10;//bBitResolution  : 0x10 (16 bits per sample)
        descrom[DESC_FSCFG_ADDR+ 160 + 7]  <= 8'h02;//bSamFreqType    : 0x02 (supports 2 sample frequencies)
        descrom[DESC_FSCFG_ADDR+ 160 + 8]  <= 8'h44;//tSamFreq[1 + 3]    : 0x0AC44 (44100 Hz)
        descrom[DESC_FSCFG_ADDR+ 160 + 9]  <= 8'hAC;//tSamFreq[1 + 3]    : 0x0AC44 (44100 Hz)
        descrom[DESC_FSCFG_ADDR+ 160 + 10]  <= 8'h00;//tSamFreq[1 + 3]   : 0x0AC44 (44100 Hz)
        descrom[DESC_FSCFG_ADDR+ 160 + 11]  <= 8'h80;//tSamFreq[2 + 3]   : 0x0BB80 (48000 Hz)
        descrom[DESC_FSCFG_ADDR+ 160 + 12]  <= 8'hBB;//tSamFreq[2 + 3]   : 0x0BB80 (48000 Hz)
        descrom[DESC_FSCFG_ADDR+ 160 + 13]  <= 8'h00;//tSamFreq[2 + 3]   : 0x0BB80 (48000 Hz)

        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_FSCFG_ADDR+ 174 + 0]  <= 8'h09;//bLength          : 0x09 (9 bytes)
        descrom[DESC_FSCFG_ADDR+ 174 + 1]  <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_FSCFG_ADDR+ 174 + 2]  <= 8'h82;//bEndpointAddress : 0x82 (Direction=IN EndpointID=2)
        descrom[DESC_FSCFG_ADDR+ 174 + 3]  <= 8'h09;//bmAttributes     : 0x09 (TransferType=Isochronous  SyncType=Adaptive  EndpointType=Data)
        descrom[DESC_FSCFG_ADDR+ 174 + 4]  <= 8'h46;//wMaxPacketSize   : 0x0246
        descrom[DESC_FSCFG_ADDR+ 174 + 5]  <= 8'h02;//wMaxPacketSize   : 0x0246
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x246 (582 bytes per packet)
        descrom[DESC_FSCFG_ADDR+ 174 + 6]  <= 8'h01;//bInterval        : 0x01 (1 ms)
        descrom[DESC_FSCFG_ADDR+ 174 + 7]  <= 8'h00;//bRefresh         : 0x00
        descrom[DESC_FSCFG_ADDR+ 174 + 8]  <= 8'h00;//bSynchAddress    : 0x00

        //----------- Audio Data Endpoint Descriptor ------------
        descrom[DESC_FSCFG_ADDR+ 183 + 0] <= 8'h07;//bLength            : 0x07 (7 bytes)
        descrom[DESC_FSCFG_ADDR+ 183 + 1] <= 8'h25;//bDescriptorType    : 0x25 (Audio Endpoint Descriptor)
        descrom[DESC_FSCFG_ADDR+ 183 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (General)
        descrom[DESC_FSCFG_ADDR+ 183 + 3] <= 8'h01;//bmAttributes       : 0x01
        descrom[DESC_FSCFG_ADDR+ 183 + 4] <= 8'h00;//bLockDelayUnits    : 0x00
        descrom[DESC_FSCFG_ADDR+ 183 + 5] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_FSCFG_ADDR+ 183 + 6] <= 8'h00;//wLockDelay         : 0x0000

//======USB Configuration Descriptor
        //---------------- Configuration header -----------------
        descrom[DESC_HSCFG_ADDR + 0] <= 8'h09;// 0 bLength = 9 bytes
        descrom[DESC_HSCFG_ADDR + 1] <= 8'h02;// 1 bDescriptorType = configuration descriptor
        descrom[DESC_HSCFG_ADDR + 2] <= DESC_HSCFG_LEN[7:0];// 2 wTotalLength L
        descrom[DESC_HSCFG_ADDR + 3] <= DESC_HSCFG_LEN[15:8];// 3 wTotalLength H
        descrom[DESC_HSCFG_ADDR + 4] <= 8'h04;// 4 bNumInterfaces = 5
        descrom[DESC_HSCFG_ADDR + 5] <= 8'h01;// 5 bConfigurationValue = 1
        descrom[DESC_HSCFG_ADDR + 6] <= 8'h00;// 6 iConfiguration - index of string
        descrom[DESC_HSCFG_ADDR + 7] <= (SELFPOWERED)? 8'hc0 : 8'h80; // 7 bmAttributes
        descrom[DESC_HSCFG_ADDR + 8] <= 8'h32;// 8 bMaxPower = 500 mA
//USB to IIS interface
        //---------------- IAD Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 9 + 0] <= 8'h08;//bLength             : 0x08 (8 bytes)
        descrom[DESC_HSCFG_ADDR + 9 + 1] <= 8'h0B;//bDescriptorType     : 0x0B
        descrom[DESC_HSCFG_ADDR + 9 + 2] <= 8'h00;//bFirstInterface     : 0x00
        descrom[DESC_HSCFG_ADDR + 9 + 3] <= 8'h03;//bInterfaceCount     : 0x03
        descrom[DESC_HSCFG_ADDR + 9 + 4] <= 8'h01;//bFunctionClass      : 0x01 (Audio)
        descrom[DESC_HSCFG_ADDR + 9 + 5] <= 8'h00;//bFunctionSubClass   : 0x00 (undefined)
        descrom[DESC_HSCFG_ADDR + 9 + 6] <= 8'h20;//bFunctionProtocol   : 0x20 (AF 2.0)
        descrom[DESC_HSCFG_ADDR + 9 + 7] <= 8'h00;//iFunction           : 0x00 (No String Descriptor)
        //---------------- Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 17 + 0] <= 8'h09;//bLength            (9 bytes)
        descrom[DESC_HSCFG_ADDR + 17 + 1] <= 8'h04;//bDescriptorType    (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 17 + 2] <= 8'h00;//bInterfaceNumber
        descrom[DESC_HSCFG_ADDR + 17 + 3] <= 8'h00;//bAlternateSetting
        descrom[DESC_HSCFG_ADDR + 17 + 4] <= 8'h00;//bNumEndpoints      (Default Control Pipe only)
        descrom[DESC_HSCFG_ADDR + 17 + 5] <= 8'h01;//bInterfaceClass    (Audio)
        descrom[DESC_HSCFG_ADDR + 17 + 6] <= 8'h01;//bInterfaceSubClass (Audio Control)
        descrom[DESC_HSCFG_ADDR + 17 + 7] <= 8'h20;//bInterfaceProtocol (Device Protocol Version 2.0)
        descrom[DESC_HSCFG_ADDR + 17 + 8] <= 8'h02;//iInterface         (String Descriptor 2)

        //---- Audio Control Interface Header Descriptor 2.0 ----
        descrom[DESC_HSCFG_ADDR + 26 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR + 26 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 26 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (Header 2.0)
        descrom[DESC_HSCFG_ADDR + 26 + 3] <= 8'h00;//bcdADC             : 0x0200 (2.0)
        descrom[DESC_HSCFG_ADDR + 26 + 4] <= 8'h02;//bcdADC             : 0x0200 (2.0)
        descrom[DESC_HSCFG_ADDR + 26 + 5] <= 8'h04;//bCategory          : 0x04 (headset)
        //descrom[DESC_HSCFG_ADDR + 26 + 6] <= 8'h40;//wTotalLength       : 0x0040 (64 bytes)
        descrom[DESC_HSCFG_ADDR + 26 + 6] <= 8'h77;//wTotalLength       : 0x0040 (64 bytes)
        descrom[DESC_HSCFG_ADDR + 26 + 7] <= 8'h00;//wTotalLength       : 0x0040 (64 bytes)
        descrom[DESC_HSCFG_ADDR + 26 + 8] <= 8'h00;//bmControls         : 0x00
        //--- Audio Control Clock Source Unit Descriptor 2.0 ----
        descrom[DESC_HSCFG_ADDR + 35 + 0] <= 8'h08;//bLength            : 0x08 (8 bytes)
        descrom[DESC_HSCFG_ADDR + 35 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 35 + 2] <= 8'h0A;//bDescriptorSubtype : 0x0A (Clock Source 2.0)
        descrom[DESC_HSCFG_ADDR + 35 + 3] <= 8'h05;//bClockID           : 0x05
        descrom[DESC_HSCFG_ADDR + 35 + 4] <= 8'h03;//bmAttributes       : 0x03 D1..0: Clock Type     : 0x03 D2   : Sync to SOF      : 0x00 D7..3: Reserved         : 0x00
        descrom[DESC_HSCFG_ADDR + 35 + 5] <= 8'h07;//bmControls         : 0x07 D1..0: Clock Frequency: 0x03 (host programmable) D3..2: Clock Validity: 0x01 (read only) D7..4: Reserved  : 0x00
        descrom[DESC_HSCFG_ADDR + 35 + 6] <= 8'h00;//bAssocTerminal     : 0x00
        descrom[DESC_HSCFG_ADDR + 35 + 7] <= 8'h00;//iClockSource       : 0x00 (No String Descriptor)
        //----- Audio Control Input Terminal Descriptor 2.0 -----
        descrom[DESC_HSCFG_ADDR + 43 + 0] <= 8'h11;//bLength            : 0x11 (17 bytes)
        descrom[DESC_HSCFG_ADDR + 43 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 43 + 2] <= 8'h02;//bDescriptorSubtype : 0x02 (Input Terminal 2.0)
        descrom[DESC_HSCFG_ADDR + 43 + 3] <= 8'h01;//bTerminalID        : 0x01
        descrom[DESC_HSCFG_ADDR + 43 + 4] <= 8'h01;//wTerminalType      : 0x0101 (USB streaming)
        descrom[DESC_HSCFG_ADDR + 43 + 5] <= 8'h01;//wTerminalType      : 0x0101 (USB streaming)
        descrom[DESC_HSCFG_ADDR + 43 + 6] <= 8'h00;//bAssocTerminal     : 0x00
        descrom[DESC_HSCFG_ADDR + 43 + 7] <= 8'h05;//bCSourceID         : 0x05 (5)
        descrom[DESC_HSCFG_ADDR + 43 + 8] <= 8'h02;//bNrChannels        : 0x02 (2 Channels)
        descrom[DESC_HSCFG_ADDR + 43 + 9] <= 8'h03;//bmChannelConfig    : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 43 + 10] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 43 + 11] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 43 + 12] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 43 + 13] <= 8'h00;//iChannelNames     : 0x00 (No String Descriptor)
        descrom[DESC_HSCFG_ADDR + 43 + 14] <= 8'h00;//bmControls        : 0x0000 D1..0  : Copy Protect   : 0x00 (not present) D3..2  : Connector      : 0x00 (not present) D5..4  : Overload       : 0x00 (not present) D7..6  : Cluster        : 0x00 (not present) D9..8  : Underflow      : 0x00 (not present) D11..10: Overflow       : 0x00 (not present) D15..12: Reserved       : 0x00
        descrom[DESC_HSCFG_ADDR + 43 + 15] <= 8'h00;//bmControls        : 0x0000 D1..0  : Copy Protect   : 0x00 (not present) D3..2  : Connector      : 0x00 (not present) D5..4  : Overload       : 0x00 (not present) D7..6  : Cluster        : 0x00 (not present) D9..8  : Underflow      : 0x00 (not present) D11..10: Overflow       : 0x00 (not present) D15..12: Reserved       : 0x00
        descrom[DESC_HSCFG_ADDR + 43 + 16] <= 8'h00;//iTerminal         : 0x00 (No String Descriptor)

        //------ Audio Control Feature Unit Descriptor 2.0 ------
        descrom[DESC_HSCFG_ADDR + 60 + 0] <= 8'h12;//bLength            : 0x12 (18 bytes)
        descrom[DESC_HSCFG_ADDR + 60 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 60 + 2] <= 8'h06;//bDescriptorSubtype : 0x06 (Feature Unit 2.0)
        descrom[DESC_HSCFG_ADDR + 60 + 3] <= 8'h03;//bUnitID            : 0x03 (3)
        descrom[DESC_HSCFG_ADDR + 60 + 4] <= 8'h01;//bSourceID          : 0x01 (1)
        descrom[DESC_HSCFG_ADDR + 60 + 5] <= 8'h0F;//bmaControls[0]     : 0x0F, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 6] <= 8'h00;//bmaControls[0]     : 0x0F, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 7] <= 8'h00;//bmaControls[0]     : 0x0F, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 8] <= 8'h00;//bmaControls[0]     : 0x0F, 0x00, 0x00, 0x00
        // D1..0  : Mute            : 0x03 (host programmable)
        // D3..2  : Volume          : 0x03 (host programmable)
        // D5..4  : Bass            : 0x00 (not present)
        // D7..6  : Mid             : 0x00 (not present)
        // D9..8  : Treble          : 0x00 (not present)
        // D11..10: Graph Equalizer : 0x00 (not present)
        // D13..12: Automatic Gain  : 0x00 (not present)
        // D15..14: Delay           : 0x00 (not present)
        // D17..16: Bass Boost      : 0x00 (not present)
        // D19..18: Loudness        : 0x00 (not present)
        // D21..20: Input Gain      : 0x00 (not present)
        // D23..22: Input Gain Pad  : 0x00 (not present)
        // D25..24: Phase Inverter  : 0x00 (not present)
        // D27..26: Underflow       : 0x00 (not present)
        // D29..28: Overflow        : 0x00 (not present)
        // D31..30: reserved        : 0x00 (not present)
        descrom[DESC_HSCFG_ADDR + 60 + 9] <= 8'h0C;//bmaControls[1]           : 0x0C, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 10] <= 8'h00;//bmaControls[1]           : 0x0C, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 11] <= 8'h00;//bmaControls[1]           : 0x0C, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 12] <= 8'h00;//bmaControls[1]           : 0x0C, 0x00, 0x00, 0x00
        // D1..0  : Mute            : 0x00 (not present)
        // D3..2  : Volume          : 0x03 (host programmable)
        // D5..4  : Bass            : 0x00 (not present)
        // D7..6  : Mid             : 0x00 (not present)
        // D9..8  : Treble          : 0x00 (not present)
        // D11..10: Graph Equalizer : 0x00 (not present)
        // D13..12: Automatic Gain  : 0x00 (not present)
        // D15..14: Delay           : 0x00 (not present)
        // D17..16: Bass Boost      : 0x00 (not present)
        // D19..18: Loudness        : 0x00 (not present)
        // D21..20: Input Gain      : 0x00 (not present)
        // D23..22: Input Gain Pad  : 0x00 (not present)
        // D25..24: Phase Inverter  : 0x00 (not present)
        // D27..26: Underflow       : 0x00 (not present)
        // D29..28: Overflow        : 0x00 (not present)
        // D31..30: reserved        : 0x00 (not present)
        descrom[DESC_HSCFG_ADDR + 60 + 13] <= 8'h0C; //bmaControls[2]           : 0x0C, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 14] <= 8'h00; //bmaControls[2]           : 0x0C, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 15] <= 8'h00; //bmaControls[2]           : 0x0C, 0x00, 0x00, 0x00
        descrom[DESC_HSCFG_ADDR + 60 + 16] <= 8'h00; //bmaControls[2]           : 0x0C, 0x00, 0x00, 0x00
        // D1..0  : Mute            : 0x00 (not present)
        // D3..2  : Volume          : 0x03 (host programmable)
        // D5..4  : Bass            : 0x00 (not present)
        // D7..6  : Mid             : 0x00 (not present)
        // D9..8  : Treble          : 0x00 (not present)
        // D11..10: Graph Equalizer : 0x00 (not present)
        // D13..12: Automatic Gain  : 0x00 (not present)
        // D15..14: Delay           : 0x00 (not present)
        // D17..16: Bass Boost      : 0x00 (not present)
        // D19..18: Loudness        : 0x00 (not present)
        // D21..20: Input Gain      : 0x00 (not present)
        // D23..22: Input Gain Pad  : 0x00 (not present)
        // D25..24: Phase Inverter  : 0x00 (not present)
        // D27..26: Underflow       : 0x00 (not present)
        // D29..28: Overflow        : 0x00 (not present)
        // D31..30: reserved        : 0x00 (not present)
        descrom[DESC_HSCFG_ADDR + 60 + 17] <= 8'h00; //iFeature                 : 0x00 (No String Descriptor)
        //----- Audio Control Output Terminal Descriptor 2.0 ----
        descrom[DESC_HSCFG_ADDR + 78 + 0] <= 8'h0C;//bLength            : 0x0C (12 bytes)
        descrom[DESC_HSCFG_ADDR + 78 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 78 + 2] <= 8'h03;//bDescriptorSubtype : 0x03 (Output Terminal 2.0)
        descrom[DESC_HSCFG_ADDR + 78 + 3] <= 8'h04;//bTerminalID        : 0x04
        descrom[DESC_HSCFG_ADDR + 78 + 4] <= 8'h01;//wTerminalType      : 0x0301 (Speaker)
        descrom[DESC_HSCFG_ADDR + 78 + 5] <= 8'h03;//wTerminalType      : 0x0301 (Speaker)
        descrom[DESC_HSCFG_ADDR + 78 + 6] <= 8'h00;//bAssocTerminal     : 0x00 (0)
        descrom[DESC_HSCFG_ADDR + 78 + 7] <= 8'h03;//bSourceID          : 0x03 (3)
        descrom[DESC_HSCFG_ADDR + 78 + 8] <= 8'h05;//bCSourceID         : 0x05 (5)
        descrom[DESC_HSCFG_ADDR + 78 + 9] <= 8'h00;//iTerminal          : 0x00 (No String Descriptor)
        descrom[DESC_HSCFG_ADDR + 78 + 10] <= 8'h00;//iTerminal         : 0x00 (No String Descriptor)
        descrom[DESC_HSCFG_ADDR + 78 + 11] <= 8'h00;//iTerminal         : 0x00 (No String Descriptor)

        //----- Audio Control Input Terminal Descriptor 2.0 -----
        descrom[DESC_HSCFG_ADDR + 90 + 0 ] <= 8'h11;//bLength            : 0x11 (17 bytes)
        descrom[DESC_HSCFG_ADDR + 90 + 1 ] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 90 + 2 ] <= 8'h02;//bDescriptorSubtype : 0x02 (Input Terminal 2.0)
        descrom[DESC_HSCFG_ADDR + 90 + 3 ] <= 8'h06;//bTerminalID        : 0x06
        descrom[DESC_HSCFG_ADDR + 90 + 4 ] <= 8'h01;//wTerminalType      : 0x0201 (Microphone)
        descrom[DESC_HSCFG_ADDR + 90 + 5 ] <= 8'h02;//wTerminalType      : 0x0201 (Microphone)
        descrom[DESC_HSCFG_ADDR + 90 + 6 ] <= 8'h00;//bAssocTerminal     : 0x00
        descrom[DESC_HSCFG_ADDR + 90 + 7 ] <= 8'h05;//bCSourceID         : 0x05 (5)
        descrom[DESC_HSCFG_ADDR + 90 + 8 ] <= 8'h02;//bNrChannels        : 0x02 (2 Channels)
        descrom[DESC_HSCFG_ADDR + 90 + 9 ] <= 8'h03;//bmChannelConfig    : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 90 + 10] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 90 + 11] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 90 + 12] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 90 + 13] <= 8'h00;//iChannelNames     : 0x00 (No String Descriptor)
        descrom[DESC_HSCFG_ADDR + 90 + 14] <= 8'h00;//bmControls        : 0x0000 D1..0  : Copy Protect   : 0x00 (not present) D3..2  : Connector      : 0x00 (not present) D5..4  : Overload       : 0x00 (not present) D7..6  : Cluster        : 0x00 (not present) D9..8  : Underflow      : 0x00 (not present) D11..10: Overflow       : 0x00 (not present) D15..12: Reserved       : 0x00
        descrom[DESC_HSCFG_ADDR + 90 + 15] <= 8'h00;//bmControls        : 0x0000 D1..0  : Copy Protect   : 0x00 (not present) D3..2  : Connector      : 0x00 (not present) D5..4  : Overload       : 0x00 (not present) D7..6  : Cluster        : 0x00 (not present) D9..8  : Underflow      : 0x00 (not present) D11..10: Overflow       : 0x00 (not present) D15..12: Reserved       : 0x00
        descrom[DESC_HSCFG_ADDR + 90 + 16] <= 8'h00;//iTerminal         : 0x00 (No String Descriptor)
        //----- Audio Control Output Terminal Descriptor 2.0 ----
        descrom[DESC_HSCFG_ADDR + 107 + 0] <= 8'h0C;//bLength            : 0x0C (12 bytes)
        descrom[DESC_HSCFG_ADDR + 107 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 107 + 2] <= 8'h03;//bDescriptorSubtype : 0x03 (Output Terminal 2.0)
        descrom[DESC_HSCFG_ADDR + 107 + 3] <= 8'h08;//bTerminalID        : 0x08
        descrom[DESC_HSCFG_ADDR + 107 + 4] <= 8'h01;//wTerminalType      : 0x0101 (USB streaming)
        descrom[DESC_HSCFG_ADDR + 107 + 5] <= 8'h01;//wTerminalType      : 0x0101 (USB streaming)
        descrom[DESC_HSCFG_ADDR + 107 + 6] <= 8'h00;//bAssocTerminal     : 0x00 (0)
        descrom[DESC_HSCFG_ADDR + 107 + 7] <= 8'h06;//bSourceID          : 0x07 (7)
        descrom[DESC_HSCFG_ADDR + 107 + 8] <= 8'h05;//bCSourceID         : 0x05 (5)
        descrom[DESC_HSCFG_ADDR + 107 + 9] <= 8'h00;//iTerminal          : 0x00 (No String Descriptor)
        descrom[DESC_HSCFG_ADDR + 107 + 10] <= 8'h00;//iTerminal         : 0x00 (No String Descriptor)
        descrom[DESC_HSCFG_ADDR + 107 + 11] <= 8'h00;//iTerminal         : 0x00 (No String Descriptor)
        //---------------- Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 119 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR + 119 + 1] <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 119 + 2] <= 8'h01;//bInterfaceNumber   : 0x01
        descrom[DESC_HSCFG_ADDR + 119 + 3] <= 8'h00;//bAlternateSetting  : 0x00
        descrom[DESC_HSCFG_ADDR + 119 + 4] <= 8'h00;//bNumEndpoints      : 0x00 (Default Control Pipe only)
        descrom[DESC_HSCFG_ADDR + 119 + 5] <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_HSCFG_ADDR + 119 + 6] <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_HSCFG_ADDR + 119 + 7] <= 8'h20;//bInterfaceProtocol : 0x20 (Device Protocol Version 2.0)
        descrom[DESC_HSCFG_ADDR + 119 + 8] <= 8'h04;//iInterface         : 0x04 (String Descriptor 4)
        //---------------- Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 128 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR + 128 + 1] <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 128 + 2] <= 8'h01;//bInterfaceNumber   : 0x01
        descrom[DESC_HSCFG_ADDR + 128 + 3] <= 8'h01;//bAlternateSetting  : 0x01
        descrom[DESC_HSCFG_ADDR + 128 + 4] <= 8'h02;//bNumEndpoints      : 0x02 (2 Endpoints)
        descrom[DESC_HSCFG_ADDR + 128 + 5] <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_HSCFG_ADDR + 128 + 6] <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_HSCFG_ADDR + 128 + 7] <= 8'h20;//bInterfaceProtocol : 0x20 (Device Protocol Version 2.0)
        descrom[DESC_HSCFG_ADDR + 128 + 8] <= 8'h00;//iInterface         : 0x00 (No String Descriptor)
        //------ Audio Streaming Interface Descriptor 2.0 -------
        descrom[DESC_HSCFG_ADDR + 137 + 0] <= 8'h10;//bLength            : 0x10 (16 bytes)
        descrom[DESC_HSCFG_ADDR + 137 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 137 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (AS General)
        descrom[DESC_HSCFG_ADDR + 137 + 3] <= 8'h01;//bTerminalLink      : 0x01 (1)
        descrom[DESC_HSCFG_ADDR + 137 + 4] <= 8'h05;//bmControls         : 0x05
        // D1..0: Active Alt Settng: 0x01 (read only)
        // D3..2: Valid Alt Settng : 0x01 (read only)
        // D7..4: Reserved         : 0x00
        descrom[DESC_HSCFG_ADDR + 137 + 5] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 137 + 6] <= 8'h01;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 137 + 7] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 137 + 8] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 137 + 9] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 137 + 10] <= 8'h02;//bNrChannels       : 0x02 (2 channels)
        descrom[DESC_HSCFG_ADDR + 137 + 11] <= 8'h03;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 137 + 12] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 137 + 13] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 137 + 14] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 137 + 15] <= 8'h00;//iChannelNames     : 0x00 (No String Descriptor)
        //----- Audio Streaming Format Type Descriptor 2.0 ------
        descrom[DESC_HSCFG_ADDR + 153 + 0] <= 8'h06;//bLength         : 0x06 (6 bytes)
        descrom[DESC_HSCFG_ADDR + 153 + 1] <= 8'h24;//bDescriptorType : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 153 + 2] <= 8'h02;//bDescriptorSubtype : 0x02 (Format Type)
        descrom[DESC_HSCFG_ADDR + 153 + 3] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 153 + 4] <= 8'h02;//bSubslotSize       : 0x02 (2 bytes)
        descrom[DESC_HSCFG_ADDR + 153 + 5] <= 8'h10;//bBitResolution     : 0x10 (16 bits)
        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 159 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 159 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 159 + 2] <= 8'h01;//bEndpointAddress : 0x01 (Direction=OUT EndpointID=1)
        descrom[DESC_HSCFG_ADDR + 159 + 3] <= 8'h05;//bmAttributes     : 0x05 (TransferType=Isochronous  SyncType=Asynchronous  EndpointType=Data)
        descrom[DESC_HSCFG_ADDR + 159 + 4] <= 8'h08;//wMaxPacketSize   : 0x0308
        descrom[DESC_HSCFG_ADDR + 159 + 5] <= 8'h03;//wMaxPacketSize   : 0x0308
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x308 (776 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 159 + 6] <= 8'h01;//bInterval                : 0x01 (1 ms)
        //----------- Audio Data Endpoint Descriptor ------------
        descrom[DESC_HSCFG_ADDR + 166 + 0] <= 8'h08;//bLength            : 0x08 (8 bytes)
        descrom[DESC_HSCFG_ADDR + 166 + 1] <= 8'h25;//bDescriptorType    : 0x25 (Audio Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 166 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (General)
        descrom[DESC_HSCFG_ADDR + 166 + 3] <= 8'h00;//bmAttributes       : 0x00
        descrom[DESC_HSCFG_ADDR + 166 + 4] <= 8'h00;//bLockDelayUnits    : 0x00
        descrom[DESC_HSCFG_ADDR + 166 + 5] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 166 + 6] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 166 + 7] <= 8'h00;//wLockDelay         : 0x0000
        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 174 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 174 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 174 + 2] <= 8'h81;//bEndpointAddress : 0x81 (Direction=IN EndpointID=1)
        descrom[DESC_HSCFG_ADDR + 174 + 3] <= 8'h11;//bmAttributes     : 0x11 (TransferType=Isochronous  SyncType=None  EndpointType=Feedback)
        descrom[DESC_HSCFG_ADDR + 174 + 4] <= 8'h04;//wMaxPacketSize   : 0x0004
        descrom[DESC_HSCFG_ADDR + 174 + 5] <= 8'h00;//wMaxPacketSize   : 0x0004
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x04 (4 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 174 + 6] <= 8'h04;//bInterval        : 0x04 (4 ms)

        //---------------- Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 1] <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 2] <= 8'h01;//bInterfaceNumber   : 0x01
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 3] <= 8'h02;//bAlternateSetting  : 0x02
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 4] <= 8'h02;//bNumEndpoints      : 0x02 (2 Endpoints)
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 5] <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 6] <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 7] <= 8'h20;//bInterfaceProtocol : 0x20 (Device Protocol Version 2.0)
        descrom[DESC_HSCFG_ADDR + 53 + 128 + 8] <= 8'h00;//iInterface         : 0x00 (No String Descriptor)
        //------ Audio Streaming Interface Descriptor 2.0 -------
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 0] <= 8'h10;//bLength            : 0x10 (16 bytes)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (AS General)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 3] <= 8'h01;//bTerminalLink      : 0x01 (1)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 4] <= 8'h05;//bmControls         : 0x05
        // D1..0: Active Alt Settng: 0x01 (read only)
        // D3..2: Valid Alt Settng : 0x01 (read only)
        // D7..4: Reserved         : 0x00
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 5] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 6] <= 8'h01;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 7] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 8] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 9] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 10] <= 8'h02;//bNrChannels       : 0x02 (2 channels)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 11] <= 8'h03;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 12] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 13] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 14] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 53 + 137 + 15] <= 8'h00;//iChannelNames     : 0x00 (No String Descriptor)
        //----- Audio Streaming Format Type Descriptor 2.0 ------
        descrom[DESC_HSCFG_ADDR + 53 + 153 + 0] <= 8'h06;//bLength         : 0x06 (6 bytes)
        descrom[DESC_HSCFG_ADDR + 53 + 153 + 1] <= 8'h24;//bDescriptorType : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 53 + 153 + 2] <= 8'h02;//bDescriptorSubtype : 0x02 (Format Type)
        descrom[DESC_HSCFG_ADDR + 53 + 153 + 3] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 53 + 153 + 4] <= 8'h03;//bSubslotSize       : 0x02 (3 bytes)
        descrom[DESC_HSCFG_ADDR + 53 + 153 + 5] <= 8'h18;//bBitResolution     : 0x10 (24 bits)
        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 53 + 159 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 53 + 159 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 53 + 159 + 2] <= 8'h01;//bEndpointAddress : 0x01 (Direction=OUT EndpointID=1)
        descrom[DESC_HSCFG_ADDR + 53 + 159 + 3] <= 8'h05;//bmAttributes     : 0x05 (TransferType=Isochronous  SyncType=Asynchronous  EndpointType=Data)
        descrom[DESC_HSCFG_ADDR + 53 + 159 + 4] <= 8'h08;//wMaxPacketSize   : 0x0308
        descrom[DESC_HSCFG_ADDR + 53 + 159 + 5] <= 8'h03;//wMaxPacketSize   : 0x0308
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x308 (776 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 53 + 159 + 6] <= 8'h01;//bInterval                : 0x01 (1 ms)
        //----------- Audio Data Endpoint Descriptor ------------
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 0] <= 8'h08;//bLength            : 0x08 (8 bytes)
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 1] <= 8'h25;//bDescriptorType    : 0x25 (Audio Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (General)
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 3] <= 8'h00;//bmAttributes       : 0x00
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 4] <= 8'h00;//bLockDelayUnits    : 0x00
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 5] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 6] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 53 + 166 + 7] <= 8'h00;//wLockDelay         : 0x0000
        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 53 + 174 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 53 + 174 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 53 + 174 + 2] <= 8'h81;//bEndpointAddress : 0x81 (Direction=IN EndpointID=1)
        descrom[DESC_HSCFG_ADDR + 53 + 174 + 3] <= 8'h11;//bmAttributes     : 0x11 (TransferType=Isochronous  SyncType=None  EndpointType=Feedback)
        descrom[DESC_HSCFG_ADDR + 53 + 174 + 4] <= 8'h04;//wMaxPacketSize   : 0x0004
        descrom[DESC_HSCFG_ADDR + 53 + 174 + 5] <= 8'h00;//wMaxPacketSize   : 0x0004
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x04 (4 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 53 + 174 + 6] <= 8'h04;//bInterval        : 0x04 (4 ms)

        //---------------- Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 1] <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 2] <= 8'h01;//bInterfaceNumber   : 0x01
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 3] <= 8'h03;//bAlternateSetting  : 0x03
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 4] <= 8'h02;//bNumEndpoints      : 0x02 (2 Endpoints)
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 5] <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 6] <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 7] <= 8'h20;//bInterfaceProtocol : 0x20 (Device Protocol Version 2.0)
        descrom[DESC_HSCFG_ADDR + 106 + 128 + 8] <= 8'h00;//iInterface         : 0x00 (No String Descriptor)
        //------ Audio Streaming Interface Descriptor 2.0 -------
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 0] <= 8'h10;//bLength            : 0x10 (16 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (AS General)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 3] <= 8'h01;//bTerminalLink      : 0x01 (1)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 4] <= 8'h05;//bmControls         : 0x05
        // D1..0: Active Alt Settng: 0x01 (read only)
        // D3..2: Valid Alt Settng : 0x01 (read only)
        // D7..4: Reserved         : 0x00
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 5] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 6] <= 8'h01;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 7] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 8] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 9] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 10] <= 8'h02;//bNrChannels       : 0x02 (2 channels)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 11] <= 8'h03;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 12] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 13] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 14] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 137 + 15] <= 8'h00;//iChannelNames     : 0x00 (No String Descriptor)
        //----- Audio Streaming Format Type Descriptor 2.0 ------
        descrom[DESC_HSCFG_ADDR + 106 + 153 + 0] <= 8'h06;//bLength         : 0x06 (6 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 153 + 1] <= 8'h24;//bDescriptorType : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 153 + 2] <= 8'h02;//bDescriptorSubtype : 0x02 (Format Type)
        descrom[DESC_HSCFG_ADDR + 106 + 153 + 3] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 106 + 153 + 4] <= 8'h04;//bSubslotSize       : 0x02 (4 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 153 + 5] <= 8'h20;//bBitResolution     : 0x10 (32 bits)
        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 106 + 159 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 159 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 159 + 2] <= 8'h01;//bEndpointAddress : 0x01 (Direction=OUT EndpointID=1)
        descrom[DESC_HSCFG_ADDR + 106 + 159 + 3] <= 8'h05;//bmAttributes     : 0x05 (TransferType=Isochronous  SyncType=Asynchronous  EndpointType=Data)
        descrom[DESC_HSCFG_ADDR + 106 + 159 + 4] <= 8'h08;//wMaxPacketSize   : 0x0308
        descrom[DESC_HSCFG_ADDR + 106 + 159 + 5] <= 8'h03;//wMaxPacketSize   : 0x0308
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x308 (776 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 106 + 159 + 6] <= 8'h01;//bInterval                : 0x01 (1 ms)
        //----------- Audio Data Endpoint Descriptor ------------
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 0] <= 8'h08;//bLength            : 0x08 (8 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 1] <= 8'h25;//bDescriptorType    : 0x25 (Audio Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (General)
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 3] <= 8'h00;//bmAttributes       : 0x00
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 4] <= 8'h00;//bLockDelayUnits    : 0x00
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 5] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 6] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 106 + 166 + 7] <= 8'h00;//wLockDelay         : 0x0000
        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 106 + 174 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 174 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 174 + 2] <= 8'h81;//bEndpointAddress : 0x81 (Direction=IN EndpointID=1)
        descrom[DESC_HSCFG_ADDR + 106 + 174 + 3] <= 8'h11;//bmAttributes     : 0x11 (TransferType=Isochronous  SyncType=None  EndpointType=Feedback)
        descrom[DESC_HSCFG_ADDR + 106 + 174 + 4] <= 8'h04;//wMaxPacketSize   : 0x0004
        descrom[DESC_HSCFG_ADDR + 106 + 174 + 5] <= 8'h00;//wMaxPacketSize   : 0x0004
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x04 (4 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 106 + 174 + 6] <= 8'h04;//bInterval        : 0x04 (4 ms)

        //---------------- Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 1] <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 2] <= 8'h02;//bInterfaceNumber   : 0x02
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 3] <= 8'h00;//bAlternateSetting  : 0x00
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 4] <= 8'h00;//bNumEndpoints      : 0x00 (Default Control Pipe only)
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 5] <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 6] <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 7] <= 8'h20;//bInterfaceProtocol : 0x20 (Device Protocol Version 2.0)
        descrom[DESC_HSCFG_ADDR + 106 + 181 + 8] <= 8'h04;//iInterface         : 0x04 (String Descriptor 4)
        //---------------- Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 0] <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 1] <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 2] <= 8'h02;//bInterfaceNumber   : 0x02
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 3] <= 8'h01;//bAlternateSetting  : 0x01
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 4] <= 8'h02;//bNumEndpoints      : 0x02 (2 Endpoints)
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 5] <= 8'h01;//bInterfaceClass    : 0x01 (Audio)
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 6] <= 8'h02;//bInterfaceSubClass : 0x02 (Audio Streaming)
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 7] <= 8'h20;//bInterfaceProtocol : 0x20 (Device Protocol Version 2.0)
        descrom[DESC_HSCFG_ADDR + 106 + 190 + 8] <= 8'h00;//iInterface         : 0x00 (No String Descriptor)
        //------ Audio Streaming Interface Descriptor 2.0 -------
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 0] <= 8'h10;//bLength            : 0x10 (16 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 1] <= 8'h24;//bDescriptorType    : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (AS General)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 3] <= 8'h08;//bTerminalLink      : 0x03 (3)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 4] <= 8'h05;//bmControls         : 0x05
        // D1..0: Active Alt Settng: 0x01 (read only)
        // D3..2: Valid Alt Settng : 0x01 (read only)
        // D7..4: Reserved         : 0x00
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 5] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 6] <= 8'h01;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 7] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 8] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 9] <= 8'h00;//bmFormats          : 0x00000001 (PCM)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 10] <= 8'h02;//bNrChannels       : 0x02 (2 channels)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 11] <= 8'h03;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 12] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 13] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 14] <= 8'h00;//bmChannelConfig   : 0x00000003 (FL, FR)
        descrom[DESC_HSCFG_ADDR + 106 + 199 + 15] <= 8'h00;//iChannelNames     : 0x00 (No String Descriptor)
        //----- Audio Streaming Format Type Descriptor 2.0 ------
        descrom[DESC_HSCFG_ADDR + 106 + 215 + 0] <= 8'h06;//bLength         : 0x06 (6 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 215 + 1] <= 8'h24;//bDescriptorType : 0x24 (Audio Interface Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 215 + 2] <= 8'h02;//bDescriptorSubtype : 0x02 (Format Type)
        descrom[DESC_HSCFG_ADDR + 106 + 215 + 3] <= 8'h01;//bFormatType        : 0x01 (FORMAT_TYPE_I)
        descrom[DESC_HSCFG_ADDR + 106 + 215 + 4] <= 8'h02;//bSubslotSize       : 0x02 (2 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 215 + 5] <= 8'h10;//bBitResolution     : 0x10 (16 bits)
        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 106 + 221 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 221 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 221 + 2] <= 8'h82;//bEndpointAddress : 0x82 (Direction=IN EndpointID=2)
        descrom[DESC_HSCFG_ADDR + 106 + 221 + 3] <= 8'h09;//bmAttributes     : 0x05 (TransferType=Isochronous  SyncType=Asynchronous  EndpointType=Data)
        descrom[DESC_HSCFG_ADDR + 106 + 221 + 4] <= 8'h08;//wMaxPacketSize   : 0x0308
        descrom[DESC_HSCFG_ADDR + 106 + 221 + 5] <= 8'h03;//wMaxPacketSize   : 0x0308
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x308 (776 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 106 + 221 + 6] <= 8'h01;//bInterval                : 0x01 (1 ms)
        //----------- Audio Data Endpoint Descriptor ------------
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 0] <= 8'h08;//bLength            : 0x08 (8 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 1] <= 8'h25;//bDescriptorType    : 0x25 (Audio Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 2] <= 8'h01;//bDescriptorSubtype : 0x01 (General)
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 3] <= 8'h00;//bmAttributes       : 0x00
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 4] <= 8'h00;//bLockDelayUnits    : 0x00
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 5] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 6] <= 8'h00;//wLockDelay         : 0x0000
        descrom[DESC_HSCFG_ADDR + 106 + 228 + 7] <= 8'h00;//wLockDelay         : 0x0000
        ////----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR + 106 + 236 + 0] <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR + 106 + 236 + 1] <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR + 106 + 236 + 2] <= 8'h02;//bEndpointAddress : 0x02 (Direction=OUT EndpointID=2)
        descrom[DESC_HSCFG_ADDR + 106 + 236 + 3] <= 8'h11;//bmAttributes     : 0x11 (TransferType=Isochronous  SyncType=None  EndpointType=Feedback)
        descrom[DESC_HSCFG_ADDR + 106 + 236 + 4] <= 8'h04;//wMaxPacketSize   : 0x0004
        descrom[DESC_HSCFG_ADDR + 106 + 236 + 5] <= 8'h00;//wMaxPacketSize   : 0x0004
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x04 (4 bytes per packet)
        descrom[DESC_HSCFG_ADDR + 106 + 236 + 6] <= 8'h04;//bInterval        : 0x04 (4 ms)

        //----------------HID Interface Descriptor -----------------
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 0]  <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 1]  <= 8'h04;//bDescriptorType    : 0x04 (Interface Descriptor)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 2]  <= 8'h03;//bInterfaceNumber   : 0x03
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 3]  <= 8'h00;//bAlternateSetting  : 0x00
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 4]  <= 8'h01;//bNumEndpoints      : 0x01 (2 Endpoints)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 5]  <= 8'h03;//bInterfaceClass    : 0x03 (HID - Human Interface Device)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 6]  <= 8'h00;//bInterfaceSubClass : 0x00 (None)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 7]  <= 8'h00;//bInterfaceProtocol : 0x00 (None)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 243 + 8]  <= 8'h07;//iInterface         : 0x07 (String Descriptor 7)

        //------------------- HID Descriptor --------------------
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 0]  <= 8'h09;//bLength            : 0x09 (9 bytes)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 1]  <= 8'h21;//bDescriptorType    : 0x21 (HID Descriptor)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 2]  <= 8'h11;//bcdHID             : 0x0111 (HID Version 1.11)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 3]  <= 8'h01;//bcdHID             : 0x0111 (HID Version 1.11)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 4]  <= 8'h00;//bCountryCode       : 0x00 (00 = not localized)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 5]  <= 8'h01;//bNumDescriptors    : 0x01
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 6]  <= 8'h22;//bDescriptorType    : 0x22 (Class=Report)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 7]  <= 8'h2B;//wDescriptorLength  : 0x002B (43 bytes)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 252 + 8]  <= 8'h00;//wDescriptorLength  : 0x002B (43 bytes)

        //----------------- Endpoint Descriptor -----------------
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 261 + 0]  <= 8'h07;//bLength          : 0x07 (7 bytes)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 261 + 1]  <= 8'h05;//bDescriptorType  : 0x05 (Endpoint Descriptor)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 261 + 2]  <= 8'h05;//bEndpointAddress : 0x05 (Direction=OUT EndpointID=5)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 261 + 3]  <= 8'h03;//bmAttributes     : 0x03 (TransferType=Interrupt)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 261 + 4]  <= 8'h08;//wMaxPacketSize   : 0x0008
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 261 + 5]  <= 8'h00;//wMaxPacketSize   : 0x0008
        // Bits 15..13             : 0x00 (reserved, must be zero)
        // Bits 12..11             : 0x00 (0 additional transactions per microframe -> allows 1..1024 bytes per packet)
        // Bits 10..0              : 0x08 (8 bytes per packet)
        descrom[DESC_HSCFG_ADDR - 0 + 106+ 261 + 6]  <= 8'h00;//bInterval        : 0x00

        //------------ Other Speed Configuration Descriptor -------------
        descrom[DESC_OSCFG_ADDR + 0] <= 8'h07;//bDescriptorType          : 0x07 (Other_speed_configuration Descriptor)
        descrom[DESC_HIDRPT_ADDR + 0] <= 8'h05;//Header 0x05
        //Bit 1..0 : 0x01 (bSize 1 byte)
        //Bit 3..2 : 0x01 (bType Global)
        //Bit 8..4 : 0x00 (bTag Usage Page)
        descrom[DESC_HIDRPT_ADDR + 1] <= 8'h0C;//

        descrom[DESC_HIDRPT_ADDR + 2] <= 8'h09;//Usage consumer control
        descrom[DESC_HIDRPT_ADDR + 3] <= 8'h01;//Usage consumer control

        descrom[DESC_HIDRPT_ADDR + 4] <= 8'hA1;//Collection Application
        descrom[DESC_HIDRPT_ADDR + 5] <= 8'h01;//Collection Application

        descrom[DESC_HIDRPT_ADDR + 6] <= 8'h15;//Logocal Minimum
        descrom[DESC_HIDRPT_ADDR + 7] <= 8'h00;//Logocal Minimum

        descrom[DESC_HIDRPT_ADDR + 8] <= 8'h25;//Logocal Maximum
        descrom[DESC_HIDRPT_ADDR + 9] <= 8'h01;//Logocal Maximum

        descrom[DESC_HIDRPT_ADDR + 10] <= 8'h75;//Report Size
        descrom[DESC_HIDRPT_ADDR + 11] <= 8'h01;//Report Size

        descrom[DESC_HIDRPT_ADDR + 12] <= 8'h95;//Report Count
        descrom[DESC_HIDRPT_ADDR + 13] <= 8'h07;//Report Count

        descrom[DESC_HIDRPT_ADDR + 14] <= 8'h09;//Volume Increment
        descrom[DESC_HIDRPT_ADDR + 15] <= 8'hE9;//Volume Increment

        descrom[DESC_HIDRPT_ADDR + 16] <= 8'h09;//Volume Decrement
        descrom[DESC_HIDRPT_ADDR + 17] <= 8'hEA;//Volume Decrement

        descrom[DESC_HIDRPT_ADDR + 18] <= 8'h09;//Mute
        descrom[DESC_HIDRPT_ADDR + 19] <= 8'hE2;//Mute

        descrom[DESC_HIDRPT_ADDR + 20] <= 8'h09;//Stop
        descrom[DESC_HIDRPT_ADDR + 21] <= 8'hB7;//Stop

        descrom[DESC_HIDRPT_ADDR + 22] <= 8'h09;//Play/Pause
        descrom[DESC_HIDRPT_ADDR + 23] <= 8'hCD;//Play/Pause

        descrom[DESC_HIDRPT_ADDR + 24] <= 8'h09;//Scan Next Track
        descrom[DESC_HIDRPT_ADDR + 25] <= 8'hB5;//Scan Next Track

        descrom[DESC_HIDRPT_ADDR + 26] <= 8'h09;//Scan Previout Track
        descrom[DESC_HIDRPT_ADDR + 27] <= 8'hB6;//Scan Previout Track

        descrom[DESC_HIDRPT_ADDR + 28] <= 8'h81;//Input Data Var Abs
        descrom[DESC_HIDRPT_ADDR + 29] <= 8'h02;//Input Data Var Abs

        descrom[DESC_HIDRPT_ADDR + 30] <= 8'h95;//Report Count
        descrom[DESC_HIDRPT_ADDR + 31] <= 8'h39;//Report Count

        descrom[DESC_HIDRPT_ADDR + 32] <= 8'h81;//Input Const Var Abs
        descrom[DESC_HIDRPT_ADDR + 33] <= 8'h03;// nput Const Var Abs

        descrom[DESC_HIDRPT_ADDR + 34] <= 8'h75;//Report Size
        descrom[DESC_HIDRPT_ADDR + 35] <= 8'h08;//Report Size

        descrom[DESC_HIDRPT_ADDR + 36] <= 8'h95;//Report Count
        descrom[DESC_HIDRPT_ADDR + 37] <= 8'h07;//Report Count

        descrom[DESC_HIDRPT_ADDR + 38] <= 8'h09;//Usage Unassigned
        descrom[DESC_HIDRPT_ADDR + 39] <= 8'h00;//Usage Unassigned

        descrom[DESC_HIDRPT_ADDR + 40] <= 8'h91;//Output Data Var Abs
        descrom[DESC_HIDRPT_ADDR + 41] <= 8'h02;//Output Data Var Abs

        descrom[DESC_HIDRPT_ADDR + 42] <= 8'hC0;//End Collection

        if(descrom_len > DESC_STRLANG_ADDR)begin
            // string descriptor 0 (supported languages)
            descrom[DESC_STRLANG_ADDR + 0] <= 8'h04;                // bLength = 4
            descrom[DESC_STRLANG_ADDR + 1] <= 8'h03;                // bDescriptorType = string descriptor
            descrom[DESC_STRLANG_ADDR + 2] <= 8'h09;
            descrom[DESC_STRLANG_ADDR + 3] <= 8'h04;         // wLangId[0] = 0x0409 = English U.S.
            descrom[DESC_STRVENDOR_ADDR + 0] <= 2 + 2*VENDORSTR_LEN;
            descrom[DESC_STRVENDOR_ADDR + 1] <= 8'h03;
            for(i = 0; i < VENDORSTR_LEN; i = i + 1) begin
                for(z = 0; z < 8; z = z + 1) begin
                    descrom[DESC_STRVENDOR_ADDR+ 2*i + 2][z] <= VENDORSTR[(VENDORSTR_LEN - 1 -i)*8+z];
                end
                descrom[DESC_STRVENDOR_ADDR+ 2*i + 3] <= 8'h00;
            end
            descrom[DESC_STRPRODUCT_ADDR + 0] <= 2 + 2*PRODUCTSTR_LEN;
            descrom[DESC_STRPRODUCT_ADDR + 1] <= 8'h03;
            for(i = 0; i < PRODUCTSTR_LEN; i = i + 1) begin
                for(z = 0; z < 8; z = z + 1) begin
                    descrom[DESC_STRPRODUCT_ADDR + 2*i + 2][z] <= PRODUCTSTR[(PRODUCTSTR_LEN - 1 - i)*8+z];
                end
                descrom[DESC_STRPRODUCT_ADDR + 2*i + 3] <= 8'h00;
            end
            descrom[DESC_STRSERIAL_ADDR + 0] <= 2 + 2*SERIALSTR_LEN;
            descrom[DESC_STRSERIAL_ADDR + 1] <= 8'h03;
            for(i = 0; i < SERIALSTR_LEN; i = i + 1) begin
                for(z = 0; z < 8; z = z + 1) begin
                    descrom[DESC_STRSERIAL_ADDR + 2*i + 2][z] <= SERIALSTR[(SERIALSTR_LEN - 1 - i)*8+z];
                end
                descrom[DESC_STRSERIAL_ADDR + 2*i + 3] <= 8'h00;
            end

            descrom[DESC_STR4_ADDR + 0] <= 2 + 2*STR4_LEN;
            descrom[DESC_STR4_ADDR + 1] <= 8'h03;
            for(i = 0; i < STR4_LEN; i = i + 1) begin
                for(z = 0; z < 8; z = z + 1) begin
                    descrom[DESC_STR4_ADDR + 2*i + 2][z] <= STR4[(STR4_LEN - 1 - i)*8+z];
                end
                descrom[DESC_STR4_ADDR + 2*i + 3] <= 8'h00;
            end
            descrom[DESC_STR5_ADDR + 0] <= 2 + 2*STR5_LEN;
            descrom[DESC_STR5_ADDR + 1] <= 8'h03;
            for(i = 0; i < STR5_LEN; i = i + 1) begin
                for(z = 0; z < 8; z = z + 1) begin
                    descrom[DESC_STR5_ADDR + 2*i + 2][z] <= STR5[(STR5_LEN - 1 - i)*8+z];
                end
                descrom[DESC_STR5_ADDR + 2*i + 3] <= 8'h00;
            end
            descrom[DESC_STR6_ADDR + 0] <= 2 + 2*STR6_LEN;
            descrom[DESC_STR6_ADDR + 1] <= 8'h03;
            for(i = 0; i < STR6_LEN; i = i + 1) begin
                for(z = 0; z < 8; z = z + 1) begin
                    descrom[DESC_STR6_ADDR + 2*i + 2][z] <= STR6[(STR6_LEN - 1 - i)*8+z];
                end
                descrom[DESC_STR6_ADDR + 2*i + 3] <= 8'h00;
            end
            descrom[DESC_STR7_ADDR + 0] <= 2 + 2*STR7_LEN;
            descrom[DESC_STR7_ADDR + 1] <= 8'h03;
            for(i = 0; i < STR7_LEN; i = i + 1) begin
                for(z = 0; z < 8; z = z + 1) begin
                    descrom[DESC_STR7_ADDR + 2*i + 2][z] <= STR7[(STR7_LEN - 1 - i)*8+z];
                end
                descrom[DESC_STR7_ADDR + 2*i + 3] <= 8'h00;
            end
        end
      end
    assign o_descrom_rdat = descrom[i_descrom_raddr];
endmodule
