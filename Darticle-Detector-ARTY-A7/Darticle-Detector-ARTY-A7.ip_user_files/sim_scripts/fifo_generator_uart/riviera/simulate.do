onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+fifo_generator_uart -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.fifo_generator_uart xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {fifo_generator_uart.udo}

run -all

endsim

quit -force
