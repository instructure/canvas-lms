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
      post_policy = assignment.create_post_policy!(post_manually: true)
      expect(post_policy).to be_valid
    end

    it "is valid if a valid course is specified without an assignment" do
      post_policy = course.post_policies.create!
      expect(post_policy).to be_valid
    end

    it "sets the course based on the associated assignment if no course is specified" do
      policy = assignment.create_post_policy!
      expect(policy.course).to eq(course)
    end
  end
end
