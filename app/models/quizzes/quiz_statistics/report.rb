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

class Quizzes::QuizStatistics::Report
  extend Forwardable

  attr_reader :quiz_statistics

  def_delegators :quiz_statistics,
    :quiz,
    :includes_all_versions?,
    :includes_sis_ids?,
    :anonymous?,
    :update_progress,
    :t

  def initialize(quiz_statistics)
    @quiz_statistics = quiz_statistics
  end

  def generatable?
    true
  end

  def readable_type
    self.class.name.demodulize.underscore
  end
end
