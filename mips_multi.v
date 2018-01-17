module mips_multi(
    input               CLOCK_50,// Para a placa
    input[3:0]      KEY, // Para a placa
    input[17:0]     SW, // Para a placa
    output[8:0]     LEDG, // Para a placa
    output[0:6]     HEX0, // Para a placa
    output[0:6]     HEX1, // Para a placa
    output[0:6]     HEX2, // Para a placa
    output[0:6]     HEX3, // Para a placa
    output[0:6]     HEX4, // Para a placa
    output[0:6]     HEX5, // Para a placa
    output[0:6]     HEX6, // Para a placa
    output[0:6]     HEX7 // Para a placa
 
);
 
reg [31:0] clk; // contador utilizado para deixar a frequência do clock na placa mais lento
 
reg[9:0] PC_F;
reg[31:0] IR_F_D;
 
reg[9:0] PC_D;
reg[31:0] A_D_E;
reg[31:0] B_D_E;
reg[31:0] IR_D_E;
 
reg[31:0] S_ULA_E_M;
reg[31:0] B_E_M;
reg[31:0] IR_E_M;
 
reg[31:0] S_ULA_M_WB;
reg[31:0] IR_M_WB;
 
/*
SCOREBOARD:
LINHAS = REGISTRADORES
COLUNAS =
 - 0: PENDENTE
 - 1: EXECUTE - E_M
 - 2: MEMORY - M_WB
 - 3: LOAD - stall
*/
reg [3:0] scoreboard[31:0];
// scoreboard 32 registradores por 4 bits de caracteristica
integer y;
integer x;
 
wire [31:0] in_a;
wire [31:0] in_b;
 
wire [31:0] out_mem_inst;
wire [31:0] out_mem_data;
 
wire [31:0] dado_lido_1; // dado lido do banco de registardores
wire [31:0] dado_lido_2; // dado lido do banco de registardores
wire [31:0] signal_dado_a_ser_escrito;
 
wire signal_write_back;
wire signal_wren; // instrucao store
 
wire [4:0] signal_rd;
 
reg halt;
 
wire [31:0] signal_reg_para_a_placa; // para a placa
 
wire stall;
 
mem_inst mem_i(.address(PC_F), .clock(clk[24]), .q(out_mem_inst)); // instanciando a memória de instruções (ROM)
 
mem_data mem_d(.address(S_ULA_E_M[9:0]), .clock(clk[24]), .data(B_E_M), .wren(signal_wren), .q(out_mem_data));
 
banco_de_registradores br(
    .br_in_SW(SW[4:0]),
    .br_out_reg_para_a_placa(signal_reg_para_a_placa),
    .br_in_clk(clk[24]),
    .br_in_rs(IR_F_D[25:21]),
    .br_in_rt(IR_F_D[20:16]),
    .br_in_rd(signal_rd),
    .br_in_data(signal_dado_a_ser_escrito),
    .br_in_reset(KEY[0]),
    .br_out_R_rs(dado_lido_1),
    .br_out_R_rt(dado_lido_2),
    .br_in_w_en(signal_write_back));
 
displayDecoder DP7_0(.entrada(signal_reg_para_a_placa[3:0]), .saida(HEX0)); // para a placa
 
assign LEDG[0] = clk[24]; // utlizando o LEDG[0] para exibir o bit 25 do contador clk (para ter noção da frequência do clock utilizado)
 
always@(posedge CLOCK_50)begin
    clk = clk + 1;
end
 
