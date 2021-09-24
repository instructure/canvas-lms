# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Submissions
  class AttachmentForSubmissionDownload
    def initialize(submission, options={})
      @submission = submission
      @options = options
    end
    attr_reader :submission, :options

    def attachment
      raise ActiveRecord::RecordNotFound unless download_id.present?
      return attachment_from_submission_comment ||
        attachment_belonging_to_submission ||
        prior_attachment ||
        attachment_from_submission_attachments ||
        attachment_from_versioned_attachments
    end

    private
    def attachment_belonging_to_submission
      submission.attachment_id == download_id && submission.attachment
    end

    def attachment_from_submission_attachments
      submission.attachments.where(id: download_id).first
    end

    def attachment_from_submission_comment
      return nil unless comment_id.present?
      submission.all_submission_comments.find(comment_id).attachments.find do |attachment|
        attachment.id == download_id
      end
    end

    def attachment_from_versioned_attachments
      submission.submission_history.map(&:versioned_attachments).flatten.find do |attachment|
        attachment.id == download_id
      end
    end

    def comment_id
      options[:comment_id]
    end

    def download_id
      options[:download].nil? ? options[:download] : options[:download].to_i
    end

    def prior_attachment
      prior_attachment_id.present? && Attachment.where(id: prior_attachment_id).first
    end

    def prior_attachment_id
      @_prior_attachment_id ||= submission.submission_history.map(&:attachment_id).find do |attachment_id|
        attachment_id == download_id
      end
    end
  end
end
