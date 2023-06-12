# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../spec_helper"

describe QuizMigrationAlert do
  describe "associations" do
    it { is_expected.to belong_to(:user).required }
    it { is_expected.to belong_to(:course).required }
    it { is_expected.to belong_to(:migration) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :user }
    it { is_expected.to validate_presence_of :course }
    it { is_expected.to validate_presence_of :migration_id }
  end

  describe "permissions" do
    before :once do
      course_with_teacher(active_all: true)
      @quiz_migration_alert = @course.quiz_migration_alerts.create!(user: @teacher, migration_id: "10000000000040")
    end

    it "grants read access to the owner of the alert" do
      expect(@quiz_migration_alert.grants_right?(@teacher, :read)).to be true
    end

    it "does not grant read access to users that don't own the alert" do
      expect(@quiz_migration_alert.grants_right?(@teacher, :read)).to be true
      other_user = user_model
      expect(@quiz_migration_alert.grants_right?(other_user, :read)).to be false
    end

    it "grants update access to the owner of the alert" do
      expect(@quiz_migration_alert.grants_right?(@teacher, :update)).to be true
    end

    it "does not grant update access to users that don't own the alert" do
      expect(@quiz_migration_alert.grants_right?(@teacher, :update)).to be true
      other_user = user_model
      expect(@quiz_migration_alert.grants_right?(other_user, :update)).to be false
    end

    it "grants destroy access to the owner of the alert" do
      expect(@quiz_migration_alert.grants_right?(@teacher, :destroy)).to be true
    end

    it "does not grant destroy access to users that don't own the alert" do
      expect(@quiz_migration_alert.grants_right?(@teacher, :destroy)).to be true
      other_user = user_model
      expect(@quiz_migration_alert.grants_right?(other_user, :destroy)).to be false
    end
  end
end
