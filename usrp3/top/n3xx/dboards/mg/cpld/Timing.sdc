#
# Copyright 2017 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: GPL-3.0
#

# All the magic numbers come from "Mg Digital Interface Timing: SPI at CPLD tab" timing
# analysis spreadsheet. Analysis should be re-performed every time a board rev occurs
# that affects the CPLD interfaces.

## PS Slave Constraints #################################################################
# - PsClk Rate
# - PsClk to SDI
# - PsClk to LE (sync and async paths)
# - PsClk to SDO

set PsSdiInputDelayMax  15.445
set PsSdiInputDelayMin -15.378

# Maximum 5 MHz clock rate!
create_clock -name PsClk -period 200 [get_ports {PsSpiSck}]

# SDI is both registered in the CPLD and used as a direct passthrough. First constrain
# the input delay on the local paths inside the CPLD. Passthrough constraints
# are handled elsewhere.
#
# SDI is driven from the FPGA on the falling edge of the Clk. Worst-case data-clock skew
# is around 15ns. Complete timing analysis is performed and recorded elsewhere. This
# constraint matches the FPGA output constraint.
set_input_delay -clock PsClk -max $PsSdiInputDelayMax [get_ports sPsSpiSdi] -clock_fall
set_input_delay -clock PsClk -min $PsSdiInputDelayMin [get_ports sPsSpiSdi] -clock_fall

# For the CPLD Cs_n, the latch enable is used both as an asynchronous reset and
# synchronously to latch data. First, constrain the overall input delay for sync use.
# Technically, Cs_n is asserted and de-asserted many nanoseconds before the clock arrives
# but we still constrain it identically to the SDI in case something goes amiss.
set_input_delay -clock PsClk -max $PsSdiInputDelayMax [get_ports sPsSpiLe] -clock_fall
set_input_delay -clock PsClk -min $PsSdiInputDelayMin [get_ports sPsSpiLe] -clock_fall
# Then set a false path only on the async reset flops.
set_false_path -from [get_ports {sPsSpiLe}] -to [get_pins sPsMosiIndex[*]|*]
set_false_path -from [get_ports {sPsSpiLe}] -to [get_pins sPsMisoIndex[*]|*]

# SDO is given a very loose output constraint.
set PsSdiOutputDelayMax  15
set PsSdiOutputDelayMin -15

set_output_delay -clock PsClk -max $PsSdiOutputDelayMax [get_ports sPsSpiSdo]
set_output_delay -clock PsClk -min $PsSdiOutputDelayMin [get_ports sPsSpiSdo]



## PL Slave Constraints #################################################################
# - PlClk Rate
# - PlClk to SDI
# - PlClk to LE (sync and async paths)
# - PlClk to SDO

set PlSdiInputDelayMax  15.445
set PlSdiInputDelayMin -15.378

# Maximum 5 MHz clock rate!
create_clock -name PlClk -period 200 [get_ports {PlSpiSck}]

# SDI is both registered in the CPLD and used as a direct passthrough. First constrain
# the input delay on the local paths inside the CPLD. Passthrough constraints
# are handled elsewhere.
#
# SDI is driven from the FPGA on the falling edge of the Clk. Worst-case data-clock skew
# is around 15ns. Complete timing analysis is performed and recorded elsewhere. This
# constraint matches the FPGA output constraint.
set_input_delay -clock PlClk -max $PlSdiInputDelayMax [get_ports lPlSpiSdi] -clock_fall
set_input_delay -clock PlClk -min $PlSdiInputDelayMin [get_ports lPlSpiSdi] -clock_fall

# For the CPLD Cs_n, the latch enable is used both as an asynchronous reset and
# synchronously to latch data. First, constrain the overall input delay for sync use.
# Technically, Cs_n is asserted and de-asserted many nanoseconds before the clock arrives
# but we still constrain it identically to the SDI in case something goes amiss.
set_input_delay -clock PlClk -max $PlSdiInputDelayMax [get_ports lPlSpiLe] -clock_fall
set_input_delay -clock PlClk -min $PlSdiInputDelayMin [get_ports lPlSpiLe] -clock_fall
# Then set a false path only on the async reset flops.
set_false_path -from [get_ports {lPlSpiLe}] -to [get_pins {lPlMosiIndex[*]|*}]
set_false_path -from [get_ports {lPlSpiLe}] -to [get_pins {lPlMisoIndex[*]|*}]

