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
  include MasterCourses::CollectionRestrictor
  self.collection_owner_association = :attachment

  belongs_to :user
  belongs_to :media_object, touch: true
  belongs_to :attachment
  belongs_to :master_content_tags, class_name: "MasterCourses::MasterContentTag", dependent: :destroy

  before_validation :set_media_and_attachment
  before_save :convert_srt_to_wvtt
  before_create :mark_downstream_create_destroy
  before_update :mark_downstream_changes
  before_destroy :mark_downstream_create_destroy
  before_destroy :check_for_restricted_updates, prepend: true
  validates :media_object_id, presence: true
  validates :kind, inclusion: { in: %w[subtitles captions descriptions chapters metadata] }
  validates :content, presence: true
  validates :locale, format: { with: /\A[A-Za-z-]+\z/ }, uniqueness: { scope: :attachment_id, unless: ->(mt) { mt.attachment_id.blank? } }
  restrict_columns :content, %i[attachment_id content locale media_object_id webvtt_content]

  RE_LOOKS_LIKE_TTML = /<tt\s+xml/i
  validates :content, format: {
    without: RE_LOOKS_LIKE_TTML,
    message: -> { t("TTML tracks are not allowed because they are susceptible to xss attacks") }
  }

  # MasterCourses::CollectionRestrictor handles soft-deletes, but doesn't handle
  # hard deletes well. One day we  might want to standardize this to more hard
  # deleted objects.
  def check_for_restricted_updates
    return true if skip_restrictions? || attachment&.skip_restrictions?
    return unless attachment&.child_content_restrictions&.dig(:content)

    raise "cannot change column: captions - locked by Master Course"
  end

  def set_media_and_attachment
    self.attachment_id ||= media_object.attachment_id
    self.media_object_id ||= attachment.media_object_by_media_id
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
