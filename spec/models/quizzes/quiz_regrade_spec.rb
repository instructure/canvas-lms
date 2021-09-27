# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Quizzes::QuizRegrade do

  around do |example|
    Timecop.freeze(Time.zone.local(2013), &example)
  end

  def quiz_regrade
    Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: 1)
  end

  describe "relationships" do

    it "belongs to a quiz" do
      expect(Quizzes::QuizRegrade.new).to respond_to :quiz
    end

    it "belongs to a user" do
      expect(Quizzes::QuizRegrade.new).to respond_to :user
    end

  end

  describe "validations" do
    it "validates presence of quiz_id" do
      expect(Quizzes::QuizRegrade.new(quiz_id: nil)).not_to be_valid
    end

    it "validates presence of user id" do
      expect(Quizzes::QuizRegrade.new(quiz_id: 1,user_id: nil)).not_to be_valid
    end

    it "validates presence of quiz_version" do
      expect(Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: nil)).
        not_to be_valid
    end

    it "is valid when all required attributes are present" do
      expect(Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: 1)).
        to be_valid
    end
  end
end

