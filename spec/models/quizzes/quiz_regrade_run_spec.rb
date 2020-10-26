# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

describe Quizzes::QuizRegradeRun do

  it "validates presence of quiz_regrade_id" do
    expect(Quizzes::QuizRegradeRun.new(quiz_regrade_id: 1)).to be_valid
    expect(Quizzes::QuizRegradeRun.new(quiz_regrade_id: nil)).not_to be_valid
  end

  describe "#perform" do
    before(:each) do
      @course = Course.create!
      @quiz = Quizzes::Quiz.create!(:context => @course)
      @user = User.create!

      @regrade = Quizzes::QuizRegrade.create(:user_id => @user.id, :quiz_id => @quiz.id, :quiz_version => 1)
    end

    it "creates a new quiz regrade run" do
      expect(Quizzes::QuizRegradeRun.first).to be_nil

      Quizzes::QuizRegradeRun.perform(@regrade) do
        # noop
      end

      run = Quizzes::QuizRegradeRun.first
      expect(run.started_at).not_to be_nil
      expect(run.finished_at).not_to be_nil
    end
  end
end