# SDO is given a very loose output constraint.
set PlSdiOutputDelayMax  15
set PlSdiOutputDelayMin -15

set_output_delay -clock PlClk -max $PlSdiOutputDelayMax [get_ports lPlSpiSdo]
set_output_delay -clock PlClk -min $PlSdiOutputDelayMin [get_ports lPlSpiSdo]



## Passthrough Constraints ##############################################################
# - LMK SYNC
# - PlClk/PsClk passthrough
#   - SDI passthrough for both
#   - SDO return mux passthrough for both
#   - Cs_n passthrough for both

# LMK Sync Passthrough: constrain min and max delays for output
set_max_delay -from [get_ports {aPlSpiAddr[2]}] -to [get_ports {aLmkSync}] 17
set_min_delay -from [get_ports {aPlSpiAddr[2]}] -to [get_ports {aLmkSync}] 2

# SPI Passthroughs: constrain min and max delays for outputs and inputs.
# Since the SDI ports have input delays pre-defined above, we have to remove those from
# the delay analysis here by adding the input delay to the constraint.
# Similarly, for the SDO pins add the output delay to the constraint.
set SpiMaxDelay 25
set SpiMinDelay  5

# PS
set_max_delay -to [get_ports {aDacDin aLmkSpiSdio}] [expr $PsSdiInputDelayMax + $SpiMaxDelay]
set_min_delay -to [get_ports {aDacDin aLmkSpiSdio}] [expr $PsSdiInputDelayMin + $SpiMinDelay]
set_max_delay -to [get_ports {aDacSync_n aLmkSpiCs_n}] $SpiMaxDelay
set_min_delay -to [get_ports {aDacSync_n aLmkSpiCs_n}] $SpiMinDelay
set_max_delay -to [get_ports {aDacSck aLmkSpiSck}] $SpiMaxDelay
set_min_delay -to [get_ports {aDacSck aLmkSpiSck}] $SpiMinDelay
set_max_delay -from [get_ports {aLmkClkinSel*}] [expr $SpiMaxDelay + $PsSdiOutputDelayMax]
set_min_delay -from [get_ports {aLmkClkinSel*}] [expr $SpiMinDelay + $PsSdiOutputDelayMin]

# PL
set_max_delay -to [get_ports {aRxLoDin aTxLoDin}] [expr $PlSdiInputDelayMax + $SpiMaxDelay]
set_min_delay -to [get_ports {aRxLoDin aTxLoDin}] [expr $PlSdiInputDelayMin + $SpiMinDelay]
set_max_delay -to [get_ports {aRxLoCs_n aTxLoCs_n}] $SpiMaxDelay
set_min_delay -to [get_ports {aRxLoCs_n aTxLoCs_n}] $SpiMinDelay
set_max_delay -to [get_ports {aRxLoSck aTxLoSck}] $SpiMaxDelay
set_min_delay -to [get_ports {aRxLoSck aTxLoSck}] $SpiMinDelay
set_max_delay -from [get_ports {aTxLoMuxOut aRxLoMuxOut}] [expr $SpiMaxDelay + $PlSdiOutputDelayMax]
set_min_delay -from [get_ports {aTxLoMuxOut aRxLoMuxOut}] [expr $SpiMinDelay + $PlSdiOutputDelayMin]



## Async Inputs #########################################################################
# aLmkStatus2 aRxLoLockDetect aTxLoLockDetect
set_false_path -from [get_ports {aRxLoLockDetect}]
set_false_path -from [get_ports {aTxLoLockDetect}]



## Async Outputs ########################################################################
# aMkReset_n aVcxoCtrl
set_false_path -to [get_ports {aMkReset_n}]
set_false_path -to [get_ports {aVcxoCtrl}]



## Sync Front End Outputs ###############################################################
# All we need to do here is constrain for maximum path delay from the aAtr(Rx|Tx)(1|2)
# control bits toggling to the outputs for aCh1* and aCh2* toggling. Just in case the
# user attempts to write the ATR while it's in use, we also constrain from the flops
# to the pins... which covers all paths... so just to -to option is needed.
set_max_delay -to [get_ports {aCh1* aCh2* aMk*x*En}] 40
set_min_delay -to [get_ports {aCh1* aCh2* aMk*x*En}] 5

# We don't care about the LED timing whatsoever. Let's not have them clogging up our
# precious timing paths.
set_false_path -to [get_ports {aCh*Led*}]
