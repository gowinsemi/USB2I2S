module top
#(
  parameter p_loopback     = 1 //0 = microphone input.  1 = I2S audio received from usb host is sent back to usb host
)(
//interconnection
input          CLK_IN         ,//50MHZ
input          CLK_IIS_I      ,//

//I2S Microphone Input
output         IIS_LRCK_I     ,
output         IIS_BCLK_I     ,
input          IIS_DATA_I     ,

//I2S Amplifier Output
output         IIS_LRCK_O     ,
output         IIS_BCLK_O     ,
output         IIS_DATA_O     ,

inout          usb_dxp_io     ,
inout          usb_dxn_io     ,
input          usb_rxdp_i     ,
input          usb_rxdn_i     ,
output         usb_pullup_en_o,
inout          usb_term_dp_io ,
inout          usb_term_dn_io

);
localparam  SAMPLE_RATE_32    = 32'h00007D00;
localparam  SAMPLE_RATE_44_1  = 32'h0000AC44;
localparam  SAMPLE_RATE_48    = 32'h0000BB80;
localparam  SAMPLE_RATE_64    = 32'h0000FA00;
localparam  SAMPLE_RATE_88_2  = 32'h00015888;
localparam  SAMPLE_RATE_96    = 32'h00017700;
localparam  SAMPLE_RATE_128   = 32'h0001F400;
localparam  SAMPLE_RATE_176_4 = 32'h0002B110;
localparam  SAMPLE_RATE_192   = 32'h0002EE00;
localparam  SAMPLE_RATE_352_8 = 32'h00056220;
localparam  SAMPLE_RATE_384   = 32'h0005DC00;
localparam  SAMPLE_RATE_705_6 = 32'h000AC440;
localparam  SAMPLE_RATE_768   = 32'h000BB800;
localparam  VOLUME_NUM = 16'h0001;
localparam  VOLUME_MIN = 16'hC080;
localparam  VOLUME_MAX = 16'h0000;
localparam  VOLUME_RES = 16'h0080;
reg [ 7:0] stage;
reg [ 7:0] sub_stage;
reg [ 7:0] req_type;
reg [ 7:0] req_code;
reg [15:0] wValue;
reg [15:0] wIndex;
reg [15:0] wLength;
reg        set_sample_rate;
reg [7:0]  sample_rate_data [0:157];
reg [16:0] sample_rate_addr;
reg [15:0] ch0_volume_cur;
reg [15:0] ch1_volume_cur;
reg [15:0] ch2_volume_cur;
reg get_ch0_volume_range;
reg get_ch1_volume_range;
reg get_ch2_volume_range;
reg get_ch0_volume_cur;
reg get_ch1_volume_cur;
reg get_ch2_volume_cur;
reg get_mute_cur;
reg get_clk_range;
reg get_clk_cur;
wire [1:0]  PHY_XCVRSELECT      ;
wire        PHY_TERMSELECT      ;
wire [1:0]  PHY_OPMODE          ;
wire [1:0]  PHY_LINESTATE       ;
wire        PHY_TXVALID         ;
wire        PHY_TXREADY         ;
wire        PHY_RXVALID         ;
wire        PHY_RXACTIVE        ;
wire        PHY_RXERROR         ;
wire [7:0]  PHY_DATAIN          ;
wire [7:0]  PHY_DATAOUT         ;
wire        PHY_CLKOUT          ;
wire [15:0] DESCROM_RADDR       ;
wire [7:0]  DESC_INDEX          ;
wire [7:0]  DESC_TYPE           ;
wire [7:0]  DESCROM_RDAT        ;
wire [15:0] DESC_DEV_ADDR       ;
wire [15:0] DESC_DEV_LEN        ;
wire [15:0] DESC_QUAL_ADDR      ;
wire [15:0] DESC_QUAL_LEN       ;
wire [15:0] DESC_FSCFG_ADDR     ;
wire [15:0] DESC_FSCFG_LEN      ;
wire [15:0] DESC_HSCFG_ADDR     ;
wire [15:0] DESC_HSCFG_LEN      ;
wire [15:0] DESC_OSCFG_ADDR     ;
wire [15:0] DESC_HIDRPT_ADDR    ;
wire [15:0] DESC_HIDRPT_LEN     ;
wire [15:0] DESC_STRLANG_ADDR   ;
wire [15:0] DESC_STRVENDOR_ADDR ;
wire [15:0] DESC_STRVENDOR_LEN  ;
wire [15:0] DESC_STRPRODUCT_ADDR;
wire [15:0] DESC_STRPRODUCT_LEN ;
wire [15:0] DESC_STRSERIAL_ADDR ;
wire [15:0] DESC_STRSERIAL_LEN  ;
wire        DESCROM_HAVE_STRINGS;
wire [ 7:0] usb_txdat           ;
reg  [11:0] usb_txdat_len       ;
wire        usb_txcork          ;
wire        usb_txpop           ;
wire        usb_txact           ;
wire        usb_txpktfin        ;
wire [ 7:0] usb_rxdat           ;
wire        usb_rxval           ;
wire        usb_rxact           ;
wire        rxpktval            ;
wire        setup_active        ;
wire [ 3:0] endpt_sel           ;
wire        usb_sof             ;
wire [7:0] interface_alter_i;
wire [7:0] interface_alter_o;
wire [7:0] interface_sel;
wire       interface_update;
reg  [7:0] interface0_alter;
reg  [7:0] interface1_alter;
reg        iis_freq_sel;
wire        clkoutd_o            ;
reg [31:0] sample_rate_cur;
reg        endpt0_send;
reg  [7:0] endpt0_dat;
wire [7:0] audio_rx_data;
reg [15:0] ff_int;
reg [15:0] ff_frac;
wire [10:0] audio_rx_num;
reg  [5:0] q_lrclk;
wire       w_lrck_source, w_data_source;

//==============================================================
//======PLL 
Gowin_rPLL u_pll(
    .clkout (fclk_480M ), //output clkout
    .clkoutd(PHY_CLKOUT), //output clkout
    .lock   (pll_locked), 
    .clkin  (CLK_IN    )  //input clkin
);

wire [3:0] clk_sel;
wire       iis_clk;

wire CLK_45_I;
wire CLK_49_I;

assign clk_sel[0] = !iis_freq_sel;
assign clk_sel[1] = iis_freq_sel;
assign clk_sel[2] = 1'b0;
assign clk_sel[3] = 1'b0;


