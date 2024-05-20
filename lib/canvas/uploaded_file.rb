# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

# This is a replacement for Rack::Test::UploadedFile that does not unnecessarily
# copy the file being uploaded. Since all our use cases involve synchronous upload
# and we don't make use of #append, we don't need to waste the time or space.
# This also doesn't implement the StringIO interface that we don't use.

module Canvas
  class UploadedFile
    attr_reader :original_filename, :tempfile, :content_type

    def initialize(path, content_type)
      @content_type = content_type
      @original_filename = File.basename(path)
      @tempfile = File.open(path, "rb")
    end

    # Delegate all methods not handled to the tempfile.
    def method_missing(method_name, ...)
      tempfile.public_send(method_name, ...)
    end

    def respond_to_missing?(method_name, include_private = false) # :nodoc:
      tempfile.respond_to?(method_name, include_private) || super
    end
  end
end
