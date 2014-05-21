#
# Copyright (C) 2014 Instructure, Inc.
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

describe Quizzes::QuizExtension do
  describe "#quiz_submission" do
    it "should be initialized" do
      qs = Quizzes::QuizSubmission.new
      params = {user_id: 1, extra_attempts: 2}
      extension = Quizzes::QuizExtension.new(qs, params)

      extension.quiz_submission.should == qs
    end
  end

  describe "#ext_params" do
    it "should be initialized" do
      qs = Quizzes::QuizSubmission.new
      params = {user_id: 1, extra_attempts: 2}
      extension = Quizzes::QuizExtension.new(qs, params)

      extension.ext_params.should == params
    end
  end

  describe "attributes" do
    it "should be delegated to the quiz submission" do
      qs = Quizzes::QuizSubmission.new
      qs.quiz_id           = 123
      qs.user_id           = 456
      qs.extra_attempts    = 2
      qs.extra_time        = 20
      qs.manually_unlocked = true
      qs.end_at            = 10.minutes.from_now

      extension = Quizzes::QuizExtension.new(qs, {})

      extension.quiz_id.should           == qs.quiz_id
      extension.user_id.should           == qs.user_id
      extension.extra_attempts.should    == qs.extra_attempts
      extension.extra_time.should        == qs.extra_time
      extension.manually_unlocked.should == qs.manually_unlocked
      extension.end_at.should            == qs.end_at
    end
  end

  describe ".build_extensions" do
    before :each do
      course
      @quiz = @course.quizzes.create!

      @user1 = user_with_pseudonym(active_all: true, name: 'Student1', username: 'student1@instructure.com')
      @user2 = user_with_pseudonym(active_all: true, name: 'Student2', username: 'student2@instructure.com')
      @course.enroll_student(@user1)
      @course.enroll_student(@user2)
    end

    it "should build a list of extensions from given hash" do
      manager  = Quizzes::SubmissionManager.new(@quiz)
      students = @course.students
      params = [
        {user_id: @user1.id, extra_attempts: 2},
        {user_id: @user2.id, extra_time: 20}
      ]

      yielded = []
      extensions = Quizzes::QuizExtension.build_extensions(students, manager, params) do |ext|
        yielded << ext
      end

      yielded.size.should == 2
      extensions.size.should == 2
      extensions[0].ext_params.should == params[0]
      extensions[1].ext_params.should == params[1]
    end
  end

  describe "#extend_submission" do
    before :each do
      course
      @quiz = @course.quizzes.create!

      @user = user_with_pseudonym(active_all: true, name: 'Student1', username: 'student1@instructure.com')
      @course.enroll_student(@user)

      manager = Quizzes::SubmissionManager.new(@quiz)
      @qs = manager.find_or_create_submission(@user, nil, 'settings_only')
    end

    it "should extend a submission's extra attempts" do
      extension = Quizzes::QuizExtension.new(@qs, extra_attempts: 2)

      extension.extend_submission!
      extension.extra_attempts.should == 2
    end

    it "should extend a submission's extra time" do
      extension = Quizzes::QuizExtension.new(@qs, extra_time: 20)

      extension.extend_submission!
      extension.extra_time.should == 20
    end

    it "should extend a submission being manually unlocked" do
      extension = Quizzes::QuizExtension.new(@qs, manually_unlocked: true)

      extension.extend_submission!
      extension.manually_unlocked.should be_true

      extension = Quizzes::QuizExtension.new(@qs, manually_unlocked: false)

      extension.extend_submission!
      extension.manually_unlocked.should be_false
    end

    it "should extend a submission's end at using extend_from_now" do
      @qs.stubs(extendable?: true)

      time = 5.minutes.ago
      Timecop.freeze(time) do
        extension = Quizzes::QuizExtension.new(@qs, extend_from_now: 20)
        extension.extend_submission!
        extension.end_at.should == time + 20.minutes
      end
    end

    it "should extend a submission's end at using extend_from_end_at" do
      end_at = 5.minutes.ago
      @qs.end_at = end_at
      @qs.save!
      @qs.stubs(extendable?: true)

      extension = Quizzes::QuizExtension.new(@qs, extend_from_end_at: 20)

      extension.extend_submission!
      extension.end_at.should == end_at + 20.minutes
    end

    it "should have reasonable limits on extendable attributes" do
      extension = Quizzes::QuizExtension.new(@qs,
        extra_attempts: 99999999, extra_time: 99999999)

      extension.extend_submission!
      extension.extra_attempts.should == 1000
      extension.extra_time.should == 10080
    end

    it "should only allow numbers or bool for input" do
      extension = Quizzes::QuizExtension.new(@qs,
        extra_attempts: "abc",
        extra_time: "abc",
        manually_unlocked: "abc")

      extension.extend_submission!

      extension.extra_attempts.should == 0
      extension.extra_time.should == 0
      extension.manually_unlocked.should == false
    end
  end
end