iis_rPLL u_iis_rPLL(
    .clkin (CLK_IIS_I  ),//input clkin
    .clkoutd(clkoutd_o), //output clkoutd
    .clkout(fclk      ) //output clkout  //98MHZ
);
//==============================================================
//======Reset
assign RESET = !(pll_locked);

//==============================================================
//======IIS TX and RX
reg [11:0] s_sample_freq;
reg [ 7:0] s_bclk_div;
reg [ 7:0] s_data_bits;
reg [ 7:0] s_channel_bits;
reg        audio_reset;
wire       dop_en;

always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        s_data_bits <= 8'd32;
        audio_reset <= 1'b0;
    end
    else begin
        if (interface_update) begin
            audio_reset <= 1'b1;
        end
        else begin
            audio_reset <= 1'b0;
        end
        if (interface1_alter == 8'h01) begin
            s_data_bits <= 8'd16;
        end
        else if (interface1_alter == 8'h02) begin
            s_data_bits <= 8'd24;
        end
        else if (interface1_alter == 8'h03) begin
            s_data_bits <= 8'd32;
        end
        else if (interface1_alter == 8'h04) begin
            s_data_bits <= 8'd32;
        end
    end
end
wire dsd_en = (interface1_alter == 8'h03);
//DSD 2.8224MHz (44.1*64)
//DSD 5.6448 (44.1*128)
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        s_sample_freq  <= 12'd48;
        s_bclk_div     <= 8'd32;
        s_channel_bits <= 8'd32;
        iis_freq_sel   <= 1'b1;
    end
    else begin
        if (sample_rate_cur == SAMPLE_RATE_768) begin
            s_sample_freq  <= 12'd768;
            s_bclk_div     <= 8'd2;
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_384) begin
            s_sample_freq  <= 12'd384;
            s_bclk_div     <= 8'd4;
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_192) begin
            s_sample_freq  <= 12'd192;
            s_bclk_div     <= 8'd8;
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_96) begin
            s_sample_freq  <= 12'd96;
            s_bclk_div     <= 8'd16;
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_48) begin
            s_sample_freq  <= 12'd48;
            s_bclk_div     <= 8'd32;  //8'd16
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_128) begin
            s_sample_freq  <= 12'd128;
            s_bclk_div     <= 8'd12;  //8'd16
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_64) begin
            s_sample_freq  <= 12'd64;
            s_bclk_div     <= 8'd24;  //8'd16
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_32) begin
            s_sample_freq  <= 12'd32;
            s_bclk_div     <= 8'd48;  //8'd16
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b0;
        end
        else if (sample_rate_cur == SAMPLE_RATE_705_6) begin
            s_sample_freq  <= 12'd705;
            s_bclk_div     <= 8'd2;
            s_channel_bits <= 8'd32;
            iis_freq_sel   <= 1'b1;
        end
        else if (sample_rate_cur == SAMPLE_RATE_352_8) begin
            s_sample_freq  <= 12'd352;
            s_bclk_div     <= 8'd2;
            s_channel_bits <= 8'd64;
            iis_freq_sel   <= 1'b1;
        end
        else if (sample_rate_cur == SAMPLE_RATE_176_4) begin
            s_sample_freq  <= 12'd176;
            s_bclk_div     <= 8'd4;
            s_channel_bits <= 8'd64;
            iis_freq_sel   <= 1'b1;
        end
        else if (sample_rate_cur == SAMPLE_RATE_88_2) begin
            s_sample_freq  <= 12'd88;
            s_bclk_div     <= 8'd8;
            s_channel_bits <= 8'd64;
            iis_freq_sel   <= 1'b1;
        end
        else if (sample_rate_cur == SAMPLE_RATE_44_1) begin
            s_sample_freq  <= 12'd44;
            s_bclk_div     <= 8'd16;
            s_channel_bits <= 8'd64;
            iis_freq_sel   <= 1'b1;
        end
    end
end

