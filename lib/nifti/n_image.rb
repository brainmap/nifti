module NIFTI
  # The NImage class is a container for the "raw" NIFTI image data making easier to deal with them.

  class NImage
    attr_reader :array_image, :dim, :previous_indexes

    # Creates an NImage instance.
    #
    # The NImages instance provides a user friendly interface to the NIFTI Image
    # A NImage is typically built by NObject instance
    #
    # === Parameters
    #
    # * <tt>array_image</tt> -- The NIFTI image contained on and one dimensional array
    # * <tt>dim</tt> -- The dimensions array from the NIFTI header.
    #
    # === Examples
    #
    #   # Creates an NImage to deal with an 9 position array that represents a 3x3 matrix
    #   img = Nimage.new(Array.new(9,0.0), [2,3,3])
    #
    def initialize(array_image, dim, previous_indexes=[])
      @array_image = array_image
      @dim = dim
      @previous_indexes = previous_indexes
    end

    # Retrieves an element or partition of the dataset
    #
    # === Parameters
    #
    # * <tt>index</tt> -- The desired index on the dataset
    #
    # === Options
    #
    # === Examples
    #
    #   img[0][0]
    #   img[0][0..1]
    #
    def [](index)
      # Dealing with Ranges is useful when the image represents a tensor
      if (index.is_a?(Fixnum) && index >= self.shape[0]) || (index.is_a?(Range) && index.last >= self.shape[0])
        raise IndexError.new("Index over bounds")
      elsif self.shape.count == 1
        if index.is_a?(Range)
          self.array_image[get_index_value(index.first)..get_index_value(index.last)]
        else
          self.array_image[get_index_value(index)]
        end
      else
        NImage.new(self.array_image, self.dim, self.previous_indexes.clone << index)
      end
    end

    # Set the value for an element of the dataset
    #
    # === Parameters
    #
    # * <tt>index</tt> -- The desired index on the dataset
    # * <tt>value</tt> -- The value that the will be set
    #
    # === Options
    #
    # === Examples
    #
    #   img[0][0] = 1.0
    #
    def []=(index,value)
      if self.shape.count != 1 or index >= self.shape[0]
        raise IndexError.new("You can only set values for array values")
      else
        @array_image[get_index_value(index)] = value
      end
    end

    # Dataset shape
    #
    # === Examples
    #
    #   img.shape
    #
    def shape
      start_index = 1
      self.previous_indexes.each {start_index += 1}
      self.dim[start_index..self.dim[0]]
    end

    private

    def get_index_value(current_index)
      index_value = 0
      step = (self.dim.inject(:*)/self.dim[0])/self.dim[self.dim[0]]
      self.previous_indexes.each_index do |index|
        index_value+= step*self.previous_indexes[index]
        step /= self.dim[index + 1]
      end

      index_value + current_index
    end
  end
end