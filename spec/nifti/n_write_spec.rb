require 'spec_helper'

describe Nifti::NRead do
  before :all do
    @n_object = NObject.new(NIFTI_TEST_FILE1)
    @new_fixture_file_name = '5PlLoc.nii'
    @fixture_image_length = 983040
    @fixture_afni_extension_length = 5660
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
  
  it "should write a NIfTI file" do
    nobj = NObject.new(NIFTI_TEST_FILE1, :image => true)
    w = NWrite.new(nobj, @new_fixture_file_name)
    w.write
  end
end
