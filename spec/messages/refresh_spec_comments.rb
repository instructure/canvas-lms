#
# Copyright (C) 2011 Instructure, Inc.
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
#

Dir.glob("../../app/messages/*.erb") do |filename|
  original_filename = filename
  original_file = File.read(original_filename)
  
  filename = File.split(filename)[-1]
  event_name = filename.split(".")[0]
  event_type = filename.split(".")[1]
  if File.exist?(filename + "_spec.rb")
    text = File.read(filename + "_spec.rb")
    text = text.split("\n\n#")[0]
    f = File.open(filename + "_spec.rb", 'w')
    f.puts text
    f.puts "\n\n#"
    f.puts "# " + original_file.gsub("\n", "\n# ")
    f.close
    puts filename
  end
end
