# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module AttachmentLocationTagger
  def self.tag_url(url, location)
    file_url_pattern = %r{(?<![a-zA-Z0-9:])(/(?:[\w-]+/(?:\d+(?:~\d+)?)/)?(?:files/(?:\d+(?:~\d+)?)(?:/[\w-]+)?|media_attachments_iframe/(?:\d+(?:~\d+)?))(?:\?[^"'<>]*)?)}

    url.gsub(file_url_pattern) do |_|
      url = Regexp.last_match(1)
      if url.include?("?")
        "#{url}&location=#{location}"
      else
        "#{url}?location=#{location}"
      end
    end
  end
end
