require 'zlib'

module NIFTI

  # The NWrite class handles the encoding of an NObject instance to a valid NIFTI string.
  # The String is then written to file.
  #
  class NWrite

    # An array which records any status messages that are generated while encoding/writing the DICOM string.
    attr_reader :msg
    # A boolean which reports whether the DICOM string was encoded/written successfully (true) or not (false).
    attr_reader :success

    # Creates an NWrite instance.
    #
    # === Parameters
    #
    # * <tt>obj</tt> -- A NObject instance which will be used to encode a NIfTI string.
    # * <tt>file_name</tt> -- A string, either specifying the path of a DICOM file to be loaded, or a binary DICOM string to be parsed.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    def initialize(obj, file_name, options = {})
      @obj = obj
      @file_name = file_name
      # Array for storing error/warning messages:
      @msg = Array.new
    end

    # Handles the encoding of NIfTI information to string as well as writing it to file.
    def write
      # Check if we are able to create given file:
      open_file(@file_name)
      # Go ahead and write if the file was opened successfully:
      if @file
        # Initiate necessary variables:
        init_variables
        @file_endian = false
        # Create a Stream instance to handle the encoding of content to a binary string:
        @stream = Stream.new(nil, @file_endian)
        # Tell the Stream instance which file to write to:
        @stream.set_file(@file)

        # Write Header and Image
        write_basic_header
        write_extended_header
        write_image

        # As file has been written successfully, it can be closed.
        @file.close
        # Mark this write session as successful:
        @success = true
      end

    end

    # Write Basic Header
    def write_basic_header
      HEADER_SIGNATURE.each do |header_item|
        begin
          name, length, type = *header_item
          str = @stream.encode(@obj.header[name], type)
          padded_str = @stream.encode_string_to_length(str, length)
          # puts @stream.index, name, str.unpack(@stream.vr_to_str(type))
          # pp padded_str.unpack(@stream.vr_to_str(type))

          @stream.write padded_str
          @stream.skip length
        rescue StandardError => e
          puts name, length, type, e
          raise e
        end
      end
    end

    # Write Extended Header
    def write_extended_header
      unless @obj.extended_header.empty?
        @stream.write @stream.encode([1,0,0,0], "BY")
        @obj.extended_header.each do |extension|
        @stream.write @stream.encode extension[:esize], "UL"
        @stream.write @stream.encode extension[:ecode], "UL"
        @stream.write @stream.encode_string_to_length(@stream.encode(extension[:data], "STR"), extension[:esize] - 8)
        end
      else
        @stream.write @stream.encode([0,0,0,0], "BY")
      end
    end

    # Write Image
    def write_image
      type = NIFTI_DATATYPES[@obj.header['datatype']]
      @stream.write @stream.encode(@obj.image, type)
    end

    # Tests if the path/file is writable, creates any folders if necessary, and opens the file for writing.
    #
    # === Parameters
    #
    # * <tt>file</tt> -- A path/file string.
    #
    def open_file(file)
      # Check if file already exists:
      if File.exist?(file)
        # Is it writable?
        if File.writable?(file)
          @file = get_new_file_writer(file)
        else
          # Existing file is not writable:
          @msg << "Error! The program does not have permission or resources to create the file you specified: (#{file})"
        end
      else
        # File does not exist.
        # Check if this file's path contains a folder that does not exist, and therefore needs to be created:
        folders = file.split(File::SEPARATOR)
        if folders.length > 1
          # Remove last element (which should be the file string):
          folders.pop
          path = folders.join(File::SEPARATOR)
          # Check if this path exists:
          unless File.directory?(path)
            # We need to create (parts of) this path:
            require 'fileutils'
            FileUtils.mkdir_p path
          end
        end
        # The path to this non-existing file is verified, and we can proceed to create the file:
        @file = get_new_file_writer(file)
      end
    end

    # Creates various variables used when encoding the DICOM string.
    #
    def init_variables
      # Until a DICOM write has completed successfully the status is 'unsuccessful':
      @success = false
    end

    private

    # Opens the file according to it's extension (gziped or uncompressed)
    #
    # === Parameters
    #
    # * <tt>file</tt> -- A path/file string.
    #
    def get_new_file_writer(file)
      if File.extname(file) == '.gz'
        Zlib::GzipWriter.new(File.new(file, 'wb'))
      else
        File.new(file, 'wb')
      end
    end
  end
end