library verilog;
use verilog.vl_types.all;
entity Digtal_Main is
    generic(
        Mode            : integer := 0;
        Length_InsertOrFrameheader: integer := 4;
        Byte1_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi1, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1);
        Byte2_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        Byte3_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        Byte4_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi1, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1);
        Byte5_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi1, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1);
        Byte6_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        Byte7_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        Byte8_InsertOrFrameheader: vl_logic_vector(0 to 7) := (Hi1, Hi1, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1)
    );
    port(
        CLOCK_Digtal    : in     vl_logic;
        CS              : in     vl_logic;
        Out_Data        : out    vl_logic_vector(7 downto 0);
        RD              : in     vl_logic;
        Rx_Data         : in     vl_logic_vector(7 downto 0);
        RAM_Data_In     : out    vl_logic_vector(7 downto 0);
        RAM_RDADD       : out    vl_logic_vector(30 downto 0);
        RAM_WRADD       : out    vl_logic_vector(30 downto 0);
        RAM_RDEN        : out    vl_logic;
        RAM_WREN        : out    vl_logic;
        RAM_Q           : in     vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of Mode : constant is 1;
    attribute mti_svvh_generic_type of Length_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte1_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte2_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte3_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte4_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte5_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte6_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte7_InsertOrFrameheader : constant is 1;
    attribute mti_svvh_generic_type of Byte8_InsertOrFrameheader : constant is 1;
end Digtal_Main;
