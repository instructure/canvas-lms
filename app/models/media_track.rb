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

class MediaTrack < ActiveRecord::Base
  belongs_to :user
  belongs_to :media_object, :touch => true
  before_save :convert_srt_to_wvtt
  validates :media_object_id, presence: true
  validates :content, presence: true

  RE_LOOKS_LIKE_TTML = /<tt\s+xml/i
  validates :content, format: {
    without: RE_LOOKS_LIKE_TTML,
    message: 'TTML tracks are not allowed because they are susceptible to xss attacks'
  }

  def webvtt_content
    self.read_attribute(:webvtt_content) || self.content
  end

  def convert_srt_to_wvtt
    if self.content.exclude?('WEBVTT') && (self.content_changed? || self.read_attribute(:webvtt_content).nil?)
      srt_content = self.content.dup
      srt_content.gsub!(/(:|^)(\d)(,|:)/, '\10\2\3')
      srt_content.gsub!(/([0-9]{2}:[0-9]{2}:[0-9]{2})([,])([0-9]{3})/, '\1.\3')
      srt_content.gsub!("\r\n", "\n")
      self.webvtt_content = "WEBVTT\n\n#{srt_content}".strip
    end
  end
end
