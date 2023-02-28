
// file: xadc_arty_fpro.v
// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
`timescale 1ns / 1 ps

(* CORE_GENERATION_INFO = "xadc_wiz_0,xadc_wiz_v3_3_3,{component_name=xadc_arty_fpro, enable_axi=false, enable_axi4stream=false, dclk_frequency=100, enable_busy=true, enable_convst=false, enable_convstclk=false, enable_dclk=true, enable_drp=true, enable_eoc=true, enable_eos=true, enable_vbram_alaram=false, enable_vccddro_alaram=false, enable_Vccint_Alaram=false, enable_Vccaux_alaram=false, enable_vccpaux_alaram=false, enable_vccpint_alaram=false,ot_alaram=true,user_temp_alaram=true,timing_mode=continuous,channel_averaging=None,sequencer_mode=on,startup_channel_selection=contineous_sequence}" *)


module xadc_wiz_0
          (
          daddr_in,            // Address bus for the dynamic reconfiguration port
          dclk_in,             // Clock input for the dynamic reconfiguration port
          den_in,              // Enable Signal for the dynamic reconfiguration port
          di_in,               // Input data bus for the dynamic reconfiguration port
          dwe_in,              // Write Enable for the dynamic reconfiguration port
          reset_in,            // Reset signal for the System Monitor control logic
          vauxp0,              // Auxiliary channel 0
          vauxn0,
          vauxp1,              // Auxiliary channel 1
          vauxn1,
          vauxp2,              // Auxiliary channel 2
          vauxn2,
          vauxp3,              // Auxiliary channel 3
          vauxn3,
          vauxp4,              // Auxiliary channel 4
          vauxn4,
          vauxp5,              // Auxiliary channel 5
          vauxn5,
          vauxp6,              // Auxiliary channel 6
          vauxn6,
          vauxp7,              // Auxiliary channel 7
          vauxn7,
          vauxp8,              // Auxiliary channel 8
          vauxn8,
          vauxp9,              // Auxiliary channel 9
          vauxn9,
          vauxp10,             // Auxiliary channel 10
          vauxn10,
          vauxp11,             // Auxiliary channel 11
          vauxn11,
          vauxp12,             // Auxiliary channel 12
          vauxn12,
          vauxp13,             // Auxiliary channel 13
          vauxn13,
          vauxp14,             // Auxiliary channel 14
          vauxn14,
          vauxp15,             // Auxiliary channel 15
          vauxn15,
          busy_out,            // ADC Busy signal
          channel_out,         // Channel Selection Outputs
          do_out,              // Output data bus for dynamic reconfiguration port
          drdy_out,            // Data ready signal for the dynamic reconfiguration port
          eoc_out,             // End of Conversion Signal
          eos_out,             // End of Sequence Signal
          //ot_out,              // Over-Temperature alarm output
          //user_temp_alarm_out, // Temperature-sensor alarm output
          alarm_out,           // OR'ed output of all the Alarms    
          vp_in,               // Dedicated Analog Input Pair
          vn_in);

          input [6:0] daddr_in;
          input dclk_in;
          input den_in;
          input [15:0] di_in;
          input dwe_in;
          input reset_in;
          input vauxp0;
          input vauxn0;
          input vauxp1;
          input vauxn1;
          input vauxp2;
          input vauxn2;
          input vauxp3;
          input vauxn3;
          input vauxp4;
          input vauxn4;
          input vauxp5;
          input vauxn5;
          input vauxp6;
          input vauxn6;
          input vauxp7;
          input vauxn7;
          input vauxp8;
          input vauxn8;
          input vauxp9;
          input vauxn9;
          input vauxp10;
          input vauxn10;
          input vauxp11;
          input vauxn11;
          input vauxp12;
          input vauxn12;
          input vauxp13;
          input vauxn13;
          input vauxp14;
          input vauxn14;
          input vauxp15;
          input vauxn15;
          input vp_in;
          input vn_in;

          output busy_out;
          output [4:0] channel_out;
          output [15:0] do_out;
          output drdy_out;
          output eoc_out;
          output eos_out;
          //output ot_out;
          //output user_temp_alarm_out;
          output alarm_out;

        wire FLOAT_VCCAUX;
        wire FLOAT_VCCINT;
          wire GND_BIT;
    wire [1:0] GND_BUS2;
          assign GND_BIT = 0;
    assign GND_BUS2 = 2'b00;
          wire [15:0] aux_channel_p;
          wire [15:0] aux_channel_n;
          wire [7:0]  alm_int;
          assign alarm_out = alm_int[7];
          assign user_temp_alarm_out = alm_int[0];
          assign aux_channel_p[0] = vauxp0;
          assign aux_channel_n[0] = vauxn0;

          assign aux_channel_p[1] = vauxp1;
          assign aux_channel_n[1] = vauxn1;

          assign aux_channel_p[2] = vauxp2;
          assign aux_channel_n[2] = vauxn2;

          assign aux_channel_p[3] = vauxp3;
          assign aux_channel_n[3] = vauxn3;

          assign aux_channel_p[4] = vauxp4;
          assign aux_channel_n[4] = vauxn4;

          assign aux_channel_p[5] = vauxp5;
          assign aux_channel_n[5] = vauxn5;

          assign aux_channel_p[6] = vauxp6;
          assign aux_channel_n[6] = vauxn6;

          assign aux_channel_p[7] = vauxp7;
          assign aux_channel_n[7] = vauxn7;

          assign aux_channel_p[8] = vauxp8;
          assign aux_channel_n[8] = vauxn8;

          assign aux_channel_p[9] = vauxp9;
          assign aux_channel_n[9] = vauxn9;

          assign aux_channel_p[10] = vauxp10;
          assign aux_channel_n[10] = vauxn10;

          assign aux_channel_p[11] = vauxp11;
          assign aux_channel_n[11] = vauxn11;

          assign aux_channel_p[12] = vauxp12;
          assign aux_channel_n[12] = vauxn12;

          assign aux_channel_p[13] = vauxp13;
          assign aux_channel_n[13] = vauxn13;

          assign aux_channel_p[14] = vauxp14;
          assign aux_channel_n[14] = vauxn14;

          assign aux_channel_p[15] = vauxp15;
          assign aux_channel_n[15] = vauxn15;
XADC #(
    .INIT_40(16'h0000),
    .INIT_41(16'h212F),
    .INIT_42(16'h0400),
    .INIT_43(16'h0000),
    .INIT_44(16'h0000),
    .INIT_45(16'h0000),
    .INIT_46(16'h0000),
    .INIT_47(16'h0000),
    .INIT_48(16'h0000),
    .INIT_49(16'h0030),
    .INIT_4A(16'h0000),
    .INIT_4B(16'h0000),
    .INIT_4C(16'h0000),
    .INIT_4D(16'h0000),
    .INIT_4E(16'h0000),
    .INIT_4F(16'h0000),
    .INIT_50(16'hB5ED),
    .INIT_51(16'h57E4),
    .INIT_52(16'hA147),
    .INIT_53(16'hCA33),
    .INIT_54(16'hA93A),
    .INIT_55(16'h52C6),
    .INIT_56(16'h9555),
    .INIT_57(16'hAE4E),
    .INIT_58(16'h5999),
    .INIT_59(16'h0000),
    .INIT_5A(16'h0000),
    .INIT_5B(16'h0000),
    .INIT_5C(16'h5111),
    .INIT_5D(16'h0000),
    .INIT_5E(16'h0000),
    .INIT_5F(16'h0000),
    .IS_CONVSTCLK_INVERTED(1'b0),
    .IS_DCLK_INVERTED(1'b0),
    .SIM_DEVICE("7SERIES"),
    .SIM_MONITOR_FILE("design.txt")
    )  
inst (
        .CONVST(GND_BIT),
        .CONVSTCLK(GND_BIT),
        .DADDR(daddr_in[6:0]),
        .DCLK(dclk_in),
        .DEN(den_in),
        .DI(di_in[15:0]),
        .DWE(dwe_in),
        .RESET(reset_in),
        .VAUXN(aux_channel_n[15:0]),
        .VAUXP(aux_channel_p[15:0]),
        .ALM(alm_int),
        .BUSY(busy_out),
        .CHANNEL(channel_out[4:0]),
        .DO(do_out[15:0]),
        .DRDY(drdy_out),
        .EOC(eoc_out),
        .EOS(eos_out),
        .JTAGBUSY(),
        .JTAGLOCKED(),
        .JTAGMODIFIED(),
        .OT(ot_out),
        .MUXADDR(),
        .VP(vp_in),
        .VN(vn_in)
          );

endmodule