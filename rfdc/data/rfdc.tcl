#
# (C) Copyright 2017-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

proc rfdc_generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set count 0
	foreach handle [hsi::get_cells -hier] {
		set ip_name [hsi get_property IP_NAME $handle]
		if {[string match -nocase $ip_name "usp_rf_data_converter"] } {
			set count [expr $count + 1]
		}
	}
	add_prop $node "num-insts" $count hexlist $dts_file

	set config {{"CONFIG.C_Sysref_Master"} \
	{"CONFIG.C_DAC0_Enable" "CONFIG.C_DAC0_PLL_Enable" "CONFIG.C_DAC0_Sampling_Rate" "CONFIG.C_DAC0_Refclk_Freq" "CONFIG.C_DAC0_Fabric_Freq" "CONFIG.C_DAC0_FBDIV" "CONFIG.C_DAC0_OutDiv" "CONFIG.C_DAC0_Refclk_Div" "CONFIG.C_DAC0_Band" "CONFIG.C_DAC0_Fs_Max" "CONFIG.C_DAC0_Slices" "CONFIG.C_DAC0_Link_Coupling"} \
	{"CONFIG.C_DAC_Slice00_Enable" "CONFIG.C_DAC_Invsinc_Ctrl00" "CONFIG.C_DAC_Mixer_Mode00" "CONFIG.C_DAC_Decoder_Mode00"} \
	{"CONFIG.C_DAC_Slice01_Enable" "CONFIG.C_DAC_Invsinc_Ctrl01" "CONFIG.C_DAC_Mixer_Mode01" "CONFIG.C_DAC_Decoder_Mode01"} \
	{"CONFIG.C_DAC_Slice02_Enable" "CONFIG.C_DAC_Invsinc_Ctrl02" "CONFIG.C_DAC_Mixer_Mode02" "CONFIG.C_DAC_Decoder_Mode02"} \
	{"CONFIG.C_DAC_Slice03_Enable" "CONFIG.C_DAC_Invsinc_Ctrl03" "CONFIG.C_DAC_Mixer_Mode03" "CONFIG.C_DAC_Decoder_Mode03"} \
	{"CONFIG.C_DAC_Data_Type00" "CONFIG.C_DAC_Data_Width00" "CONFIG.C_DAC_Interpolation_Mode00" "CONFIG.C_DAC_Fifo00_Enable" "CONFIG.C_DAC_Adder00_Enable" "CONFIG.C_DAC_Mixer_Type00" "CONFIG.C_DAC_NCO_Freq00"} \
	{"CONFIG.C_DAC_Data_Type01" "CONFIG.C_DAC_Data_Width01" "CONFIG.C_DAC_Interpolation_Mode01" "CONFIG.C_DAC_Fifo01_Enable" "CONFIG.C_DAC_Adder01_Enable" "CONFIG.C_DAC_Mixer_Type01" "CONFIG.C_DAC_NCO_Freq01"} \
	{"CONFIG.C_DAC_Data_Type02" "CONFIG.C_DAC_Data_Width02" "CONFIG.C_DAC_Interpolation_Mode02" "CONFIG.C_DAC_Fifo02_Enable" "CONFIG.C_DAC_Adder02_Enable" "CONFIG.C_DAC_Mixer_Type02" "CONFIG.C_DAC_NCO_Freq02"} \
	{"CONFIG.C_DAC_Data_Type03" "CONFIG.C_DAC_Data_Width03" "CONFIG.C_DAC_Interpolation_Mode03" "CONFIG.C_DAC_Fifo03_Enable" "CONFIG.C_DAC_Adder03_Enable" "CONFIG.C_DAC_Mixer_Type03" "CONFIG.C_DAC_NCO_Freq03"} \
	{"CONFIG.C_DAC1_Enable" "CONFIG.C_DAC1_PLL_Enable" "CONFIG.C_DAC1_Sampling_Rate" "CONFIG.C_DAC1_Refclk_Freq" "CONFIG.C_DAC1_Fabric_Freq" "CONFIG.C_DAC1_FBDIV" "CONFIG.C_DAC1_OutDiv" "CONFIG.C_DAC1_Refclk_Div" "CONFIG.C_DAC1_Band" "CONFIG.C_DAC1_Fs_Max" "CONFIG.C_DAC1_Slices" "CONFIG.C_DAC1_Link_Coupling"} \
	{"CONFIG.C_DAC_Slice10_Enable" "CONFIG.C_DAC_Invsinc_Ctrl10" "CONFIG.C_DAC_Mixer_Mode10" "CONFIG.C_DAC_Decoder_Mode10"} \
	{"CONFIG.C_DAC_Slice11_Enable" "CONFIG.C_DAC_Invsinc_Ctrl11" "CONFIG.C_DAC_Mixer_Mode11" "CONFIG.C_DAC_Decoder_Mode11"} \
	{"CONFIG.C_DAC_Slice12_Enable" "CONFIG.C_DAC_Invsinc_Ctrl12" "CONFIG.C_DAC_Mixer_Mode12" "CONFIG.C_DAC_Decoder_Mode12"} \
	{"CONFIG.C_DAC_Slice13_Enable" "CONFIG.C_DAC_Invsinc_Ctrl13" "CONFIG.C_DAC_Mixer_Mode13" "CONFIG.C_DAC_Decoder_Mode13"} \
	{"CONFIG.C_DAC_Data_Type10" "CONFIG.C_DAC_Data_Width10" "CONFIG.C_DAC_Interpolation_Mode10" "CONFIG.C_DAC_Fifo10_Enable" "CONFIG.C_DAC_Adder10_Enable" "CONFIG.C_DAC_Mixer_Type10" "CONFIG.C_DAC_NCO_Freq10"} \
	{"CONFIG.C_DAC_Data_Type11" "CONFIG.C_DAC_Data_Width11" "CONFIG.C_DAC_Interpolation_Mode11" "CONFIG.C_DAC_Fifo11_Enable" "CONFIG.C_DAC_Adder11_Enable" "CONFIG.C_DAC_Mixer_Type11" "CONFIG.C_DAC_NCO_Freq11"} \
	{"CONFIG.C_DAC_Data_Type12" "CONFIG.C_DAC_Data_Width12" "CONFIG.C_DAC_Interpolation_Mode12" "CONFIG.C_DAC_Fifo12_Enable" "CONFIG.C_DAC_Adder12_Enable" "CONFIG.C_DAC_Mixer_Type12" "CONFIG.C_DAC_NCO_Freq12"} \
	{"CONFIG.C_DAC_Data_Type13" "CONFIG.C_DAC_Data_Width13" "CONFIG.C_DAC_Interpolation_Mode13" "CONFIG.C_DAC_Fifo13_Enable" "CONFIG.C_DAC_Adder13_Enable" "CONFIG.C_DAC_Mixer_Type13" "CONFIG.C_DAC_NCO_Freq13"} \
	{"CONFIG.C_DAC2_Enable" "CONFIG.C_DAC2_PLL_Enable" "CONFIG.C_DAC2_Sampling_Rate" "CONFIG.C_DAC2_Refclk_Freq" "CONFIG.C_DAC2_Fabric_Freq" "CONFIG.C_DAC2_FBDIV" "CONFIG.C_DAC2_OutDiv" "CONFIG.C_DAC2_Refclk_Div" "CONFIG.C_DAC2_Band" "CONFIG.C_DAC2_Fs_Max" "CONFIG.C_DAC2_Slices" "CONFIG.C_DAC2_Link_Coupling"} \
	{"CONFIG.C_DAC_Slice20_Enable" "CONFIG.C_DAC_Invsinc_Ctrl20" "CONFIG.C_DAC_Mixer_Mode20" "CONFIG.C_DAC_Decoder_Mode20"} \
	{"CONFIG.C_DAC_Slice21_Enable" "CONFIG.C_DAC_Invsinc_Ctrl21" "CONFIG.C_DAC_Mixer_Mode21" "CONFIG.C_DAC_Decoder_Mode21"} \
	{"CONFIG.C_DAC_Slice22_Enable" "CONFIG.C_DAC_Invsinc_Ctrl22" "CONFIG.C_DAC_Mixer_Mode22" "CONFIG.C_DAC_Decoder_Mode22"} \
	{"CONFIG.C_DAC_Slice23_Enable" "CONFIG.C_DAC_Invsinc_Ctrl23" "CONFIG.C_DAC_Mixer_Mode23" "CONFIG.C_DAC_Decoder_Mode23"} \
	{"CONFIG.C_DAC_Data_Type20" "CONFIG.C_DAC_Data_Width20" "CONFIG.C_DAC_Interpolation_Mode20" "CONFIG.C_DAC_Fifo20_Enable" "CONFIG.C_DAC_Adder20_Enable" "CONFIG.C_DAC_Mixer_Type20" "CONFIG.C_DAC_NCO_Freq20"} \
	{"CONFIG.C_DAC_Data_Type21" "CONFIG.C_DAC_Data_Width21" "CONFIG.C_DAC_Interpolation_Mode21" "CONFIG.C_DAC_Fifo21_Enable" "CONFIG.C_DAC_Adder21_Enable" "CONFIG.C_DAC_Mixer_Type21" "CONFIG.C_DAC_NCO_Freq21"} \
	{"CONFIG.C_DAC_Data_Type22" "CONFIG.C_DAC_Data_Width22" "CONFIG.C_DAC_Interpolation_Mode22" "CONFIG.C_DAC_Fifo22_Enable" "CONFIG.C_DAC_Adder22_Enable" "CONFIG.C_DAC_Mixer_Type22" "CONFIG.C_DAC_NCO_Freq22"} \
	{"CONFIG.C_DAC_Data_Type23" "CONFIG.C_DAC_Data_Width23" "CONFIG.C_DAC_Interpolation_Mode23" "CONFIG.C_DAC_Fifo23_Enable" "CONFIG.C_DAC_Adder23_Enable" "CONFIG.C_DAC_Mixer_Type23" "CONFIG.C_DAC_NCO_Freq23"} \
	{"CONFIG.C_DAC3_Enable" "CONFIG.C_DAC3_PLL_Enable" "CONFIG.C_DAC3_Sampling_Rate" "CONFIG.C_DAC3_Refclk_Freq" "CONFIG.C_DAC3_Fabric_Freq" "CONFIG.C_DAC3_FBDIV" "CONFIG.C_DAC3_OutDiv" "CONFIG.C_DAC3_Refclk_Div" "CONFIG.C_DAC3_Band" "CONFIG.C_DAC3_Fs_Max" "CONFIG.C_DAC3_Slices" "CONFIG.C_DAC3_Link_Coupling"} \
	{"CONFIG.C_DAC_Slice30_Enable" "CONFIG.C_DAC_Invsinc_Ctrl30" "CONFIG.C_DAC_Mixer_Mode30" "CONFIG.C_DAC_Decoder_Mode30"} \
	{"CONFIG.C_DAC_Slice31_Enable" "CONFIG.C_DAC_Invsinc_Ctrl31" "CONFIG.C_DAC_Mixer_Mode31" "CONFIG.C_DAC_Decoder_Mode31"} \
	{"CONFIG.C_DAC_Slice32_Enable" "CONFIG.C_DAC_Invsinc_Ctrl32" "CONFIG.C_DAC_Mixer_Mode32" "CONFIG.C_DAC_Decoder_Mode32"} \
	{"CONFIG.C_DAC_Slice33_Enable" "CONFIG.C_DAC_Invsinc_Ctrl33" "CONFIG.C_DAC_Mixer_Mode33" "CONFIG.C_DAC_Decoder_Mode33"} \
	{"CONFIG.C_DAC_Data_Type30" "CONFIG.C_DAC_Data_Width30" "CONFIG.C_DAC_Interpolation_Mode30" "CONFIG.C_DAC_Fifo30_Enable" "CONFIG.C_DAC_Adder30_Enable" "CONFIG.C_DAC_Mixer_Type30" "CONFIG.C_DAC_NCO_Freq30"} \
	{"CONFIG.C_DAC_Data_Type31" "CONFIG.C_DAC_Data_Width31" "CONFIG.C_DAC_Interpolation_Mode31" "CONFIG.C_DAC_Fifo31_Enable" "CONFIG.C_DAC_Adder31_Enable" "CONFIG.C_DAC_Mixer_Type31" "CONFIG.C_DAC_NCO_Freq31"} \
	{"CONFIG.C_DAC_Data_Type32" "CONFIG.C_DAC_Data_Width32" "CONFIG.C_DAC_Interpolation_Mode32" "CONFIG.C_DAC_Fifo32_Enable" "CONFIG.C_DAC_Adder32_Enable" "CONFIG.C_DAC_Mixer_Type32" "CONFIG.C_DAC_NCO_Freq32"} \
	{"CONFIG.C_DAC_Data_Type33" "CONFIG.C_DAC_Data_Width33" "CONFIG.C_DAC_Interpolation_Mode33" "CONFIG.C_DAC_Fifo33_Enable" "CONFIG.C_DAC_Adder33_Enable" "CONFIG.C_DAC_Mixer_Type33" "CONFIG.C_DAC_NCO_Freq33"} \
	{"CONFIG.C_ADC0_Enable" "CONFIG.C_ADC0_PLL_Enable" "CONFIG.C_ADC0_Sampling_Rate" "CONFIG.C_ADC0_Refclk_Freq" "CONFIG.C_ADC0_Fabric_Freq" "CONFIG.C_ADC0_FBDIV" "CONFIG.C_ADC0_OutDiv" "CONFIG.C_ADC0_Refclk_Div" "CONFIG.C_ADC0_Band" "CONFIG.C_ADC0_Fs_Max" "CONFIG.C_ADC0_Slices"} \
	{"CONFIG.C_ADC_Slice00_Enable" "CONFIG.C_ADC_Mixer_Mode00"} \
	{"CONFIG.C_ADC_Slice01_Enable" "CONFIG.C_ADC_Mixer_Mode01"} \
	{"CONFIG.C_ADC_Slice02_Enable" "CONFIG.C_ADC_Mixer_Mode02"} \
	{"CONFIG.C_ADC_Slice03_Enable" "CONFIG.C_ADC_Mixer_Mode03"} \
	{"CONFIG.C_ADC_Data_Type00" "CONFIG.C_ADC_Data_Width00" "CONFIG.C_ADC_Decimation_Mode00" "CONFIG.C_ADC_Fifo00_Enable" "CONFIG.C_ADC_Mixer_Type00" "CONFIG.C_ADC_NCO_Freq00"} \
	{"CONFIG.C_ADC_Data_Type01" "CONFIG.C_ADC_Data_Width01" "CONFIG.C_ADC_Decimation_Mode01" "CONFIG.C_ADC_Fifo01_Enable" "CONFIG.C_ADC_Mixer_Type01" "CONFIG.C_ADC_NCO_Freq01"} \
	{"CONFIG.C_ADC_Data_Type02" "CONFIG.C_ADC_Data_Width02" "CONFIG.C_ADC_Decimation_Mode02" "CONFIG.C_ADC_Fifo02_Enable" "CONFIG.C_ADC_Mixer_Type02" "CONFIG.C_ADC_NCO_Freq02"} \
	{"CONFIG.C_ADC_Data_Type03" "CONFIG.C_ADC_Data_Width03" "CONFIG.C_ADC_Decimation_Mode03" "CONFIG.C_ADC_Fifo03_Enable" "CONFIG.C_ADC_Mixer_Type03" "CONFIG.C_ADC_NCO_Freq03"} \
	{"CONFIG.C_ADC1_Enable" "CONFIG.C_ADC1_PLL_Enable" "CONFIG.C_ADC1_Sampling_Rate" "CONFIG.C_ADC1_Refclk_Freq" "CONFIG.C_ADC1_Fabric_Freq" "CONFIG.C_ADC1_FBDIV" "CONFIG.C_ADC1_OutDiv" "CONFIG.C_ADC1_Refclk_Div" "CONFIG.C_ADC1_Band" "CONFIG.C_ADC1_Fs_Max" "CONFIG.C_ADC1_Slices"} \
	{"CONFIG.C_ADC_Slice10_Enable" "CONFIG.C_ADC_Mixer_Mode10"} \
	{"CONFIG.C_ADC_Slice11_Enable" "CONFIG.C_ADC_Mixer_Mode11"} \
	{"CONFIG.C_ADC_Slice12_Enable" "CONFIG.C_ADC_Mixer_Mode12"} \
	{"CONFIG.C_ADC_Slice13_Enable" "CONFIG.C_ADC_Mixer_Mode13"} \
	{"CONFIG.C_ADC_Data_Type10" "CONFIG.C_ADC_Data_Width10" "CONFIG.C_ADC_Decimation_Mode10" "CONFIG.C_ADC_Fifo10_Enable" "CONFIG.C_ADC_Mixer_Type10" "CONFIG.C_ADC_NCO_Freq10"} \
	{"CONFIG.C_ADC_Data_Type11" "CONFIG.C_ADC_Data_Width11" "CONFIG.C_ADC_Decimation_Mode11" "CONFIG.C_ADC_Fifo11_Enable" "CONFIG.C_ADC_Mixer_Type11" "CONFIG.C_ADC_NCO_Freq11"} \
	{"CONFIG.C_ADC_Data_Type12" "CONFIG.C_ADC_Data_Width12" "CONFIG.C_ADC_Decimation_Mode12" "CONFIG.C_ADC_Fifo12_Enable" "CONFIG.C_ADC_Mixer_Type12" "CONFIG.C_ADC_NCO_Freq12"} \
	{"CONFIG.C_ADC_Data_Type13" "CONFIG.C_ADC_Data_Width13" "CONFIG.C_ADC_Decimation_Mode13" "CONFIG.C_ADC_Fifo13_Enable" "CONFIG.C_ADC_Mixer_Type13" "CONFIG.C_ADC_NCO_Freq13"} \
	{"CONFIG.C_ADC2_Enable" "CONFIG.C_ADC2_PLL_Enable" "CONFIG.C_ADC2_Sampling_Rate" "CONFIG.C_ADC2_Refclk_Freq" "CONFIG.C_ADC2_Fabric_Freq" "CONFIG.C_ADC2_FBDIV" "CONFIG.C_ADC2_OutDiv" "CONFIG.C_ADC2_Refclk_Div" "CONFIG.C_ADC2_Band" "CONFIG.C_ADC2_Fs_Max" "CONFIG.C_ADC2_Slices"} \
	{"CONFIG.C_ADC_Slice20_Enable" "CONFIG.C_ADC_Mixer_Mode20"} \
	{"CONFIG.C_ADC_Slice21_Enable" "CONFIG.C_ADC_Mixer_Mode21"} \
	{"CONFIG.C_ADC_Slice22_Enable" "CONFIG.C_ADC_Mixer_Mode22"} \
	{"CONFIG.C_ADC_Slice23_Enable" "CONFIG.C_ADC_Mixer_Mode23"} \
	{"CONFIG.C_ADC_Data_Type20" "CONFIG.C_ADC_Data_Width20" "CONFIG.C_ADC_Decimation_Mode20" "CONFIG.C_ADC_Fifo20_Enable" "CONFIG.C_ADC_Mixer_Type20" "CONFIG.C_ADC_NCO_Freq20"} \
	{"CONFIG.C_ADC_Data_Type21" "CONFIG.C_ADC_Data_Width21" "CONFIG.C_ADC_Decimation_Mode21" "CONFIG.C_ADC_Fifo21_Enable" "CONFIG.C_ADC_Mixer_Type21" "CONFIG.C_ADC_NCO_Freq21"} \
	{"CONFIG.C_ADC_Data_Type22" "CONFIG.C_ADC_Data_Width22" "CONFIG.C_ADC_Decimation_Mode22" "CONFIG.C_ADC_Fifo22_Enable" "CONFIG.C_ADC_Mixer_Type22" "CONFIG.C_ADC_NCO_Freq22"} \
	{"CONFIG.C_ADC_Data_Type23" "CONFIG.C_ADC_Data_Width23" "CONFIG.C_ADC_Decimation_Mode23" "CONFIG.C_ADC_Fifo23_Enable" "CONFIG.C_ADC_Mixer_Type23" "CONFIG.C_ADC_NCO_Freq23"} \
	{"CONFIG.C_ADC3_Enable" "CONFIG.C_ADC3_PLL_Enable" "CONFIG.C_ADC3_Sampling_Rate" "CONFIG.C_ADC3_Refclk_Freq" "CONFIG.C_ADC3_Fabric_Freq" "CONFIG.C_ADC3_FBDIV" "CONFIG.C_ADC3_OutDiv" "CONFIG.C_ADC3_Refclk_Div" "CONFIG.C_ADC3_Band" "CONFIG.C_ADC3_Fs_Max" "CONFIG.C_ADC3_Slices"} \
	{"CONFIG.C_ADC_Slice30_Enable" "CONFIG.C_ADC_Mixer_Mode30"} \
	{"CONFIG.C_ADC_Slice31_Enable" "CONFIG.C_ADC_Mixer_Mode31"} \
	{"CONFIG.C_ADC_Slice32_Enable" "CONFIG.C_ADC_Mixer_Mode32"} \
	{"CONFIG.C_ADC_Slice33_Enable" "CONFIG.C_ADC_Mixer_Mode33"} \
	{"CONFIG.C_ADC_Data_Type30" "CONFIG.C_ADC_Data_Width30" "CONFIG.C_ADC_Decimation_Mode30" "CONFIG.C_ADC_Fifo30_Enable" "CONFIG.C_ADC_Mixer_Type30" "CONFIG.C_ADC_NCO_Freq30"} \
	{"CONFIG.C_ADC_Data_Type31" "CONFIG.C_ADC_Data_Width31" "CONFIG.C_ADC_Decimation_Mode31" "CONFIG.C_ADC_Fifo31_Enable" "CONFIG.C_ADC_Mixer_Type31" "CONFIG.C_ADC_NCO_Freq31"} \
	{"CONFIG.C_ADC_Data_Type32" "CONFIG.C_ADC_Data_Width32" "CONFIG.C_ADC_Decimation_Mode32" "CONFIG.C_ADC_Fifo32_Enable" "CONFIG.C_ADC_Mixer_Type32" "CONFIG.C_ADC_NCO_Freq32"} \
	{"CONFIG.C_ADC_Data_Type33" "CONFIG.C_ADC_Data_Width33" "CONFIG.C_ADC_Decimation_Mode33" "CONFIG.C_ADC_Fifo33_Enable" "CONFIG.C_ADC_Mixer_Type33" "CONFIG.C_ADC_NCO_Freq33"}}
	rfdc_add_top_level_props $drv_handle $config
	rfdc_add_param_hsi $drv_handle "DEVICE_ID" "C_BASEADDR" "C_High_Speed_ADC" "C_Sysref_Master" "C_Sysref_Master" "C_Sysref_Source" "C_Sysref_Source" "C_IP_Type" "C_Silicon_Revision" \
	"C_DAC0_Enable" "C_DAC0_PLL_Enable" "C_DAC0_Sampling_Rate" "C_DAC0_Refclk_Freq" "C_DAC0_Fabric_Freq" "C_DAC0_FBDIV" "C_DAC0_OutDiv" "C_DAC0_Refclk_Div" "C_DAC0_Band" "C_DAC0_Fs_Max" "C_DAC0_Slices" "DAC0_Link_Coupling" \
	"C_DAC_Slice00_Enable" "C_DAC_Invsinc_Ctrl00" "C_DAC_Mixer_Mode00" "C_DAC_Decoder_Mode00" \
	"C_DAC_Slice01_Enable" "C_DAC_Invsinc_Ctrl01" "C_DAC_Mixer_Mode01" "C_DAC_Decoder_Mode01" \
	"C_DAC_Slice02_Enable" "C_DAC_Invsinc_Ctrl02" "C_DAC_Mixer_Mode02" "C_DAC_Decoder_Mode02" \
	"C_DAC_Slice03_Enable" "C_DAC_Invsinc_Ctrl03" "C_DAC_Mixer_Mode03" "C_DAC_Decoder_Mode03" \
	"C_DAC_Data_Type00" "C_DAC_Data_Width00" "C_DAC_Interpolation_Mode00" "C_DAC_Fifo00_Enable" "C_DAC_Adder00_Enable" "C_DAC_Mixer_Type00" "C_DAC_NCO_Freq00" \
	"C_DAC_Data_Type01" "C_DAC_Data_Width01" "C_DAC_Interpolation_Mode01" "C_DAC_Fifo01_Enable" "C_DAC_Adder01_Enable" "C_DAC_Mixer_Type01" "C_DAC_NCO_Freq01" \
	"C_DAC_Data_Type02" "C_DAC_Data_Width02" "C_DAC_Interpolation_Mode02" "C_DAC_Fifo02_Enable" "C_DAC_Adder02_Enable" "C_DAC_Mixer_Type02" "C_DAC_NCO_Freq02" \
	"C_DAC_Data_Type03" "C_DAC_Data_Width03" "C_DAC_Interpolation_Mode03" "C_DAC_Fifo03_Enable" "C_DAC_Adder03_Enable" "C_DAC_Mixer_Type03" "C_DAC_NCO_Freq03" \
	"C_DAC1_Enable" "C_DAC1_PLL_Enable" "C_DAC1_Sampling_Rate" "C_DAC1_Refclk_Freq" "C_DAC1_Fabric_Freq" "C_DAC1_FBDIV" "C_DAC1_OutDiv" "C_DAC1_Refclk_Div" "C_DAC1_Band" "C_DAC1_Fs_Max" "C_DAC1_Slices" "DAC1_Link_Coupling" \
	"C_DAC_Slice10_Enable" "C_DAC_Invsinc_Ctrl10" "C_DAC_Mixer_Mode10" "C_DAC_Decoder_Mode10" \
	"C_DAC_Slice11_Enable" "C_DAC_Invsinc_Ctrl11" "C_DAC_Mixer_Mode11" "C_DAC_Decoder_Mode11" \
	"C_DAC_Slice12_Enable" "C_DAC_Invsinc_Ctrl12" "C_DAC_Mixer_Mode12" "C_DAC_Decoder_Mode12" \
	"C_DAC_Slice13_Enable" "C_DAC_Invsinc_Ctrl13" "C_DAC_Mixer_Mode13" "C_DAC_Decoder_Mode13" \
	"C_DAC_Data_Type10" "C_DAC_Data_Width10" "C_DAC_Interpolation_Mode10" "C_DAC_Fifo10_Enable" "C_DAC_Adder10_Enable" "C_DAC_Mixer_Type10" "C_DAC_NCO_Freq10" \
	"C_DAC_Data_Type11" "C_DAC_Data_Width11" "C_DAC_Interpolation_Mode11" "C_DAC_Fifo11_Enable" "C_DAC_Adder11_Enable" "C_DAC_Mixer_Type11" "C_DAC_NCO_Freq11" \
	"C_DAC_Data_Type12" "C_DAC_Data_Width12" "C_DAC_Interpolation_Mode12" "C_DAC_Fifo12_Enable" "C_DAC_Adder12_Enable" "C_DAC_Mixer_Type12" "C_DAC_NCO_Freq12" \
	"C_DAC_Data_Type13" "C_DAC_Data_Width13" "C_DAC_Interpolation_Mode13" "C_DAC_Fifo13_Enable" "C_DAC_Adder13_Enable" "C_DAC_Mixer_Type13" "C_DAC_NCO_Freq13" \
	"C_DAC2_Enable" "C_DAC2_PLL_Enable" "C_DAC2_Sampling_Rate" "C_DAC2_Refclk_Freq" "C_DAC2_Fabric_Freq" "C_DAC2_FBDIV" "C_DAC2_OutDiv" "C_DAC2_Refclk_Div" "C_DAC2_Band" "C_DAC2_Fs_Max" "C_DAC2_Slices" "DAC2_Link_Coupling" \
	"C_DAC_Slice20_Enable" "C_DAC_Invsinc_Ctrl20" "C_DAC_Mixer_Mode20" "C_DAC_Decoder_Mode20" \
	"C_DAC_Slice21_Enable" "C_DAC_Invsinc_Ctrl21" "C_DAC_Mixer_Mode21" "C_DAC_Decoder_Mode21" \
	"C_DAC_Slice22_Enable" "C_DAC_Invsinc_Ctrl22" "C_DAC_Mixer_Mode22" "C_DAC_Decoder_Mode22" \
	"C_DAC_Slice23_Enable" "C_DAC_Invsinc_Ctrl23" "C_DAC_Mixer_Mode23" "C_DAC_Decoder_Mode23" \
	"C_DAC_Data_Type20" "C_DAC_Data_Width20" "C_DAC_Interpolation_Mode20" "C_DAC_Fifo20_Enable" "C_DAC_Adder20_Enable" "C_DAC_Mixer_Type20" "C_DAC_NCO_Freq20" \
	"C_DAC_Data_Type21" "C_DAC_Data_Width21" "C_DAC_Interpolation_Mode21" "C_DAC_Fifo21_Enable" "C_DAC_Adder21_Enable" "C_DAC_Mixer_Type21" "C_DAC_NCO_Freq21" \
	"C_DAC_Data_Type22" "C_DAC_Data_Width22" "C_DAC_Interpolation_Mode22" "C_DAC_Fifo22_Enable" "C_DAC_Adder22_Enable" "C_DAC_Mixer_Type22" "C_DAC_NCO_Freq22" \
	"C_DAC_Data_Type23" "C_DAC_Data_Width23" "C_DAC_Interpolation_Mode23" "C_DAC_Fifo23_Enable" "C_DAC_Adder23_Enable" "C_DAC_Mixer_Type23" "C_DAC_NCO_Freq23" \
	"C_DAC3_Enable" "C_DAC3_PLL_Enable" "C_DAC3_Sampling_Rate" "C_DAC3_Refclk_Freq" "C_DAC3_Fabric_Freq" "C_DAC3_FBDIV" "C_DAC3_OutDiv" "C_DAC3_Refclk_Div" "C_DAC3_Band" "C_DAC3_Fs_Max" "C_DAC3_Slices" "DAC3_Link_Coupling" \
	"C_DAC_Slice30_Enable" "C_DAC_Invsinc_Ctrl30" "C_DAC_Mixer_Mode30" "C_DAC_Decoder_Mode30" \
	"C_DAC_Slice31_Enable" "C_DAC_Invsinc_Ctrl31" "C_DAC_Mixer_Mode31" "C_DAC_Decoder_Mode31" \
	"C_DAC_Slice32_Enable" "C_DAC_Invsinc_Ctrl32" "C_DAC_Mixer_Mode32" "C_DAC_Decoder_Mode32" \
	"C_DAC_Slice33_Enable" "C_DAC_Invsinc_Ctrl33" "C_DAC_Mixer_Mode33" "C_DAC_Decoder_Mode33" \
	"C_DAC_Data_Type30" "C_DAC_Data_Width30" "C_DAC_Interpolation_Mode30" "C_DAC_Fifo30_Enable" "C_DAC_Adder30_Enable" "C_DAC_Mixer_Type30" "C_DAC_NCO_Freq30" \
	"C_DAC_Data_Type31" "C_DAC_Data_Width31" "C_DAC_Interpolation_Mode31" "C_DAC_Fifo31_Enable" "C_DAC_Adder31_Enable" "C_DAC_Mixer_Type31" "C_DAC_NCO_Freq31" \
	"C_DAC_Data_Type32" "C_DAC_Data_Width32" "C_DAC_Interpolation_Mode32" "C_DAC_Fifo32_Enable" "C_DAC_Adder32_Enable" "C_DAC_Mixer_Type32" "C_DAC_NCO_Freq32" \
	"C_DAC_Data_Type33" "C_DAC_Data_Width33" "C_DAC_Interpolation_Mode33" "C_DAC_Fifo33_Enable" "C_DAC_Adder33_Enable" "C_DAC_Mixer_Type33" "C_DAC_NCO_Freq33" \
	"C_ADC0_Enable" "C_ADC0_PLL_Enable" "C_ADC0_Sampling_Rate" "C_ADC0_Refclk_Freq" "C_ADC0_Fabric_Freq" "C_ADC0_FBDIV" "C_ADC0_OutDiv" "C_ADC0_Refclk_Div" "C_ADC0_Band" "C_ADC0_Fs_Max" "C_ADC0_Slices" \
	"C_ADC_Slice00_Enable" "C_ADC_Mixer_Mode00" \
	"C_ADC_Slice01_Enable" "C_ADC_Mixer_Mode01" \
	"C_ADC_Slice02_Enable" "C_ADC_Mixer_Mode02" \
	"C_ADC_Slice03_Enable" "C_ADC_Mixer_Mode03" \
	"C_ADC_Data_Type00" "C_ADC_Data_Width00" "C_ADC_Decimation_Mode00" "C_ADC_Fifo00_Enable" "C_ADC_Mixer_Type00" "C_ADC_NCO_Freq00" \
	"C_ADC_Data_Type01" "C_ADC_Data_Width01" "C_ADC_Decimation_Mode01" "C_ADC_Fifo01_Enable" "C_ADC_Mixer_Type01" "C_ADC_NCO_Freq01" \
	"C_ADC_Data_Type02" "C_ADC_Data_Width02" "C_ADC_Decimation_Mode02" "C_ADC_Fifo02_Enable" "C_ADC_Mixer_Type02" "C_ADC_NCO_Freq02" \
	"C_ADC_Data_Type03" "C_ADC_Data_Width03" "C_ADC_Decimation_Mode03" "C_ADC_Fifo03_Enable" "C_ADC_Mixer_Type03" "C_ADC_NCO_Freq03" \
	"C_ADC1_Enable" "C_ADC1_PLL_Enable" "C_ADC1_Sampling_Rate" "C_ADC1_Refclk_Freq" "C_ADC1_Fabric_Freq" "C_ADC1_FBDIV" "C_ADC1_OutDiv" "C_ADC1_Refclk_Div" "C_ADC1_Band" "C_ADC1_Fs_Max" "C_ADC1_Slices" \
	"C_ADC_Slice10_Enable" "C_ADC_Mixer_Mode10" \
	"C_ADC_Slice11_Enable" "C_ADC_Mixer_Mode11" \
	"C_ADC_Slice12_Enable" "C_ADC_Mixer_Mode12" \
	"C_ADC_Slice13_Enable" "C_ADC_Mixer_Mode13" \
	"C_ADC_Data_Type10" "C_ADC_Data_Width10" "C_ADC_Decimation_Mode10" "C_ADC_Fifo10_Enable" "C_ADC_Mixer_Type10" "C_ADC_NCO_Freq10" \
	"C_ADC_Data_Type11" "C_ADC_Data_Width11" "C_ADC_Decimation_Mode11" "C_ADC_Fifo11_Enable" "C_ADC_Mixer_Type11" "C_ADC_NCO_Freq11" \
	"C_ADC_Data_Type12" "C_ADC_Data_Width12" "C_ADC_Decimation_Mode12" "C_ADC_Fifo12_Enable" "C_ADC_Mixer_Type12" "C_ADC_NCO_Freq12" \
	"C_ADC_Data_Type13" "C_ADC_Data_Width13" "C_ADC_Decimation_Mode13" "C_ADC_Fifo13_Enable" "C_ADC_Mixer_Type13" "C_ADC_NCO_Freq13" \
	"C_ADC2_Enable" "C_ADC2_PLL_Enable" "C_ADC2_Sampling_Rate" "C_ADC2_Refclk_Freq" "C_ADC2_Fabric_Freq" "C_ADC2_FBDIV" "C_ADC2_OutDiv" "C_ADC2_Refclk_Div" "C_ADC2_Band" "C_ADC2_Fs_Max" "C_ADC2_Slices" \
	"C_ADC_Slice20_Enable" "C_ADC_Mixer_Mode20" \
	"C_ADC_Slice21_Enable" "C_ADC_Mixer_Mode21" \
	"C_ADC_Slice22_Enable" "C_ADC_Mixer_Mode22" \
	"C_ADC_Slice23_Enable" "C_ADC_Mixer_Mode23" \
	"C_ADC_Data_Type20" "C_ADC_Data_Width20" "C_ADC_Decimation_Mode20" "C_ADC_Fifo20_Enable" "C_ADC_Mixer_Type20" "C_ADC_NCO_Freq20" \
	"C_ADC_Data_Type21" "C_ADC_Data_Width21" "C_ADC_Decimation_Mode21" "C_ADC_Fifo21_Enable" "C_ADC_Mixer_Type21" "C_ADC_NCO_Freq21" \
	"C_ADC_Data_Type22" "C_ADC_Data_Width22" "C_ADC_Decimation_Mode22" "C_ADC_Fifo22_Enable" "C_ADC_Mixer_Type22" "C_ADC_NCO_Freq22" \
	"C_ADC_Data_Type23" "C_ADC_Data_Width23" "C_ADC_Decimation_Mode23" "C_ADC_Fifo23_Enable" "C_ADC_Mixer_Type23" "C_ADC_NCO_Freq23" \
	"C_ADC3_Enable" "C_ADC3_PLL_Enable" "C_ADC3_Sampling_Rate" "C_ADC3_Refclk_Freq" "C_ADC3_Fabric_Freq" "C_ADC3_FBDIV" "C_ADC3_OutDiv" "C_ADC3_Refclk_Div" "C_ADC3_Band" "C_ADC3_Fs_Max" "C_ADC3_Slices" \
	"C_ADC_Slice30_Enable" "C_ADC_Mixer_Mode30" \
	"C_ADC_Slice31_Enable" "C_ADC_Mixer_Mode31" \
	"C_ADC_Slice32_Enable" "C_ADC_Mixer_Mode32" \
	"C_ADC_Slice33_Enable" "C_ADC_Mixer_Mode33" \
	"C_ADC_Data_Type30" "C_ADC_Data_Width30" "C_ADC_Decimation_Mode30" "C_ADC_Fifo30_Enable" "C_ADC_Mixer_Type30" "C_ADC_NCO_Freq30" \
	"C_ADC_Data_Type31" "C_ADC_Data_Width31" "C_ADC_Decimation_Mode31" "C_ADC_Fifo31_Enable" "C_ADC_Mixer_Type31" "C_ADC_NCO_Freq31" \
	"C_ADC_Data_Type32" "C_ADC_Data_Width32" "C_ADC_Decimation_Mode32" "C_ADC_Fifo32_Enable" "C_ADC_Mixer_Type32" "C_ADC_NCO_Freq32" \
	"C_ADC_Data_Type33" "C_ADC_Data_Width33" "C_ADC_Decimation_Mode33" "C_ADC_Fifo33_Enable" "C_ADC_Mixer_Type33" "C_ADC_NCO_Freq33"

}

