RUBY NIfTI
==========

Ruby NIfTI is a pure-ruby library for handling NIfTI data in Ruby. NIfTI
[(Neuroimaging Informatics Technology Initiative)](http://nifti.nimh.nih.gov/)
is an image format designed primarily for the storage and analysis of MRI & PET
imaging data.

Ruby NIfTI currently supports basic access to NIfTI files, including
basic and extended header information, as well as image information. It
doesn't attempt to touch the image data (rotate it, etc.), but it does provide
access to qform and sform orientation matrices. Nonetheless it does provide a
nice interface to get at NIfTI info from within ruby. Since Ruby isn't as
widely seen as a quantitative scripting language yet (Python is more well
known, and PyNifti is more mature than NumericalRuby / NArray) I don't know
how widely this will be used, but hopefully it will be useful for somebody.

INSTALLATION
------------

    gem install nifti


BASIC USAGE
-----------

Initialize the library:

    require "nifti"

Read file:

    obj = NIFTI::NObject.new("some_file.nii")

Display some key information about the file:

	  puts obj.header['sform_code_descr']
    => "NIFTI_XFORM_SCANNER_ANAT"

Retrieve the pixel data in a Ruby Array:

    image = obj.get_image

Load the pixel data to an NArray image object and display it on the screen:

    image = obj.get_image_narray

Or load the pixel data into an NImage (for easier indexing):

    image = obj.get_nimage
    

LIMITATIONS
-----------

There are several good NIfTI libraries around (the canonical
[nifticlib](http://niftilib.sourceforge.net/), which includes c, python and
matlab interfaces, and Matlab interfaces in the Mathworks image processing
toolbox (IPT) and [Toolbox for
NIfTI](http://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image)
by Jimmy Shen. 

This library does not intend to replace them, but rather to provide a few ruby
convenience methods for quickly accessing imaging data from ruby without
having to call out to external programs, as well as write custom extensions to
the NIfTI header.

GETTING HELP
------------

Feel free to use the [github issue tracker](https://github.com/brainmap/nifti/issues) 
to post any questions, or email me directly.

CREDIT
------

Ruby NIfTI is highly derivative of the very good library [Ruby
DICOM](http://dicom.rubyforge.org/), from which all of the design and most of
the code has been cold-heartedly stolen. Many thanks to Chris Lervag - this
wouldn't exist without his examples.


RESOURCES
---------

* [Development / Source code](https://github.com/brainmap/nifti)
* [Documentation](http://rdoc.info/github/brainmap/nifti/master/frames)


Examples
--------

### Using Extended Headers ###

Each NObject that is successfully read has an array of extended_header hashes.
Each extended_header hash has 3 keys, :esize, :ecode, and :data corresponding
to the available fields in the nifti header extension.

Here's a silly example (since you'd probably want to read do this using
something that's designed for it, like 3dinfo). Suppose you wanted to collect
the history of an image from inside the AFNI extended header. Since the data
of the AFNI extended header is just xml, you could easily parse it with an xml
parser like nokogiri (using the AFNI ecode of 4 to select it from the list of
extended headers, and assuming that there's only 1 AFNI header per file):

    require 'nifti'; require 'nokogiri'
    obj = NIFTI::NObject.new('./T1.nii')
    afni_extended_header = obj.extended_header.select{|ext| ext[:ecode] == 4 }[:data]
    afni_xml = Nokogiri::XML(xml)
    history = afni_xml.xpath("//AFNI_atr[@atr_name='HISTORY_NOTE']").first.children.first.text

### Image Summary Statistics ###

Again, this is a trivial example, but shows one usage of the library. Say you
want to take find the mean and std dev of the entire image.

    obj = NIFTI::NObject.new('./T1.nii', :narray => true)
    mean = obj.image.mean
    stddev = obj.image.stddev

If you don't have narray installed, you could still use obj.image as a ruby
array, but you'd have to collect the summary stats yourself.
