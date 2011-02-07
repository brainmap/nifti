module NIFTI
  # The NRead class parses the NIFTI data from a binary string.
  # 
  class NRead
    # An array which records any status messages that are generated while parsing the DICOM string.
    attr_reader :msg
    # A boolean which reports whether the NIFTI string was parsed successfully (true) or not (false).
    attr_reader :success
    # A hash containing header attributes.
    attr_reader :hdr
    # An array of nifti header extension hashes with keys esize, ecode and data.
    attr_reader :extended_header
    # An array of decoded image values
    attr_reader :image_rubyarray
    # A narray of image values reshapred to image dimensions
    attr_reader :image_narray
    
    # Valid Magic codes for the NIFTI Header
    MAGIC = %w{ni1 n+1}
    
    # Create a NRead object to parse a nifti file or binary string and set header and image info instance variables.
    #
    # The nifti header will be checked for validity (header size and magic number) and will raise an IOError if invalid.
    # 
    # NIFTI header extensions are not yet supported and are not included in the header.
    #
    # The header and image are accessible via the hdr and image instance variables.  An optional narray matrix may also be available in image_narray if desired by passing in :narray => true as an option.
    #
    # === Parameters
    #
    # * <tt>source</tt> -- A string which specifies either the path of a NIFTI file to be loaded, or a binary NIFTI string to be parsed.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:bin</tt> -- Boolean. If set to true, string parameter will be interpreted as a binary NIFTI string, and not a path string, which is the default behaviour.
    # * <tt>:image</tt> -- Boolean. If set to true, automatically load the image into @image, otherwise only a header is collected and you can get an image
    # * <tt>:narray</tt> -- Boolean.  If set to true, a properly shaped narray matrix will be set in the instance variable @image_narray.  Automatically sets :image => true
    #
    def initialize(source=nil, options={})
      options[:image] = true if options[:narray]
      @msg = []
      @success = false
      set_stream(source, options)
      parse_header(options)
      
      return self
    end
    
    # Unpack an image array from vox_offset to the end of a nifti file.
    # 
    # === Parameters
    #
    # There are no parameters - this reads from the binary string in the @string instance variable.
    # 
    # This sets @image_rubyarray to the image data vector and also returns it.
    # 
    def read_image
      raw_image = []
      @stream.index = @hdr['vox_offset']
      type = NIFTI_DATATYPES[@hdr['datatype']]
      format = @stream.format[type]
      @image_rubyarray = @stream.decode(@stream.rest_length, type)
    end
    
    # Create an narray if the NArray is available 
    # Tests if a file is readable, and if so, opens it.
    #
    # === Parameters
    #
    # * <tt>image_array</tt> -- Array. A vector of image data.
    # * <tt>dim</tt> -- Array. The dim array from the nifti header, specifing number of dimensions (dim[0]) and dimension length of other dimensions to reshape narray into.
    # 
    def get_image_narray(image_array, dim)
      if defined? NArray
        @image_narray = pixel_data = NArray.to_na(image_array).reshape!(*dim[1..dim[0]])
      else
        add_msg "Can't find NArray, no image_narray created.  Please `gem install narray`"
      end
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
    
    # Parse the NIFTI Header.
    def parse_header(options = {})
      check_header
      @hdr = parse_basic_header
      @extended_header = parse_extended_header
      
      # Optional image gathering
      read_image if options[:image] 
      get_image_narray(@image_rubyarray, @hdr['dim']) if options[:narray]
      
      @success = true
    end
    
    # NIFTI uses the header length (first 4 bytes) to be 348 number of "ni1\0"
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
      # The HEADER_SIGNATURE is defined in NIFTI::Constants and used for both reading and writing.
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
    # The file stream will be left at imaging data itself, taking vox_offset into account for NIFTI Header Extended Attributes.
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
    
    # Add a message (TODO: and maybe print to screen if verbose)
    def add_msg(msg)
      @msg << msg
    end
    
  end
end
