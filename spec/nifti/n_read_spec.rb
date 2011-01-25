require 'spec_helper'

describe Nifti::NRead do
  before :all do
    @file = File.open(NIFTI_TEST_FILE1, 'rb')
    @fixture_image_length = 983040
    @string = @file.read
    @stream = Stream.new(@string, false)
    @valid_header = {
      "xyzt_units"=>2, "pixdim"=>[1.0, 0.9375, 0.9375, 12.5, 0.0, 0.0, 0.0,
      0.0], "sform_code"=>1, "aux_file"=>"", "scl_slope"=>0.0,
      "srow_x"=>[-0.9375, -0.0, -0.0, 119.53125], "glmin"=>0, "srow_y"=>[-0.0,
      -0.9375, -0.0, 159.531005859375], "qform_code"=>1,
      "slice_duration"=>0.0, "cal_min"=>0.0, "db_name"=>"", "magic"=>"n+1",
      "srow_z"=>[0.0, 0.0, 12.5, -25.0], "quatern_b"=>0.0, "data_type"=>"",
      "intent_name"=>"", "quatern_c"=>0.0, "slice_end"=>0, "scl_inter"=>0.0,
      "quatern_d"=>1.0, "slice_code"=>0, "sizeof_hdr"=>348,
      "qoffset_x"=>119.53125, "dim_info"=>0, "qoffset_y"=>159.531005859375,
      "descrip"=>"", "datatype"=>4, "intent_p1"=>0.0, "dim"=>[3, 256, 256, 15,
      1, 1, 1, 1], "qoffset_z"=>-25.0, "glmax"=>0, "toffset"=>0.0,
      "bitpix"=>16, "intent_code"=>0, "intent_p2"=>0.0, "session_error"=>0,
      "extents"=>0, "cal_max"=>0.0, "vox_offset"=>6032.0, "slice_start"=>0,
      "intent_p3"=>0.0, "regular"=>"r"}
    @n_read_obj = NRead.new(@string, :bin => true)
  end
  
  it "should read a binary string and correctly return header variables" do
    NRead.new(@string, :bin => true).hdr.should == @valid_header
  end
  
  it "should read a nifti file and correctly return header variables" do
    NRead.new(NIFTI_TEST_FILE1).hdr.should == @valid_header
  end
  
  it "should raise IOError if header size != 348." do
    str = @string.dup
    str[0..4] = [0].pack("N*")
    lambda {
      NRead.new(str, :bin => true).hdr
    }.should raise_error IOError, /Header appears to be malformed/
  end
  
  it "should raise IOError if magic != ni1 or n+1." do
    str = @string.dup
    str[344..348] = ["NOPE"].pack("a*")
    lambda {
      NRead.new(str, :bin => true).hdr
    }.should raise_error IOError, /Header appears to be malformed/
  end
  
  it "should read image data correctly" do
    @n_read_obj.image.class.should == Array
    @n_read_obj.image.length.should == @fixture_image_length
    # Since this is a fixture, we know exactly what the values are.
    # Pick some from the middle of the string and test them.
    @n_read_obj.image[(@fixture_image_length / 2)..(@fixture_image_length/2 + 100)].should == [0, 0, 0, 0, 18, 36, 25, 23, 19, 23, 13, 14, 16, 16, 12, 16, 22, 17, 13, 17, 19, 24, 19, 14, 11, 16, 49, 81, 129, 194, 216, 175, 130, 128, 146, 154, 159, 205, 304, 391, 414, 380, 320, 281, 297, 343, 358, 322, 287, 339, 450, 493, 426, 344, 310, 285, 275, 290, 282, 283, 310, 278, 268, 222, 49, 284, 235, 172, 116, 108, 115, 112, 135, 176, 196, 200, 216, 207, 86, 30, 152, 161, 138, 117, 81, 47, 73, 207, 381, 459, 415, 346, 353, 429, 490, 503, 492, 454, 379, 304, 275]
  end
  
end
