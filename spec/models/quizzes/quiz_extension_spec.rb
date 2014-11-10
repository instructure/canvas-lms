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
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  describe "#quiz_submission" do
    it "should be initialized" do
      qs = Quizzes::QuizSubmission.new
      params = {user_id: 1, extra_attempts: 2}
      extension = Quizzes::QuizExtension.new(qs, params)

      expect(extension.quiz_submission).to eq qs
    end
  end

  describe "#ext_params" do
    it "should be initialized" do
      qs = Quizzes::QuizSubmission.new
      params = {user_id: 1, extra_attempts: 2}
      extension = Quizzes::QuizExtension.new(qs, params)

      expect(extension.ext_params).to eq params
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

      expect(extension.quiz_id).to           eq qs.quiz_id
      expect(extension.user_id).to           eq qs.user_id
      expect(extension.extra_attempts).to    eq qs.extra_attempts
      expect(extension.extra_time).to        eq qs.extra_time
      expect(extension.manually_unlocked).to eq qs.manually_unlocked
      expect(extension.end_at).to            eq qs.end_at
    end
  end

  describe ".build_extensions" do
    before :once do
      course
      @quiz = @course.quizzes.create!

      @user1 = user_with_pseudonym(active_all: true, name: 'Student1', username: 'student1@instructure.com')
      @user2 = user_with_pseudonym(active_all: true, name: 'Student2', username: 'student2@instructure.com')
      @course.enroll_student(@user1)
      @course.enroll_student(@user2)
    end

    it "should build a list of extensions from given hash" do
      students = @course.students
      params = [
        {user_id: @user1.id, extra_attempts: 2},
        {user_id: @user2.id, extra_time: 20}
      ]

      yielded = []
      extensions = Quizzes::QuizExtension.build_extensions(students, [@quiz], params) do |ext|
        yielded << ext
      end

      expect(yielded.size).to eq 2
      expect(extensions.size).to eq 2
      expect(extensions[0].ext_params).to eq params[0]
      expect(extensions[1].ext_params).to eq params[1]
    end
  end

  describe "#extend_submission" do
    before :once do
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
      expect(extension.extra_attempts).to eq 2
    end

    it "should extend a submission's extra time" do
      extension = Quizzes::QuizExtension.new(@qs, extra_time: 20)

      extension.extend_submission!
      expect(extension.extra_time).to eq 20
    end

    it "should extend a submission being manually unlocked" do
      extension = Quizzes::QuizExtension.new(@qs, manually_unlocked: true)

      extension.extend_submission!
      expect(extension.manually_unlocked).to be_truthy

      extension = Quizzes::QuizExtension.new(@qs, manually_unlocked: false)

      extension.extend_submission!
      expect(extension.manually_unlocked).to be_falsey
    end

    it "should extend a submission's end at using extend_from_now" do
      @qs.stubs(extendable?: true)

      time = 5.minutes.ago
      Timecop.freeze(time) do
        extension = Quizzes::QuizExtension.new(@qs, extend_from_now: 20)
        extension.extend_submission!
        expect(extension.end_at).to eq time + 20.minutes
      end
    end

    it "should extend a submission's end at using extend_from_end_at" do
      end_at = 5.minutes.ago
      @qs.end_at = end_at
      @qs.save!
      @qs.stubs(extendable?: true)

      extension = Quizzes::QuizExtension.new(@qs, extend_from_end_at: 20)

      extension.extend_submission!
      expect(extension.end_at).to eq end_at + 20.minutes
    end

    it "should have reasonable limits on extendable attributes" do
      extension = Quizzes::QuizExtension.new(@qs,
        extra_attempts: 99999999, extra_time: 99999999)

      extension.extend_submission!
      expect(extension.extra_attempts).to eq 1000
      expect(extension.extra_time).to eq 10080
    end

    it "should only allow numbers or bool for input" do
      extension = Quizzes::QuizExtension.new(@qs,
        extra_attempts: "abc",
        extra_time: "abc",
        manually_unlocked: "abc")

      extension.extend_submission!

      expect(extension.extra_attempts).to eq 0
      expect(extension.extra_time).to eq 0
      expect(extension.manually_unlocked).to eq false
    end
  end
end
