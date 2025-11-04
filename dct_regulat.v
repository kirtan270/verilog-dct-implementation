// 16-point DCT-II (same as "DFT" formula you posted), Q1.15 fixed-point
// single-cycle result after the clock edge that latches the 16 samples
module dct16 #(parameter N = 16)(
    input  wire                    clk,
    input  wire signed [15:0]      xin0,  xin1,  xin2,  xin3,
    input  wire signed [15:0]      xin4,  xin5,  xin6,  xin7,
    input  wire signed [15:0]      xin8,  xin9,  xin10, xin11,
    input  wire signed [15:0]      xin12, xin13, xin14, xin15,
    output reg  signed [15:0]      X0,  X1,  X2,  X3,
    output reg  signed [15:0]      X4,  X5,  X6,  X7,
    output reg  signed [15:0]      X8,  X9,  X10, X11,
    output reg  signed [15:0]      X12, X13, X14, X15
);

    // local buffers
    reg signed [15:0] x [0:N-1];
    reg signed [47:0] acc [0:N-1];         // 16?×?(16-bit?×?16-bit) needs 47 bits worst-case
    reg signed [15:0] coeff_mem [0:N-1][0:N-1];

    // load the cosine table (Q1.15) at time-0
    initial $readmemh("coeff_rom.mem", coeff_mem);

    // ? factors in Q1.15 ( ?2/16 ? 0.088388 ? 0x0B50 ; 2/16 = 0.125 ? 0x1000 )
    localparam signed [15:0] ALPHA0 = 16'h0B50;
    localparam signed [15:0] ALPHAK = 16'h1000;

    integer k,n;

    always @(posedge clk) begin
        // 1. latch inputs
        {x[0],  x[1],  x[2],  x[3],
         x[4],  x[5],  x[6],  x[7],
         x[8],  x[9],  x[10], x[11],
         x[12], x[13], x[14], x[15]} <=
        {xin0,  xin1,  xin2,  xin3,
         xin4,  xin5,  xin6,  xin7,
         xin8,  xin9,  xin10, xin11,
         xin12, xin13, xin14, xin15};

        // 2. MAC
        for (k = 0; k < N; k = k + 1) begin
            acc[k] = 0;
            for (n = 0; n < N; n = n + 1)
                acc[k] = acc[k] + x[n] * coeff_mem[k][n];  // 16-bit × 16-bit ? 32 bits ? 48-bit acc

            // 3. multiply by ? and shift back to Q1.15
            acc[k] = (k == 0) ? (acc[k] * ALPHA0) : (acc[k] * ALPHAK);
        end

        // 4. round & pack to 16 bits (drop 15 frac bits, saturate by simple cut)
        {X0,  X1,  X2,  X3,
         X4,  X5,  X6,  X7,
         X8,  X9,  X10, X11,
         X12, X13, X14, X15} <=
        {acc[0][45:30],  acc[1][45:30],  acc[2][45:30],  acc[3][45:30],
         acc[4][45:30],  acc[5][45:30],  acc[6][45:30],  acc[7][45:30],
         acc[8][45:30],  acc[9][45:30],  acc[10][45:30], acc[11][45:30],
         acc[12][45:30], acc[13][45:30], acc[14][45:30], acc[15][45:30]};
    end
endmodule
