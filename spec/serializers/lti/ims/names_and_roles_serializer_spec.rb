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

  subject { described_class.new(page) }

  let_once(:course) { course_factory(active_course: true) }
  let(:result) { raise 'Override in context' }
  let(:url) { 'http://test.test/results' }
  let(:page) { raise 'Override in context' }
  let(:privacy_level) { 'public' }
  let(:tool) do
    ContextExternalTool.create!(
      context: course,
      consumer_key: 'key',
      shared_secret: 'secret',
      name: 'test tool',
      url: 'http://www.tool.com/launch',
      settings: { use_1_3: true },
      workflow_state: privacy_level
    )
  end

  def serialize
    subject.as_json.with_indifferent_access
  end

  def be_lti_membership_context
    return be_lti_course_membership_context(decorated_course) if context_type == :course
    be_lti_group_membership_context(decorated_group)
  end

  def be_lti_membership
    return be_lti_course_membership(decorated_enrollment) if context_type == :course
    be_lti_group_membership(decorated_group_member)
  end

  def create_pseudonym!(user)
    user.pseudonyms.create!({
      account: course.account,
      unique_id: 'user1@example.com',
      password: 'asdfasdf',
      password_confirmation: 'asdfasdf',
      workflow_state: 'active',
      sis_user_id: 'user-1-sis-user-id-1'
    })
  end

  shared_examples 'enrollment serialization' do
    it 'properly formats NRPS json' do
      json = serialize
      expect(json[:id]).to eq url
      expect(json[:context]).to be_lti_membership_context
      expect(json[:members][0]).to be_lti_membership
    end
  end

  # Technically all these '...privacy policy' examples are redundant w/r/t be_lti_*_membership(). But those matchers
  # know nothing about privacy policies... they just know that if a model provides a value, it should appear in the
  # resulting json/hash. So you could have an incorrectly implemented privacy policy, but all the serialization tests
  # would still pass. Hence the explicit checks here for user fields specific to each policy.
  shared_examples 'public privacy policy' do
    it 'properly formats NRPS json' do
      json = serialize
      expect(json[:id]).to eq url
      expect(json[:context]).to be_lti_membership_context
      expect(json[:members][0]).to include(:status, :name, :picture, :given_name, :family_name, :email, :lis_person_sourcedid, :user_id, :roles)
    end
  end

  shared_examples 'anonymous privacy policy' do
    it 'properly formats NRPS json' do
      json = serialize
      expect(json[:id]).to eq url
      expect(json[:context]).to be_lti_membership_context
      expect(json[:members][0]).to include(:status, :user_id, :roles)
      expect(json[:members][0]).not_to include(:name, :picture, :given_name, :family_name, :email, :lis_person_sourcedid)
    end
  end

  shared_examples 'name_only privacy policy' do
    it 'properly formats NRPS json' do
      json = serialize
      expect(json[:id]).to eq url
      expect(json[:context]).to be_lti_membership_context
      expect(json[:members][0]).to include(:status, :name, :given_name, :family_name, :lis_person_sourcedid, :user_id, :roles)
      expect(json[:members][0]).not_to include(:picture, :email)
    end
  end

  shared_examples 'email_only privacy policy' do
    it 'properly formats NRPS json' do
      json = serialize
      expect(json[:id]).to eq url
      expect(json[:context]).to be_lti_membership_context
      expect(json[:members][0]).to include(:status, :email, :user_id, :roles)
      expect(json[:members][0]).not_to include(:name, :picture, :given_name, :family_name, :lis_person_sourcedid)
    end
  end

  describe '#as_json' do
    context 'with a course' do
      let(:context_type) { :course }
      let(:enrollment) do
        enrollment = teacher_in_course(course: course, active_all: true, name: 'Marta Perkins')
        user = enrollment.user
        user.email = 'marta.perkins@school.edu'
        user.avatar_image_url = 'http://school.edu/image/url.png'
        user.save!
        create_pseudonym!(user)
        enrollment
      end
      let(:decorated_user_factory) do
        Lti::Ims::Providers::CourseMembershipsProvider.new(course, nil, tool)
      end
      let(:decorated_enrollment) do
        Lti::Ims::Providers::CourseMembershipsProvider::CourseEnrollmentsDecorator.new(
          [enrollment],
          tool,
          decorated_user_factory
        )
      end
      let(:decorated_course) { Lti::Ims::Providers::CourseMembershipsProvider::CourseContextDecorator.new(course) }
      let(:page) do
        {
          memberships: [decorated_enrollment],
          url: url,
          context: decorated_course
        }
      end

      context 'and a public tool' do
        it_behaves_like 'enrollment serialization'
        it_behaves_like 'public privacy policy'
      end

      context 'and an anonymous tool' do
        let(:privacy_level) { 'anonymous' }

          it_behaves_like 'enrollment serialization'
        it_behaves_like 'anonymous privacy policy'
      end

      context 'and a name_only tool' do
        let(:privacy_level) { 'name_only' }

        it_behaves_like 'enrollment serialization'
        it_behaves_like 'name_only privacy policy'
      end

      context 'and an email_only tool' do
        let(:privacy_level) { 'email_only' }

        it_behaves_like 'enrollment serialization'
        it_behaves_like 'email_only privacy policy'
      end
    end

    context 'with a group' do
      let(:context_type) { :group }
      let(:group_record) { group_with_user(context: course, active_all: true, name: 'Marta Perkins').group }
      let(:group_member) do
        enrollment = group_record.group_memberships.first
        user = enrollment.user
        user.email = 'marta.perkins@school.edu'
        user.avatar_image_url = 'http://school.edu/image/url.png'
        user.save!
        create_pseudonym!(user)
        enrollment
      end
      let(:decorated_user_factory) do
        Lti::Ims::Providers::GroupMembershipsProvider.new(group_record, nil, tool)
      end
      let(:decorated_group_member) do
        Lti::Ims::Providers::GroupMembershipsProvider::GroupMembershipDecorator.new(
          group_member,
          tool,
          decorated_user_factory
        )
      end
      let(:decorated_group) { Lti::Ims::Providers::GroupMembershipsProvider::GroupContextDecorator.new(group_record) }
      let(:page) do
        {
          memberships: [decorated_group_member],
          url: url,
          context: decorated_group
        }
      end

      context 'and a public tool' do
        it_behaves_like 'enrollment serialization'
        it_behaves_like 'public privacy policy'
      end

      context 'and an anonymous tool' do
        let(:privacy_level) { 'anonymous' }

        it_behaves_like 'enrollment serialization'
        it_behaves_like 'anonymous privacy policy'
      end

      context 'and a name_only tool' do
        let(:privacy_level) { 'name_only' }

        it_behaves_like 'enrollment serialization'
        it_behaves_like 'name_only privacy policy'
      end

      context 'and an email_only tool' do
        let(:privacy_level) { 'email_only' }

        it_behaves_like 'enrollment serialization'
        it_behaves_like 'email_only privacy policy'
      end
    end
  end
end
