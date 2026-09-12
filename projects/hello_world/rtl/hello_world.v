module hello_world (
    input  wire clk_125_p,
    input  wire clk_125_n,
    output wire [3:0] gpio_led
);

    wire clk;
    IBUFDS #(
        .DIFF_TERM("TRUE")
    ) clk_ibufds (
        .I  (clk_125_p),
        .IB (clk_125_n),
        .O  (clk)
    );

    reg [26:0] counter = 27'd0;

    always @(posedge clk) begin
        counter <= counter + 1'b1;
    end

    assign gpio_led = counter[26:23];

endmodule
