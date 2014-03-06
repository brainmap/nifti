After('@clean_saved_files') do
  File.delete('test.nii.gz') if File.exist?('test.nii.gz')
end