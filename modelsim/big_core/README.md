vlog.exe -lint -f ../../verif/big_core/tb/big_core_list.f
vsim.exe work.big_core_tb -c -do 'run -all' +STRING=alive
vsim.exe -gui work.big_core_tb +STRING=alive &
