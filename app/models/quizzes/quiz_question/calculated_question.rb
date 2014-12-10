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

class Quizzes::QuizQuestion::CalculatedQuestion < Quizzes::QuizQuestion::NumericalQuestion
  def answers
    answer = @question_data.answers.first
    return [] unless answer
    return [{:id => answer[:id], :numerical_answer_type => "exact_answer", :exact => answer[:answer], :margin => @question_data[:answer_tolerance]}]
  end

  # TODO: remove once new stats is on for everybody
  # returns @question_data augmented with statistical data
  # mutates responses with statistical data
  # also potentially mutates @question_data[:answers]
  def stats(responses)
    #@question_data[:answers]:
    #[{"weight"=>100,
    #  "variables"=>[{"name"=>"x", "value"=>4}, {"name"=>"y", "value"=>3}],
    #  "answer"=>6,
    #  "id"=>9339,
    #  "responses"=>0,
    #  "user_ids"=>[]},
    # {"weight"=>100,
    #  "variables"=>[{"name"=>"x", "value"=>9}, {"name"=>"y", "value"=>7}],
    #  "answer"=>7,
    #  "id"=>1200,
    #  "responses"=>0,
    #  "user_ids"=>[]}]
    #
    # example response:
    # {:correct=>true,
    #  :points=>1,
    #  :question_id=>1023,
    #  :answer_id=>9339,
    #  :text=>"6.0000",
    #  :user_id=>3}
    responses.each do |r|
      answer = @question_data.answers.detect { |a| r[:answer_id] == a[:id] }
      next unless answer

      answer[:responses] += 1
      answer[:user_ids] << r[:user_id]

      answer[:numbers] ||= {}
      answer_stats = answer[:numbers][r[:text].to_f] ||= {
        :responses => 1,
        :user_ids => [],
        :correct => true,
      }
      answer_stats[:responses] += 1
      answer_stats[:user_ids] << r[:user_id]
    end

    stats = {:multiple_responses => true}
    @question_data.merge stats
  end
end
