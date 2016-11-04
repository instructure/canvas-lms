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

describe AssessmentQuestionBank do
  before :once do
    course
    assessment_question_bank_model
    @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
  end

  describe "#select_for_submission" do
    before :once do
      assessment_question_bank_with_questions
      @quiz = @course.quizzes.create!(:title => "some quiz")
      @group = @quiz.quiz_groups.create!(:name => "question group", :pick_count => 3, :question_points => 5.0)
      @group.assessment_question_bank = @bank
      @group.save
    end

    after(:each) do
      Timecop.return
    end

    it "should return the desired count of questions" do
      expect(@bank.select_for_submission(@quiz.id, nil, 0).length).to eq 0
      expect(@bank.select_for_submission(@quiz.id, nil, 2).length).to eq 2
      expect(@bank.select_for_submission(@quiz.id, nil, 4).length).to eq 4
      expect(@bank.select_for_submission(@quiz.id, nil, 11).length).to eq 10
    end

    it "should exclude specified questions" do
      [@q1.id, @q2.id, @q3.id, @q4.id, @q5.id, @q6.id, @q7.id, @q8.id, @q9.id, @q10.id]
      selected_ids = @bank.select_for_submission(@quiz.id, nil, 10, [@q1.id, @q10.id]).map(&:assessment_question_id)

      expect(selected_ids.include?(@q1.id)).to be_falsey
      expect(selected_ids.include?(@q10.id)).to be_falsey
      expect(selected_ids.include?(@q2.id)).to be_truthy
      expect(selected_ids.include?(@q9.id)).to be_truthy
    end

    it "should return the questions in a random order" do
      original = [@q1.id, @q2.id, @q3.id, @q4.id, @q5.id, @q6.id, @q7.id, @q8.id, @q9.id, @q10.id]

      selected1 = @bank.select_for_submission(@quiz.id, nil, 10).map(&:id)
      selected2 = @bank.select_for_submission(@quiz.id, nil, 10).map(&:id)

      # make sure at least one is shuffled
      is_shuffled1 = (original != selected1)
      is_shuffled2 = (original != selected2)

      # it's possible but unlikely that shuffled version is same as original
      expect(is_shuffled1 || is_shuffled2).to be_truthy
    end

    it "should pick randomly quiz group questions in the db" do
      aq_ids = []
      20.times do
        aq_ids << @bank.select_for_submission(@quiz.id, nil, 1).first.assessment_question_id
      end
      # shouldn't pick the same one over and over again
      # yes, technically there's a 0.000000000000000001% chance this will fail spontaneously - sue me
      expect(aq_ids.uniq.count > 1).to be_truthy
    end
  end

  it "should allow user read access through question bank users" do
    user
    @bank.assessment_question_bank_users.create!(:user => user)
    expect(@course.grants_right?(@user, :manage_assignments)).to be_falsey
    expect(@bank.grants_right?(@user, :read)).to be_truthy
  end

  it "should remove outcome alignments when deleted" do
    outcome_model(:context => @course)
    @bank.alignments = { @outcome.id => 0.5 }

    @bank.reload
    expect(@bank.learning_outcome_alignments).to be_present
    expect(@bank.learning_outcome_alignments.first.learning_outcome_id).to eq @outcome.id

    # regular save shouldn't mess with alignments
    @bank.save!
    @bank.reload
    expect(@bank.learning_outcome_alignments).to be_present
    expect(@bank.learning_outcome_alignments.first.learning_outcome_id).to eq @outcome.id

    @bank.destroy
    @bank.reload
    expect(@bank.learning_outcome_alignments).to be_empty
  end
end
