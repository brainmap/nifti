module NIFTI
  # The NImage class is a container for the "raw" NIFTI image data making easier to deal with them.

  class NImage
    attr_reader :array_image, :dim, :previous_indexes

    def initialize(array_image, dim, previous_indexes=[])
      @array_image = array_image
      @dim = dim
      @previous_indexes = previous_indexes
    end

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

    def []=(index,value)
      if self.shape.count != 1 or index >= self.shape[0]
        raise IndexError.new("You can only set values for array values")
      else
        @array_image[get_index_value(index)] = value
      end
    end

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