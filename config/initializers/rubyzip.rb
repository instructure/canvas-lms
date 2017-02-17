# ZipEntry filenames are returned with an encoding of ASCII-8BIT
# even though the string itself is typically UTF-8 in our uses.
# Tag the string as UTF-8 if it's valid UTF-8 so we can search
# for files with non-ASCII names inside archives.

require 'zip'

Zip.write_zip64_support = true

module ZipEncodingFix
  def fix_name_encoding
    @name.force_encoding('UTF-8')
    @name.force_encoding('ASCII-8BIT') unless @name.valid_encoding?
  end

  def read_c_dir_entry(io)
    retval = super
    fix_name_encoding
    retval
  end

  def read_local_entry(io)
    retval = super
    fix_name_encoding
    retval
  end
end

Zip::Entry.prepend(ZipEncodingFix)
