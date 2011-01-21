# Varaibles used to determine endianness.
x = 0xdeadbeef
endian_type = {
  Array(x).pack("V*") => false, # Little
  Array(x).pack("N*") => true   # Big
}
# System (CPU) Endianness.
CPU_ENDIAN = endian_type[Array(x).pack("L*")]

# Custom string used for (un)packing big endian signed short.
CUSTOM_SS = "k*"
# Custom string used for (un)packing big endian signed long.
CUSTOM_SL = "r*"