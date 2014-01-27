#
# Copyright (C) 2013 Instructure, Inc.
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

class Quizzes::QuizRegrader::AttemptVersion

  attr_reader :version, :question_regrades

  def initialize(hash)
    @version = hash.fetch(:version)
    @question_regrades = hash.fetch(:question_regrades)
  end

  def regrade!
    version.model = Quizzes::QuizRegrader::Submission.new(
      :submission => version.model,
      :question_regrades => question_regrades).rescored_submission
      version.save!
  end

end