assign signal_write_back = ( // caso estejamos no write back de uma instrucao aritmetica
    (IR_M_WB[31:26] == 6'b000000 && IR_M_WB[5:0] == 6'b100010) ||
    (IR_M_WB[31:26] == 6'b000000 && IR_M_WB[5:0] == 6'b100000) ||
    (IR_M_WB[31:26] == 6'b001000) ||
    (IR_M_WB[31:26] == 6'b100011)
    ) ? 1 : 0;
 
assign signal_dado_a_ser_escrito = ( // dado que iremos escrever no registrador no write back
    (IR_M_WB[31:26] == 6'b000000 && IR_M_WB[5:0] == 6'b100010) ||
    (IR_M_WB[31:26] == 6'b000000 && IR_M_WB[5:0] == 6'b100000) ||
    (IR_M_WB[31:26] == 6'b001000)
    ) ? S_ULA_M_WB : out_mem_data;
 
assign signal_wren = (IR_E_M[31:26] == 6'b101011) ? 1 : 0;
 
assign signal_rd    = (
    (IR_M_WB[31:26] == 6'b001000) ||
    (IR_M_WB[31:26] == 6'b100011)
    ) ? IR_M_WB[20:16] : IR_M_WB[15:11];
 
assign in_a = (((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) ||//add
                    (IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) ||//sub
                    IR_D_E[31:26] == 6'b001000 || //addi
                    IR_D_E[31:26] == 6'b000100 || //beq
                    IR_D_E[31:26] == 6'b100011 || //lw
                    IR_D_E[31:26] == 6'b101011) //sw
                    && scoreboard[IR_D_E[25:21]][0] == 1'b0) ? A_D_E :
                    (((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) ||
                    (IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) ||
                    IR_D_E[31:26] == 6'b001000 ||
                    IR_D_E[31:26] == 6'b000100 ||
                    IR_D_E[31:26] == 6'b100011 ||
                    IR_D_E[31:26] == 6'b101011) && scoreboard[IR_D_E[25:21]][0] == 1'b1 && scoreboard[IR_D_E[25:21]][1] == 1'b1) ? S_ULA_E_M :
                    (((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) ||
                    (IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) ||
                    IR_D_E[31:26] == 6'b001000 ||
                    IR_D_E[31:26] == 6'b000100 ||
                    IR_D_E[31:26] == 6'b100011 ||
                    IR_D_E[31:26] == 6'b101011) && scoreboard[IR_D_E[25:21]][0] == 1'b1 && scoreboard[IR_D_E[25:21]][2] == 1'b1) ? S_ULA_M_WB : 32'b0;
 
 
assign in_b = (((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) || // add
                    (IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) || // sub
                    IR_D_E[31:26] == 6'b001000 || //addi
                    IR_D_E[31:26] == 6'b000100 || //beq
                    IR_D_E[31:26] == 6'b100011 || //lw
                    IR_D_E[31:26] == 6'b101011) //sw
                    && scoreboard[IR_D_E[20:16]][0] == 1'b0) ? B_D_E :
                    (((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) ||
                    (IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) ||
                    IR_D_E[31:26] == 6'b001000 ||
                    IR_D_E[31:26] == 6'b000100 ||
                    IR_D_E[31:26] == 6'b100011 ||
                    IR_D_E[31:26] == 6'b101011) && scoreboard[IR_D_E[20:16]][0] == 1'b1 && scoreboard[IR_D_E[20:16]][1] == 1'b1) ? S_ULA_E_M :
                    ((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000 ||
                    IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010 ||
                    IR_D_E[31:26] == 6'b001000 ||
                    IR_D_E[31:26] == 6'b000100 ||
                    IR_D_E[31:26] == 6'b100011 ||
                    IR_D_E[31:26] == 6'b101011) && scoreboard[IR_D_E[20:16]][0] == 1'b1 && scoreboard[IR_D_E[20:16]][2] == 1'b1) ? S_ULA_M_WB : 32'b0;
 
 
assign stall = ((IR_D_E[31:26] == 6'b000100 || IR_D_E[31:26] == 6'b000010) || //beq ou j
					(((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) ||//add
					  (IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) ||//sub
                  IR_D_E[31:26] == 6'b001000 ||//addi
					   IR_D_E[31:26] == 6'b100011 ||//load
                  IR_D_E[31:26] == 6'b000100 ||//beq
                  IR_D_E[31:26] == 6'b101011)//store
        && (scoreboard[IR_D_E[25:21]][0] == 1'b1 && scoreboard[IR_D_E[25:21]][3] == 1'b1)) ||
               (((IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) ||
                 (IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) ||
                  IR_D_E[31:26] == 6'b000100 ||
						IR_D_E[31:26] == 6'b101011)
        && (scoreboard[IR_D_E[20:16]][0] == 1'b1 && scoreboard[IR_D_E[20:16]][3] == 1'b1))) ? 1 : 0;
 
    always@(posedge clk[24])begin
 
        if(KEY[0] == 0)
        begin
            PC_F <= 10'b0;
            halt <= 1'b1;
            IR_F_D <= 32'b0;
            IR_D_E <= 32'b0;
            IR_E_M <= 32'b0;
            IR_M_WB <= 32'b0;
				B_E_M <= 32'b0;
            for(y = 0; y < 32; y = y + 1)
            begin
                for(x = 0; x < 4; x = x + 1)
                begin
                    scoreboard[y][x] <= 0;
                end
            end
 
        end
 
        else
        begin
 
            if(halt == 1'b1)
            begin
                halt <= 1'b0;
                PC_F <= PC_F + 1;
            end
 
            else
            begin
 
                if(stall == 1'b0)
                begin
                    ////////////////////////BUSCA
                    PC_F <= PC_F + 1;
                    IR_F_D <= out_mem_inst;
                    ////////////////////////BUSCA
 
                    ////////////////////////DECODE
                    if (IR_F_D[31:26] == 6'b000000 && (IR_F_D[5:0] == 6'b100000 || IR_F_D[5:0] == 6'b100010))
                    begin
                        //scoreboard[IR_F_D[15:11]][0] <= 1;
                    end
                    else if (IR_F_D[31:26] == 6'b100011)
                    begin
                        //scoreboard[IR_F_D[20:16]][0] <= 1;
                        //scoreboard[IR_F_D[20:16]][3] <= 1;
                    end
                    else if (IR_F_D[31:26] == 6'b001000)
                    begin
                        //scoreboard[IR_F_D[20:16]][0] <= 1;
                    end
                   
                    A_D_E <= dado_lido_1;
                    B_D_E <= dado_lido_2;
                    IR_D_E <= IR_F_D;
                    PC_D <= PC_F;
                    ////////////////////////DECODE
                   
                end
                else//stall
                begin
                    ////////////////////////BUSCA
                    /////////////////////////////
                    ////////////////////////BUSCA
                   
                    ////////////////////////DECODE
                    IR_D_E <= 32'b0;
                    A_D_E <= 32'b0;
                    B_D_E <= 32'b0;
                    ////////////////////////DECODE
                end
 
            ////////////////////////EXECUTE
 
            if(IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100000) // add
            begin
                scoreboard[IR_D_E[15:11]][0] <= 1;
                scoreboard[IR_D_E[15:11]][1] <= 1;
                scoreboard[IR_D_E[15:11]][2] <= 0;
                S_ULA_E_M <= in_a + in_b;
            end
            else if(IR_D_E[31:26] == 6'b000000 && IR_D_E[5:0] == 6'b100010) // sub
            begin
                scoreboard[IR_D_E[15:11]][0] <= 1;
                scoreboard[IR_D_E[15:11]][1] <= 1;
                scoreboard[IR_D_E[15:11]][2] <= 0;
                S_ULA_E_M <= in_a - in_b;
            end
            else if(IR_D_E[31:26] == 6'b001000) // addi
            begin
                scoreboard[IR_D_E[20:16]][0] <= 1;
                scoreboard[IR_D_E[20:16]][1] <= 1;
                scoreboard[IR_D_E[20:16]][2] <= 0;
 
                S_ULA_E_M <= in_a + {{16{IR_D_E[15]}}, IR_D_E[15:0]};
            end
            else if(IR_D_E[31:26] == 6'b000100) // beq
            begin
                if(in_a == in_b)
                begin
                    IR_F_D <= 32'b0;
                    PC_F <= PC_D + {{16{IR_D_E[15]}}, IR_D_E[15:0]};
                    IR_D_E <= 32'b0;
                end
            end
            else if(IR_D_E[31:26] == 6'b000010) // jump
            begin
                IR_F_D <= 32'b0;   
                PC_F <= IR_D_E[9:0];
                IR_D_E <= 32'b0;       
            end
            else if(IR_D_E[31:26] == 6'b100011) // load
            begin
                scoreboard[IR_D_E[20:16]][0] <= 1;
                scoreboard[IR_D_E[20:16]][1] <= 0;
                scoreboard[IR_D_E[20:16]][2] <= 0;
                scoreboard[IR_D_E[20:16]][3] <= 1;
                S_ULA_E_M <= in_a + {{16{IR_D_E[15]}}, IR_D_E[15:0]};
            end
            else if(IR_D_E[31:26] == 6'b101011) // store
            begin
                S_ULA_E_M <= in_a + {{16{IR_D_E[15]}}, IR_D_E[15:0]};
            end
				B_E_M <= in_b;
            IR_E_M <= IR_D_E;
            ////////////////////////EXECUTE
 
 
 
 
            ////////////////////////MEMORY
            if((IR_E_M[31:26] == 6'b000000 && IR_E_M[5:0] == 6'b100000) || // add
                    (IR_E_M[31:26] == 6'b000000 && IR_E_M[5:0] == 6'b100010)) // sub
            begin
                scoreboard[IR_E_M[15:11]][0] <= 1;
                scoreboard[IR_E_M[15:11]][1] <= 0;
                scoreboard[IR_E_M[15:11]][2] <= 1;
            end
            else if(IR_E_M[31:26] == 6'b001000) // addi
            begin
                scoreboard[IR_E_M[20:16]][0] <= 1;
                scoreboard[IR_E_M[20:16]][1] <= 0;
                scoreboard[IR_E_M[20:16]][2] <= 1;
            end
            else if(IR_E_M[31:26] == 6'b100011) // load
            begin
                scoreboard[IR_E_M[20:16]][0] <= 1;
                scoreboard[IR_E_M[20:16]][1] <= 0;
                scoreboard[IR_E_M[20:16]][2] <= 1;
                scoreboard[IR_E_M[20:16]][3] <= 0;
            end
           
            S_ULA_M_WB <= S_ULA_E_M;
            IR_M_WB <= IR_E_M;
            ////////////////////////MEMORY
 
 
 
            ////////////////////////WRITE BACK
            if(IR_M_WB[31:26] == 6'b000000)
            begin
                scoreboard[IR_M_WB[15:11]][0] <= 0;
                scoreboard[IR_M_WB[15:11]][1] <= 0;
                scoreboard[IR_M_WB[15:11]][2] <= 0;
            end
            else if(IR_M_WB[31:26] == 6'b001000) // addi
            begin
                scoreboard[IR_M_WB[20:16]][0] <= 0;
                scoreboard[IR_M_WB[20:16]][1] <= 0;
                scoreboard[IR_M_WB[20:16]][2] <= 0;
            end
				else if(IR_M_WB[31:26] == 6'b100011)
				begin
					 scoreboard[IR_M_WB[20:16]][0] <= 0;
                scoreboard[IR_M_WB[20:16]][1] <= 0;
                scoreboard[IR_M_WB[20:16]][2] <= 0;
					 scoreboard[IR_M_WB[20:16]][3] <= 0;
				end
 
            ////////////////////////WRITE BACK
 
            end
        end
 
    end
 

    endmodule
