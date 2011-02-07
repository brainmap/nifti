module Nifti
  # The NObject class is the main class for interacting with the Nifti object.
  # Reading from and writing to files is executed from instances of this class.
  # 
  class NObject
    # An array which contain any notices/warnings/errors that have been recorded for the NObject instance.
    attr_reader :errors
    # A boolean which is set as true if a Nifti file has been successfully read & parsed from a file (or binary string).
    attr_reader :read_success
    # The Stream instance associated with this DObject instance (this attribute is mostly used internally).
    attr_reader :stream
    # A boolean which is set as true if a DObject instance has been successfully written to file (or successfully encoded).
    attr_reader :write_success
    # A hash of header information
    attr_accessor :header
    # A hash of extended attributes
    attr_accessor :extended_header
    # An array or narray of image values
    attr_accessor :image

    # Creates an NObject instance (NObject is an abbreviation for "Nifti object").
    #
    # The NObject instance holds references to the Nifti Header and Image
    # A NObject is typically built by reading and parsing a file or a
    # binary string, but can also be built from an empty state by the user.
    #
    # === Parameters
    #
    # * <tt>string</tt> -- A string which specifies either the path of a DICOM file to be loaded, or a binary DICOM string to be parsed. The parameter defaults to nil, in which case an empty DObject instance is created.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:bin</tt> -- Boolean. If set to true, string parameter will be interpreted as a binary DICOM string, and not a path string, which is the default behaviour.
    # * <tt>:syntax</tt> -- String. If a syntax string is specified, the DRead class will be forced to use this transfer syntax when decoding the file/binary string.
    # * <tt>:verbose</tt> -- Boolean. If set to false, the NObject instance will run silently and not output warnings and error messages to the screen. Defaults to true.
    # * <tt>:image</tt> -- Boolean. If set to true, automatically load the image into @image, otherwise only a header is collected and you can get an image from #get_image
    # * <tt>:narray</tt> -- Boolean. If set to true, the NObject will build a properly shaped narray from the image data.
    #
    # === Examples
    #
    #   # Load a Nifti file's header information:
    #   require 'nifti'
    #   obj = Nifti::NObject.new("test.nii")
    #   # Read a Nifti header and image into a numerical-ruby narray:
    #   obj = Nfiti::NObject.new("test.nii", :image => true, :narray => true)
    #   # Create an empty NIfTI object & choose non-verbose behaviour:
    #   obj = Nifti::NObject.new(nil, :verbose => false)
    #
    def initialize(string=nil, options={})
      # Process option values, setting defaults for the ones that are not specified:
      # Default verbosity is true if verbosity hasn't been specified (nil):
      @verbose = (options[:verbose] == false ? false : true)
      # Messages (errors, warnings or notices) will be accumulated in an array:
      @errors = Array.new
      # Structural information (default values):
      @file_endian = false
      # Control variables:
      @read_success = nil

      # Call the read method if a string has been supplied:
      if string.is_a?(String)
        @file = string unless options[:bin]
        read(string, options)
      elsif not string == nil
        raise ArgumentError, "Invalid argument. Expected String (or nil), got #{string.class}."
      end
      
    end
    
    # Reopen the Nifti File and retrieve image data
    def get_image
      r = NRead.new(@string, :image => true)
      if r.success
        @image = r.image_rubyarray
      end
    end
    
    # Passes the NObject to the DWrite class, which writes out the header and image to the specified file.
    #
    # === Parameters
    #
    # * <tt>file_name</tt> -- A string which identifies the path & name of the NIfTI file which is to be written to disk.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # === Examples
    #
    #   obj.write(path + "test.dcm")
    #
    def write(file_name, options={})
      if file_name.is_a?(String)
        w = NWrite.new(self, file_name, options)
        w.write
        # Write process succesful?
        @write_success = w.success
        # If any messages has been recorded, send these to the message handling method:
        add_msg(w.msg) if w.msg.length > 0
      else
        raise ArgumentError, "Invalid file_name. Expected String, got #{file_name.class}."
      end
    end
    
    # Following methods are private:
    private 
    
    # Returns a Nifti object by reading and parsing the specified file.
    # This is accomplished by initializing the NRead class, which loads Nifti information.
    #
    # === Notes
    #
    # This method is called automatically when initializing the NObject class with a file parameter,
    # and in practice should not be called by users.
    # 
    def read(string, options={})
      if string.is_a?(String)
        @string = string
        r = NRead.new(string, options)
        # Store the data to the instance variables if the readout was a success:
        if r.success
          @read_success = true
          # Update instance variables based on the properties of the NRead object:
          @header = r.hdr
          @extended_header = r.extended_header
          if r.image_narray
            @image = r.image_narray 
          elsif r.image_rubyarray
            @image = r.image_rubyarray
          end
        else
          @read_success = false
        end
        # If any messages have been recorded, send these to the message handling method:
        add_msg(r.msg) if r.msg.length > 0
      else
        raise ArgumentError, "Invalid argument. Expected String, got #{string.class}."
      end
    end

    # Adds one or more status messages to the instance array holding messages, and if the verbose instance variable
    # is true, the status message(s) are printed to the screen as well.
    #
    # === Parameters
    #
    # * <tt>msg</tt> -- Status message string, or an array containing one or more status message strings.
    #
    def add_msg(msg)
      puts msg if @verbose
      @errors << msg
      @errors.flatten
    end
    
  end
end
