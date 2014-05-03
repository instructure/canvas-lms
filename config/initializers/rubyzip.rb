# ZipEntry filenames are returned with an encoding of ASCII-8BIT
# even though the string itself is typically UTF-8 in our uses.
# Tag the string as UTF-8 if it's valid UTF-8 so we can search
# for files with non-ASCII names inside archives.

require 'zip'

Zip.write_zip64_support = true

Zip::Entry::class_eval do
  def fix_name_encoding
    @name.force_encoding('UTF-8')
    @name.force_encoding('ASCII-8BIT') unless @name.valid_encoding?
  end

  def read_c_dir_entry_with_encoding_fix(io)
    retval = read_c_dir_entry_without_encoding_fix(io)
    fix_name_encoding
    retval
  end
  alias_method_chain :read_c_dir_entry, :encoding_fix

  def read_local_entry_with_encoding_fix(io)
    retval = read_local_entry_without_encoding_fix(io)
    fix_name_encoding
    retval
  end
  alias_method_chain :read_local_entry, :encoding_fix
end
