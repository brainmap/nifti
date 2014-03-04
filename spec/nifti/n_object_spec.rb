require 'spec_helper'

describe NIFTI::NObject do
  before :all do
    @string = File.open(NIFTI_TEST_FILE1, 'rb').read
    @fixture_image_length = 983040
    @fixture_afni_extension_length = 5661
    @new_fixture_file_name = '5PlLoc.nii'
    @valid_header = {
      "xyzt_units"=>2, "pixdim"=>[1.0, 0.9375, 0.9375, 12.5, 0.0, 0.0, 0.0,
      0.0], "sform_code"=>1, "aux_file"=>"", "scl_slope"=>0.0,
      "srow_x"=>[-0.9375, -0.0, -0.0, 119.53125], "glmin"=>0, "freq_dim"=>0,
      "srow_y"=>[-0.0, -0.9375, -0.0, 159.531005859375], "qform_code"=>1,
      "slice_duration"=>0.0, "cal_min"=>0.0, "db_name"=>"", "magic"=>"n+1",
      "srow_z"=>[0.0, 0.0, 12.5, -25.0], "quatern_b"=>0.0, "data_type"=>"",
      "qform_code_descr"=>"NIFTI_XFORM_SCANNER_ANAT",
      "sform_code_descr"=>"NIFTI_XFORM_SCANNER_ANAT", "intent_name"=>"",
      "quatern_c"=>0.0, "slice_end"=>0, "scl_inter"=>0.0, "quatern_d"=>1.0,
      "slice_code"=>0, "sizeof_hdr"=>348, "slice_dim"=>0,
      "qoffset_x"=>119.53125, "dim_info"=>0, "phase_dim"=>0,
      "qoffset_y"=>159.531005859375, "descrip"=>"", "datatype"=>4,
      "intent_p1"=>0.0, "dim"=>[3, 256, 256, 15, 1, 1, 1, 1],
      "qoffset_z"=>-25.0, "glmax"=>0, "toffset"=>0.0, "bitpix"=>16,
      "intent_code"=>0, "intent_p2"=>0.0, "session_error"=>0, "extents"=>0,
      "cal_max"=>0.0, "vox_offset"=>6032.0, "slice_start"=>0,
      "intent_p3"=>0.0, "regular"=>"r"
    }
  end

  # Think of these more as integration tests, since the actual reading
  # is done and tested in the NRead spec
  it "should read a nifti file and correctly initialize header and image" do
    obj = NObject.new(NIFTI_TEST_FILE1)

    obj.header.should == @valid_header
    obj.extended_header.should_not be_empty
    obj.extended_header.first[:esize].should == 5680
    obj.extended_header.first[:ecode].should == 4
    obj.extended_header.first[:data].length.should == @fixture_afni_extension_length
    obj.image.should be_nil

  end

  it "should read a binary string and correctly initialize header and image" do
    obj = NObject.new(@string, :bin => true)

    obj.header.should == @valid_header
    obj.extended_header.should_not be_empty
    obj.extended_header.first[:esize].should == 5680
    obj.extended_header.first[:ecode].should == 4
    obj.extended_header.first[:data].length.should == @fixture_afni_extension_length
    obj.image.should be_nil

  end

  it "should read a nifti file with image" do
    obj = NObject.new(NIFTI_TEST_FILE1, :image => true)

    obj.header.should == @valid_header
    obj.extended_header.should_not be_empty
    obj.extended_header.first[:esize].should == 5680
    obj.extended_header.first[:ecode].should == 4
    obj.extended_header.first[:data].length.should == @fixture_afni_extension_length
    obj.image.should_not be_nil
    obj.image.length.should == @fixture_image_length

  end

  it "should read a nifti file with image as narray" do
    obj = NObject.new(NIFTI_TEST_FILE1, :image => true, :narray => true)

    obj.header.should == @valid_header
    obj.extended_header.should_not be_empty
    obj.extended_header.first[:esize].should == 5680
    obj.extended_header.first[:ecode].should == 4
    obj.extended_header.first[:data].length.should == @fixture_afni_extension_length
    obj.image.should_not be_nil
    obj.image.class.should == NArray
    obj.image.dim.should == 3

  end

  it "should retrieve image data when requested" do
    obj = NObject.new(NIFTI_TEST_FILE1)
    obj.get_image.length.should == @fixture_image_length
  end


  it "should raise an error if initialized with bad argument" do
    lambda {
      NObject.new(12345)
    }.should raise_error ArgumentError, /Invalid argument/
  end

  it "should sucessfully write a NIfTI file" do
    obj = NObject.new(NIFTI_TEST_FILE1, :image => true)
    obj.write(@new_fixture_file_name)
    File.exist?(@new_fixture_file_name).should be_true
    obj.write_success.should be_true
  end

  it "should be able to assign an image" do
    obj = NObject.new(@string, :bin => true, :image => true)
    obj.image = [0] * @fixture_image_length
  end

  it 'should retrieve an NImage' do
    obj = NObject.new(NIFTI_TEST_FILE1)
    obj.get_nimage.should be_a(NImage)
  end

  after :each do
    File.delete @new_fixture_file_name if File.exist? @new_fixture_file_name
  end

end