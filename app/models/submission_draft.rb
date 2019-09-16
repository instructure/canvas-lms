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
  has_many :submission_draft_attachments, inverse_of: :submission_draft, dependent: :delete_all
  has_many :attachments, through: :submission_draft_attachments

  validates :submission, presence: true
  validates :submission_attempt, numericality: { only_integer: true }
  validates :submission, uniqueness: { scope: :submission_attempt }
  validates :body, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}
  validate :submission_attempt_matches_submission
  validates :url, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}

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

  def submission_attempt_matches_submission
    current_submission_attempt = self.submission&.attempt || 0
    this_submission_attempt = self.submission_attempt || 0
    if this_submission_attempt > (current_submission_attempt + 1)
      err = 'submission draft cannot be more then one attempt ahead of the current submission'
      errors.add(:submission_draft_attempt, err)
    end
  end
  private :submission_attempt_matches_submission

  def meets_assignment_criteria?
    # we just need to meet draft criteria for a single type to be valid
    submission_types = self.submission.assignment.submission_types.split(',')
    submission_types.each do |type|
      case type
      when 'online_text_entry'
        return true if self.body.present?
      when 'online_upload'
        return true if self.attachments.present?
      when 'online_url'
        return false if self.url.blank?
        begin
          CanvasHttp.validate_url(self.url)
          return true
        rescue URI::Error, ArgumentError
          return false
        end
      end
    end

    # return false if we did not meet our draft requirements for any of the types
    false
  end
end
