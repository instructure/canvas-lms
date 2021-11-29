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

class Quizzes::QuizQuestionRegrade < ActiveRecord::Base
  self.table_name = "quiz_question_regrades"

  belongs_to :quiz_question, class_name: "Quizzes::QuizQuestion"
  belongs_to :quiz_regrade, class_name: "Quizzes::QuizRegrade"

  validates :quiz_question_id, presence: true
  validates :quiz_regrade_id, presence: true

  delegate :question_data, to: :quiz_question
end