proc rfdc_add_props {drv_handle node props} {
	set prop_name_list [default_parameters $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	foreach ip_prop_name $props {
		set value 0
		if {[lsearch $prop_name_list $ip_prop_name] >= 0 } {
			set value [hsi get_property $ip_prop_name $drv_handle]
			if {[string compare -nocase "false" $value] == 0} {
				set value 0
			} elseif {[string compare -nocase "true" $value] == 0} {
				set value 1
			}
		}
		set drv_prop_name $ip_prop_name
		regsub -all {CONFIG.C_} $drv_prop_name {xlnx,} drv_prop_name
		regsub -all {0} $drv_prop_name {} drv_prop_name
		regsub -all {1} $drv_prop_name {} drv_prop_name
		regsub -all {2} $drv_prop_name {} drv_prop_name
		regsub -all {3} $drv_prop_name {} drv_prop_name
		regsub -all {DAC_} $drv_prop_name {} drv_prop_name
		regsub -all {ADC_} $drv_prop_name {} drv_prop_name
		regsub -all {_} $drv_prop_name {-} drv_prop_name
		set drv_prop_name [string tolower $drv_prop_name]
		add_prop $node $drv_prop_name $value hexint $dts_file
	}
}

proc rfdc_add_top_level_props {drv_handle config} {
	set index 0
	set dts_file [set_drv_def_dts $drv_handle]
	set ip_name [get_ip_property $drv_handle IP_NAME]
	set node [get_node $drv_handle]
	rfdc_add_props $drv_handle $node [lindex $config $index]
	incr index
	set ap "ap"
	set dp "dp"
	set name "dac"
	set at "@"
	for {set converter_index 0} {$converter_index < 4} {incr converter_index} {
		set converter [create_node -n $name$at$converter_index -p $node -d $dts_file]
		rfdc_add_props $drv_handle $converter [lindex $config $index]
		incr index
		for {set slice_index 0} {$slice_index < 4} {incr slice_index} {
			set slice [create_node -n $name$converter_index$ap$at$slice_index -p $converter -d $dts_file]
			rfdc_add_props $drv_handle $slice [lindex $config $index]
			incr index
		}
		for {set slice_index 0} {$slice_index < 4} {incr slice_index} {
			set slice [create_node -n $name$converter_index$dp$at$slice_index -p $converter -d $dts_file]
			rfdc_add_props $drv_handle $slice [lindex $config $index]
			incr index
		}
	}
	set name "adc"
	for {set converter_index 0} {$converter_index < 4} {incr converter_index} {
		set converter [create_node -n $name$at$converter_index -p $node -d $dts_file]
		rfdc_add_props $drv_handle $converter [lindex $config $index]
		incr index
		for {set slice_index 0} {$slice_index < 4} {incr slice_index} {
			set slice [create_node -n $name$converter_index$ap$at$slice_index -p $converter -d $dts_file]
			rfdc_add_props $drv_handle $slice [lindex $config $index]
			incr index
		}
		for {set slice_index 0} {$slice_index < 4} {incr slice_index} {
			set slice [create_node -n $name$converter_index$dp$at$slice_index -p $converter -d $dts_file]
			rfdc_add_props $drv_handle $slice [lindex $config $index]
			incr index
		}
	}
}

proc rfdc_convert_hex_string_to_byte_code {var} {
    return [string trimright [regsub -all {..} $var {& }]]
}

proc rfdc_convert_double_to_le_byte_code_format {var} {
    set result ""
    set double [binary format q $var]
    binary scan $double H* result
    return [rfdc_convert_hex_string_to_byte_code $result]
}

proc rfdc_convert_int_to_le_byte_code_format {var} {
    set result ""
    set integer [binary format i $var]
    binary scan $integer H* result
    return [rfdc_convert_hex_string_to_byte_code $result]
}

#
# Given a list of arguments, add them in param-list property,
# in byte code format
#
proc rfdc_add_param_hsi {drv_handle args} {
    set args [get_exact_arg_list $args]
    set periphs ""
    foreach handle [hsi::get_cells -hier] {
            set ip_name [hsi get_property IP_NAME $handle]
            if {[string match -nocase $ip_name "usp_rf_data_converter"]} {
                    lappend periphs $handle
            }
    }

    # Get all peripherals connected to this driver
    set device_id 0
    foreach periph $periphs {
            if {[string compare -nocase $periph $drv_handle] == 0} {
                    break
            }
            incr device_id
    }

    foreach arg $args {
            if {[string compare -nocase "DEVICE_ID" $arg] == 0} {
                    set value $device_id
            } else {
                    set value [hsi get_property CONFIG.$arg $periph]
            }
            if {[llength $value] == 0} {
                    set value 0
            }
			puts $arg
            if { [string first "_Sampling_Rate" $arg] > -1 || [string first "_Refclk_Freq" $arg] > -1 || [string first "_Fabric_Freq" $arg] > -1 || [string first "_Fs_Max" $arg] > -1 || [string match "*_NCO_Freq*" $arg]} {
			puts "here"
                    append data " " [rfdc_convert_double_to_le_byte_code_format $value]
            } elseif { [string first "C_BASEADDR" $arg] > -1 } {
                    set high_addr 0x00000000
                    #Check if address is greater than 4GB (i.e more than 32 bit)
                    if {[regexp -nocase {([0-9a-f]{9})} "$value" match]} {
                            set high_addr "0x[string range $value 10 17]"
                    }
                    set low_addr [string range $value 0 9]
                    append data " " [rfdc_convert_int_to_le_byte_code_format $low_addr]
                    append data " " [rfdc_convert_int_to_le_byte_code_format $high_addr]
            } else {
			puts "there"
                    if {[string compare -nocase "false" $value] == 0} {
                            set value 0
                    } elseif {[string compare -nocase "true" $value] == 0} {
                            set value 1
                    }
                    append data " " [rfdc_convert_int_to_le_byte_code_format $value]
            }
    }
    set node [get_node $drv_handle]
    set dts_file [set_drv_def_dts $drv_handle]
    add_prop $node "param-list" $data bytesequence $dts_file
}
