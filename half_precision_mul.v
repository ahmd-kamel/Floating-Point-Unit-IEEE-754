module half_prescision_mul(
    input [N - 1 : 0] a, b,
    output [N - 1 : 0] p,
    output reg snan, qnan, infinity,
    zero, subnormal, normal
);

localparam N = 16;

wire a_snan, a_qnan, a_infinity, a_zero, a_subnormal, a_normal;
wire b_snan, b_qnan, b_infinity, b_zero, b_subnormal, b_normal;

wire signed [6 : 0] a_exp, b_exp;
reg signed [6 : 0] p_exp, t1_exp, t2_exp;
wire [10 : 0] a_man, b_man;
reg  [10 : 0] p_man, t_man;

reg [15 : 0] p_tmp;
wire [21 : 0] raw_mantissa;
reg p_sign;

half_precision_class a_num(a,
                           a_exp,
                           a_man,
                           a_snan,
                           a_qnan,
                           a_infinity,
                           a_zero,
                           a_subnormal,
                           a_normal);

half_precision_class b_num(b,
                           b_exp,
                           b_man,
                           b_snan,
                           b_qnan,
                           b_infinity,
                           b_zero,
                           b_subnormal,
                           b_normal);

assign raw_mantissa = a_man * b_man;

always @(*) begin

    {snan, qnan, infinity, zero, subnormal, normal} = 6'b000000;
    p_sign = a[15] ^ b[15];
    p_tmp = {p_sign, 5{1'b1}, 1'b0, 9{1'b1}};

    if((a_snan | b_snan) == 1'b1) begin
        p_tmp = a_snan == 1'b1 ? a : b;
        snan = 1'b1;
    end
    else if ((a_qnan | b_qnan) == 1'b1) begin
        p_tmp = a_qnan == 1'b1 ? a : b;
        qnan = 1'b1;
    end
    else if ((a_infinity | b_infinity) == 1'b1) begin
        if ((a_zero | b_zero) == 1'b1) begin
            p_tmp = {p_sign, 5{1'b1}, 1'b1, 9'hCA};
            qnan = 1'b1;
        end
        else begin
            p_tmp = {p_sign, 5{1'b1}, 10{1'b0}};
            infinity = 1'b1;
        end
    end
    else if ((a_zero | b_zero) == 1'b1 || (a_subnormal | b_subnormal) == 1'b1) begin
        p_tmp = {p_sign, 15{1'b0}};
        zero = 1'b1;
    end
    else begin
        t1_exp = a_exp + b_exp;
        if (raw_mantissa[21] == 1'b1) begin
            t_man = raw_mantissa[21 : 11];
            t2_exp = t1_exp + 1;
        end
        else begin
            t_man = raw_mantissa[20 : 10];
            t2_exp = t1_exp;
        end

        if (t2_exp < -24) begin // too small to be subnormal --> zero
            p_tmp = {p_sign, 15{1'b0}};
            zero = 1'b1;  
        end
        else if (t2_exp < -14) begin // subnormal
            p_man = p_man >> (-14 - t2_exp);
            p_tmp = {p_sign, 5{1'b0}, p_man[9:0]};
            subnormal = 1'b1;
        end
        else if (t2_exp > 15) begin // infinity
            p_tmp = {p_sign, 5{1'b1}, 10{1'b0}};
            infinity = 1;
        end
        else begin // normal
            p_exp = t2_exp + 15;
            p_man = t_man;
            p_tmp = {p_sign, p_exp[4 : 0], p_man[9 : 0]}
            normal = 1;
        end
    end

    assign p = p_tmp;
end
    
endmodule