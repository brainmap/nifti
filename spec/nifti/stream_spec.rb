require 'spec_helper'

describe NIFTI::Stream do
  before :each do
    @string = File.open(NIFTI_TEST_FILE1, 'rb').read
    @endianess = false
    @stream = Stream.new(@string, @endianess)
  end
  
  it "should create a well-behaved stream instance given a binary string" do
    stream = Stream.new(@string, @endianess)
    stream.index.should == 0
    stream.string.should == @string
    stream.errors.should be_empty
    stream.str_endian.should == @endianess
  end
  
  it "should be able to jump around within a string" do
    @stream.skip 5
    @stream.index.should == 5
    @stream.skip -3
    @stream.index.should == 2
  end
  
  it "should read the size of the header as 348" do
    @stream.decode(4, "UL").should == 348
  end
  
  it "unused Analyze header datatype field should be blank" do
    @stream.skip 4
    @stream.decode(10, "STR").should == ""
  end
  
  it "should read the datatype as something" do
    @stream.skip 14
    @stream.decode(18, "STR").should == ""
  end
  
  it "should read the dim as something" do
    @stream.skip 40
    @stream.decode(16, "US").should == [3, 256, 256, 15, 1, 1, 1, 1]
  end

end