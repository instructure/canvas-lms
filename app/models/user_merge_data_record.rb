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
#
class UserMergeDataRecord < ActiveRecord::Base
  belongs_to :previous_user, class_name: "User"
  belongs_to :merge_data, class_name: "UserMergeData", inverse_of: :records, foreign_key: "user_merge_data_id"
  belongs_to :context, polymorphic: [:account_user,
                                     :enrollment,
                                     :pseudonym,
                                     :user_observer,
                                     :user_observation_link,
                                     :attachment,
                                     :communication_channel,
                                     :user_service,
                                     :submission,
                                     { quiz_submission: "Quizzes::QuizSubmission" },
                                     :assignment_override_student]
end