reg [7:0] sim_data;
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        sim_data <= 8'h00;
    end
    else begin
        if (usb_rxact&(endpt_sel == 4'd1)) begin
            if (usb_rxval) begin
                sim_data <= sim_data + 8'h01;
            end
        end
        else begin
            sim_data <= 8'h00;
        end
    end
end

wire PCM_LRCK;
wire PCM_BCLK;
wire PCM_DATA;
wire IIS_LRCK;
wire IIS_BCLK;
wire IIS_DATA;
wire fifo_r_empty;
wire fifo_r_alempty;
wire fifo_rdnum_diff_flag;
reg rx_fifo_rden;
reg rx_fifo_dval;
wire [7:0] rx_fifo_data;
wire [10:0] rx_fifo_wrnum;
wire rx_fifo_empty;
reg audio_rx_reset;
reg audio_tx_reset;



i2s_audio_tx audio_tx_inst0 //384 192 96 48
(
     .CLK                 (fclk                )//iis clock 98.304MHz
    ,.RESET               (RESET|audio_tx_reset   )//reset
    ,.PCLK                (PHY_CLKOUT          )//
    ,.DSD_EN              (dsd_en              )//
    ,.DSD_CLK_O           (DSD_CLK             )
    ,.DSD_DATA1_O         (DSD_DATA1           )
    ,.DSD_DATA2_O         (DSD_DATA2           )
    ,.TX_ACT              (rx_fifo_dval        )//(usb_rxact&(endpt_sel == 4'd1))//
    ,.TX_VALID            (rx_fifo_dval        )//(usb_rxval&(endpt_sel == 4'd1))//
    ,.TX_DATA             (rx_fifo_data        )//(usb_rxdat )//sim_data
    ,.SOF                 (usb_sof             )//
    ,.LEFT_EN             (1'b1                )//
    ,.RIGHT_EN            (1'b1                )//
    ,.SAMPLE_FREQ         (s_sample_freq       )
    ,.BCLK_DIV            (s_bclk_div          )
    ,.DATA_BITS           (s_data_bits         )
    ,.CHANNEL_BITS        (s_channel_bits      )
    ,.MCLK_O              (                    )
    ,.PCM_LRCK_O          (PCM_LRCK            )
    ,.PCM_BCLK_O          (PCM_BCLK            )
    ,.PCM_DATA_O          (PCM_DATA            )
    ,.DOP_EN_O            (dop_en              )
    ,.IIS_LRCK_O          (IIS_LRCK            )
    ,.IIS_BCLK_O          (IIS_BCLK            )
    ,.IIS_DATA_O          (IIS_DATA            )
    ,.fifo_r_empty        (fifo_r_empty        )
    ,.fifo_r_alempty      (fifo_r_alempty      )
    ,.fifo_rdnum_diff_flag(fifo_rdnum_diff_flag)
);


//==============================================================
//======Audio IN/OUT
reg [31:0] feedback_01;
reg [3:0] tx_cnt;
assign usb_txdat = (endpt_sel == 4'd0) ? endpt0_dat :
                   (endpt_sel == 4'd1) ? feedback_01[7:0] :
                   (endpt_sel == 4'd2) ? audio_rx_data[7:0] : 8'd0;
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        feedback_01 <= 32'd0;
    end
    else begin
        if (usb_txact&(endpt_sel == 4'd1)) begin
            if (usb_txpop) begin
                feedback_01 <= {8'd0,feedback_01[31:8]};
            end
        end
        else begin
            feedback_01 <= {ff_int[15:0],ff_frac[15:0]};
        end
    end
end
 
//==============================================================
//======Feedback
//sof sig dect
localparam F768_705_F_MAX = 64;
localparam F384_352_F_MAX = 32;
localparam F192_176_F_MAX = 16;
localparam F96_88_F_MAX = 8;
localparam F48_44_F_MAX = 4;
wire [7:0] T_meas;
wire [7:0] F_meas;
wire [15:0] F_meas_frac;
assign T_meas = (sample_rate_cur == 32'd768000)||(sample_rate_cur == 32'd705600) ? 64 :
                (sample_rate_cur == 32'd384000)||(sample_rate_cur == 32'd352800) ? 32 :
                (sample_rate_cur == 32'd192000)||(sample_rate_cur == 32'd176400) ? 16 :
                (sample_rate_cur == 32'd128000) ? 12 :
                (sample_rate_cur == 32'd64000) ? 6 :
                (sample_rate_cur == 32'd32000) ? 3 :
                (sample_rate_cur == 32'd96000)||(sample_rate_cur == 32'd88200) ? 8 :
                (sample_rate_cur == 32'd48000)||(sample_rate_cur == 32'd44100) ? 4 : 64;
assign F_meas = (sample_rate_cur == 32'd768000) ? 96 :
                (sample_rate_cur == 32'd705600) ? 88 :
                (sample_rate_cur == 32'd384000) ? 48 :
                (sample_rate_cur == 32'd352800) ? 45 :
                (sample_rate_cur == 32'd192000) ? 24 :
                (sample_rate_cur == 32'd176400) ? 23 :
                (sample_rate_cur == 32'd128000) ? 16 :
                (sample_rate_cur == 32'd96000 ) ? 12 :
                (sample_rate_cur == 32'd88200 ) ? 12 :
                (sample_rate_cur == 32'd64000 ) ? 8 :
                (sample_rate_cur == 32'd32000 ) ? 4 :
                (sample_rate_cur == 32'd48000 ) ? 6 :
                (sample_rate_cur == 32'd44100 ) ? 6 : 96;
assign F_meas_frac = (sample_rate_cur == 32'd768000) ? 16'h0000 :
                     (sample_rate_cur == 32'd705600) ? 16'h1970 :
                     (sample_rate_cur == 32'd384000) ? 16'h0000 :
                     (sample_rate_cur == 32'd352800) ? 16'h1978 :
                     (sample_rate_cur == 32'd192000) ? 16'h0000 :
                     //(sample_rate_cur == 32'd176400) ? 16'h0CC0 :
                     (sample_rate_cur == 32'd176400) ? 16'h0010 :
                     (sample_rate_cur == 32'd128000) ? 16'h0000 :
                     (sample_rate_cur == 32'd96000 ) ? 16'h0000 :
                     (sample_rate_cur == 32'd88200 ) ? 16'h1970 :
                     (sample_rate_cur == 32'd64000 ) ? 16'h0000 :
                     (sample_rate_cur == 32'd32000 ) ? 16'h0000 :
                     (sample_rate_cur == 32'd48000 ) ? 16'h0000 :
                     (sample_rate_cur == 32'd44100 ) ? 16'h8338 : 16'h0000;
reg [ 7:0] frame_cnt;
reg [31:0] fclk_cnt;
reg ff_clear;
reg ff_clear_d0;
reg ff_clear_d1;
wire ff_clear_rise;
reg [7:0] sof_keep_cnt;
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        ff_clear <= 1'b0;
        sof_keep_cnt <= 8'd0;
        ff_int <= 16'd0;
        ff_frac <= 16'd0;
    end
    else begin
        if (usb_sof) begin
            sof_keep_cnt <= 8'd0;
            if (frame_cnt >= T_meas) begin
                frame_cnt <= 8'd1;
                ff_clear <= 1'b1;
                if (fifo_r_alempty) begin
                    ff_int <= F_meas;
                    ff_frac <= 16'h6000;
                end
                else begin
                    ff_int <= F_meas;
                    ff_frac <= 16'h0000;
                end
            end
            else begin
                frame_cnt <= frame_cnt + 8'd1;
                ff_clear <= 1'b0;
            end
        end
        else begin
            if (sof_keep_cnt >= 5) begin
                ff_clear <= 1'b0;
            end
            else begin
                sof_keep_cnt <= sof_keep_cnt + 8'd1;
                ff_clear <= ff_clear;
            end
        end
    end
end
always@(posedge fclk, posedge RESET) begin
    if (RESET) begin
        ff_clear_d0 <= 1'b0;
        ff_clear_d1 <= 1'b0;
    end
    else begin
        ff_clear_d0 <= ff_clear;
        ff_clear_d1 <= ff_clear_d0;
    end
end
assign ff_clear_rise = ff_clear_d0&(!ff_clear_d1);
reg [31:0] sof_clk_cnt;
reg [31:0] sof_clk_cnt_d0;
always@(posedge fclk, posedge RESET) begin
    if (RESET) begin
        fclk_cnt <= 32'd0;
        sof_clk_cnt <= 32'd0;
        sof_clk_cnt_d0 <= 32'd0;
    end
    else begin
        if (ff_clear_rise) begin
            fclk_cnt <= 32'd0;
            sof_clk_cnt <= 32'd0;
        end
        else begin
            fclk_cnt <= fclk_cnt + 1'b1;
            sof_clk_cnt <= sof_clk_cnt + 32'd1;
        end
    end
end
//==============================================================
//======Interface Setting
assign interface_alter_i = (interface_sel == 0) ?  interface0_alter :
                           (interface_sel == 1) ?  interface1_alter : 8'd0;
always@(posedge PHY_CLKOUT, posedge RESET   ) begin
    if (RESET) begin
        interface0_alter <= 'd0;
        interface1_alter <= 'd0;
    end
    else begin
        if (interface_update) begin
            if (interface_sel == 0) begin
                interface0_alter <= interface_alter_o;
            end
            else if (interface_sel == 1) begin
                interface1_alter <= interface_alter_o;
            end
        end
    end
end

always@(posedge PHY_CLKOUT, posedge RESET   ) begin
    if (RESET) begin
        audio_rx_reset <= 1'b0;
        audio_tx_reset <= 1'b0;
    end
    else begin
        if (interface_update) begin
            if (interface_sel == 1) begin
                if (interface_alter_o == 8'd0) begin
                    audio_tx_reset <= 1'b1;
                end
                else begin
                    audio_tx_reset <= 1'b0;
                end
            end
            else if (interface_sel == 2) begin
                if (interface_alter_o == 8'd0) begin
                    audio_rx_reset <= 1'b1;
                end
                else begin
                    audio_rx_reset <= 1'b0;
                end
            end
        end
        else begin
            audio_rx_reset <= 1'b0;
            audio_tx_reset <= 1'b0;
        end
    end
end
//==============================================================
//======


sync_pkt_fifo  #(
     .DSIZE (8)
    ,.ASIZE (10)
)sync_pkt_fifo
(
     .CLK   (PHY_CLKOUT  )
    ,.RSTn  (!RESET      )
    ,.write (usb_rxact&usb_rxval&(endpt_sel==4'd1))
    ,.iData (usb_rxdat                  )
    ,.pktval(rxpktval&(endpt_sel==4'd1) )
    ,.rxact (usb_rxact&(endpt_sel==4'd1))
    ,.read  (rx_fifo_rden )
    ,.oData (rx_fifo_data )
    ,.wrnum (rx_fifo_wrnum)
    ,.full  (             )
    ,.empty (rx_fifo_empty)
);
always @(posedge PHY_CLKOUT or posedge RESET) begin
    if (RESET) begin
        rx_fifo_rden <= 1'b0;
    end
    else begin
        //if ((rx_fifo_empty == 0)&&(rx_fifo_rden == 1'b0)) begin
        if (rx_fifo_empty == 0) begin
            rx_fifo_rden <= 1'b1;
        end
        else begin
            rx_fifo_rden <= 1'b0;
        end
    end
end
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        rx_fifo_dval <= 1'b0;
    end
    else begin
        rx_fifo_dval <= rx_fifo_rden & (rx_fifo_empty == 0);
    end
end


//==============================================================
//======IIS RX

assign w_lrck_source = p_loopback ? IIS_LRCK_O : IIS_LRCK_I;  //loopback mode takes I2S data from USB and sends it back out USB.  Otherwise use I2S microphone input
assign w_data_source = p_loopback ? IIS_DATA_O : IIS_DATA_I;
assign IIS_BCLK_I    = IIS_BCLK;

i2s_audio_rx audio_rx_inst
(
     .MCLK          (fclk          )//clock
    ,.RESET         (RESET|audio_rx_reset)//reset
    ,.L_EN_I        (1'b1          )
    ,.R_EN_I        (1'b1          )
    ,.PCM_EN_I      (1'b0          )
    ,.DATA_BITS_I   (s_data_bits   )
    ,.MONO_R_I      (p_loopback==0 )//use mono input (right side only).  Use for microphone if there is only one on I2S interface bus
    ,.PCM_LRCK_I    (1'b0          )
    ,.PCM_BCLK_I    (1'b0          )
    ,.PCM_DATA_I    (1'b0          )
    ,.IIS_LRCK_I    (w_lrck_source )
    ,.IIS_BCLK_I    (IIS_BCLK_I    )
    ,.IIS_DATA_I    (w_data_source )
    ,.LRCK_O        (IIS_LRCK_I    )
    ,.RD_CLK        (PHY_CLKOUT    )
    ,.USB_TXPKTVAL  (usb_txpktfin  )
    ,.USB_TXACT     (usb_txact     )
    ,.FIFO_RD_I     (usb_txpop&(endpt_sel == 4'd2))
    ,.FIFO_RD_DATA_O(audio_rx_data )
    ,.FIFO_RDNUM_O  (audio_rx_num  )
);

//==============================================================
//======Tx Cork
reg [11:0] sub_packet_size;
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        sub_packet_size <= 12'd0;
    end
    else begin
        if (s_data_bits == 8'd8) begin
            sub_packet_size <= {2'd0,s_sample_freq[11:2]};//2 Channel 125us(Freq*1*2/8)
        end
        else if (s_data_bits == 8'd16) begin
            sub_packet_size <= {1'd0,s_sample_freq[11:1]};//2 Channel 125us(Freq*1*2/8)
        end
        else if (s_data_bits == 8'd24) begin
            sub_packet_size <= {1'd0,s_sample_freq[11:1]} + s_sample_freq[11:2];//2 Channel 125us(Freq*3*2/8)
        end
        else if (s_data_bits == 8'd32) begin
            sub_packet_size <= s_sample_freq;//2 Channel 125us(Freq*4*2/8)
        end
    end
end
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        usb_txdat_len <= 12'd32;
    end
    else begin
        if (usb_txact) begin
            usb_txdat_len <= usb_txdat_len;
        end
        else if (endpt_sel == 4'd1) begin
            usb_txdat_len <= 12'd4;
        end
        else if (endpt_sel == 4'd2) begin
            usb_txdat_len <= sub_packet_size;
        end
    end
end
assign usb_txcork = (endpt_sel == 4'd6) ? 1'b1 :
                    (endpt_sel == 4'd2) ? (audio_rx_num < sub_packet_size) : 1'b0;
//==============================================================
//======USB Device Controller
USB_Device_Controller_Top u_usb_device_controller_top (
         .clk_i                 (PHY_CLKOUT          )
        ,.reset_i               (RESET               )
        ,.usbrst_o              (usb_busreset        )
        ,.highspeed_o           (usb_highspeed       )
        ,.suspend_o             (usb_suspend         )
        ,.online_o              (usb_online          )
        ,.txdat_i               (usb_txdat           )
        ,.txval_i               (endpt0_send         )
        ,.txdat_len_i           (usb_txdat_len       )
        ,.txcork_i              (usb_txcork          )
        ,.txiso_pid_i           (4'b0011             )//DATA0
        ,.txpop_o               (usb_txpop           )
        ,.txact_o               (usb_txact           )
        ,.txpktfin_o            (usb_txpktfin        )
        ,.rxdat_o               (usb_rxdat           )
        ,.rxval_o               (usb_rxval           )
        ,.rxact_o               (usb_rxact           )
        ,.rxrdy_i               (1'b1                )
        ,.rxpktval_o            (rxpktval            )
        ,.setup_o               (setup_active        )
        ,.endpt_o               (endpt_sel           )
        ,.sof_o                 (usb_sof             )
        ,.inf_alter_i           (interface_alter_i   )
        ,.inf_alter_o           (interface_alter_o   )
        ,.inf_sel_o             (interface_sel       )
        ,.inf_set_o             (interface_update    )
        ,.descrom_rdata_i       (DESCROM_RDAT        )
        ,.descrom_raddr_o       (DESCROM_RADDR       )
        ,.desc_index_o          (DESC_INDEX          )
        ,.desc_type_o           (DESC_TYPE           )
        ,.desc_dev_addr_i       (DESC_DEV_ADDR       )
        ,.desc_dev_len_i        (DESC_DEV_LEN        )
        ,.desc_qual_addr_i      (DESC_QUAL_ADDR      )
        ,.desc_qual_len_i       (DESC_QUAL_LEN       )
        ,.desc_fscfg_addr_i     (DESC_FSCFG_ADDR     )
        ,.desc_fscfg_len_i      (DESC_FSCFG_LEN      )
        ,.desc_hscfg_addr_i     (DESC_HSCFG_ADDR     )
        ,.desc_hscfg_len_i      (DESC_HSCFG_LEN      )
        ,.desc_oscfg_addr_i     (DESC_OSCFG_ADDR     )
        ,.desc_hidrpt_addr_i    (DESC_HIDRPT_ADDR    )
        ,.desc_hidrpt_len_i     (DESC_HIDRPT_LEN     )
        ,.desc_strlang_addr_i   (DESC_STRLANG_ADDR   )
        ,.desc_strvendor_addr_i (DESC_STRVENDOR_ADDR )
        ,.desc_strvendor_len_i  (DESC_STRVENDOR_LEN  )
        ,.desc_strproduct_addr_i(DESC_STRPRODUCT_ADDR)
        ,.desc_strproduct_len_i (DESC_STRPRODUCT_LEN )
        ,.desc_strserial_addr_i (DESC_STRSERIAL_ADDR )
        ,.desc_strserial_len_i  (DESC_STRSERIAL_LEN  )
        ,.desc_have_strings_i   (DESCROM_HAVE_STRINGS)
        ,.utmi_dataout_o        (PHY_DATAOUT         )
        ,.utmi_txvalid_o        (PHY_TXVALID         )
        ,.utmi_txready_i        (PHY_TXREADY         )
        ,.utmi_datain_i         (PHY_DATAIN          )
        ,.utmi_rxactive_i       (PHY_RXACTIVE        )
        ,.utmi_rxvalid_i        (PHY_RXVALID         )
        ,.utmi_rxerror_i        (PHY_RXERROR         )
        ,.utmi_linestate_i      (PHY_LINESTATE       )
        ,.utmi_opmode_o         (PHY_OPMODE          )
        ,.utmi_xcvrselect_o     (PHY_XCVRSELECT      )
        ,.utmi_termselect_o     (PHY_TERMSELECT      )
        ,.utmi_reset_o          (PHY_RESET           )
);

usb_desc
#(

         .VENDORID    (16'h33AA)//33AA
        ,.PRODUCTID   (16'h0202)//301F for shangling
        ,.VERSIONBCD  (16'h0201)
        ,.HSSUPPORT   (1)
        ,.SELFPOWERED (0)
)
u_usb_desc (
         .CLK                    (PHY_CLKOUT          )
        ,.RESET                  (RESET               )
        ,.i_descrom_raddr        (DESCROM_RADDR       )
        ,.o_descrom_rdat         (DESCROM_RDAT        )
        ,.i_desc_index_o         (DESC_INDEX          )
        ,.i_desc_type_o          (DESC_TYPE           )
        ,.o_desc_dev_addr        (DESC_DEV_ADDR       )
        ,.o_desc_dev_len         (DESC_DEV_LEN        )
        ,.o_desc_qual_addr       (DESC_QUAL_ADDR      )
        ,.o_desc_qual_len        (DESC_QUAL_LEN       )
        ,.o_desc_fscfg_addr      (DESC_FSCFG_ADDR     )
        ,.o_desc_fscfg_len       (DESC_FSCFG_LEN      )
        ,.o_desc_hscfg_addr      (DESC_HSCFG_ADDR     )
        ,.o_desc_hscfg_len       (DESC_HSCFG_LEN      )
        ,.o_desc_oscfg_addr      (DESC_OSCFG_ADDR     )
        ,.o_desc_hidrpt_addr     (DESC_HIDRPT_ADDR    )
        ,.o_desc_hidrpt_len      (DESC_HIDRPT_LEN     )
        ,.o_desc_strlang_addr    (DESC_STRLANG_ADDR   )
        ,.o_desc_strvendor_addr  (DESC_STRVENDOR_ADDR )
        ,.o_desc_strvendor_len   (DESC_STRVENDOR_LEN  )
        ,.o_desc_strproduct_addr (DESC_STRPRODUCT_ADDR)
        ,.o_desc_strproduct_len  (DESC_STRPRODUCT_LEN )
        ,.o_desc_strserial_addr  (DESC_STRSERIAL_ADDR )
        ,.o_desc_strserial_len   (DESC_STRSERIAL_LEN  )
        ,.o_descrom_have_strings (DESCROM_HAVE_STRINGS)
);


//==============================================================
//======USB SoftPHY 
    USB2_0_SoftPHY_Top u_USB_SoftPHY_Top
    (
         .clk_i            (PHY_CLKOUT    )
        ,.rst_i            (PHY_RESET     )
        ,.fclk_i           (fclk_480M     )
        ,.pll_locked_i     (pll_locked    )
        ,.utmi_data_out_i  (PHY_DATAOUT   )
        ,.utmi_txvalid_i   (PHY_TXVALID   )
        ,.utmi_op_mode_i   (PHY_OPMODE    )
        ,.utmi_xcvrselect_i(PHY_XCVRSELECT)
        ,.utmi_termselect_i(PHY_TERMSELECT)
        ,.utmi_data_in_o   (PHY_DATAIN    )
        ,.utmi_txready_o   (PHY_TXREADY   )
        ,.utmi_rxvalid_o   (PHY_RXVALID   )
        ,.utmi_rxactive_o  (PHY_RXACTIVE  )
        ,.utmi_rxerror_o   (PHY_RXERROR   )
        ,.utmi_linestate_o (PHY_LINESTATE )
        ,.usb_dxp_io        (usb_dxp_io   )
        ,.usb_dxn_io        (usb_dxn_io   )
        ,.usb_rxdp_i        (usb_rxdp_i   )
        ,.usb_rxdn_i        (usb_rxdn_i   )
        ,.usb_pullup_en_o   (usb_pullup_en_o)
        ,.usb_term_dp_io    (usb_term_dp_io)
        ,.usb_term_dn_io    (usb_term_dn_io)
    );


//==============================================================
//======USB Audio Control
always @(posedge PHY_CLKOUT,posedge RESET) begin
    if (RESET) begin
        stage <= 8'd0;
        sub_stage <= 8'd0;
        req_type <= 8'd0;
        req_code <= 8'd0;
        wValue <= 16'd0;
        wIndex <= 16'd0;
        wLength <= 16'd0;
        set_sample_rate <= 1'b0;
        endpt0_send <= 1'd0;
        endpt0_dat  <= 8'd0;
        get_ch0_volume_range <= 1'b0;
        get_ch1_volume_range <= 1'b0;
        get_ch2_volume_range <= 1'b0;
        get_ch0_volume_cur <= 1'b0;
        get_ch1_volume_cur <= 1'b0;
        get_ch2_volume_cur <= 1'b0;
        get_mute_cur <= 1'b0;
        get_clk_range <= 1'b0;
        get_clk_cur <= 1'b0;
        sample_rate_addr <= 16'd0;
        sample_rate_cur <= 32'd44100;
        ch0_volume_cur  <= 16'd0;
        ch1_volume_cur  <= 16'd0;
        ch2_volume_cur  <= 16'd0;
    end
    else begin
        if (setup_active) begin
            if (usb_rxval) begin
                case (stage)
                    8'd0 : begin
                        req_type <= usb_rxdat;//request type set (D7:0set 1get, D6D5: 01 class-specific, D4-D0:00001 control function or 00010 iso endpoint)
                                              //0x21 set class-spec control function
                                              //0xA1 get class-spec control function
                        stage <= stage + 8'd1;
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'b0;
                        get_ch1_volume_range <= 1'b0;
                        get_ch2_volume_range <= 1'b0;
                        get_ch0_volume_cur <= 1'b0;
                        get_ch1_volume_cur <= 1'b0;
                        get_ch2_volume_cur <= 1'b0;
                        get_mute_cur <= 1'b0;
                        get_clk_range <= 1'b0;
                        get_clk_cur <= 1'b0;
                        sample_rate_addr <= 16'd0;
                        set_sample_rate <= 1'b0;
                    end
                    8'd1 : begin
                        req_code <= usb_rxdat;//0x01:CUR 
                                              //0x02:RANGE
                                              //0x00:undefined
                        stage <= stage + 8'd1;
                    end
                    8'd2 : begin
                        //wValue LSB CN channel number
                        //0x00 channle 0
                        //0x00 channle 1
                        //0x00 channle 2
                        wValue[7:0] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd3 : begin
                        //wValue MSB CS control selector
                        //0x01 CS_SAM_FREQ_CONTROL
                        //0x02 FU_VOLUME_CONTROL in feature unit control selector
                        wValue[15:8] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd4 : begin
                        //wIndex LSB interface or Entity ID
                        //0x05 Clock Entity ID
                        //0x03 Audio Feature Control ID
                        wIndex[7:0] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd5 : begin
                        //wIndex MSB
                        //0x00
                        wIndex[15:8] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd6 : begin
                        //wLength
                        //if (s_req_code == GET_LINE_CODING) begin
                        //    endpt0_send <= 1'd1;
                        //end
                        if ((req_type == 8'h21)&&(req_code == 8'h01)&&(wValue[15:0] == 16'h0100)&&(wIndex[15:0]==16'h0500)) begin
                            set_sample_rate <= 1'b1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h02)&&(wValue[15:0] == 16'h0200)&&(wIndex[15:0]==16'h0300)) begin
                            get_ch0_volume_range <= 1'b1;
                            endpt0_dat  <= VOLUME_NUM[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h02)&&(wValue[15:0] == 16'h0201)&&(wIndex[15:0]==16'h0300)) begin
                            get_ch1_volume_range <= 1'b1;
                            endpt0_dat  <= VOLUME_NUM[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h02)&&(wValue[15:0] == 16'h0202)&&(wIndex[15:0]==16'h0300)) begin
                            get_ch2_volume_range <= 1'b1;
                            endpt0_dat  <= VOLUME_NUM[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h01)&&(wValue[15:0] == 16'h0200)&&(wIndex[15:0]==16'h0300)) begin
                            get_ch0_volume_cur <= 1'b1;
                            endpt0_dat  <= ch0_volume_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h01)&&(wValue[15:0] == 16'h0201)&&(wIndex[15:0]==16'h0300)) begin
                            get_ch1_volume_cur <= 1'b1;
                            endpt0_dat  <= ch1_volume_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h01)&&(wValue[15:0] == 16'h0202)&&(wIndex[15:0]==16'h0300)) begin
                            get_ch2_volume_cur <= 1'b1;
                            endpt0_dat  <= ch2_volume_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h01)&&(wValue[15:0] == 16'h0100)&&(wIndex[15:0]==16'h0300)) begin
                            get_mute_cur <= 1'b1;
                            endpt0_dat  <= 8'd0;
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h02)&&(wValue[15:0] == 16'h0100)&&(wIndex[15:0]==16'h0500)) begin
                            get_clk_range <= 1'b1;
                            sample_rate_addr <= 8'd1;
                            endpt0_dat  <= sample_rate_data[0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == 8'hA1)&&(req_code == 8'h01)&&(wValue[15:0] == 16'h0100)&&(wIndex[15:0]==16'h0500)) begin
                            get_clk_cur <= 1'b1;
                            endpt0_dat  <= sample_rate_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        wLength[7:0] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd7 : begin
                        //if (s_req_code == GET_LINE_CODING) begin
                        //    s_set_len[15:8] <= usb_rxdat;
                        //    endpt0_send <= 1'd1;
                        //end
                        wLength[15:8] <= usb_rxdat;
                        stage <= stage + 8'd1;
                        sub_stage <= 8'd0;
                    end
                    8'd8 : ;
                endcase
            end
        end
        else if (set_sample_rate) begin
            stage <= 8'd0;
            if ((usb_rxact)&&(endpt_sel == 4'd0)) begin
                if (usb_rxval) begin
                    sub_stage <= sub_stage + 8'd1;
                    if (sub_stage == 0) begin
                        sample_rate_cur[7:0] <= usb_rxdat;
                    end
                    else if (sub_stage == 1) begin
                        sample_rate_cur[15:8] <= usb_rxdat;
                    end
                    else if (sub_stage == 2) begin
                        sample_rate_cur[23:16] <= usb_rxdat;
                    end
                    else if (sub_stage == 3) begin
                        sample_rate_cur[31:24] <= usb_rxdat;
                        sub_stage <= 8'd0;
                        set_sample_rate <= 1'b0;
                    end
                end
            end
        end
        else if (get_ch0_volume_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_NUM[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MIN[7:0];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MIN[15:8];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MAX[7:0];
                    end
                    else if (sub_stage == 4) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MAX[15:8];
                    end
                    else if (sub_stage == 5) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_RES[7:0];
                    end
                    else if (sub_stage == 6) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_RES[15:8];
                    end
                    else if (sub_stage == 7) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch1_volume_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch1_volume_range <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_NUM[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MIN[7:0];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MIN[15:8];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MAX[7:0];
                    end
                    else if (sub_stage == 4) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MAX[15:8];
                    end
                    else if (sub_stage == 5) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_RES[7:0];
                    end
                    else if (sub_stage == 6) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_RES[15:8];
                    end
                    else if (sub_stage == 7) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch2_volume_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_range <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_NUM[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MIN[7:0];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MIN[15:8];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MAX[7:0];
                    end
                    else if (sub_stage == 4) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_MAX[15:8];
                    end
                    else if (sub_stage == 5) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_RES[7:0];
                    end
                    else if (sub_stage == 6) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_RES[15:8];
                    end
                    else if (sub_stage == 7) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_range <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch0_volume_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= ch0_volume_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch1_volume_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch1_volume_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= ch1_volume_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch1_volume_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch2_volume_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= ch2_volume_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_mute_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    sub_stage <= 8'd0;
                    endpt0_send <= 1'd0;
                    get_mute_cur <= 1'd0;
                end
            end
        end
        else if (get_clk_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_clk_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= sample_rate_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= sample_rate_cur[23:16];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= sample_rate_cur[31:24];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_clk_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_clk_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    //if (sample_rate_addr >= wLength) begin
                    if (sub_stage == 0) begin
                        if (sample_rate_addr >= 64) begin
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_send <= 1'd0;
                            sub_stage <= 1;
                        end
                        else begin
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                        end
                    end
                    else if (sub_stage == 1) begin
                        if (sample_rate_addr >= 128) begin
                            endpt0_dat <= 8'h00;
                            endpt0_send <= 1'd0;
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            sub_stage <= 2;
                        end
                        else begin
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                        end
                    end
                    else if (sub_stage == 2) begin
                        if (sample_rate_addr >= 158) begin
                            endpt0_dat <= 8'h00;
                            endpt0_send <= 1'd0;
                            sample_rate_addr <= 8'd0;
                            sub_stage <= 0;
                        end
                        else begin
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                        end
                    end
                end
            end
            else begin
                if (sub_stage == 0) begin
                    endpt0_send <= 1'd1;
                end
                else if (sub_stage == 1) begin
                    endpt0_send <= 1'd1;
                end
                else if (sub_stage == 2) begin
                    endpt0_send <= 1'd1;
                end
                else if (sub_stage == 3) begin
                    endpt0_send <= 1'd1;
                end
            end
        end
        else begin
            stage <= 8'd0;
            sub_stage <= 8'd0;
        end
    end
end


always @(posedge PHY_CLKOUT,posedge RESET) begin
    if (RESET) begin
        sample_rate_data[0]     <= 8'h0D;
        sample_rate_data[1]     <= 8'h00;
        sample_rate_data[2 +  0]<= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  1]<= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  2]<= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  3]<= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  4]<= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  5]<= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  6]<= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  7]<= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  8] <= 0;
        sample_rate_data[2 +  9] <= 0;
        sample_rate_data[2 + 10] <= 0;
        sample_rate_data[2 + 11] <= 0;
        sample_rate_data[14 +  0] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  1] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  2] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  3] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  4] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  5] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  6] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  7] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  8] <= 0;
        sample_rate_data[14 +  9] <= 0;
        sample_rate_data[14 + 10] <= 0;
        sample_rate_data[14 + 11] <= 0;
        sample_rate_data[26 +  0] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  1] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  2] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  3] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  4] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  5] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  6] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  7] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  8] <= 0;
        sample_rate_data[26 +  9] <= 0;
        sample_rate_data[26 + 10] <= 0;
        sample_rate_data[26 + 11] <= 0;
        sample_rate_data[38 +  0] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  1] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  2] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  3] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  4] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  5] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  6] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  7] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  8] <= 0;
        sample_rate_data[38 +  9] <= 0;
        sample_rate_data[38 + 10] <= 0;
        sample_rate_data[38 + 11] <= 0;
        sample_rate_data[50 +  0] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  1] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  2] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  3] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  4] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  5] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  6] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  7] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  8] <= 0;
        sample_rate_data[50 +  9] <= 0;
        sample_rate_data[50 + 10] <= 0;
        sample_rate_data[50 + 11] <= 0;
        sample_rate_data[62 +  0] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  1] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  2] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  3] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  4] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  5] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  6] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  7] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  8] <= 0;
        sample_rate_data[62 +  9] <= 0;
        sample_rate_data[62 + 10] <= 0;
        sample_rate_data[62 + 11] <= 0;
        sample_rate_data[74 +  0]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  1]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  2]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  3]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  4]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  5]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  6]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  7]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  8] <= 0;
        sample_rate_data[74 +  9] <= 0;
        sample_rate_data[74 + 10] <= 0;
        sample_rate_data[74 + 11] <= 0;
        sample_rate_data[86 +  0] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  1] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  2] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  3] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  4] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  5] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  6] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  7] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  8] <= 0;
        sample_rate_data[86 +  9] <= 0;
        sample_rate_data[86 + 10] <= 0;
        sample_rate_data[86 + 11] <= 0;
        sample_rate_data[98 +  0] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  1] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  2] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  3] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  4] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  5] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  6] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  7] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  8] <= 0;
        sample_rate_data[98 +  9] <= 0;
        sample_rate_data[98 + 10] <= 0;
        sample_rate_data[98 + 11] <= 0;
        sample_rate_data[110 +  0] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  1] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  2] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  3] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  4] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  5] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  6] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  7] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  8] <= 0;
        sample_rate_data[110 +  9] <= 0;
        sample_rate_data[110 + 10] <= 0;
        sample_rate_data[110 + 11] <= 0;
        sample_rate_data[122 +  0] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  1] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  2] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  3] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  4] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  5] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  6] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  7] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  8] <= 0;
        sample_rate_data[122 +  9] <= 0;
        sample_rate_data[122 + 10] <= 0;
        sample_rate_data[122 + 11] <= 0;
        sample_rate_data[134 +  0] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  1] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  2] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  3] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  4] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  5] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  6] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  7] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  8] <= 0;
        sample_rate_data[134 +  9] <= 0;
        sample_rate_data[134 + 10] <= 0;
        sample_rate_data[134 + 11] <= 0;
        sample_rate_data[146 +  0] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  1] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  2] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  3] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  4] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  5] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  6] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  7] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  8] <= 0;
        sample_rate_data[146 +  9] <= 0;
        sample_rate_data[146 + 10] <= 0;
        sample_rate_data[146 + 11] <= 0;
    end
    else begin
        sample_rate_data[0]     <= 8'h0D;
        sample_rate_data[1]     <= 8'h00;
        sample_rate_data[2 +  0]<= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  1]<= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  2]<= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  3]<= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  4]<= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  5]<= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  6]<= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  7]<= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  8] <= 0;
        sample_rate_data[2 +  9] <= 0;
        sample_rate_data[2 + 10] <= 0;
        sample_rate_data[2 + 11] <= 0;
        sample_rate_data[14 +  0] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  1] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  2] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  3] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  4] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  5] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  6] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  7] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  8] <= 0;
        sample_rate_data[14 +  9] <= 0;
        sample_rate_data[14 + 10] <= 0;
        sample_rate_data[14 + 11] <= 0;
        sample_rate_data[26 +  0] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  1] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  2] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  3] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  4] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  5] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  6] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  7] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  8] <= 0;
        sample_rate_data[26 +  9] <= 0;
        sample_rate_data[26 + 10] <= 0;
        sample_rate_data[26 + 11] <= 0;
        sample_rate_data[38 +  0] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  1] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  2] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  3] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  4] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  5] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  6] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  7] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  8] <= 0;
        sample_rate_data[38 +  9] <= 0;
        sample_rate_data[38 + 10] <= 0;
        sample_rate_data[38 + 11] <= 0;
        sample_rate_data[50 +  0] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  1] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  2] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  3] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  4] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  5] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  6] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  7] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  8] <= 0;
        sample_rate_data[50 +  9] <= 0;
        sample_rate_data[50 + 10] <= 0;
        sample_rate_data[50 + 11] <= 0;
        sample_rate_data[62 +  0] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  1] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  2] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  3] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  4] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  5] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  6] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  7] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  8] <= 0;
        sample_rate_data[62 +  9] <= 0;
        sample_rate_data[62 + 10] <= 0;
        sample_rate_data[62 + 11] <= 0;
        sample_rate_data[74 +  0]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  1]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  2]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  3]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  4]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  5]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  6]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  7]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  8] <= 0;
        sample_rate_data[74 +  9] <= 0;
        sample_rate_data[74 + 10] <= 0;
        sample_rate_data[74 + 11] <= 0;
        sample_rate_data[86 +  0] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  1] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  2] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  3] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  4] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  5] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  6] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  7] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  8] <= 0;
        sample_rate_data[86 +  9] <= 0;
        sample_rate_data[86 + 10] <= 0;
        sample_rate_data[86 + 11] <= 0;
        sample_rate_data[98 +  0] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  1] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  2] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  3] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  4] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  5] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  6] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  7] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  8] <= 0;
        sample_rate_data[98 +  9] <= 0;
        sample_rate_data[98 + 10] <= 0;
        sample_rate_data[98 + 11] <= 0;
        sample_rate_data[110 +  0] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  1] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  2] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  3] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  4] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  5] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  6] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  7] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  8] <= 0;
        sample_rate_data[110 +  9] <= 0;
        sample_rate_data[110 + 10] <= 0;
        sample_rate_data[110 + 11] <= 0;
        sample_rate_data[122 +  0] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  1] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  2] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  3] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  4] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  5] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  6] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  7] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  8] <= 0;
        sample_rate_data[122 +  9] <= 0;
        sample_rate_data[122 + 10] <= 0;
        sample_rate_data[122 + 11] <= 0;
        sample_rate_data[134 +  0] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  1] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  2] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  3] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  4] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  5] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  6] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  7] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  8] <= 0;
        sample_rate_data[134 +  9] <= 0;
        sample_rate_data[134 + 10] <= 0;
        sample_rate_data[134 + 11] <= 0;
        sample_rate_data[146 +  0] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  1] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  2] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  3] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  4] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  5] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  6] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  7] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  8] <= 0;
        sample_rate_data[146 +  9] <= 0;
        sample_rate_data[146 + 10] <= 0;
        sample_rate_data[146 + 11] <= 0;
    end
end



assign IIS_BCLK_O = dsd_en|dop_en ? DSD_CLK   : IIS_BCLK;
assign IIS_LRCK_O = dsd_en|dop_en ? DSD_DATA2 : IIS_LRCK;
assign IIS_DATA_O = dsd_en|dop_en ? DSD_DATA1 : IIS_DATA;

endmodule
