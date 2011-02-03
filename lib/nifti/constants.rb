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

# Q/S Form Transform codes defined in the nifti header
# Reference: http://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/qsform.html
XFORM_CODES = {
  0 => 'NIFTI_XFORM_UNKNOWN',       # Arbitrary coordinates (Method 1). 
  1 => 'NIFTI_XFORM_SCANNER_ANAT',  # Scanner-based anatomical coordinates
  2 => 'NIFTI_XFORM_ALIGNED_ANAT',  # Coordinates aligned to another file's, or to anatomical "truth".
  3 => 'NIFTI_XFORM_TALAIRACH',     # Coordinates aligned to Talairach-Tournoux Atlas; (0,0,0)=AC, etc.
  4 => 'NIFTI_XFORM_MNI_152'        # MNI 152 normalized coordinates
}