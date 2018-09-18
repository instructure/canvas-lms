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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require_dependency "lti/ims/names_and_roles_controller.rb"
require_dependency "lti/ims/helpers/course_memberships_finder.rb"
require_dependency "lti/ims/helpers/group_memberships_finder.rb"

describe Lti::Ims::NamesAndRolesController do
  include Lti::Ims::NamesAndRolesMatchers

  let_once(:course) { course_factory(active_course: true) }
  let_once(:group_record) { group(context: course) } # _record suffix to avoid conflict with group() factory mtd
  let(:course_id) { course.id }
  let(:group_id) { group_record.id }
  let(:context_id) { raise 'Override in spec' }
  let(:unknown_context_id) { raise 'Override in spec' }
  let(:context_param_name) { raise 'Override in spec' }
  let(:action) { raise 'Override in spec'}
  let(:params_overrides) { {} }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  shared_examples 'mime_type check' do
    it 'does not return ims mime_type' do
      expect(response.headers['Content-Type']).not_to include described_class::MIME_TYPE
    end
  end

  shared_examples 'response check' do
    before do
      send_request
    end

    it 'returns correct mime_type' do
      expect(response.headers['Content-Type']).to include described_class::MIME_TYPE
    end

    it 'returns 200 success' do
      expect(response).to have_http_status :ok
    end

    it 'returns request url in payload' do
      expect(json[:id]).to eq request.url
    end

    it 'returns an empty members array' do
      expect_empty_members_array
    end

    context 'with unknown context' do
      let(:context_id) { unknown_context_id }

      it_behaves_like 'mime_type check'

      it 'returns 404 not found' do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe '#course_index' do
    let(:action) { :course_index }
    let(:context_param_name) { :course_id }
    let(:context_id) { course_id }
    let(:unknown_context_id) { Course.maximum(:id) + 1 }

    it_behaves_like 'response check'

    # Bunch of single-enrollment tests b/c they're just so much easier to
    # debug as compared to multi-enrollment tests

    context 'when a course has a single enrollment' do
      it 'returns teacher in members array' do
        enrollment = teacher_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns student in members array' do
        enrollment = student_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns ta in members array' do
        enrollment = ta_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns observer in members array' do
        enrollment = observer_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns designer in members array' do
        enrollment = designer_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom teacher in members array' do
        enrollment = custom_enrollment_in_course('TeacherEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom student in members array' do
        enrollment = custom_enrollment_in_course('StudentEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom ta in members array' do
        enrollment = custom_enrollment_in_course('TaEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom observer in members array' do
        enrollment = custom_enrollment_in_course('ObserverEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom designer in members array' do
        enrollment = custom_enrollment_in_course('DesignerEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end
    end

    context 'when a course has a concluded enrollment' do
      it 'does not return the concluded enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.conclude
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a deactivated enrollment' do
      it 'does not return the deactivated enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.deactivate
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a deleted enrollment' do
      it 'does not return the deleted enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.destroy # logical delete (physical wont work and will just raise a FK violation)
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a rejected enrollment' do
      it 'does not return the rejected enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.reject!
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a invited instructor enrollment' do
      it 'does not return the invited instructor enrollment' do
        teacher_in_course(course: course)
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a creation_pending student enrollment' do
      it 'does not return the creation_pending student enrollment' do
        student_in_course(course: course)
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has multiple enrollments' do
      it 'returns all enrollments sorted by user id' do
        enrollments = [
          teacher_in_course(course: course, active_all: true),
          student_in_course(course: course, active_all: true),
          ta_in_course(course: course, active_all: true),
          observer_in_course(course: course, active_all: true),
          designer_in_course(course: course, active_all: true)
        ]
        send_request
        enrollments.
          sort_by { |e| e.user.id }.
          each_with_index { |e,i| expect_member(e,i) }
        expect_member_count(5)
      end
    end
  end

  describe '#group_index' do
    let(:action) { :group_index }
    let(:context_param_name) { :group_id }
    let(:context_id) { group_id }
    let(:unknown_context_id) { Group.maximum(:id) + 1 }

    it_behaves_like 'response check'

    context 'when a group has a single membership' do
      let(:group_record) { group_with_user(active_all: true).group }
      let(:group_member) { group_record.group_memberships.first }

      it 'returns that membership' do
        send_request
        expect_single_member(group_member)
      end
    end

    context 'when a group has a deleted membership' do
      let(:group_record) { group_with_user(active_all: true).group }
      let(:group_member) { group_record.group_memberships.first }

      it 'does not return the deleted membership' do
        group_member.destroy
        send_request
        expect_empty_members_array
      end
    end

    context 'when a group has a pending membership' do
      let(:group_record) { group_with_user(join_level: 'invitation_only').group }
      let(:group_member) { group_record.group_memberships.first }

      it 'does not return the pending membership' do
        pending("group memberships are always auto-accepted so cant test \"invited\" workflow state - see GroupMembership#auto_join")
        send_request
        expect_empty_members_array
      end
    end

    context 'when a group has multiple memberships' do
      it 'returns all memberships sorted by user id' do
        memberships = [
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model),
        ]
        send_request
        memberships.
          sort_by { |m| m.user.id }.
          each_with_index { |m,i| expect_member(m,i) }
        expect_member_count(5)
      end
    end
  end

  def send_request
    get action, params: { context_param_name => context_id }.merge(params_overrides)
  end

  def expect_single_member(enrollment)
    expect_member(enrollment)
    expect_member_count(1)
    enrollment
  end

  def expect_member(enrollment, index=0)
    # Not doing contain_exactly() b/c it's impossible to see which specific field is problematic in
    # any given bad element.
    expect(json[:members][index]).to match_enrollment(enrollment)
    enrollment
  end

  def expect_empty_members_array
    expect(json[:members]).to be_empty
    expect(json[:members]).to be_a_kind_of(Array)
  end

  def expect_member_count(count)
    expect(json[:members].length).to equal(count)
  end

  def custom_enrollment_in_course(base_type_name, opts={})
    opts[:account] = opts[:course].account unless opts[:account]
    opts[:role] = custom_role(base_type_name, "Custom#{base_type_name}", opts) unless opts[:role]
    course_with_user(base_type_name, opts)
  end

  def match_enrollment(enrollment)
    enrollment.is_a?(Enrollment) ? be_lti_course_membership(enrollment) : be_lti_group_membership(enrollment)
  end

end
