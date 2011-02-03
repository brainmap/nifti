module Nifti

  # The NRead class parses the NIFTI data from a binary string.
  class NRead
    # An array which records any status messages that are generated while parsing the DICOM string.
    attr_reader :msg
    # A boolean which reports whether the Nifti string was parsed successfully (true) or not (false).
    attr_reader :success
    # A hash containing header attributes.
    attr_reader :hdr
    # An array of nifti header extension hashes with keys esize, ecode and data.
    attr_reader :extended_header
    # An array of decoded image values
    attr_reader :image_rubyarray
    # A narray of image values reshapred to image dimensions
    attr_reader :image_narray
    
    # Valid Magic codes for the Nifti Header
    MAGIC = %w{ni1 n+1}
    
    # Create a NRead object to parse a nifti file or binary string and set header and image info instance variables.
    #
    # The nifti header will be checked for validity (header size and magic number) and will raise an IOError if invalid.
    # 
    # Nifti header extensions are not yet supported and are not included in the header.
    #
    # The header and image are accessible via the hdr and image instance variables.  An optional narray matrix may also be available in image_narray if desired by passing in :narray => true as an option.
    #
    # === Parameters
    #
    # * <tt>source</tt> -- A string which specifies either the path of a Nifti file to be loaded, or a binary Nifti string to be parsed.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:bin</tt> -- Boolean. If set to true, string parameter will be interpreted as a binary DICOM string, and not a path string, which is the default behaviour.
    # * <tt>:narray</tt> -- Boolean.  If set to true, a properly shaped narray matrix will be set in the instance variable @image_narray
    #
    def initialize(source=nil, options={})
      @msg = [], @success = false
      set_stream(source, options)
      parse_header(options)
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
    def parse_header(options = {})
      check_header
      @hdr = parse_basic_header
      @extended_header = parse_extended_header
      read_image
      if options[:narray]
        get_image_narray(@image_rubyarray, @hdr['dim'])
      end
      
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
    # The file stream will be left open and should be positioned at the end of the 348 byte header. 
    def parse_basic_header
      # The HEADER_SIGNATURE is defined in Nifti::Constants and used for both reading and writing.
      header = {}
      HEADER_SIGNATURE.each do |header_item| 
        name, length, type = *header_item
        header[name] = @stream.decode(length, type)
      end
      
      # Extract Freq, Phase & Slice Dimensions from diminfo
      if header['dim_info']
        header['freq_dim'] = dim_info_to_freq_dim(header['dim_info'])
        header['phase_dim'] = dim_info_to_phase_dim(header['dim_info'])
        header['slice_dim'] = dim_info_to_slice_dim(header['dim_info'])
      end
      header['sform_code_descr'] = XFORM_CODES[header['sform_code']]
      header['qform_code_descr'] = XFORM_CODES[header['qform_code']]
            
      return header
    end

    # Read any extended header information.
    # The file stream will be left at imaging data itself, taking vox_offset into account for Nifti Header Extended Attributes.
    # Pass in the voxel offset so the extended header knows when to stop reading.

    def parse_extended_header
      extended = []
      extension = @stream.decode(4, "BY")

      # "After the end of the 348 byte header (e.g., after the magic field),
      # the next 4 bytes are an byte array field named extension. By default,
      # all 4 bytes of this array should be set to zero. In a .nii file, these 4
      # bytes will always be present, since the earliest start point for the
      # image data is byte #352. In a separate .hdr file, these bytes may or may
      # not be present (i.e., a .hdr file may only be 348 bytes long). If not
      # present, then a NIfTI-1.1 compliant program should use the default value
      # of extension={0,0,0,0}. The first byte (extension[0]) is the only value
      # of this array that is specified at present. The other 3 bytes are
      # reserved for future use."
      if extension[0] != 0
        while @stream.index < @hdr['vox_offset']
          esize, ecode = *@stream.decode(8, "UL")
          data = @stream.decode(esize - 8, "STR")
          extended << {:esize => esize, :ecode => ecode, :data => data}
        end
        # stream.decode(header['vox_offset'] - stream.index, "STR")
        # stream.skip header['vox_offset'] - stream.index
      end
      return extended
    end
    
    # Read an image array from the end of the nifti file.  Jumps straight to vox_offset irregardless of whether it's there or not.
    def read_image
      set_datatype
      raw_image = []
      @stream.index = @hdr['vox_offset']
      type = @datatypes[@hdr['datatype']]
      format = @stream.format[type]
      @image_rubyarray = @stream.decode(@stream.rest_length, type)
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
      if defined? NArray
        @image_narray = pixel_data = NArray.to_na(image_array).reshape!(*dim[1..dim[0]])
      else
        add_msg "Can't find NArray, no image_narray created.  Please `gem install narray`"
      end
    end
    
    # Bitwise Operator to extract Frequency Dimension
    def dim_info_to_freq_dim(dim_info)
      extract_dim_info(dim_info, 0)
    end
    
    # Bitwise Operator to extract Phase Dimension 
    def dim_info_to_phase_dim(dim_info)
      extract_dim_info(dim_info, 2)
    end
    
    # Bitwise Operator to extract Slice Dimension
    def dim_info_to_slice_dim(dim_info)
      extract_dim_info(dim_info, 4)
    end
    
    # Bitwise Operator to extract Frequency, Phase & Slice Dimensions from 2byte diminfo
    def extract_dim_info(dim_info, offset = 0)
      (dim_info >> offset) & 0x03
    end
    
    # Bitwise Operator to encode Freq, Phase & Slice into Diminfo
    def fps_into_dim_info(frequency_dim, phase_dim, slice_dim)
      ((frequency_dim & 0x03 ) << 0 ) | 
      ((phase_dim & 0x03) << 2 ) | 
      ((slice_dim & 0x03) << 4 )
    end
    
    def add_msg(msg)
      @msg << msg
      puts msg
    end
    
  end
end
