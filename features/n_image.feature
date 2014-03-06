Feature: Image data interface with NImage
  In Order to able manipulate the image data
  As a developer
  I want to access it as a multidimensional array

  @clean_saved_files
  Scenario: reading and writing
    Given I have a NObject loaded
    And I have the NImage representation of the image
    When I get the value at ("64", "64", "35", "3")
    # I know the dataset, so we know this value
    Then the value should be equals to "2.4997341632843018"
    When I set the value at ("64", "64", "35", "3") to "2.0"
    And I save the NImage as new file
    And I load the new file
    And I have the NImage representation of the image
    And I get the value at ("64", "64", "35", "3")
    Then the value should be equals to "2.0"