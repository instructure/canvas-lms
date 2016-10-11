# coding: utf-8
#
# Copyright (C) 2011 Instructure, Inc.
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

module Factories
  def assessment_question_bank_model
    @course ||= course_model(:reusable => true)
    @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
  end

  def assessment_question_bank_with_questions
    @bank ||= assessment_question_bank_model

    # create a bunch of questions to make it more likely that they'll shuffle randomly
    # define @q1..@q10
    (1..10).each do |i|
      q = @bank.assessment_questions.create!(
        :question_data => {
          'name' => "test question #{i}",
          'points_possible' => 10,
          'answers' => [{'id' => 1}, {'id' => 2}]
        }
      )
      instance_variable_set("@q#{i}", q)
    end

    @bank
  end
end
