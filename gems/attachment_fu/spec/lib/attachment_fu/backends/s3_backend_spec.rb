# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe AttachmentFu::Backends::S3Backend do
  it "can handle a nil filename" do
    expect do
      @class = Class.new do
        extend AttachmentFu::Backends::S3Backend

        def self.thumbnail_name_for
          nil
        end

        def self.base_path
          ""
        end
      end

      @class.full_filename
    end.not_to raise_error
  end
end
