`timescale 1 ns/ 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ZHANG ZEKUN
// 
// Create Date: 2019/08/22 15:01:16
// Design Name: 
// Module Name: Synchronize FIFO
// Project Name:  
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sync_tx_pkt_fifo
#(
    parameter DSIZE = 8,
    parameter ASIZE = 9
)
(
    input        CLK,
    input        RSTn,
    input        write,
    input        pktfin,
    input        txact,
    input        read,
    input  [7:0] iData,
    
    output [7:0] oData,
    output reg [ASIZE:0] wrnum,
    output       full,
    output       empty
);

reg [ASIZE - 1:0] wp;          //write point should add 1 bit(N+1) 
reg [ASIZE - 1:0] pkt_rp;      //write point should add 1 bit(N+1) 
reg [ASIZE - 1:0] rp;          //read point
reg [DSIZE - 1:0] RAM [0:(1<<ASIZE) - 1];  //deep 512, 8 bit RAM
reg [DSIZE - 1:0] oData_reg;   //regsiter of oData
reg [1:0] txact_dly;
wire txact_rise;

always @ ( posedge CLK or negedge RSTn )
begin                  //write to RAM
    if (!RSTn)
    begin
        wp <= 'd0;
    end
    else if ( write & (~full))
    begin
        RAM[wp[ASIZE - 1:0]] <= iData;
        wp <= wp + 1'b1;
    end
end

always @ ( posedge CLK or negedge RSTn )
begin                  // read from RAM
    if (!RSTn)
    begin
        rp <= 'd0;
    end
    else if ( txact_rise ) begin
        if (read & (~empty)) begin
            rp <= pkt_rp + 1'b1;
        end
        else begin
            rp <= pkt_rp;
        end
    end
    else if ( read & (~empty)  )
    begin
        rp <= rp + 1'b1;
    end
end
always @ ( posedge CLK or negedge RSTn )
begin                  // read from RAM
    if (!RSTn)
    begin
        oData_reg <= 'd0;
    end
    else begin
        oData_reg <= RAM[rp[ASIZE - 1:0]];
    end
end

always @ ( posedge CLK or negedge RSTn ) begin    // 
    if (!RSTn) begin
        txact_dly <= 'd0;
    end
    else begin
        txact_dly <= {txact_dly[0],txact};
    end
end
assign txact_rise = (txact_dly == 2'b01);

always @ ( posedge CLK or negedge RSTn ) begin    // 
    if (!RSTn) begin
        pkt_rp <= 'd0;
    end
    else if (pktfin) begin
        pkt_rp <= rp;
    end
end
always @ ( posedge CLK or negedge RSTn ) begin    // 
    if (!RSTn) begin
        wrnum <= 'd0;
    end
    else begin
        if (wp[ASIZE - 1 : 0] >= pkt_rp[ASIZE - 1 : 0]) begin
            wrnum <= wp[ASIZE - 1 : 0] - pkt_rp[ASIZE - 1 : 0];
        end
        else begin
            wrnum <= {1'b1,wp[ASIZE - 1 : 0]} - {1'b0,pkt_rp[ASIZE - 1 : 0]};
        end
    end
end
assign full = ( (wp[ASIZE] ^ pkt_rp[ASIZE]) & (wp[ASIZE - 1:0] == pkt_rp[ASIZE - 1:0]) );
assign empty = ( wp == pkt_rp );
//assign oData = oData_reg;
assign oData = RAM[rp[ASIZE - 1:0]];

endmodule
