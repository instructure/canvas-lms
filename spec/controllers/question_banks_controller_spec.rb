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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionBanksController do
  describe "move_questions" do
    before do
      course_with_teacher_logged_in
      @bank1 = @course.assessment_question_banks.create!
      @bank2 = @course.assessment_question_banks.create!
      @question1 = @bank1.assessment_questions.create!
      @question2 = @bank1.assessment_questions.create!
    end

    it "should copy questions" do
      post 'move_questions', :course_id => @course.id, :question_bank_id => @bank1.id, :assessment_question_bank_id => @bank2.id, :questions => { @question1.id => 1, @question2.id => 1 }
      response.should be_success

      @bank1.reload
      @bank1.assessment_questions.count.should == 2
      @bank2.assessment_questions.count.should == 2
    end

    it "should move questions" do
      post 'move_questions', :course_id => @course.id, :question_bank_id => @bank1.id, :assessment_question_bank_id => @bank2.id, :move => '1', :questions => { @question1.id => 1, @question2.id => 1 }
      response.should be_success

      @bank1.reload
      @bank1.assessment_questions.count.should == 0
      @bank2.assessment_questions.count.should == 2
    end
  end
end
