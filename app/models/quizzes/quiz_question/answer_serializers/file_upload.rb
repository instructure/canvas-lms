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

module Quizzes::QuizQuestion::AnswerSerializers
  class FileUpload < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    # @example output where the question ID is 5
    # {
    #   question_5_answer: "123"
    # }
    def serialize(*args)
      rc = SerializedAnswer.new

      rc.answer[question_key] = args
      rc
    end

    # @return [String|NilClass]
    #   ID of the attachment for the file that was uploaded, if any.
    #
    # @example output for uploading a file that was stored in an attachment with
    #          the id of "3":
    #   "3"
    #
    # @example output for not uploading any file:
    #   null
    def deserialize(submission_data, full: false)
      # when this is present, it would be an array, but it always includes 1
      # ID (or none, in which case it would contain 1 item which is '')
      attachment_ids = Array(submission_data[question_key]).compact_blank

      if attachment_ids.present?
        attachment_ids.first
      end
    end
  end
end
