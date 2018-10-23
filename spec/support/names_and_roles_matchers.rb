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

module Lti::Ims::NamesAndRolesMatchers

  def expected_lti_id(entity)
    Lti::Asset.opaque_identifier_for(entity)
  end

  def expected_course_lti_roles(*enrollment)
    lti_roles = []
    # Try to accommodate 'naked' Enrollment AR models and CourseEnrollmentsDecorators that
    # wrap multiple Enrollments
    enrollment.each do |e|
      if e.respond_to?(:enrollments)
        e.enrollments.each do |ee|
          lti_roles += map_course_enrollment_role(ee)
        end
      else lti_roles += map_course_enrollment_role(e)
      end
    end
    lti_roles.uniq
  end

  def map_course_enrollment_role(enrollment)
    case enrollment.role.base_role_type
    when 'TeacherEnrollment'
      [ 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor' ]
    when 'TaEnrollment'
      [ 'http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor#TeachingAssistant',
        'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor' ]
    when 'DesignerEnrollment'
      [ 'http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper' ]
    when 'StudentEnrollment'
      [ 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner' ]
    when 'ObserverEnrollment'
      [ 'http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor' ]
    else
      []
    end
  end

  def expected_group_lti_roles(membership)
    ['http://purl.imsglobal.org/vocab/lis/v2/membership#Member',
     *('http://purl.imsglobal.org/vocab/lis/v2/membership#Manager' if is_group_leader(membership))]
  end

  def is_group_leader(membership)
    membership.group.leader_id == membership.user.id
  end

  def expected_base_membership_context(context)
    {
      'id' => expected_lti_id(context),
      'title' => context.name
    }.compact
  end

  def expected_group_membership_context(context)
    expected_base_membership_context(context)
  end

  def expected_course_membership_context(context)
    expected_base_membership_context(context).merge!({'label' => context.course_code}).compact
  end

  def expected_sourced_id(user)
    return user.sourced_id if user.respond_to?(:sourced_id)
    SisPseudonym.for(user, Account.default, type: :trusted, require_sis: false)&.sis_user_id
  end

  def expected_base_membership(user, privacy_level)
    privacy_level = privacy_level.presence || 'public'
    {
      'status' => 'Active',
      'name' => (user.name if %w(public name_only).include?(privacy_level)),
      'picture' => (user.avatar_image_url if privacy_level == 'public'),
      'given_name' => (user.first_name if %w(public name_only).include?(privacy_level)),
      'family_name' => (user.last_name if %w(public name_only).include?(privacy_level)),
      'email' => (user.email if %w(public email_only).include?(privacy_level)),
      'lis_person_sourcedid' => (expected_sourced_id(user) if %w(public name_only).include?(privacy_level)),
      'user_id' => expected_lti_id(Lti::Ims::Providers::MembershipsProvider.unwrap(user))
    }.compact
  end

  def expected_message_array(message_matcher, user)
    [
      {
        'https://purl.imsglobal.org/spec/lti/claim/message_type' => 'LtiResourceLinkRequest',
        'locale' => (user.locale || I18n.default_locale.to_s),
        'https://purl.imsglobal.org/spec/lti/claim/custom' => {}
      }.merge!(message_matcher.presence || {})
    ]
  end

  def expected_context_membership(user, roles_matcher, opts)
    expected_base_membership(user, opts[:privacy_level]).
      merge!('roles' => roles_matcher.call).
      merge('message' => opts[:message_matcher] ? match_array(expected_message_array(opts[:message_matcher], user)) : nil).
      compact
  end

  def expected_course_membership(opts)
    expected_context_membership(
      opts[:expected].first.user,
      -> { match_array(expected_course_lti_roles(*opts[:expected])) },
      opts
    )
  end

  def expected_group_membership(opts)
    expected_context_membership(
      opts[:expected].user,
      -> { match_array(expected_group_lti_roles(opts[:expected])) },
      opts
    )
  end

  RSpec::Matchers.define :be_lti_course_membership_context do |expected|
    match do |actual|
      @expected = expected_course_membership_context(expected)
      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs (w/o this will compare 'actual' JSON to 'expected' AR model)
    attr_reader :actual, :expected
  end

  RSpec::Matchers.define :be_lti_group_membership_context do |expected|
    match do |actual|
      @expected = expected_group_membership_context(expected)
      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs (w/o this will compare 'actual' JSON to 'expected' AR model)
    attr_reader :actual, :expected
  end

  RSpec::Matchers.define :be_lti_course_membership do |opts|
    match do |actual|
      @expected = expected_course_membership(opts)
      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs (w/o this will compare 'actual' JSON to 'expected' AR model)
    attr_reader :actual, :expected
  end

  RSpec::Matchers.define :be_lti_group_membership do |opts|
    match do |actual|
      @expected = expected_group_membership(opts)
      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs (w/o this will compare 'actual' JSON to 'expected' AR model)
    attr_reader :actual, :expected
  end

  RSpec::Matchers.define :be_lti_advantage_error_response_body do |expected_type, expected_message|
    match do |actual|
      @expected = {
        'errors' => {
          'type' => expected_type,
          'message' => expected_message
        }
      }.compact

      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs
    attr_reader :actual, :expected
  end
end


