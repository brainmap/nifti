module Nifti
  # Variables used to determine endianness.
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

    # Take a Nifti TypeCode and return datatype and bitpix
    # 
    # From Jimmy Shen: 
    # Set bitpix according to datatype
    # /*Acceptable values for datatype are*/ 
    # 
    #    0 None                     (Unknown bit per voxel) % DT_NONE, DT_UNKNOWN 
    #    1 Binary                         (ubit1, bitpix=1) % DT_BINARY 
    #    2 Unsigned char         (uchar or uint8, bitpix=8) % DT_UINT8, NIFTI_TYPE_UINT8 
    #    4 Signed short                  (int16, bitpix=16) % DT_INT16, NIFTI_TYPE_INT16 
    #    8 Signed integer                (int32, bitpix=32) % DT_INT32, NIFTI_TYPE_INT32 
    #   16 Floating point    (single or float32, bitpix=32) % DT_FLOAT32, NIFTI_TYPE_FLOAT32 
    #   32 Complex, 2 float32      (Use float32, bitpix=64) % DT_COMPLEX64, NIFTI_TYPE_COMPLEX64
    #   64 Double precision  (double or float64, bitpix=64) % DT_FLOAT64, NIFTI_TYPE_FLOAT64 
    #  128 uint8 RGB                 (Use uint8, bitpix=24) % DT_RGB24, NIFTI_TYPE_RGB24 
    #  256 Signed char            (schar or int8, bitpix=8) % DT_INT8, NIFTI_TYPE_INT8 
    #  511 Single RGB              (Use float32, bitpix=96) % DT_RGB96, NIFTI_TYPE_RGB96
    #  512 Unsigned short               (uint16, bitpix=16) % DT_UNINT16, NIFTI_TYPE_UNINT16 
    #  768 Unsigned integer             (uint32, bitpix=32) % DT_UNINT32, NIFTI_TYPE_UNINT32 
    # 1024 Signed long long              (int64, bitpix=64) % DT_INT64, NIFTI_TYPE_INT64
    # 1280 Unsigned long long           (uint64, bitpix=64) % DT_UINT64, NIFTI_TYPE_UINT64 
    # 1536 Long double, float128  (Unsupported, bitpix=128) % DT_FLOAT128, NIFTI_TYPE_FLOAT128 
    # 1792 Complex128, 2 float64  (Use float64, bitpix=128) % DT_COMPLEX128, NIFTI_TYPE_COMPLEX128 
    # 2048 Complex256, 2 float128 (Unsupported, bitpix=256) % DT_COMPLEX128, NIFTI_TYPE_COMPLEX128 
    NIFTI_DATATYPES = {
      0 => "Unknown",
      # 1 => "", Can't find a single bit encoding in ruby's unpack method?
      2 => "OB",
      4 => "SS",
      8 => "SL",
     16 => "FL",
     32 => "FD",
     64 => "FD",
    128 => "RGBUnknown",
    256 => "BY",
    511 => "RGBUnknown",
    512 => "US",
    768 => "UL"
   # 1024 => "",
   # 1280 => "",
   # 1536 => "",
   # 1792 => "",
   # 2048 => ""
  }

  # The Nifti signature is hardcoded by bytes. This consists of arrays for 
  # each item in the signature, where item[0] is the name of the item,
  # item[1] is the length in bytes of the item, and dim[2] is the Format
  # string to use in packing/unpacking the item.
  HEADER_SIGNATURE = [
    #                           /**********************/    /**********************/     /***************/
    # struct nifti_1_header {  /* NIFTI-1 usage      */    /*ANALYZE 7.5 field(s)*/     /* Byte offset */
    #                         /**********************/    /**********************/     /***************/
    #  int   sizeof_hdr;    /*!< MUST be 348           */  /* int sizeof_hdr;      */   /*   0 */
    ['sizeof_hdr', 4, 'SL'],
  
    #  char  data_type[10]; /*!< ++UNUSED++            */  /* char data_type[10];  */   /*   4 */
    ['data_type', 10, 'STR'],
  
    #  char  db_name[18];   /*!< ++UNUSED++            */  /* char db_name[18];    */   /*  14 */
    ['db_name', 18, 'STR'],
  
    #  int   extents;       /*!< ++UNUSED++            */  /* int extents;         */   /*  32 */
    ['extents', 4, "SL"],

    #  short session_error; /*!< ++UNUSED++            */  /* short session_error; */   /*  36 */
    ['session_error', 2, "SS"],

    #  char  regular;       /*!< ++UNUSED++            */  /* char regular;        */   /*  38 */
    ['regular', 1, "STR"],

    #  char  dim_info;      /*!< MRI slice ordering.   */  /* char hkey_un0;       */   /*  39 */
    ['dim_info', 1, "BY"],


    #                                       /*--- was image_dimension substruct ---*/
    #  short dim[8];        /*!< Data array dimensions.*/  /* short dim[8];        */   /*  40 */
    ['dim', 16, "US"],

    #  float intent_p1;     /*!< 1st intent parameter. */  /* short unused8;       */   /*  56 */
    ['intent_p1', 4, "FL"],

    #  float intent_p2;     /*!< 2nd intent parameter. */  /* short unused10;      */   /*  60 */
    ['intent_p2', 4, "FL"],
    #                                                      /* short unused11;      */
    #  float intent_p3;     /*!< 3rd intent parameter. */  /* short unused12;      */   /*  64 */
    ['intent_p3', 4, "FL"],

    #  short intent_code;   /*!< NIFTIINTENT code.     */  /* short unused14;      */   /*  68 */
    ['intent_code', 2, "US"],

    #  short datatype;      /*!< Defines data type!    */  /* short datatype;      */   /*  70 */
    ['datatype', 2, "US"],
  
    #  short bitpix;        /*!< Number bits/voxel.    */  /* short bitpix;        */   /*  72 */
    ['bitpix', 2, "US"],

    #  short slice_start;   /*!< First slice index.    */  /* short dim_un0;       */   /*  74 */
    ['slice_start', 2, "US"],

    #  float pixdim[8];     /*!< Grid spacings.        */  /* float pixdim[8];     */   /*  76 */
    ['pixdim', 32, "FL"],

    #  float vox_offset;    /*!< Offset into .nii file */  /* float vox_offset;    */   /* 108 */
    ['vox_offset', 4, "FL"],

    #  float scl_slope;     /*!< Data scaling: slope.  */  /* float funused1;      */   /* 112 */
    ['scl_slope', 4, "FL"],

    #  float scl_inter;     /*!< Data scaling: offset. */  /* float funused2;      */   /* 116 */
    ['scl_inter', 4, "FL"],

    #  short slice_end;     /*!< Last slice index.     */  /* float funused3;      */   /* 120 */
    ['slice_end', 2, "US"],

    #  char  slice_code;    /*!< Slice timing order.   */                               /* 122 */
    ['slice_code', 1, "BY"],

    #  char  xyzt_units;    /*!< Units of pixdim[1..4] */                               /* 123 */
    ['xyzt_units', 1, "BY"],

    #  float cal_max;       /*!< Max display intensity */  /* float cal_max;       */   /* 124 */
    ['cal_max', 4, "FL"],

    #  float cal_min;       /*!< Min display intensity */  /* float cal_min;       */   /* 128 */
    ['cal_min', 4, "FL"],

    #  float slice_duration;/*!< Time for 1 slice.     */  /* float compressed;    */   /* 132 */
    ['slice_duration', 4, "FL"],

    #  float toffset;       /*!< Time axis shift.      */  /* float verified;      */   /* 136 */
    ['toffset', 4, "FL"],

    #  int   glmax;         /*!< ++UNUSED++            */  /* int glmax;           */   /* 140 */
    ['glmax', 4, "UL"],

    #  int   glmin;         /*!< ++UNUSED++            */  /* int glmin;           */   /* 144 */
    ['glmin', 4, "UL"],

    #                                          /*--- was data_history substruct ---*/
    #  char  descrip[80];   /*!< any text you like.    */  /* char descrip[80];    */   /* 148 */
    ['descrip', 80, "STR"],

    #  char  aux_file[24];  /*!< auxiliary filename.   */  /* char aux_file[24];   */   /* 228 */
    ['aux_file', 24, "STR"],

    # 
    #  short qform_code;    /*!< NIFTIXFORM code.      */  /*-- all ANALYZE 7.5 ---*/   /* 252 */
    ['qform_code', 2, "US"],                           #   /*   fields below here  */
                                                      #    /*   are replaced       */
    #  short sform_code;    /*!< NIFTIXFORM code.      */                               /* 254 */
    ['sform_code', 2, "US"],
    #                                                      
    #  float quatern_b;     /*!< Quaternion b param.    */                              /* 256 */
    ['quatern_b', 4, "FL"],

    #  float quatern_c;     /*!< Quaternion c param.    */                              /* 260 */
    ['quatern_c', 4, "FL"],

    #  float quatern_d;     /*!< Quaternion d param.    */                              /* 264 */
    ['quatern_d', 4, "FL"],


    #  float qoffset_x;     /*!< Quaternion x shift.    */                              /* 268 */
    ['qoffset_x', 4, "FL"],

    #  float qoffset_y;     /*!< Quaternion y shift.    */                              /* 272 */
    ['qoffset_y', 4, "FL"],

    #  float qoffset_z;     /*!< Quaternion z shift.    */                              /* 276 */
    ['qoffset_z', 4, "FL"],

    #  float srow_x[4];     /*!< 1st row affine transform.   */                         /* 280 */
    ['srow_x', 16, "FL"],

    #  float srow_y[4];     /*!< 2nd row affine transform.   */                         /* 296 */
    ['srow_y', 16, "FL"],

    #  float srow_z[4];     /*!< 3rd row affine transform.   */                         /* 312 */
    ['srow_z', 16, "FL"],

    # 
    # 
    #  char intent_name[16];/*!< name or meaning of data.  */                         /* 328 */
    ['intent_name', 16, "STR"],

    # 
    # 
    #  char magic[4];       /*!< MUST be "ni1\0" or "n+1\0". */                         /* 344 */
    ['magic', 4, "STR"]

    # } ;                   /** 348 bytes total **/
    # 
    # 
  
  
  ]
end