require File.dirname(__FILE__) + '/../lib/nifti'
include Nifti

module Nifti
  # Fixture file to use for specs/tests
  NIFTI_TEST_FILE1 = File.join(File.dirname(__FILE__), 'fixtures/3plLoc.nii')
end

RSpec.configure do |config|
  config.mock_with :mocha
end
