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
    course
    bank = @course.assessment_question_banks.create!
    a = bank.assessment_questions.create!
    q = QuizQuestion.create(:question_data => qd, :assessment_question => a)
    q.question_data.should_not be_nil
    q.question_data.class.should == HashWithIndifferentAccess
    q.assessment_question_id.should eql(a.id)
    q.question_data == qd

    data = q.data
    data[:assessment_question_id].should eql(a.id)
    data[:answers].should_not be_empty
    data[:answers].length.should eql(2)
    data[:answers][0][:weight].should eql(100)
    data[:answers][1][:weight].should eql(0.0)
  end

  describe "#question_data=" do
    before do
      course_with_teacher
      course.root_account.enable_quiz_regrade!

      @quiz = @course.quizzes.create

      @data = {:question_name   => 'test question',
               :points_possible => '1',
               :question_type   => 'multiple_choice_question',
               :answers         => {'answer_0' => {'answer_text' => '1', 'id' => 1},
                                    'answer_1' => {'answer_text' => '2', 'id' => 2},
                                    'answer_1' => {'answer_text' => '3', 'id' => 3},
                                    'answer_1' => {'answer_text' => '4', 'id' => 4}}}
      @question = @quiz.quiz_questions.create(:question_data => @data)
    end

    it "should save regrade if passed in regrade option in data hash" do
      QuizQuestionRegrade.first.should be_nil

      QuizRegrade.create(quiz_id: @quiz.id, user_id: @user.id, quiz_version: @quiz.version_number)
      @question.question_data = @data.merge(:regrade_option => 'full_credit',
                                            :regrade_user   => @user)
      @question.save

      question_regrade = QuizQuestionRegrade.first
      question_regrade.should be
      question_regrade.regrade_option.should == 'full_credit'
    end
  end

  context "migrate_question_hash" do
    before do
      course_with_teacher
      @orig_course = Course.create
      @attachment_count = 0
      attachment_tag = lambda {
        a = @orig_course.attachments.build(:filename => "foo-#{@attachment_count += 1}.gif")
        a.content_type = 'image/gif'
        a.save!
        "<img src=\"/courses/#{@orig_course.id}/files/#{a.id}/download\">"
      }
      data = {
        :name => 'test question',
        :question_type => 'multiple_choice_question',
        :question_text => "which ones are like this one? #{attachment_tag.call}",
        :correct_comments => "yay! #{attachment_tag.call}",
        :incorrect_comments => "boo! #{attachment_tag.call}",
        :neutral_comments => "meh. #{attachment_tag.call}",
        :text_after_answers => "oh btw #{attachment_tag.call}",
        :answers => [
          {:weight => 1, :text => "A", :html => "A #{attachment_tag.call}", :comments_html => "yeppers #{attachment_tag.call}"},
          {:weight => 1, :text => "B", :html => "B #{attachment_tag.call}", :comments_html => "yeppers #{attachment_tag.call}"},
          {:weight => 0, :text => "C", :html => "C #{attachment_tag.call}", :comments_html => "nope #{attachment_tag.call}"},
          {:weight => 0, :text => "D", :html => "D #{attachment_tag.call}", :comments_html => "nope #{attachment_tag.call}"}
        ]
      }
      @quiz = @orig_course.quizzes.create
      @quiz_question = @quiz.quiz_questions.build
      @quiz_question.write_attribute(:question_data, data)
      @quiz_question.save!
      @quiz_question.question_data.class.should == HashWithIndifferentAccess
    end

    def confirm_all_migrations(result)
      @orig_data = @quiz_question.reload.question_data
      [:question_text, :correct_comments, :incorrect_comments, :neutral_comments, :text_after_answers].each do |key|
        confirm_migration(@orig_data[key], result[key])
      end
      result[:answers].each_with_index do |answer, i|
        [:html, :comments_html].each do |key|
          confirm_migration(@orig_data[:answers][i][key], answer[key])
        end
      end
    end

    def confirm_migration(old, new)
      new.should_not eql old
      new.gsub(/<[^>]+>/, '').should eql old.gsub(/<[^>]+>/, '')
      new.should match(%r{/courses/#{@course.id}/files/\d+/download})
    end

    it "should migrate all content to the new context" do
      expect {
        result = QuizQuestion.migrate_question_hash @quiz_question.question_data, :old_context => @orig_course, :new_context => @course
        confirm_all_migrations(result)
      }.to change(Attachment, :count).by(@attachment_count)
    end

    it "should migrate all content the user has rights to" do
      # no change, since the user can't access the orig course (yet)
      expect {
        result = QuizQuestion.migrate_question_hash @quiz_question.question_data, :context => @course, :user => @user
      }.to change(Attachment, :count).by(0)

      @orig_course.enroll_teacher(@user)
      @orig_course.reload
      expect {
        result = QuizQuestion.migrate_question_hash @quiz_question.question_data, :context => @course, :user => @user
        confirm_all_migrations(result)
      }.to change(Attachment, :count).by(@attachment_count)
    end
  end
end
