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

describe Lti::Ims::NamesAndRolesSerializer do
  include Lti::Ims::NamesAndRolesMatchers

  let_once(:course) { course_factory(active_course: true) }
  let(:result) { raise 'Override in context' }
  let(:url) { 'http://test.test/results' }
  let(:page) { raise 'Override in context' }

  describe '#as_json' do
    context 'with course enrollment' do
      let(:enrollment) { teacher_in_course(course: course, active_all: true) }
      let(:decorated_enrollment) { Lti::Ims::Providers::CourseMembershipsProvider::CourseEnrollmentsDecorator.new([enrollment]) }
      let(:page) do
        {
          memberships: [decorated_enrollment],
          url: url,
          context: Lti::Ims::Providers::CourseMembershipsProvider::CourseContextDecorator.new(course)
        }
      end

      it 'properly formats NRPS json' do
        json = serialize
        expect(json[:id]).to eq url
        expect(json[:members][0]).to be_lti_course_membership(decorated_enrollment)
      end
    end

    context 'with group membership' do
      let(:group_record) { group_with_user(active_all: true).group }
      let(:group_member) { group_record.group_memberships.first }
      let(:decorated_group_member) { Lti::Ims::Providers::GroupMembershipsProvider::GroupMembershipDecorator.new(group_member) }
      let(:page) do
        {
          memberships: [decorated_group_member],
          url: url,
          context: Lti::Ims::Providers::GroupMembershipsProvider::GroupContextDecorator.new(group_record)
        }
      end

      it 'properly formats NRPS json' do
        json = serialize
        expect(json[:id]).to eq url
        expect(json[:members][0]).to be_lti_group_membership(decorated_group_member)
      end
    end
  end

  def serialize
    described_class.new(page).as_json.with_indifferent_access
  end
end
