module half_precision(
    f,
    snan,
    qnan,
    infinity,
    zero,
    subnormal,
    normal
);

localparam N = 16;
input [N - 1 : 0] f;
output snan, qnan, infinity, zero, subnormal, normal;

wire expOnes, expZeros, sigZeros;

assign expOnes  =  &f[14:10];
assign expZeros = ~|f[14:10];
assign sigZeros = ~|f[9:0];

// signaling nan -> exponent are ones & at least one in sig & bit 9 is zero.
assign snan      = expOnes & ~sigZeros & ~f[9];
// quiet nan -> exponent are ones & at least one in sig & bit 9 is one.
assign qnan      = expOnes & ~sigZeros &  f[9]; 
// exponent are ones & sig are zeros
assign infinity  = expOnes & sigZeros;
// all exponent are zeros & sig are zeros
assign zero      = expZeros & sigZeros;
// all exponent are zeros & sig at least has ones
assign subnormal = expZeros & ~sigZeros;
// normal number exponent are zeros & exponent are ones
assign normal    = ~expOnes & ~expZeros;

    
endmodule