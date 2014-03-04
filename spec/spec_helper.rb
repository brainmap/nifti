require 'simplecov'
SimpleCov.start

require File.dirname(__FILE__) + '/../lib/nifti'
require 'custom_matchers'

include NIFTI

module NIFTI
  # Fixture file to use for specs/tests
  NIFTI_TEST_FILE1 = File.join(File.dirname(__FILE__), 'fixtures/3plLoc.nii')
  NIFTI_TEST_FILE1_GZ = File.join(File.dirname(__FILE__), 'fixtures/3plLoc.nii.gz')
end

RSpec.configure do |config|
  # Mock Framework
  config.mock_with :mocha

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Colors
  config.color_enabled = true
end
