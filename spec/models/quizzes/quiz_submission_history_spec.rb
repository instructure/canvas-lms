# encoding: UTF-8
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

describe Quizzes::QuizSubmissionHistory do

  context "submissions with history" do
    before :once do
      course_factory
      @quiz       = @course.quizzes.create!
      @submission = @quiz.quiz_submissions.new

      @submission.workflow_state = "complete"
      @submission.score = 5.0
      @submission.attempt = 1
      @submission.with_versioning(true, &:save!)
      expect(@submission.version_number).to eql(1)
      expect(@submission.score).to eql(5.0)

      # regrade 1
      @submission.score_before_regrade = 5.0
      @submission.score = 4.0
      @submission.attempt = 1
      @submission.with_versioning(true, &:save!)
      expect(@submission.version_number).to eql(2)

      # new attempt
      @submission.score = 3.0
      @submission.attempt = 2
      @submission.with_versioning(true, &:save!)
      expect(@submission.version_number).to eql(3)
    end

    describe "#initialize" do
      it "should group list of attempts for the quiz submission" do
        attempts = Quizzes::QuizSubmissionHistory.new(@submission)
        expect(attempts.length).to eq 2
        expect(attempts.first).to be_a(Quizzes::QuizSubmissionAttempt)
      end

      it "should sort attempts sequentially" do
        attempts = Quizzes::QuizSubmissionHistory.new(@submission)
        expect(attempts.length).to eq 2
        expect(attempts.map {|attempt| attempt.number }).to eq [1, 2]
      end
    end

    describe "#last_versions" do
      it "should return last versions for each attempt" do
        attempts = Quizzes::QuizSubmissionHistory.new(@submission)
        expect(attempts.length).to eq 2

        versions = attempts.last_versions
        expect(versions.length).to eq 2
        expect(versions.first).to be_a(Version)
      end
    end

    describe "#version_models" do
      it "should return models for the latest versions" do
        attempts = Quizzes::QuizSubmissionHistory.new(@submission)
        expect(attempts.length).to eq 2

        models = attempts.version_models
        expect(models.length).to eq 2
        expect(models.first).to be_a(Quizzes::QuizSubmission)
      end

      it "should return the submission itself as the latest attempt" do
        @submission.extra_attempts = 1
        @submission.save! # doesn't add a new version

        attempts = Quizzes::QuizSubmissionHistory.new(@submission)

        models = attempts.version_models
        expect(models.last.extra_attempts).to eq 1
      end
    end

    describe "#kept" do
      it "should return the version of the submission that was kept" do
        attempts = Quizzes::QuizSubmissionHistory.new(@submission)
        expect(attempts.length).to eq 2

        models = attempts.version_models
        expect(models.length).to eq 2

        expect(attempts.kept).to eq models.first
      end
    end

    describe "#model_for" do
      it "should return model for the current attempt" do
        attempts = Quizzes::QuizSubmissionHistory.new(@submission)
        expect(attempts.length).to eq 2

        qs = attempts.model_for(@submission.attempt)
        expect(qs.attempt).to eq 2
        expect(qs).to be_a(Quizzes::QuizSubmission)
      end

      it "should return model for previous attempts" do
        attempts = Quizzes::QuizSubmissionHistory.new(@submission)
        expect(attempts.length).to eq 2

        qs = attempts.model_for(1)
        expect(qs.attempt).to eq 1
        expect(qs).to be_a(Quizzes::QuizSubmission)
      end
    end
  end
end
