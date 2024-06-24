module half_precision_tb;

localparam N = 16;
reg [N - 1 : 0]f;
wire snan, qnan, infinity, zero, subnormal, normal;

integer i, num_snan, num_infinity, num_zero;
integer num_qnan, num_subnormal, num_normal;

half_precision dut(.f(f),
                   .snan(snan),
                   .qnan(qnan),
                   .infinity(infinity),
                   .zero(zero),
                   .subnormal(subnormal),
                   .normal(normal));

initial begin

    assign f = 0;
    // x 11111 0 xxxxxxxxx --> signaling nan format
    num_snan = 0; // expected to be 2(2^9 - 1) = 1022

    // x 11111 1 xxxxxxxxx --> quiet nan format
    num_qnan = 0; // expected to be 2^10 = 1024

    // x 11111 0000000000 -->  infinity format
    num_infinity = 0; // expected to be 2

    // x 00000 0000000000 -->  zero format
    num_zero = 0; // expected to be 2

    // x 00000 xxxxxxxxxx -->  subnormal format
    num_subnormal = 0; // expected to be 2(2^10 - 1) = 2046

    // x xxxxx xxxxxxxxxx -->  normal format
    num_normal = 0; // expected to be 2(2^5 - 2)(2^10) = 61440
end

initial begin
    for (i = 0; i < (1 << 16); i = i + 1) begin
        #5 assign f = i;

        if(snan & ~qnan & ~infinity & ~zero & ~subnormal & ~normal)
            num_snan = num_snan + 1;
        else if(~snan & qnan & ~infinity & ~zero & ~subnormal & ~normal)
            num_qnan = num_qnan + 1;
        else if(~snan & ~qnan & infinity & ~zero & ~subnormal & ~normal)
            num_infinity = num_infinity + 1;
        else if(~snan & ~qnan & ~infinity & zero & ~subnormal & ~normal)
            num_zero = num_zero + 1;
        else if(~snan & ~qnan & ~infinity & ~zero & subnormal & ~normal)
            num_subnormal = num_subnormal + 1;
        else if(~snan & ~qnan & ~infinity & ~zero & ~subnormal & normal)
            num_normal = num_normal + 1;
        else begin
            $display("Error: number = %x , is not in one of the above clusters.", f);
            $stop;
        end
    end

end

initial begin

	@(i == (1 << 16));

        $display("Number of Signaling nans = %0d", num_snan);

        $display("Number of Quiet nans = %0d", num_qnan);

        $display("Number of Infinity = %0d", num_infinity);

        $display("Number of Zero = %0d", num_zero);

        $display("Number of Sub normals = %0d", num_subnormal);

        $display("Number of Normals = %0d", num_normal);

	$finish;
end

endmodule
