require 'rspec'
require 'digest/md5'

# Source: Matt Wynne; https://gist.github.com/736421
RSpec::Matchers.define(:be_same_file_as) do |exected_file_path|
  match do |actual_file_path|
    md5_hash(actual_file_path).should == md5_hash(exected_file_path)
  end

  # Calculate an md5 hash from a file path
  def md5_hash(file_path)
    Digest::MD5.hexdigest(File.read(file_path))    
  end
end
