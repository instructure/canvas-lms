#
# Copyright (C) 2019 - present Instructure, Inc.
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

class SubmissionDraft < ActiveRecord::Base
  belongs_to :submission, inverse_of: :submission_drafts
  belongs_to :media_object, primary_key: :media_id
  has_many :submission_draft_attachments, inverse_of: :submission_draft, dependent: :delete_all
  has_many :attachments, through: :submission_draft_attachments

  validates :submission, presence: true
  validates :submission_attempt, numericality: { only_integer: true }
  validates :submission, uniqueness: { scope: :submission_attempt }
  validates :body, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}
  validate :submission_attempt_matches_submission
  validates :url, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}
  validate :media_object_id_matches_media_object

  before_save :validate_url

  def validate_url
    if self.url.present?
      begin
        # also updates the url with a scheme if missing and is a valid url
        # otherwise leaves the url as whatever the user submitted as thier draft
        value, = CanvasHttp.validate_url(self.url)
        self.send("url=", value)
      rescue URI::Error, ArgumentError
        return
      end
    end
  end

  def media_object_id_matches_media_object
    if self.media_object_id.present? && self.media_object.blank?
      err = I18n.t('the media_object_id must match an existing media object')
      errors.add(:media_object_id, err)
    end
  end
  private :media_object_id_matches_media_object

  def submission_attempt_matches_submission
    current_submission_attempt = self.submission&.attempt || 0
    this_submission_attempt = self.submission_attempt || 0
    if this_submission_attempt > (current_submission_attempt + 1)
      err = I18n.t('submission draft cannot be more then one attempt ahead of the current submission')
      errors.add(:submission_draft_attempt, err)
    end
  end
  private :submission_attempt_matches_submission

  def meets_media_recording_criteria?
    self.media_object_id.present?
  end

  def meets_text_entry_criteria?
    self.body.present?
  end

  def meets_upload_criteria?
    self.attachments.present?
  end

  def meets_url_criteria?
    return false if self.url.blank?
    begin
      CanvasHttp.validate_url(self.url)
      true
    rescue URI::Error, ArgumentError
      false
    end
  end

  # this checks if any type on the assignment is drafted
  def meets_assignment_criteria?
    submission_types = self.submission.assignment.submission_types.split(',')
    submission_types.each do |type|
      case type
      when 'media_recording'
        return true if meets_media_recording_criteria?
      when 'online_text_entry'
        return true if meets_text_entry_criteria?
      when 'online_upload'
        return true if meets_upload_criteria?
      when 'online_url'
        return true if meets_url_criteria?
      end
    end

    false
  end
end
