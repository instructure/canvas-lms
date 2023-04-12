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

describe GradebookFilter do
  describe "associations" do
    it { is_expected.to belong_to(:user).required }
    it { is_expected.to belong_to(:course).required }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :user }
    it { is_expected.to validate_presence_of :course }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :payload }
    it { is_expected.not_to allow_value("").for(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(ActiveRecord::Base.maximum_string_length) }

    it "requires the payload to be a hash" do
      filter = GradebookFilter.new
      filter.payload = "potato"
      filter.validate
      expect(filter.errors.full_messages).to include "Payload must be a hash"
    end
  end

  describe "permissions" do
    before :once do
      course_with_teacher(active_all: true)
      @gradebook_filter = @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })
    end

    it "grants read access to the creator of the filter" do
      expect(@gradebook_filter.grants_right?(@teacher, :read)).to be true
    end

    it "does not grant read access to users that are not the creator of the filter" do
      expect(@gradebook_filter.grants_right?(@teacher, :read)).to be true
      other_user = user_model
      expect(@gradebook_filter.grants_right?(other_user, :read)).to be false
    end

    it "grants update access to the creator of the filter" do
      expect(@gradebook_filter.grants_right?(@teacher, :update)).to be true
    end

    it "does not grant update access to users that are not the creator of the filter" do
      expect(@gradebook_filter.grants_right?(@teacher, :update)).to be true
      other_user = user_model
      expect(@gradebook_filter.grants_right?(other_user, :update)).to be false
    end

    it "grants destroy access to the creator of the filter" do
      expect(@gradebook_filter.grants_right?(@teacher, :destroy)).to be true
    end

    it "does not grant destroy access to users that are not the creator of the filter" do
      expect(@gradebook_filter.grants_right?(@teacher, :destroy)).to be true
      other_user = user_model
      expect(@gradebook_filter.grants_right?(other_user, :destroy)).to be false
    end
  end
end
