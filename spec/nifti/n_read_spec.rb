require 'spec_helper'

describe NIFTI::NRead do
  before do
    @fixture_image_length = 983040
    @fixture_afni_extension_length = 5661
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

  context 'with an uncompressed file' do
    before do
      @string = File.open(NIFTI_TEST_FILE1, 'rb').read
      @stream = Stream.new(@string, false)
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

    it "should read image data correctly if :image option is true" do
      obj = NRead.new(@string, :bin => true, :image => true)
      obj.image_rubyarray.class.should == Array
      obj.image_rubyarray.length.should == @fixture_image_length
      # Since this is a fixture, we know exactly what the values are.
      # Pick some from the middle of the string and test them.
      obj.image_rubyarray[(@fixture_image_length / 2)..(@fixture_image_length/2 + 100)].should == [0, 0, 0, 0, 18, 36, 25, 23, 19, 23, 13, 14, 16, 16, 12, 16, 22, 17, 13, 17, 19, 24, 19, 14, 11, 16, 49, 81, 129, 194, 216, 175, 130, 128, 146, 154, 159, 205, 304, 391, 414, 380, 320, 281, 297, 343, 358, 322, 287, 339, 450, 493, 426, 344, 310, 285, 275, 290, 282, 283, 310, 278, 268, 222, 49, 284, 235, 172, 116, 108, 115, 112, 135, 176, 196, 200, 216, 207, 86, 30, 152, 161, 138, 117, 81, 47, 73, 207, 381, 459, 415, 346, 353, 429, 490, 503, 492, 454, 379, 304, 275]
      obj.image_narray.should be_nil
    end

    it "should return an narray if requested" do
      obj = NRead.new(@string, :bin => true, :narray => true)
      obj.image_narray.should_not be_nil
    end

    it "should add an NArray Install message and not set the image_narray if NArray was not available" do
      Object.expects(:const_defined?).with('NArray').returns(false)
      obj = NRead.new(@string, :bin => true, :narray => true)
      obj.msg.should_not be_empty
      obj.msg.grep(/Please `gem install narray`/).empty?.should be_false
      obj.image_narray.should be_nil
      obj.image_rubyarray.size.should == @fixture_image_length
    end

    it "should read extended header attributes" do
      @n_read_obj.extended_header.should_not be_empty
      @n_read_obj.extended_header.first[:esize].should == 5680
      @n_read_obj.extended_header.first[:ecode].should == 4
      @n_read_obj.extended_header.first[:data].length.should == @fixture_afni_extension_length
      @n_read_obj.extended_header.first[:data].should == "<?xml version='1.0' ?>\n<AFNI_attributes\n  self_idcode=\"XYZ_Fk5B7fY4srOPxYrGolqMIg\"\n  NIfTI_nums=\"256,256,15,1,1,4\"\n  ni_form=\"ni_group\" >\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"HISTORY_NOTE\" >\n \"[erik@nelson.medicine.wisc.edu: Fri Jan 21 10:24:14 2011] to3d -prefix 3plLoc.nii I0001.dcm I0002.dcm I0003.dcm ... I0014.dcm I0015.dcm\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"TYPESTRING\" >\n \"3DIM_HEAD_ANAT\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"IDCODE_STRING\" >\n \"XYZ_Fk5B7fY4srOPxYrGolqMIg\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"IDCODE_DATE\" >\n \"Fri Jan 21 10:24:15 2011\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"8\"\n  atr_name=\"SCENE_DATA\" >\n 0\n 0\n 0\n -999\n -999\n -999\n -999\n -999\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"LABEL_1\" >\n \"3plLoc.nii+orig\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"LABEL_2\" >\n \"Viggo!\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"DATASET_NAME\" >\n \"./3plLoc.nii+orig\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"3\"\n  atr_name=\"ORIENT_SPECIFIC\" >\n 0\n 3\n 4\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"3\"\n  atr_name=\"ORIGIN\" >\n -119.531\n -159.531\n -25\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"3\"\n  atr_name=\"DELTA\" >\n 0.9375\n 0.9375\n 12.5\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"12\"\n  atr_name=\"IJK_TO_DICOM\" >\n 0.9375\n 0.9375\n 0.9375\n -360\n 0\n 0\n 0\n 0\n 0\n 0\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"12\"\n  atr_name=\"IJK_TO_DICOM_REAL\" >\n 0.9375\n 0\n 0\n -119.531\n 0\n 0.9375\n 0\n -159.531\n 0\n 0\n 12.5\n -25\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"30\"\n  atr_name=\"MARKS_XYZ\" >\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"MARKS_LAB\" >\n \"AC superior edge~~~~AC posterior margin~PC inferior edge~~~~First mid-sag pt~~~~Another mid-sag pt~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"3\"\n  atr_name=\"MARKS_HELP\" >\n \"This is the uppermost point&#x0a;on the anterior commisure,&#x0a;in the mid-sagittal plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~This is the rearmost point&#x0a;on the anterior commisure,&#x0a;in the mid-sagittal plane.&#x0a;[Just a couple mm behind and&#x0a; below the AC superior edge.]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~This is the bottommost point&#x0a;on the posterior commissure,&#x0a;in the mid-sagittal plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~You must also specify two other points in the&#x0a;mid-sagittal plane, ABOVE the corpus callosum&#x0a;(i.e., in the longitudinal fissure).  These&#x0a;points are needed to define the vertical plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n \"~~~~~~~~~~~~~~~~~~~~~~~~You must also specify two other points in the&#x0a;mid-sagittal plane, ABOVE the corpus callosum&#x0a;(i.e., in the longitudinal fissure).  These&#x0a;points are needed to define the vertical plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n \"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"8\"\n  atr_name=\"MARKS_FLAGS\" >\n 1\n 1\n 0\n 0\n 0\n 0\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"2\"\n  atr_name=\"BRICK_STATS\" >\n 0\n 2402\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"8\"\n  atr_name=\"DATASET_RANK\" >\n 3\n 1\n 0\n 0\n 0\n 0\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"5\"\n  atr_name=\"DATASET_DIMENSIONS\" >\n 256\n 256\n 15\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"1\"\n  atr_name=\"BRICK_TYPES\" >\n 1\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"1\"\n  atr_name=\"BRICK_FLOAT_FACS\" >\n 0\n</AFNI_atr>\n\n</AFNI_attributes>\n"
    end
  end

  context 'with an gzip compressed file' do
    before do
      @string = File.open(NIFTI_TEST_FILE1_GZ, 'rb').read
      @stream = Stream.new(@string, false)
      @n_read_obj = NRead.new(NIFTI_TEST_FILE1_GZ)
    end

    it "should read a nifti file and correctly return header variables" do
      NRead.new(NIFTI_TEST_FILE1_GZ).hdr.should == @valid_header
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

    it "should read image data correctly if :image option is true" do
      obj = NRead.new(NIFTI_TEST_FILE1_GZ, :image => true)
      obj.image_rubyarray.class.should == Array
      obj.image_rubyarray.length.should == @fixture_image_length
      # Since this is a fixture, we know exactly what the values are.
      # Pick some from the middle of the string and test them.
      obj.image_rubyarray[(@fixture_image_length / 2)..(@fixture_image_length/2 + 100)].should == [0, 0, 0, 0, 18, 36, 25, 23, 19, 23, 13, 14, 16, 16, 12, 16, 22, 17, 13, 17, 19, 24, 19, 14, 11, 16, 49, 81, 129, 194, 216, 175, 130, 128, 146, 154, 159, 205, 304, 391, 414, 380, 320, 281, 297, 343, 358, 322, 287, 339, 450, 493, 426, 344, 310, 285, 275, 290, 282, 283, 310, 278, 268, 222, 49, 284, 235, 172, 116, 108, 115, 112, 135, 176, 196, 200, 216, 207, 86, 30, 152, 161, 138, 117, 81, 47, 73, 207, 381, 459, 415, 346, 353, 429, 490, 503, 492, 454, 379, 304, 275]
      obj.image_narray.should be_nil
    end

    it "should return an narray if requested" do
      obj = NRead.new(NIFTI_TEST_FILE1_GZ, :narray => true)
      obj.image_narray.should_not be_nil
    end

    it "should add an NArray Install message and not set the image_narray if NArray was not available" do
      Object.expects(:const_defined?).with('NArray').returns(false)
      obj = NRead.new(NIFTI_TEST_FILE1_GZ, :narray => true)
      obj.msg.should_not be_empty
      obj.msg.grep(/Please `gem install narray`/).empty?.should be_false
      obj.image_narray.should be_nil
      obj.image_rubyarray.size.should == @fixture_image_length
    end

    it "should read extended header attributes" do
      @n_read_obj.extended_header.should_not be_empty
      @n_read_obj.extended_header.first[:esize].should == 5680
      @n_read_obj.extended_header.first[:ecode].should == 4
      @n_read_obj.extended_header.first[:data].length.should == @fixture_afni_extension_length
      @n_read_obj.extended_header.first[:data].should == "<?xml version='1.0' ?>\n<AFNI_attributes\n  self_idcode=\"XYZ_Fk5B7fY4srOPxYrGolqMIg\"\n  NIfTI_nums=\"256,256,15,1,1,4\"\n  ni_form=\"ni_group\" >\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"HISTORY_NOTE\" >\n \"[erik@nelson.medicine.wisc.edu: Fri Jan 21 10:24:14 2011] to3d -prefix 3plLoc.nii I0001.dcm I0002.dcm I0003.dcm ... I0014.dcm I0015.dcm\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"TYPESTRING\" >\n \"3DIM_HEAD_ANAT\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"IDCODE_STRING\" >\n \"XYZ_Fk5B7fY4srOPxYrGolqMIg\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"IDCODE_DATE\" >\n \"Fri Jan 21 10:24:15 2011\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"8\"\n  atr_name=\"SCENE_DATA\" >\n 0\n 0\n 0\n -999\n -999\n -999\n -999\n -999\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"LABEL_1\" >\n \"3plLoc.nii+orig\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"LABEL_2\" >\n \"Viggo!\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"DATASET_NAME\" >\n \"./3plLoc.nii+orig\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"3\"\n  atr_name=\"ORIENT_SPECIFIC\" >\n 0\n 3\n 4\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"3\"\n  atr_name=\"ORIGIN\" >\n -119.531\n -159.531\n -25\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"3\"\n  atr_name=\"DELTA\" >\n 0.9375\n 0.9375\n 12.5\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"12\"\n  atr_name=\"IJK_TO_DICOM\" >\n 0.9375\n 0.9375\n 0.9375\n -360\n 0\n 0\n 0\n 0\n 0\n 0\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"12\"\n  atr_name=\"IJK_TO_DICOM_REAL\" >\n 0.9375\n 0\n 0\n -119.531\n 0\n 0.9375\n 0\n -159.531\n 0\n 0\n 12.5\n -25\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"30\"\n  atr_name=\"MARKS_XYZ\" >\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n -999999\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"1\"\n  atr_name=\"MARKS_LAB\" >\n \"AC superior edge~~~~AC posterior margin~PC inferior edge~~~~First mid-sag pt~~~~Another mid-sag pt~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"String\"\n  ni_dimen=\"3\"\n  atr_name=\"MARKS_HELP\" >\n \"This is the uppermost point&#x0a;on the anterior commisure,&#x0a;in the mid-sagittal plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~This is the rearmost point&#x0a;on the anterior commisure,&#x0a;in the mid-sagittal plane.&#x0a;[Just a couple mm behind and&#x0a; below the AC superior edge.]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~This is the bottommost point&#x0a;on the posterior commissure,&#x0a;in the mid-sagittal plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~You must also specify two other points in the&#x0a;mid-sagittal plane, ABOVE the corpus callosum&#x0a;(i.e., in the longitudinal fissure).  These&#x0a;points are needed to define the vertical plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n \"~~~~~~~~~~~~~~~~~~~~~~~~You must also specify two other points in the&#x0a;mid-sagittal plane, ABOVE the corpus callosum&#x0a;(i.e., in the longitudinal fissure).  These&#x0a;points are needed to define the vertical plane.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n \"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\"\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"8\"\n  atr_name=\"MARKS_FLAGS\" >\n 1\n 1\n 0\n 0\n 0\n 0\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"2\"\n  atr_name=\"BRICK_STATS\" >\n 0\n 2402\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"8\"\n  atr_name=\"DATASET_RANK\" >\n 3\n 1\n 0\n 0\n 0\n 0\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"5\"\n  atr_name=\"DATASET_DIMENSIONS\" >\n 256\n 256\n 15\n 0\n 0\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"int\"\n  ni_dimen=\"1\"\n  atr_name=\"BRICK_TYPES\" >\n 1\n</AFNI_atr>\n\n<AFNI_atr\n  ni_type=\"float\"\n  ni_dimen=\"1\"\n  atr_name=\"BRICK_FLOAT_FACS\" >\n 0\n</AFNI_atr>\n\n</AFNI_attributes>\n"
    end
  end

  context 'without narray' do

  end
end
