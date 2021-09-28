# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

Rails.configuration.to_prepare do
  reflection = Version.reflections['versionable']
  reflection.options[:exhaustive] = false
  reflection.options[:polymorphic] = [
    :assessment_question,
    :assignment,
    :assignment_override,
    :learning_outcome_question_result,
    :learning_outcome_result,
    :rubric,
    :rubric_assessment,
    :submission,
    :wiki_page,
    { quiz: 'Quizzes::Quiz',
      quiz_submission: 'Quizzes::QuizSubmission' }]
  Version.add_polymorph_methods(reflection)

  Version.include(CanvasPartman::Concerns::Partitioned)
  Version.partitioning_strategy = :by_id
  Version.partitioning_field = 'versionable_id'
  Version.partition_size = 5_000_000
end
