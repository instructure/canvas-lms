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

  def create_course_with_two_question_banks!
    course_with_teacher(active_all: true)
    @bank1 = @course.assessment_question_banks.create!
    @bank2 = @course.assessment_question_banks.create!
    @question1 = @bank1.assessment_questions.create!
    @question2 = @bank1.assessment_questions.create!
  end

  describe "GET / (#index)" do

    before { create_course_with_two_question_banks!; user_session(@teacher) }

    it "only includes active question banks" do
      @bank3 = @course.account.assessment_question_banks.create!
      @bank3.destroy
      res = get 'index', controller: :question_banks, inherited: '1',course_id: @course.id, format: 'json'
      expect(response).to be_success
      json = json_parse(response.body)
      expect(json.size).to eq 2
      expect(json.detect { |bank|
        bank["assessment_question_bank"]["id"] == @bank3.id
      }).to be_nil
    end
  end

  describe "move_questions" do

    before(:once) { create_course_with_two_question_banks! }
    before(:each) { user_session(@teacher) }

    it "should copy questions" do
      post 'move_questions', :course_id => @course.id, :question_bank_id => @bank1.id, :assessment_question_bank_id => @bank2.id, :questions => { @question1.id => 1, @question2.id => 1 }
      expect(response).to be_success

      @bank1.reload
      expect(@bank1.assessment_questions.count).to eq 2
      expect(@bank2.assessment_questions.count).to eq 2
    end

    it "should move questions" do
      post 'move_questions', :course_id => @course.id, :question_bank_id => @bank1.id, :assessment_question_bank_id => @bank2.id, :move => '1', :questions => { @question1.id => 1, @question2.id => 1 }
      expect(response).to be_success

      @bank1.reload
      expect(@bank1.assessment_questions.count).to eq 0
      expect(@bank2.assessment_questions.count).to eq 2
    end
  end

  describe "bookmark" do
    before :once do
      course_with_teacher
      @bank = @course.assessment_question_banks.create!
    end

    before :each do
      user_session(@teacher)
    end

    it "bookmarks" do
      post 'bookmark', :course_id => @course.id,
                       :question_bank_id => @bank.id
      expect(response).to be_success
      expect(@teacher.reload.assessment_question_banks).to include @bank
    end

    it "unbookmarks" do
      @teacher.assessment_question_banks << @bank
      @teacher.save!

      # should work even if the bank's context is destroyed
      @course.destroy

      post 'bookmark', :course_id => @course.id,
                       :question_bank_id => @bank.id,
                       :unbookmark => 1
      expect(response).to be_success
      expect(@teacher.reload.assessment_question_banks).not_to include @bank
    end
  end
end
