require File.dirname(__FILE__) + '/../lib/nifti'
include Nifti

NIFTI_TEST_FILE1 = File.join(File.dirname(__FILE__), 'fixtures/3plLoc.nii')

RSpec.configure do |config|
  config.mock_with :mocha
end
