#
# Copyright (C) 2012 Instructure, Inc.
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

class Quizzes::QuizQuestion::FileUploadAnswer < Quizzes::QuizQuestion::UserAnswer
  def initialize(question_id, points_possible, answer_data)
    super(question_id, points_possible, answer_data)
    self.answer_details = {:attachment_ids => attachment_ids}
  end

  def attachment_ids
    return nil unless data = @answer_data["question_#{question_id}".to_sym]
    ids = data.select(&:present?)
    ids.present? ? ids : nil
  end
end
