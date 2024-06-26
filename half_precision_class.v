module half_precision_class(
    input [N - 1 : 0] f,
    output reg signed [6 : 0] f_exponent,
    output reg [10 : 0] f_mantissa,
    output is_snan,
    is_qnan,
    is_infinity,
    is_zero,
    is_subnormal,
    is_normal
);

localparam N = 16;

reg bais = 15; // (2^(5 - 1)) - 1

wire exponent_ones, exponent_zeros, mantissa_zeros;
assign exponent_ones  = &f[14:10];
assign exponent_zeros = ~|f[14:10];
assign mantissa_zeros = ~|f[9:0];

// NaNs (Not a Number) are special values used to represent undefined or unrepresentable values

// sNaN is encountered in a computation, it raises an exception or interrupt, alerting the system to an error.
assign is_snan      = exponent_ones & ~mantissa_zeros & ~f[9];
//  qNaNs are used to propagate errors through a computation without causing an exception. 
assign is_qnan      = exponent_ones & f[9];
assign is_infinity  = exponent_ones & mantissa_zeros;
assign is_zero      = exponent_zeros & mantissa_zeros;
assign is_subnormal = exponent_zeros & ~mantissa_zeros;
assign is_normal    = ~exponent_ones & ~mantissa_zeros;

integer i;
reg [10 : 0] mask = ~0;
reg [3 : 0] shift_amount;


always @(*) begin

    f_exponent = f[14 : 10];
    f_mantissa = f[9 : 0];
    shift_amount = 0;

    if(is_normal)
        // - Normal numbers have an implicit leading 1 in their significand, which is not stored explicitly.
        // - The stored exponent has a bias that needs to be subtracted to get the actual exponent value.
        {f_exponent, f_mantissa} = {f[14:10] - bais, 1'b1, f[9:0]};
    else if (is_subnormal) begin
        for (i = 8; i > 0; i = i >> 1) begin
            if ((f_mantissa & (mask << (11 - i))) == 0) begin
                f_mantissa = f_mantissa << i;
                shift_amount = shift_amount | i;
            end
        end
        // "-14" is the smallest Normal exponent as a signed value.
        f_exponent = (1 - bais) - shift_amount;
    end
end


endmodule