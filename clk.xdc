create_clock -period 17.000 -name CLK -waveform {0.000 8.500} [get_ports -filter { NAME =~  "*" && DIRECTION == "IN" } -of_objects [get_nets -hierarchical -filter { NAME =~  "*clk*" }]]


