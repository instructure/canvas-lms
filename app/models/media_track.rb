# frozen_string_literal: true

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
  belongs_to :media_object, touch: true
  belongs_to :attachment
  before_validation :add_attachment_id
  before_save :convert_srt_to_wvtt
  validates :media_object_id, presence: true
  validates :kind, inclusion: { in: %w[subtitles captions descriptions chapters metadata] }
  validates :locale, format: { with: /\A[A-Za-z-]+\z/ }
  validates :content, presence: true
  validates :locale, uniqueness: { scope: :attachment_id }, unless: proc { |mt| mt.attachment_id.blank? }

  RE_LOOKS_LIKE_TTML = /<tt\s+xml/i.freeze
  validates :content, format: {
    without: RE_LOOKS_LIKE_TTML,
    message: "TTML tracks are not allowed because they are susceptible to xss attacks"
  }

  def add_attachment_id
    self.attachment_id = media_object.attachment_id
  end

  def webvtt_content
    read_attribute(:webvtt_content) || content
  end

  def convert_srt_to_wvtt
    if content.exclude?("WEBVTT") && (content_changed? || read_attribute(:webvtt_content).nil?)
      srt_content = content.dup
      srt_content.gsub!(/(:|^)(\d)(,|:)/, '\10\2\3')
      srt_content.gsub!(/([0-9]{2}:[0-9]{2}:[0-9]{2})(,)([0-9]{3})/, '\1.\3')
      srt_content.gsub!("\r\n", "\n")
      self.webvtt_content = "WEBVTT\n\n#{srt_content}".strip
    end
  end
end
