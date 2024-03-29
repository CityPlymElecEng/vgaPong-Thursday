module vga_controller(iRST_n,
                      iVGA_CLK,
                      oBLANK_n,
                      oHS,
                      oVS,
                      oVGA_B,
                      oVGA_G,
                      oVGA_R);
input iRST_n;
input iVGA_CLK;
output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [3:0] oVGA_B;
output [3:0] oVGA_G;  
output [3:0] oVGA_R;                       
///////// ////                     
reg [18:0] ADDR ;
reg [10:0] ballX = 0;
reg [9:0] ballY = 50;
reg [11:0] charAddr;
reg [7:0] charData;
wire char_nWr;
wire VGA_CLK_n;
wire [7:0] index;
wire [23:0] bgr_data_raw;
wire cBLANK_n,cHS,cVS,rst;
wire [10:0] xPos;
wire [9:0] yPos;
integer ballXDir = 1;
integer ballYDir = 1;
integer sideWall = 20;
integer ballSpeed = 2;
integer title = 50;
integer offset = 5;
integer paddle1Xpos = 50;
integer paddle1Ypos = 240;
integer paddle2Xpos = 600;
integer paddle2Ypos = 240;
integer paddleHeight = 60;
integer paddleWidth = 10;

////
assign rst = ~iRST_n;

video_sync_generator LTM_ins (.vga_clk(iVGA_CLK),
                              .reset(rst),
                              .blank_n(cBLANK_n),
                              .HS(cHS),
                              .VS(cVS),
										.xPos(xPos),
										.yPos(yPos)
										);
txtScreen txtScreen(
      .hp(xPos),
		.vp(yPos),
		.addr(charAddr),
		.data(charData),
		.nWr (char_nWr),
      .pClk(iVGA_CLK),
		.nblnk(cBLANK_n),
		.pix(textRGB)
      );

////Addresss generator
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)
     ADDR<=19'd0;
  else if (cBLANK_n==1'b1)
     ADDR<=ADDR+19'd1;
	  else
	    ADDR<=19'd0;
end
										
reg [23:0] bgr_data;

parameter VIDEO_W	= 640;
parameter VIDEO_H	= 480;

always@(posedge iVGA_CLK)
begin
  if (~iRST_n)
  begin
     bgr_data<=24'h000000;
  end
    else
    begin
				if (yPos >= paddle1Ypos && yPos < paddle1Ypos + paddleHeight &&
							xPos >= paddle1Xpos && xPos < paddle1Xpos + paddleWidth)
					bgr_data <= {8'hff, 8'h00, 8'hff};  // Magenta paddle 1
				else if (yPos >= paddle2Ypos && yPos < paddle2Ypos + paddleHeight &&
							xPos >= paddle2Xpos && xPos < paddle2Xpos + paddleWidth)
					bgr_data <= {8'hff, 8'hff, 8'h00};  // Cyan paddle 2

				else if (yPos > 58 && yPos < 62)
					bgr_data <= {8'h00,8'hff, 8'h00};  // green side line top
				else if (yPos > VIDEO_H - 12 && yPos < VIDEO_H - 8)
					bgr_data <= {8'h00,8'hff, 8'h00};  // green side line bottom
				else if ((xPos >= VIDEO_W/2 - 1) && (xPos < VIDEO_W/2 + 1) &&
							(yPos > sideWall + title) && (yPos < VIDEO_H -sideWall) &&
							(yPos % 20 < 10))
					bgr_data <= {8'hcc, 8'hcc, 8'hcc}; // white net
				else if (xPos >= ballX && xPos <= ballX + 12 && yPos >= ballY && yPos <= ballY + 12)
					bgr_data <= {8'hff, 8'hff, 8'hff}; // white ball
				else if (textRGB == 1'b1) bgr_data = {8'h00, 8'hcc, 8'hcc}; // yellow text
				else bgr_data <= 24'h0000; 
 
    end
end

always @(negedge cVS)
begin
	ballX <= ballX + ballXDir; // Where the horizontal bouncing takes place
	ballY <= ballY + ballYDir; // where the vertical bounce is calculated
	if (ballY >= paddle1Ypos && ballY < paddle1Ypos + paddleHeight &&
		 ballX >= paddle1Xpos && ballX < paddle1Xpos + paddleWidth)
		 ballXDir <= ballSpeed; // Paddle1 ball hit
	else if (ballY >= paddle2Ypos && ballY < paddle2Ypos + paddleHeight &&
		 ballX >= paddle2Xpos - paddleWidth && ballX < paddle2Xpos )
		 ballXDir <= -ballSpeed; // Paddle2 ball hit
	else if (ballX > VIDEO_W - sideWall) ballXDir <= -ballSpeed;
	else if (ballX < sideWall) ballXDir <= ballSpeed;
	else if (ballY > VIDEO_H - sideWall - offset) ballYDir <= -ballSpeed;
	else if (ballY < sideWall + title - offset) ballYDir <= ballSpeed;
	paddle1Ypos <= ballY - paddleHeight/2;
	paddle2Ypos <= ballY - paddleHeight/2;
	
end

assign oVGA_B=bgr_data[23:20];
assign oVGA_G=bgr_data[15:12]; 
assign oVGA_R=bgr_data[7:4];
///////////////////
//////Delay the iHD, iVD,iDEN for one clock cycle;
reg mHS, mVS, mBLANK_n;
always@(posedge iVGA_CLK)
begin
  mHS<=cHS;
  mVS<=cVS;
  mBLANK_n<=cBLANK_n;
  oHS<=mHS;
  oVS<=mVS;
  oBLANK_n<=mBLANK_n;
end


////for signaltap ii/////////////
reg [18:0] H_Cont/*synthesis noprune*/;
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)
     H_Cont<=19'd0;
  else if (mHS==1'b1)
     H_Cont<=H_Cont+19'd1;
	  else
	    H_Cont<=19'd0;
end
endmodule
 	
















