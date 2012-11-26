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

module Api::V1::Quiz
  include Api::V1::Json

  def quizzes_json(quizzes, context, user, session)
    quizzes.map do |quiz|
      quiz_json(quiz, context, user, session)
    end
  end

  def quiz_json(quiz, context, user, session)
    api_json(quiz, user, session, :only => %w(id title)).merge(
      :html_url => polymorphic_url([context, quiz])
    )
  end

end
