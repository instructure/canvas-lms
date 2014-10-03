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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizQuestionLinkMigrator do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  before :each do
    Quizzes::QuizQuestionLinkMigrator.reset_cache!
  end

  context "for_each_interesting_field" do
    it "should yield for each interesting root-level field" do
      data = {
        :question_text => "question text",
        :correct_comments => "correct comments",
        :incorrect_comments => "incorrect comments",
        :neutral_comments => "neutral comments"
      }
      yielded = []
      Quizzes::QuizQuestionLinkMigrator.for_each_interesting_field(data) do |field|
        yielded << field
      end
      yielded.sort.should == data.values.sort
    end

    it "should yield for each answers comments" do
      data = {:answers => [
        {:comments => "first answer comments"},
        {:comments => "second answer comments"},
        {:comments => "third answer comments"}
      ]}
      yielded = []
      Quizzes::QuizQuestionLinkMigrator.for_each_interesting_field(data) do |field|
        yielded << field
      end
      yielded.sort.should == data[:answers].map{ |a| a[:comments] }.sort
    end

    it "should not yield empty fields" do
      data = {
        :question_text => "question text",
        :correct_comments => "",
        :incorrect_comments => nil,
        :answers => [
          {:comments => "first answer comments"},
          {:comments => ""},
          {:comments => nil}
        ]
      }
      yielded = []
      Quizzes::QuizQuestionLinkMigrator.for_each_interesting_field(data) do |field|
        yielded << field
      end
      yielded.sort.should == [data[:question_text], data[:answers].first[:comments]].sort
    end

    it "should not yield irrelevant fields" do
      data = {
        :question_text => "question text",
        :irrelevant_comments => "irrelevant comments",
        :answers => [
          {:comments => "first answer comments"},
          {:garbage => "garbage"}
        ]
      }
      yielded = []
      Quizzes::QuizQuestionLinkMigrator.for_each_interesting_field(data) do |field|
        yielded << field
      end
      yielded.sort.should == [data[:question_text], data[:answers].first[:comments]].sort
    end
  end

  context "related_attachment_ids" do
    before :once do
      @course = course_model
      @file = @course.attachments.new(:filename => 'foo.txt')
      @file.content_type = 'text/plain'
      @file.save!
    end

    it "should include the input" do
      ids = Quizzes::QuizQuestionLinkMigrator.related_attachment_ids(@file.id)
      ids.should include(@file.id)
    end

    it "should include files for the same cloned_item" do
      @file.cloned_item = ClonedItem.create(:original_item => @file)
      @file.save!

      @new_file = @course.attachments.new(:filename => 'bar.txt')
      @new_file.content_type = 'text/plain'
      @new_file.cloned_item = @file.cloned_item
      @new_file.save!

      ids = Quizzes::QuizQuestionLinkMigrator.related_attachment_ids(@file.id)
      ids.should include(@new_file.id)
    end

    it "should include files derived from the input" do
      @new_file = @course.attachments.new(:filename => 'bar.txt')
      @new_file.content_type = 'text/plain'
      @new_file.root_attachment_id = @file.id
      @new_file.save!

      ids = Quizzes::QuizQuestionLinkMigrator.related_attachment_ids(@file.id)
      ids.should include(@new_file.id)
    end

    it "should include files the input is derived from" do
      @new_file = @course.attachments.new(:filename => 'bar.txt')
      @new_file.content_type = 'text/plain'
      @new_file.save!

      @file.root_attachment_id = @new_file.id
      @file.save!

      ids = Quizzes::QuizQuestionLinkMigrator.related_attachment_ids(@file.id)
      ids.should include(@new_file.id)
    end

    it "should include files derived from the same file the input is derived from" do
      @root_file = @course.attachments.new(:filename => 'bar.txt')
      @root_file.content_type = 'text/plain'
      @root_file.save!

      @file.root_attachment_id = @root_file.id
      @file.save!

      @other_file = @course.attachments.new(:filename => 'baz.txt')
      @other_file.content_type = 'text/plain'
      @other_file.root_attachment_id = @root_file.id
      @other_file.save!

      ids = Quizzes::QuizQuestionLinkMigrator.related_attachment_ids(@file.id)
      ids.should include(@other_file.id)
    end

    it "should only include each files once" do
      @file.cloned_item = ClonedItem.create(:original_item => @file)
      @file.save!

      @new_file = @course.attachments.new(:filename => 'bar.txt')
      @new_file.content_type = 'text/plain'
      @new_file.cloned_item = @file.cloned_item
      @new_file.root_attachment_id = @file.id
      @new_file.save!

      ids = Quizzes::QuizQuestionLinkMigrator.related_attachment_ids(@file.id)
      ids.select{ |id| id == @new_file.id }.size.should == 1
    end
  end

  context "migrate_file_link" do
    before :once do
      @course = course_model
      @quiz = @course.quizzes.create!
    end

    it "should pass links unchanged when the question has no assessment_question" do
      @question = @quiz.quiz_questions.create!(:question_data => {})
      @question.assessment_question.should be_nil
      link = '/courses/1/files/1/preview'
      new_link = Quizzes::QuizQuestionLinkMigrator.migrate_file_link(@question, link)
      new_link.should == link
    end

    context "with assessment questions" do
      before :once do
        @question = @quiz.quiz_questions.create!(:question_data => {:question_type => :multiple_choice})
        @question.assessment_question.should_not be_nil
      end

      let_once(:file) do
        file = @course.attachments.new(:filename => 'foo.txt')
        file.content_type = 'text/plain'
        file.save!
        file
      end

      it "should find links in the assessment question for related attachments" do
        new_file = @course.attachments.new(:filename => 'bar.txt')
        new_file.content_type = 'text/plain'
        new_file.root_attachment_id = file.id
        new_file.save!

        source_link = "/courses/#{@course.id}/files/#{file.id}/preview"
        target_link = "/assessment_questions/#{@question.assessment_question_id}/files/#{new_file.id}/download"
        @question.assessment_question.question_data[:question_text] = "Some text #{target_link} more text."
        @question.assessment_question.save!

        new_link = Quizzes::QuizQuestionLinkMigrator.migrate_file_link(@question, source_link)
        new_link.should == target_link
      end

      it "should look for links in more than the question text" do
        new_file = @course.attachments.new(:filename => 'bar.txt')
        new_file.content_type = 'text/plain'
        new_file.root_attachment_id = file.id
        new_file.save!

        source_link = "/courses/#{@course.id}/files/#{file.id}/preview"
        target_link = "/assessment_questions/#{@question.assessment_question_id}/files/#{new_file.id}/download"
        @question.assessment_question.question_data[:correct_comments] = "Some text #{target_link} more text."
        @question.assessment_question.save!

        new_link = Quizzes::QuizQuestionLinkMigrator.migrate_file_link(@question, source_link)
        new_link.should == target_link
      end

      it "should just pass the link through if the assessment question doesn't have a matching link" do
        # note I'm not linking file and new_file
        new_file = @course.attachments.new(:filename => 'bar.txt')
        new_file.content_type = 'text/plain'
        new_file.save!

        source_link = "/courses/#{@course.id}/files/#{file.id}/preview"
        unrelated_link = "/assessment_questions/#{@question.assessment_question_id}/files/#{new_file.id}/download"
        @question.assessment_question.question_data[:question_text] = "Some text #{unrelated_link} more text."
        @question.assessment_question.save!

        new_link = Quizzes::QuizQuestionLinkMigrator.migrate_file_link(@question, source_link)
        new_link.should == source_link
      end

      it "reuse cached translations" do
        new_file = @course.attachments.new(:filename => 'bar.txt')
        new_file.content_type = 'text/plain'
        new_file.root_attachment_id = file.id
        new_file.save!

        source_link = "/courses/#{@course.id}/files/#{file.id}/preview"
        target_link = "/assessment_questions/#{@question.assessment_question_id}/files/#{new_file.id}/download"
        @question.assessment_question.question_data[:question_text] = "Some text #{target_link} more text."
        @question.assessment_question.save!

        Quizzes::QuizQuestionLinkMigrator.migrate_file_link(@question, source_link)
        @question.assessment_question.question_data[:question_text] = ""
        @question.assessment_question.save!

        new_link = Quizzes::QuizQuestionLinkMigrator.migrate_file_link(@question, source_link)
        new_link.should == target_link
      end
    end
  end

  context "migrating" do
    before :once do
      @course1 = course_model
      @course2 = course_model
      @quiz = @course1.quizzes.create!
      @question = @quiz.quiz_questions.create!(:question_data => {:question_type => :multiple_choice})
    end

    let_once :file do
      # we'll just use this one file everywhere
      file = @course2.attachments.new(:filename => 'foo.txt')
      file.content_type = 'text/plain'
      file.save!
      file
    end

    # using the wrong course in source link
    let_once(:source_link) { "/courses/#{@course2.id}/files/#{file.id}/preview" }
    let_once(:target_link) { "/assessment_questions/#{@question.assessment_question_id}/files/#{file.id}/download" }
    let_once(:source_blob) { "Some question text #{source_link} more text" }
    let_once(:assessment_text) { "Some assessment text #{target_link} more text" }
    let_once(:target_blob) { "Some question text #{target_link} more text" }

    context "migrate_file_links_in_blob" do
      it "should migrate links for the wrong course" do

        @question.assessment_question.question_data[:question_text] = assessment_text
        @question.assessment_question.save!

        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_blob(source_blob, @question, @question.quiz)
        source_blob.should == target_blob
      end

      it "should not migrate links for the correct course" do
        file = @course1.attachments.new(:filename => 'foo.txt')
        file.content_type = 'text/plain'
        file.save!

        # using the right course in source link
        source_link = "/courses/#{@course1.id}/files/#{file.id}/preview"
        irrelevant_link = "/assessment_questions/#{@question.assessment_question_id}/files/#{file.id}/download"
        source_blob = "Some question text #{source_link} more text"
        assessment_text = "Some assessment text #{irrelevant_link} more text"

        @question.assessment_question.question_data[:question_text] = assessment_text
        @question.assessment_question.save!

        # done this way because the modification is in place
        original_blob = source_blob.dup
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_blob(source_blob, @question, @question.quiz)
        source_blob.should == original_blob
      end

      it "should return true iff a link was migrated" do
        @question.assessment_question.question_data[:question_text] = assessment_text
        @question.assessment_question.save!

        # first time true, second time false because it's already migrated
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_blob(source_blob, @question, @question.quiz).should be_true
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_blob(source_blob, @question, @question.quiz).should be_false
      end
    end

    context "migrate_file_links_in_question_data" do
      before :once do
        @question.assessment_question.question_data[:question_text] = assessment_text
        @question.assessment_question.save!
      end

      it "should migrate links in each interesting field" do
        question_data = {
          :question_text => source_blob.dup,
          :correct_comments => source_blob.dup,
          :incorrect_comments => source_blob.dup,
          :neutral_comments => source_blob.dup,
          :answers => [{:comments => source_blob.dup}]
        }

        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_question_data(question_data, :question => @question)
        question_data[:question_text].should == target_blob
        question_data[:correct_comments].should == target_blob
        question_data[:incorrect_comments].should == target_blob
        question_data[:neutral_comments].should == target_blob
        question_data[:answers].first[:comments].should == target_blob
      end

      it "should infer the contextual question from the question_data" do
        question_data = { :question_text => source_blob.dup, :id => @question.id }
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_question_data(question_data)
        question_data[:question_text].should == target_blob
      end

      it "should return true iff a link was migrated" do
        question_data = {
          :question_text => source_blob.dup,
          :correct_comments => source_blob.dup,
          :incorrect_comments => source_blob.dup,
          :neutral_comments => source_blob.dup,
          :answers => [{:comments => source_blob.dup}]
        }

        # first time true, second time false because it's already migrated
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_question_data(question_data, :question => @question).should be_true
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_question_data(question_data, :question => @question).should be_false
      end
    end

    context "migrate_file_links_in_question" do
      before :once do
        @question.assessment_question.question_data[:question_text] = assessment_text
        @question.assessment_question.save!
      end

      it "should migrate links in the question's data" do
        qd = @question.question_data
        qd[:question_text] = source_blob.dup
        @question.question_data = qd

        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_question(@question)
        @question.question_data[:question_text].should == target_blob
      end

      it "should return true iff a question was migrated" do
        qd = @question.question_data
        qd[:question_text] = source_blob.dup
        @question.question_data = qd

        # first time true, second time false because it's already migrated
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_question(@question).should be_true
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_question(@question).should be_false
      end
    end

    context "migrate_file_links_in_quiz" do
      before :once do
        @question.assessment_question.question_data[:question_text] = assessment_text
        @question.assessment_question.save!
      end

      it "should migrate links each question in the quiz's data" do
        @quiz.quiz_data = [
          {:question_type => :multiple_choice, :question_text => source_blob.dup, :id => @question.id},
          {:question_type => :multiple_choice, :question_text => source_blob.dup, :id => @question.id},
          {:question_type => :multiple_choice, :question_text => source_blob.dup, :id => @question.id}
        ]

        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_quiz(@quiz)
        @quiz.quiz_data.each{ |q| q[:question_text].should == target_blob }
      end

      it "should migrate links from each question in each question group in the quiz's data" do
        @quiz.quiz_data = [{ :entry_type => 'quiz_group', :questions => [
          {:question_text => source_blob.dup, :id => @question.id},
          {:question_text => source_blob.dup, :id => @question.id},
          {:question_text => source_blob.dup, :id => @question.id}
        ]}]

        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_quiz(@quiz)
        @quiz.quiz_data.first[:questions].each{ |q| q[:question_text].should == target_blob }
      end

      it "should migrate links where the course matches the question's quiz's course but not the quiz's course" do
        # a quiz in the course the link uses, and a question in that quiz (sharing the assessment question)
        @quiz2 = @course2.quizzes.create!
        @question2 = @quiz2.quiz_questions.new(:question_data => {:question_type => :multiple_choice})
        @question2.assessment_question = @question.assessment_question
        @question2.save!

        # use the quiz from the first course, but embed the question from the
        # second course. this happens in practice when @quiz2 existed first and
        # @quiz was cloned from it. @quiz gets a copy of @question2 as @question,
        # but the quiz_data, up until the next time it's rebuilt, has the
        # question_data from @question2 still, including id.
        @quiz.quiz_data = [{:question_type => :multiple_choice, :question_text => source_blob.dup, :id => @question2.id}]

        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_quiz(@quiz)
        @quiz.quiz_data.first[:question_text].should == target_blob
      end

      it "should not migrate links where the course matches the quiz's course but not the question's quiz's course" do
        # a quiz in the course the link uses
        @quiz2 = @course2.quizzes.create!

        # use the quiz from the second course, but embed the question from the
        # first course. I'm not sure if it can happen in practice, but it's the
        # converse of the above, and if it does happen in practice, we don't want
        # it migrating
        @quiz2.quiz_data = [{:question_type => :multiple_choice, :question_text => source_blob.dup, :id => @question.id}]

        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_quiz(@quiz2)
        @quiz2.quiz_data.first[:question_text].should == source_blob
      end

      it "should return true iff a link was migrated" do
        @quiz.quiz_data = [{:question_type => :multiple_choice, :question_text => source_blob.dup, :id => @question.id}]

        # first time true, second time false because it's already migrated
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_quiz(@quiz).should be_true
        Quizzes::QuizQuestionLinkMigrator.migrate_file_links_in_quiz(@quiz).should be_false
      end
    end
  end
end
