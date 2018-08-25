#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Multipart
  class FileParam
    attr_accessor :k, :filename, :content

    def initialize(k, content)
      @k = k
      @filename = (content.respond_to?(:path) && content.path) || k.to_s || "file.csv"
      @content = content
    end

    def to_multipart_stream(boundary)
      SequencedStream.new([
        StringIO.new("--#{boundary}\r\n" \
                     "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" \
                     "Content-Transfer-Encoding: binary\r\n" \
                     "Content-Type: #{MIME::Types.type_for(filename).first}\r\n" \
                     "\r\n"),
        content,
        StringIO.new("\r\n")
      ])
    end
  end
end
