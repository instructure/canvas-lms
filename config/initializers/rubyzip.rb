#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# ZipEntry filenames are returned with an encoding of ASCII-8BIT
# even though the string itself is typically UTF-8 in our uses.
# Tag the string as UTF-8 if it's valid UTF-8 so we can search
# for files with non-ASCII names inside archives.

require 'zip'

Zip.write_zip64_support = true
Zip.unicode_names = true

module ZipEncodingFix
  def fix_name_encoding
    @name.force_encoding('UTF-8')
    @name.force_encoding('ASCII-8BIT') unless @name.valid_encoding?
  end

  # see https://github.com/rubyzip/rubyzip/issues/324
  # there's a test for this case, see
  # spec/lib/canvas/migration_spec.rb:85, ie
  # "should deal with backslashes path separators in migrations"
  def fix_name_backslashes
    @name.tr!('\\', '/')
  end

  def read_c_dir_entry(io)
    retval = super
    fix_name_backslashes
    fix_name_encoding
    retval
  end

  def read_local_entry(io)
    retval = super
    # fix_name_backslashes # regression was only in read_c_dir_entry
    fix_name_encoding
    retval
  end
end

Zip::Entry.prepend(ZipEncodingFix)
