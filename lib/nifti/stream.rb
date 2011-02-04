module Nifti
  # The Stream class handles string operations (encoding to and decoding from binary strings).
  #  
  class Stream
    # A boolean which reports the relationship between the endianness of the system and the instance string.
    attr_reader :equal_endian
    # Our current position in the instance string (used only for decoding).
    attr_accessor :index
    # The instance string.
    attr_accessor :string
    # The endianness of the instance string.
    attr_reader :str_endian
    # An array of warning/error messages that (may) have been accumulated.
    attr_reader :errors
    # A hash of proper strings (based on endianess) to use for unpacking binary strings.
    attr_reader :format
    # A File object to write to
    attr_accessor :file
    
    # Creates a Stream instance.
    #
    # === Parameters
    #
    # * <tt>binary</tt> -- A binary string.
    # * <tt>string_endian</tt> -- Boolean. The endianness of the instance string (true for big endian, false for small endian).
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:index</tt> -- Fixnum. A position (offset) in the instance string where reading will start.
    #
    def initialize(binary, string_endian, options={})
      @string = binary || ""
      @index = options[:index] || 0
      @errors = Array.new
      self.endian = string_endian
    end
    

    
    # Decodes a section of the instance string and returns the formatted data.
    # The instance index is offset in accordance with the length read.
    #
    # === Notes
    #
    # * If multiple numbers are decoded, these are returned in an array.
    #
    # === Parameters
    #
    # * <tt>length</tt> -- Fixnum. The string length which will be decoded.
    # * <tt>type</tt> -- String. The type (vr) of data to decode.
    #
    def decode(length, type)
      # Check if values are valid:
      if (@index + length) > @string.length
        # The index number is bigger then the length of the binary string.
        # We have reached the end and will return nil.
        value = nil
      else
        if type == "AT"
          value = decode_tag
        else
          # Decode the binary string and return value:
          value = @string.slice(@index, length).unpack(vr_to_str(type))
          # If the result is an array of one element, return the element instead of the array.
          # If result is contained in a multi-element array, the original array is returned.
          if value.length == 1
            value = value[0]
            # If value is a string, strip away possible trailing whitespace:
            value = value.rstrip if value.is_a?(String)
          end
          # Update our position in the string:
          skip(length)
        end
      end
      return value
    end    
    
    # Returns the length of the binary instance string.
    #
    def length
      return @string.length
    end

    # Calculates and returns the remaining length of the instance string (from the index position).
    #
    def rest_length
      length = @string.length - @index
      return length
    end

    # Extracts and returns the remaining part of the instance string (from the index position to the end of the string).
    #
    def rest_string
      str = @string[@index..(@string.length-1)]
      return str
    end

    # Resets the instance string and index.
    #
    def reset
      @string = ""
      @index = 0
    end

    # Resets the instance index.
    #
    def reset_index
      @index = 0
    end

    # Sets an instance file variable.
    #
    # === Notes
    #
    # For performance reasons, we enable the Stream instance to write directly to file,
    # to avoid expensive string operations which will otherwise slow down the write performance.
    #
    # === Parameters
    #
    # * <tt>file</tt> -- A File instance.
    #
    def set_file(file)
      @file = file
    end

    # Sets a new instance string, and resets the index variable.
    #
    # === Parameters
    #
    # * <tt>binary</tt> -- A binary string.
    #
    def set_string(binary)
      binary = binary[0] if binary.is_a?(Array)
      @string = binary
      @index = 0
    end

    # Applies an offset (positive or negative) to the instance index.
    #
    # === Parameters
    #
    # * <tt>offset</tt> -- Fixnum. The length to skip (positive) or rewind (negative).
    #
    def skip(offset)
      @index += offset
    end
    
    # Converts a data type/vr to an encode/decode string used by the pack/unpack methods, which is returned.
    #
    # === Parameters
    #
    # * <tt>vr</tt> -- String. A data type (value representation).
    #
    def vr_to_str(vr)
      unless @format[vr]
        errors << "Warning: Element type #{vr} does not have a reading method assigned to it. Something is not implemented correctly or the DICOM data analyzed is invalid."
        return @hex
      else
        return @format[vr]
      end
    end
    
    # Sets an instance file variable.
    #
    # === Notes
    #
    # For performance reasons, we enable the Stream instance to write directly to file,
    # to avoid expensive string operations which will otherwise slow down the write performance.
    #
    # === Parameters
    #
    # * <tt>file</tt> -- A File instance.
    #
    def set_file(file)
      @file = file
    end
    
    # Writes a binary string to the File instance.
    #
    # === Parameters
    #
    # * <tt>binary</tt> -- A binary string.
    #
    def write(binary)
      @file.write(binary)
    end
    
    # Encodes a value and returns the resulting binary string.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- A custom value (String, Fixnum, etc..) or an array of numbers.
    # * <tt>type</tt> -- String. The type (vr) of data to encode.
    #
    def encode(value, type)
      value = [value] unless value.is_a?(Array)
      return value.pack(vr_to_str(type))
    end
    
    # Appends a string with trailling spaces to achieve a target length, and encodes it to a binary string.
    # Returns the binary string.  Raises an error if pad option is different than :null or :spaces
    #
    # === Parameters
    #
    # * <tt>string</tt> -- A string to be processed.
    # * <tt>target_length</tt> -- Fixnum. The target length of the string that is created.
    # * <tt>pad</tt> -- Type of desired padding, either :null or :spaces
    #
    def encode_string_to_length(string, target_length, pad = :null)
      if pad == :spaces
        template = "A#{target_length}"
      elsif pad == :null
        template = "a#{target_length}"
      else
        raise StandardError, "Could not identify padding type #{pad}"
      end
      
      length = string.length
      if length < target_length
        return [string].pack(template)
      elsif length == target_length
        return [string].pack(@str)
      else
        raise "The specified string is longer than the allowed maximum length (String: #{string}, Target length: #{target_length})."
      end
    end
    
    # Following methods are private:
    private


    # Determines the relationship between system and string endianness, and sets the instance endian variable.
    #
    def configure_endian
      if CPU_ENDIAN == @str_endian
        @equal_endian = true
      else
        @equal_endian = false
      end
    end
    
    # Sets the pack/unpack format strings that is used for encoding/decoding.
    # Some of these depends on the endianness of the system and the String.
    #
    #--
    # Note: Surprisingly the Ruby pack/unpack methods lack a format for signed short
    # and signed long in the network byte order. A hack has been implemented to to ensure
    # correct behaviour in this case, but it is slower (~4 times slower than a normal pack/unpack).
    #
    def set_string_formats
      if @equal_endian
        # Native byte order:
        @us = "S*" # Unsigned short (2 bytes)
        @ss = "s*" # Signed short (2 bytes)
        @ul = "I*" # Unsigned long (4 bytes)
        @sl = "l*" # Signed long (4 bytes)
        @fs = "e*" # Floating point single (4 bytes)
        @fd = "E*" # Floating point double ( 8 bytes)
      else
        # Network byte order:
        @us = "n*"
        @ss = CUSTOM_SS # Custom string for our redefined pack/unpack.
        @ul = "N*"
        @sl = CUSTOM_SL # Custom string for our redefined pack/unpack.
        @fs = "g*"
        @fd = "G*"
      end
      # Format strings that are not dependent on endianness:
      @by = "C*" # Unsigned char (1 byte)
      @str = "a*"
      @hex = "H*" # (this may be dependent on endianness(?))
    end
  
    # Sets the hash which is used to convert data element types (VR) to
    # encode/decode strings accepted by the pack/unpack methods.
    #
    def set_format_hash
      @format = {
        "BY" => @by, # Byte/Character (1-byte integers)
        "US" => @us, # Unsigned short (2 bytes)
        "SS" => @ss, # Signed short (2 bytes)
        "UL" => @ul, # Unsigned long (4 bytes)
        "SL" => @sl, # Signed long (4 bytes)
        "FL" => @fs, # Floating point single (4 bytes)
        "FD" => @fd, # Floating point double (8 bytes)
        "OB" => @by, # Other byte string (1-byte integers)
        "OF" => @fs, # Other float string (4-byte floating point numbers)
        "OW" => @us, # Other word string (2-byte integers)
        "AT" => @hex, # Tag reference (4 bytes) NB: This may need to be revisited at some point...
        "UN" => @hex, # Unknown information (header element is not recognized from local database)
        "HEX" => @hex, # HEX
        # We have a number of VRs that are decoded as string:
        "AE" => @str,
        "AS" => @str,
        "CS" => @str,
        "DA" => @str,
        "DS" => @str,
        "DT" => @str,
        "IS" => @str,
        "LO" => @str,
        "LT" => @str,
        "PN" => @str,
        "SH" => @str,
        "ST" => @str,
        "TM" => @str,
        "UI" => @str,
        "UT" => @str,
        "STR" => @str
      }
    end
    
    # Sets the hash which is used to keep track of which bytes to use for padding
    # data elements of various vr which have an odd value length.
    #
    def set_pad_byte
      @pad_byte = {
        # Space character:
        "AE" => "\x20",
        "AS" => "\x20",
        "CS" => "\x20",
        "DA" => "\x20",
        "DS" => "\x20",
        "DT" => "\x20",
        "IS" => "\x20",
        "LO" => "\x20",
        "LT" => "\x20",
        "PN" => "\x20",
        "SH" => "\x20",
        "ST" => "\x20",
        "TM" => "\x20",
        "UT" => "\x20",
        # Zero byte:
        "AT" => "\x00",
        "FL" => "\x00",
        "FD" => "\x00",
        "OB" => "\x00",
        "OF" => "\x00",
        "OW" => "\x00",
        "SL" => "\x00",
        "SQ" => "\x00",
        "SS" => "\x00",
        "UI" => "\x00",
        "UL" => "\x00",
        "UN" => "\x00",
        "US" => "\x00"
      }
      @pad_byte.default = "\20"
    end


    # Sets the endianness of the instance string. The relationship between the string endianness and
    # the system endianness, determines which encoding/decoding flags to use.
    #
    # === Parameters
    #
    # * <tt>string_endian</tt> -- Boolean. The endianness of the instance string (true for big endian, false for small endian).
    #
    def endian=(string_endian)
      @str_endian = string_endian
      configure_endian
      set_string_formats
      set_format_hash
      set_pad_byte
    end

  end
  
end
