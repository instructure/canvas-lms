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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe QuizQuestion do
  
  it "should deserialize its json data" do
    answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
    qd = {'name' => 'test question', 'question_type' => 'multiple_choice_question', 'answers' => answers}
    a = AssessmentQuestion.create!
    q = QuizQuestion.create(:question_data => qd, :assessment_question => a)
    q.question_data.should_not be_nil
    q.assessment_question_id.should eql(a.id)
    q.question_data == qd

    data = q.data
    data[:assessment_question_id].should eql(a.id)
    data[:answers].should_not be_empty
    data[:answers].length.should eql(2)
    data[:answers][0][:weight].should eql(100)
    data[:answers][1][:weight].should eql(0.0)
  end
end
