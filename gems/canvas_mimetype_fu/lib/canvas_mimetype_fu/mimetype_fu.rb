#
# Copyright (C) 2011 - present Instructure, Inc.
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

class File

  def self.mime_type?(file)
    # INSTRUCTURE: added condition, file.class can also be Tempfile
    if file.class == File || file.class == Tempfile
      unless RUBY_PLATFORM.include? 'mswin32'
        # INSTRUCTURE: changed to IO.popen to avoid shell injection attacks when paths include user defined content
        mime = IO.popen(['file', '--mime', '--brief', '--raw', '--', file.path], &:read).strip
      else
        mime = extensions[File.extname(file.path).gsub('.','').downcase] rescue nil
      end
    elsif file.class == String
      mime = extensions[(file[file.rindex('.')+1, file.size]).downcase] rescue nil
    elsif file.respond_to?(:string)
      temp = File.open(Dir.tmpdir + '/upload_file.' + Process.pid.to_s, "wb")
      temp << file.string
      temp.close
      # INSTRUCTURE: changed to IO.popen to be sane and consistent. This one shouldn't be able to contain a user
      # specified path, but that's no reason to not do things the right way.
      mime = IO.popen(['file', '--mime', '--brief', '--raw', '--', temp.path], &:read).strip
      mime = mime.gsub(/^.*: */,"")
      mime = mime.gsub(/;.*$/,"")
      mime = mime.gsub(/,.*$/,"")
      File.delete(temp.path)
    end

    mime = mime && mime.split(";").first
    mime = nil unless mime_types[mime]

     if mime
       return mime
     else
       'unknown/unknown'
     end
   end

   def self.mime_types
    extensions.invert
   end

  private

  def self.extensions
    ::MimetypeFu::EXTENSIONS
  end

end
