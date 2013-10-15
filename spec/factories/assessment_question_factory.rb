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

def assessment_question_model(opts={})
  opts.delete(:bank).assessment_questions.create!(valid_assessment_question_attributes.merge(opts))
end

def valid_assessment_question_attributes
  {
    :name => "value for name",
    :question_data => {
      :incorrect_comments=>"",
      :question_name=>"Factory Question",
      :question_type=>"multiple_dropdowns_question",
      :neutral_comments=>"",
      :points_possible=>1,
      :question_text=>"<p>does [a] equal [b] ?</p>",
      :answers=>[{:comments=>"", :blank_id=>"a", :id=>626, :text=>"a1", :weight=>100}, {:comments=>"", :blank_id=>"a", :id=>1192, :text=>"a2", :weight=>0}, {:comments=>"", :blank_id=>"b", :id=>1946, :text=>"a3", :weight=>100}, {:comments=>"", :blank_id=>"b", :id=>1511, :text=>"b1", :weight=>0}],
      :name=>"Question",
      :correct_comments=>"",
    },
  }
end
