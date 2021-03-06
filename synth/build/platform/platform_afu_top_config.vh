//
// This file has been generated automatically by afu_platform_config.
// Do not edit it by hand.
//
// Platform: a10_gx_pac_hssi
// AFU top-level interface: ccip_std_afu
//

`ifndef __PLATFORM_AFU_TOP_CONFIG_VH__
`define __PLATFORM_AFU_TOP_CONFIG_VH__

`define PLATFORM_CLASS_NAME "A10_GX_PAC_HSSI"
`define PLATFORM_CLASS_NAME_IS_A10_GX_PAC_HSSI 1

// This may be passed as the "intended_device_family"
// parameter to simulated megafunctions.
`define PLATFORM_INTENDED_DEVICE_FAMILY "Arria10"

`define AFU_TOP_MODULE_NAME ccip_std_afu
`define PLATFORM_SHIM_MODULE_NAME platform_shim_ccip_std_afu

`define PLATFORM_FPGA_FAMILY_A10 1
`define PLATFORM_FPGA_FAMILY_A10_GX 1
`define PLATFORM_FPGA_PAC 1
`define PLATFORM_FPGA_PAC_RC 1


// These top-level port classes are provided
`define PLATFORM_PROVIDES_CLOCKS 1
`define PLATFORM_PROVIDES_CCI_P 1
`define PLATFORM_PROVIDES_POWER 1
`define PLATFORM_PROVIDES_ERROR 1


//
// These top-level ports are passed from the platform to the AFU
//

// clocks
`define AFU_TOP_REQUIRES_CLOCKS_PCLK3_USR2 1
`define PLATFORM_PARAM_CLOCKS_PCLK_FREQ 200

// cci-p
`define AFU_TOP_REQUIRES_CCI_P_STRUCT 1
`define PLATFORM_PARAM_CCI_P_ADD_TIMING_REG_STAGES 0
`define PLATFORM_PARAM_CCI_P_C0_SUPPORTED_REQS (C0_REQ_RDLINE_S | C0_REQ_RDLINE_I)
`define PLATFORM_PARAM_CCI_P_C1_SUPPORTED_REQS (C1_REQ_WRLINE_S | C1_REQ_WRLINE_I | C1_REQ_WRFENCE | C1_REQ_INTR)
`define PLATFORM_PARAM_CCI_P_CL_LEN_SUPPORTED { 1, 1, 0, 1 }
`define PLATFORM_PARAM_CCI_P_CLOCK default
`define PLATFORM_PARAM_CCI_P_CLOCK_IS_DEFAULT 1
`define PLATFORM_PARAM_CCI_P_MAX_BW_ACTIVE_LINES_C0 { 256, 256, 256, 256 }
`define PLATFORM_PARAM_CCI_P_MAX_BW_ACTIVE_LINES_C1 { 128, 128, 128, 128 }
`define PLATFORM_PARAM_CCI_P_MAX_OUTSTANDING_MMIO_RD_REQS 64
`define PLATFORM_PARAM_CCI_P_NUM_PHYS_CHANNELS 1
`define PLATFORM_PARAM_CCI_P_SUGGESTED_TIMING_REG_STAGES 1
`define PLATFORM_PARAM_CCI_P_VC_DEFAULT 2
`define PLATFORM_PARAM_CCI_P_VC_SUPPORTED { 1, 0, 1, 0 }

// power
`define AFU_TOP_REQUIRES_POWER_2BIT 1

// error
`define AFU_TOP_REQUIRES_ERROR_1BIT 1


`endif // __PLATFORM_AFU_TOP_CONFIG_VH__
