module Nifti

  # The NRead class parses the NIFTI data from a binary string.
  class NRead
    # An array which records any status messages that are generated while parsing the DICOM string.
    attr_reader :msg
    # A boolean which reports whether the Nifti string was parsed successfully (true) or not (false).
    attr_reader :success
    # A hash containing header attributes.
    attr_reader :hdr
    # An array of decoded image values
    attr_reader :image
    attr_reader :image_narray
    
    # Valid Magic codes for the Nifti Header
    MAGIC = %w{ni1 n+1}
    
    # Create a NRead object to parse a nifti file or binary string and set
    # header and image info instance variables.
    def initialize(source=nil, options={})
      set_stream(source, options)
      parse_header
    end
        
    private
    
    # Initializes @stream from a binary string or filename
    def set_stream(source, options)
      # Are we going to read from a file, or read from a binary string?
      if options[:bin]
        # Read from the provided binary string:
        @str = source
      else
        # Read from file:
        open_file(source)
        # Read the initial header of the file:
        if @file == nil
          # File is not readable, so we return:
          @success = false
          return
        else
          # Extract the content of the file to a binary string:
          @str = @file.read
          @file.close
        end
      end
      
      # Create a Stream instance to handle the decoding of content from this binary string:
      @file_endian = false
      @stream = Stream.new(@str, false)
    end
    
    # Parse the Nifti Header.
    def parse_header
      check_header
      @hdr = parse_basic_header(@stream)
      @hdr.merge parse_extended_header(@stream)
      read_image(@stream)
      get_image_narray(@image, @hdr['dim'])
      
      @success = true
    end
    
    # Nifti uses the header length (first 4 bytes) to be 348 number of "ni1\0"
    # or "n+1\0" as the last 4 bytes to be magic numbers to validate the header.
    # 
    # The header is usually checked before any data is read, but can be
    # checked at any point in the process as the stream index is reset to its
    # original position after validation.
    # 
    # There are no options - the method will raise an IOError if any of the 
    # magic numbers are not valid.
    def check_header
      begin
        starting_index = @stream.index
        
        # Check sizeof_hdr
        @stream.index = 0; 
        sizeof_hdr = @stream.decode(4, "UL")
        raise IOError, "Bad Header Length #{sizeof_hdr}" unless sizeof_hdr == 348
            
        # Check magic
        @stream.index = 344; 
        magic = @stream.decode(4, "STR")
        raise IOError, "Bad Magic Code #{magic} (should be ni1 or n+1)" unless MAGIC.include?(magic)
        
      rescue IOError => e
        raise IOError, "Header appears to be malformed: #{e}"
      else
        @stream.index = starting_index
      end        
    end

    # Read the nifti header according to its byte signature.
    # The file stream will be left open and should be left positioned at the imaging
    # data itself, taking vox_offset into account for Nifti Header Extended Attributes.
    def parse_basic_header(stream)
      header = {}
      
      #                           /**********************/    /**********************/     /***************/
      # struct nifti_1_header {  /* NIFTI-1 usage      */    /*ANALYZE 7.5 field(s)*/     /* Byte offset */
      #                         /**********************/    /**********************/     /***************/
      # 
      # 
      # 
      # 
      #  int   sizeof_hdr;    /*!< MUST be 348           */  /* int sizeof_hdr;      */   /*   0 */
      header['sizeof_hdr'] = stream.decode(4, "UL")

      #  char  data_type[10]; /*!< ++UNUSED++            */  /* char data_type[10];  */   /*   4 */
      header['data_type']   = stream.decode(10, "STR")

      #  char  db_name[18];   /*!< ++UNUSED++            */  /* char db_name[18];    */   /*  14 */
      header['db_name']     = stream.decode(18, "STR")
       
      #  int   extents;       /*!< ++UNUSED++            */  /* int extents;         */   /*  32 */
      header['extents']     = stream.decode(4, "UL")
      
      #  short session_error; /*!< ++UNUSED++            */  /* short session_error; */   /*  36 */
      header['session_error'] = stream.decode(2, "US")
      
      #  char  regular;       /*!< ++UNUSED++            */  /* char regular;        */   /*  38 */
      header['regular']     = stream.decode(1, "STR")
      
      #  char  dim_info;      /*!< MRI slice ordering.   */  /* char hkey_un0;       */   /*  39 */
      header['dim_info']    = stream.decode(1, "BY")
      
      
      #                                       /*--- was image_dimension substruct ---*/
      #  short dim[8];        /*!< Data array dimensions.*/  /* short dim[8];        */   /*  40 */
      header['dim']         = stream.decode(16, "US")
      
      #  float intent_p1;     /*!< 1st intent parameter. */  /* short unused8;       */   /*  56 */
      header['intent_p1']   = stream.decode(4, "FL")
      #                                                      /* short unused9;       */
      #  float intent_p2;     /*!< 2nd intent parameter. */  /* short unused10;      */   /*  60 */
      header['intent_p2']   = stream.decode(4, "FL")
      #                                                      /* short unused11;      */
      #  float intent_p3;     /*!< 3rd intent parameter. */  /* short unused12;      */   /*  64 */
      header['intent_p3']   = stream.decode(4, "FL")

      #  short intent_code;   /*!< NIFTIINTENT code.     */  /* short unused14;      */   /*  68 */
      header['intent_code']   = stream.decode(2, "US")

      #  short datatype;      /*!< Defines data type!    */  /* short datatype;      */   /*  70 */
      header['datatype']   = stream.decode(2, "US")
      
      #  short bitpix;        /*!< Number bits/voxel.    */  /* short bitpix;        */   /*  72 */
      header['bitpix']     = stream.decode(2, "US")
      
      #  short slice_start;   /*!< First slice index.    */  /* short dim_un0;       */   /*  74 */
      header['slice_start']   = stream.decode(2, "US")
      
      #  float pixdim[8];     /*!< Grid spacings.        */  /* float pixdim[8];     */   /*  76 */
      header['pixdim']   = stream.decode(32, "FL")
      
      #  float vox_offset;    /*!< Offset into .nii file */  /* float vox_offset;    */   /* 108 */
      header['vox_offset']   = stream.decode(4, "FL")
      
      #  float scl_slope;     /*!< Data scaling: slope.  */  /* float funused1;      */   /* 112 */
      header['scl_slope']   = stream.decode(4, "FL")
      
      #  float scl_inter;     /*!< Data scaling: offset. */  /* float funused2;      */   /* 116 */
      header['scl_inter']   = stream.decode(4, "FL")
      
      #  short slice_end;     /*!< Last slice index.     */  /* float funused3;      */   /* 120 */
      header['slice_end']   = stream.decode(2, "US")
      
      #  char  slice_code;    /*!< Slice timing order.   */                               /* 122 */
      header['slice_code']   = stream.decode(1, "BY")
      
      #  char  xyzt_units;    /*!< Units of pixdim[1..4] */                               /* 123 */
      header['xyzt_units']   = stream.decode(1, "BY")

      #  float cal_max;       /*!< Max display intensity */  /* float cal_max;       */   /* 124 */
      header['cal_max']   = stream.decode(4, "FL")
      
      #  float cal_min;       /*!< Min display intensity */  /* float cal_min;       */   /* 128 */
      header['cal_min']   = stream.decode(4, "FL")
      
      #  float slice_duration;/*!< Time for 1 slice.     */  /* float compressed;    */   /* 132 */
      header['slice_duration']   = stream.decode(4, "FL")
      
      #  float toffset;       /*!< Time axis shift.      */  /* float verified;      */   /* 136 */
      header['toffset']   = stream.decode(4, "FL")

      #  int   glmax;         /*!< ++UNUSED++            */  /* int glmax;           */   /* 140 */
      header['glmax']   = stream.decode(4, "UL")
      
      #  int   glmin;         /*!< ++UNUSED++            */  /* int glmin;           */   /* 144 */
      header['glmin']   = stream.decode(4, "UL")

      #                                          /*--- was data_history substruct ---*/
      #  char  descrip[80];   /*!< any text you like.    */  /* char descrip[80];    */   /* 148 */
      header['descrip']   = stream.decode(80, "STR")
      
      #  char  aux_file[24];  /*!< auxiliary filename.   */  /* char aux_file[24];   */   /* 228 */
      header['aux_file']   = stream.decode(24, "STR")

      # 
      #  short qform_code;    /*!< NIFTIXFORM code.      */  /*-- all ANALYZE 7.5 ---*/   /* 252 */
      header['qform_code']   = stream.decode(2, "US")   #    /*   fields below here  */
                                                        #    /*   are replaced       */
      #  short sform_code;    /*!< NIFTIXFORM code.      */                               /* 254 */
      header['sform_code']  = stream.decode(2, "US")
      #                                                      
      #  float quatern_b;     /*!< Quaternion b param.    */                              /* 256 */
      header['quatern_b']   = stream.decode(4, "FL")

      #  float quatern_c;     /*!< Quaternion c param.    */                              /* 260 */
      header['quatern_c']   = stream.decode(4, "FL")

      #  float quatern_d;     /*!< Quaternion d param.    */                              /* 264 */
      header['quatern_d']   = stream.decode(4, "FL")


      #  float qoffset_x;     /*!< Quaternion x shift.    */                              /* 268 */
      header['qoffset_x']   = stream.decode(4, "FL")

      #  float qoffset_y;     /*!< Quaternion y shift.    */                              /* 272 */
      header['qoffset_y']   = stream.decode(4, "FL")
      
      #  float qoffset_z;     /*!< Quaternion z shift.    */                              /* 276 */
      header['qoffset_z']   = stream.decode(4, "FL")

      #  float srow_x[4];     /*!< 1st row affine transform.   */                         /* 280 */
      header['srow_x']      = stream.decode(16, "FL")
      
      #  float srow_y[4];     /*!< 2nd row affine transform.   */                         /* 296 */
      header['srow_y']      = stream.decode(16, "FL")

      #  float srow_z[4];     /*!< 3rd row affine transform.   */                         /* 312 */
      header['srow_z']      = stream.decode(16, "FL")

      # 
      # 
      #  char intent_name[16];/*!< name or meaning of data.  */                         /* 328 */
      header['intent_name'] = stream.decode(16, "STR")

      # 
      # 
      #  char magic[4];       /*!< MUST be "ni1\0" or "n+1\0". */                         /* 344 */
      header['magic'] = stream.decode(4, "STR")

      # } ;                   /** 348 bytes total **/
      # 
      # 
      
      return header
    end

    # TODO : Work up Extensions    
    def parse_extended_header(stream)
      header = {}
      # header['extension'] = stream.decode(4, "BY")
      # header['extension1']  = stream.decode(8, "UL")
      # header['extension1_data'] = stream.decode(header['extension1'].first - 8, "STR")      
      # stream.decode(header['vox_offset'] - stream.index, "STR")
      # stream.skip header['vox_offset'] - stream.index
    end
    
    def read_image(stream)
      set_datatype
      raw_image = []
      stream.index = @hdr['vox_offset']
      type = @datatypes[@hdr['datatype']]
      format = stream.format[type]
      @image = stream.decode(stream.rest_length, type)
      raw_image.class
      raw_image.length
    end
    
    # Take a Nifti TypeCode and return datatype and bitpix
    def set_datatype
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
      @datatypes = {
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
    end
    
    
    # Tests if a file is readable, and if so, opens it.
    #
    # === Parameters
    #
    # * <tt>file</tt> -- A path/file string.
    #
    def open_file(file)
      if File.exist?(file)
        if File.readable?(file)
          if not File.directory?(file)
            if File.size(file) > 8
              @file = File.new(file, "rb")
            else
              @msg << "Error! File is too small to contain DICOM information (#{file})."
            end
          else
            @msg << "Error! File is a directory (#{file})."
          end
        else
          @msg << "Error! File exists but I don't have permission to read it (#{file})."
        end
      else
        @msg << "Error! The file you have supplied does not exist (#{file})."
      end
    end
    
    def get_image_narray(image_array, dim)
      rows, columns, slices = dim[1..3]
      @image_narray = pixel_data = NArray.to_na(image_array).reshape!(slices, columns, rows)
    end
    
  end
end
