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
  let(:context) { raise 'Override in spec' }
  let(:context_id) { context.id }
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

  shared_examples 'page size check' do
    # Needs all the same variables as 'multiple enrollments check', plus:
    #
    #   page_size_param_name - symbol naming the page size query param
    #
    let(:pagination_overrides) { { page_size_param_name => rqst_page_size } }
    let(:params_overrides) { super().merge(pagination_overrides) }

    it 'returns the first page of results, with the correct size and proper navigation links' do
      send_request
      expect_enrollment_response_page
      expect(response_links).to have_correct_pagination_urls
    end

    context 'when the page size parameter is too large' do
      let(:rqst_page_size) { 4611686018427387903 }
      let(:rsp_page_size) { 50 } # system max

      it 'defaults to the system maximum page size' do
        send_request
        expect_enrollment_response_page
        expect(response_links).to have_correct_pagination_urls
      end
    end

    context 'when a page index parameter is specified' do
      let(:rqst_page) { 2 }
      let(:rsp_page) { 2 }
      let(:pagination_overrides) { super().merge(page: rqst_page) }

      it 'returns the specified page of results, with the correct size and proper navigation links' do
        send_request
        expect_enrollment_response_page
        expect(response_links).to have_correct_pagination_urls
      end

      context 'and when the page index parameter is too large ' do
        let(:rqst_page) { total_items + 1 } # cant have more pages than there are items
        let(:rsp_page) { rqst_page }
        let(:rsp_page_size) { 30 } # don't know why, Api just does this

        it 'returns an empty members array, with the correct size and proper navigation links' do
          send_request
          expect_empty_members_array
          expect(response_links).to have_correct_pagination_urls
        end
      end
    end
  end

  shared_examples 'multiple enrollments check' do
    # When including, define the following:
    #   enrollments: array of context enrollments
    #   total_items: context's active enrollment count
    #   rsp_page: expected response page index
    #   rsp_page_size: expected response page size
    #   pass_through_param: hash of query params to be written through to pagination links
    #   params_overrides: hash of all request params

    it 'returns all enrollments sorted by user id' do
      send_request
      expect_enrollment_response_page
      expect(response_links).to have_correct_pagination_urls
    end

    context 'when a limit page size parameter is specified' do
      let(:rqst_page_size) { 2 }
      let(:rsp_page_size) { 2 }
      let(:page_size_param_name) { :limit }

      it_behaves_like 'page size check'
    end

    context 'when a per_page parameter is specified' do
      let(:rqst_page_size) { 2 }
      let(:rsp_page_size) { 2 }
      let(:page_size_param_name) { :per_page }

      it_behaves_like 'page size check'
    end

    context 'when a limit param overrides a per_page param' do
      let(:rqst_page_size) { 2 }
      let(:rsp_page_size) { 2 }
      let(:page_size_param_name) { :limit }

      # limit=2, per_page=3 ... latter should be ignored
      let(:params_overrides) { super().merge(per_page: 3) }

      it_behaves_like 'page size check'
    end
  end

  describe '#course_index' do
    let(:action) { :course_index }
    let(:context) { course }
    let(:context_param_name) { :course_id }
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

      let!(:enrollments) do
        [
          teacher_in_course(course: course, active_all: true),
          student_in_course(course: course, active_all: true),
          ta_in_course(course: course, active_all: true),
          observer_in_course(course: course, active_all: true),
          designer_in_course(course: course, active_all: true)
        ]
      end
      let(:total_items) { enrollments.length }
      let(:rsp_page) { 1 }
      let(:rsp_page_size) { 10 } # system default
      let(:pass_thru_params) { { pass: 'thru' } }
      let(:params_overrides) { super().merge(pass_thru_params) }

      it_behaves_like 'multiple enrollments check'

    end
  end

  describe '#group_index' do
    let(:action) { :group_index }
    let(:context) { group_record }
    let(:context_param_name) { :group_id }
    let(:unknown_context_id) { Group.maximum(:id) + 1 }

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

      let!(:enrollments) do
        [
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model),
          group_membership_model(group: group_record, user: user_model)
        ]
      end
      let(:total_items) { enrollments.length }
      let(:rsp_page) { 1 }
      let(:rsp_page_size) { 10 } # system default
      let(:pass_thru_params) { { pass: 'thru' } }
      let(:params_overrides) { super().merge(pass_thru_params) }

      it_behaves_like 'multiple enrollments check'
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
    expect(json[:members].length).to eq(count)
  end

  def custom_enrollment_in_course(base_type_name, opts={})
    opts[:account] = opts[:course].account unless opts[:account]
    opts[:role] = custom_role(base_type_name, "Custom#{base_type_name}", opts) unless opts[:role]
    course_with_user(base_type_name, opts)
  end

  def match_enrollment(enrollment)
    enrollment.is_a?(Enrollment) ? be_lti_course_membership(enrollment) : be_lti_group_membership(enrollment)
  end

  def expect_enrollment_response_page
    enrollments.
      sort_by { |e| e.user.id }.
      slice(rsp_page_size*(rsp_page-1), rsp_page_size).
      each_with_index { |e,i| expect_member(e,i) }
    expect_member_count([rsp_page_size,total_items].min)
  end

  def have_correct_pagination_urls
    total_pages = page_count(total_items, rsp_page_size)
    pass_thrus = as_query_params(pass_thru_params)

    # rubocop:disable Metrics/LineLength
    expected_links = [
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{rsp_page}&per_page=#{rsp_page_size}>; rel=\"current\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{rsp_page+1}&per_page=#{rsp_page_size}>; rel=\"next\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{rsp_page-1}&per_page=#{rsp_page_size}>; rel=\"prev\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=1&per_page=#{rsp_page_size}>; rel=\"first\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{total_pages}&per_page=#{rsp_page_size}>; rel=\"last\""
    ]
    # rubocop:enable Metrics/LineLength
    expected_links.reject! {|el| el.include?('rel="next"')} if rsp_page == total_pages
    expected_links.reject! {|el| el.include?('rel="prev"')} if rsp_page <= 1
    expected_links.reject! {|el| el.include?('rel="last"')} if rsp_page > total_pages
    match_array(expected_links)
  end

  def as_query_params(params_hash)
    params_hash.empty? ? '' : "#{params_hash.to_query}&"
  end

  def page_count(total_items, page_size)
    (total_items / page_size) + (total_items % page_size > 0 ? 1 : 0)
  end

  def response_links
    response.headers["Link"].split(",")
  end

end
