Given(/^I have a NObject loaded$/) do
  @n_object = NIFTI::NObject.new(File.join(File.dirname(__FILE__), '..', 'support', 'fixtures', 'brain_dti.nii.gz'))
end

Given(/^I have the NImage representation of the image$/) do
  @n_image = @n_object.get_nimage
end

When(/^I get the value at \("(.*?)", "(.*?)", "(.*?)", "(.*?)"\)$/) do |x, y, z, t|
  @value = @n_image[x.to_i][y.to_i][z.to_i][t.to_i]
end

When(/^I set the value at \("(.*?)", "(.*?)", "(.*?)", "(.*?)"\) to "(.*?)"$/) do |x, y, z, t, val|
  @n_image[x.to_i][y.to_i][z.to_i][t.to_i] = val.to_f
end

When(/^I save the NImage as new file$/) do
  obj = NIFTI::NObject.new
  obj.header = @n_object.header
  obj.extended_header = @n_object.extended_header
  obj.image = @n_image.array_image

  writer = NIFTI::NWrite.new(obj, "test.nii.gz")
  writer.write
end

When(/^I load the new file$/) do
  @n_object = NIFTI::NObject.new('test.nii.gz')
end

Then(/^the value should be equals to "(.*?)"$/) do |val|
  @value.should eq(val.to_f)
end
