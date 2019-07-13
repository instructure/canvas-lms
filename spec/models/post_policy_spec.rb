#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe PostPolicy do
  describe "relationships" do
    it { is_expected.to belong_to(:course).inverse_of(:post_policies) }
    it { is_expected.to validate_presence_of(:course) }

    it { is_expected.to belong_to(:assignment).inverse_of(:post_policy) }
    it { is_expected.not_to validate_presence_of(:assignment) }
  end

  describe "validation" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: '!!!') }

    it "is valid if a valid course and assignment are specified" do
      post_policy = PostPolicy.new(course: course, assignment: assignment)
      expect(post_policy).to be_valid
    end

    it "is valid if a valid course is specified without an assignment" do
      post_policy = PostPolicy.new(course: course)
      expect(post_policy).to be_valid
    end

    it "sets the course based on the associated assignment if no course is specified" do
      expect(assignment.post_policy.course).to eq(course)
    end
  end

  describe "post policies feature" do
    describe ".feature_enabled?" do
      it "returns true if the post_policies_enabled setting is set to true" do
        Setting.set("post_policies_enabled", true)
        expect(PostPolicy).to be_feature_enabled
      end

      it "returns false if the post_policies_enabled setting is set to any other value" do
        Setting.set("post_policies_enabled", "NO")
        expect(PostPolicy).not_to be_feature_enabled
      end

      it "returns false if no value is set for the setting" do
        expect(PostPolicy).not_to be_feature_enabled
      end
    end

    describe ".enable_feature!" do
      it "sets the post_policies_enabled setting to 'true'" do
        PostPolicy.enable_feature!
        expect(Setting.get("post_policies_enabled", false)).to eq "true"
      end
    end

    describe ".disable_feature!" do
      it "sets the post_policies_enabled setting to 'false'" do
        PostPolicy.disable_feature!
        expect(Setting.get("post_policies_enabled", false)).to eq "false"
      end
    end
  end
end
