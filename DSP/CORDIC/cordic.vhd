library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity cordic is
  generic (
    G_ITERATIONS : integer := 16 -- also equates to output precision
  );
  port (
    clk          : in  std_logic;
    valid_in     : in  std_logic;
    x_start      : in  signed(G_ITERATIONS - 1 downto 0);
    y_start      : in  signed(G_ITERATIONS - 1 downto 0);
    angle        : in  signed(31 downto 0);
    valid_out    : out std_logic;
    sine         : out signed(G_ITERATIONS - 1 downto 0);
    cosine       : out signed(G_ITERATIONS - 1 downto 0)
  );
end entity cordic;

architecture rtl of cordic is

  type T_sign_iter is array (integer range<>) of signed(G_ITERATIONS downto 0);
  type T_sign_31   is array (integer range<>) of signed(31 downto 0);

  function F_init_atan_LUT return T_sign_31 is
    variable V_return : T_sign_31(30 downto 0);
  begin
    V_return( 0) := "00100000000000000000000000000000"; -- 45.000 degrees -> atan(2^0)
    V_return( 1) := "00010010111001000000010100011101"; -- 26.565 degrees -> atan(2^-1)
    V_return( 2) := "00001001111110110011100001011011"; -- 14.036 degrees -> atan(2^-2)
    V_return( 3) := "00000101000100010001000111010100"; -- atan(2^-3)
    V_return( 4) := "00000010100010110000110101000011";
    V_return( 5) := "00000001010001011101011111100001";
    V_return( 6) := "00000000101000101111011000011110";
    V_return( 7) := "00000000010100010111110001010101";
    V_return( 8) := "00000000001010001011111001010011";
    V_return( 9) := "00000000000101000101111100101110";
    V_return(10) := "00000000000010100010111110011000";
    V_return(11) := "00000000000001010001011111001100";
    V_return(12) := "00000000000000101000101111100110";
    V_return(13) := "00000000000000010100010111110011";
    V_return(14) := "00000000000000001010001011111001";
    V_return(15) := "00000000000000000101000101111100";
    V_return(16) := "00000000000000000010100010111110";
    V_return(17) := "00000000000000000001010001011111";
    V_return(18) := "00000000000000000000101000101111";
    V_return(19) := "00000000000000000000010100010111";
    V_return(20) := "00000000000000000000001010001011";
    V_return(21) := "00000000000000000000000101000101";
    V_return(22) := "00000000000000000000000010100010";
    V_return(23) := "00000000000000000000000001010001";
    V_return(24) := "00000000000000000000000000101000";
    V_return(25) := "00000000000000000000000000010100";
    V_return(26) := "00000000000000000000000000001010";
    V_return(27) := "00000000000000000000000000000101";
    V_return(28) := "00000000000000000000000000000010";
    V_return(29) := "00000000000000000000000000000001";
    V_return(30) := "00000000000000000000000000000000";
    return V_return;
  end F_init_atan_LUT;

  signal atan_LUT : T_sign_31(30 downto 0) := F_init_atan_LUT;
  signal x, y     : T_sign_iter(G_ITERATIONS - 1 downto 0) := (others => (others => '0'));
  signal z        : T_sign_31(G_ITERATIONS - 1 downto 0)   := (others => (others => '0'));

  signal sig_valid_sr : std_logic_vector(G_ITERATIONS - 1 downto 0) := (others => '0');

begin

  valid_out <= sig_valid_sr(sig_valid_sr'high);
  cosine    <= resize( x(G_ITERATIONS - 1), sine'length );
  sine      <= resize( y(G_ITERATIONS - 1), cosine'length );

  S_shift_reg_valid: process(clk)
  begin
    if rising_edge(clk) then
      -- shift register to delay data valid to match pipeline delay
      sig_valid_sr <= sig_valid_sr(G_ITERATIONS - 2 downto 0) & valid_in;
    end if;
  end process S_shift_reg_valid;

  S_quad: process(clk)
  begin
    if rising_edge(clk) then
      case angle(31 downto 30) is -- account for angles in different quads
        when "00" | "11" => -- no changes needed for these quadrants
          x(0) <= resize( x_start, G_ITERATIONS + 1 );
          y(0) <= resize( y_start, G_ITERATIONS + 1 );
          z(0) <= angle;
        when "01" =>
          x(0) <= -resize( y_start, G_ITERATIONS + 1 );
          y(0) <=  resize( x_start, G_ITERATIONS + 1 );
          z(0) <= "00" & angle(29 downto 0); -- subtract pi/2 for angle in this quad
        when "10" =>
          x(0) <=  resize( y_start, G_ITERATIONS + 1 );
          y(0) <= -resize( x_start, G_ITERATIONS + 1 );
          z(0) <= "11" & angle(29 downto 0); -- add pi/2 for angle in this quad
        when others =>
      end case;
    end if;
  end process S_quad;

  UG_intermediate: for i in 0 to G_ITERATIONS - 2 generate
    S_add_sub: process(clk) -- add/subtract shifted data
    begin
      if rising_edge(clk) then
        if z(i)(31) = '1' then
          x(i + 1) <= x(i) + shift_right( y(i), i );
          y(i + 1) <= y(i) - shift_right( x(i), i );
          z(i + 1) <= z(i) + atan_LUT(i);
        else
          x(i + 1) <= x(i) - shift_right( y(i), i );
          y(i + 1) <= y(i) + shift_right( x(i), i );
          z(i + 1) <= z(i) - atan_LUT(i);
        end if;
      end if;
    end process S_add_sub;
  end generate UG_intermediate;

end architecture rtl;
