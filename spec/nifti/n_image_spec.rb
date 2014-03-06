require 'spec_helper'

describe NIFTI::NImage do
  let!(:image_array) { Array.new(27,0.0) }
  let!(:dim) { [3, 3, 3, 3, 1, 1, 1] }

  describe 'shape' do
    it 'should disconsider the first (number of dimensions) and three last elements of dim' do
      NImage.new(image_array, dim).shape.should eq([3,3,3])
    end
  end

  describe '[]' do
    subject { NImage.new(image_array, dim) }

    context 'with a Fixnum' do
      context 'with a index out of range' do
        it 'should raise a IndexError' do
          expect{ subject[2][2][3] }.to raise_error(IndexError)
        end
      end

      context 'with a valid index' do
        it 'should return the value' do
          mod_image_array = image_array
          mod_image_array[26] = 1.0
          n_image = NImage.new(mod_image_array, dim)

          n_image[2][2][2].should eq(1.0)
        end
      end
    end

    context 'with a Range' do
      context 'with a index out of range' do
        it 'should raise a IndexError' do
          expect{ subject[2][2][0..3] }.to raise_error(IndexError)
        end
      end

      context 'with a valid index' do
        it 'should return the value' do
          mod_image_array = image_array
          mod_image_array[26] = 1.0
          n_image = NImage.new(mod_image_array, dim)

          n_image[2][2][0..2].should eq([0.0, 0.0, 1.0])
        end
      end
    end
  end

  describe '[]=' do
    subject { NImage.new(image_array, dim) }

    context 'when setting value for a non Fixnum' do
      it 'should raise an error' do
        expect { subject[2]=1.0}.to raise_error(IndexError)
      end
    end

    context 'with an invalid index' do
      it 'should raise an error' do
        expect { subject[2][2][3]=1.0}.to raise_error(IndexError)
      end
    end

    context 'with a valid index' do
      it 'should set the value' do
        subject[2][2][2] = 1.0

        image_array[26].should eq(1.0)
      end
    end
  end
end