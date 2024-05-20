# frozen_string_literal: true

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

module Lti::IMS::NamesAndRolesMatchers
  def expected_lti_id(entity)
    entity.is_a?(User) ? entity.lti_id : Lti::Asset.opaque_identifier_for(entity)
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
      else
        lti_roles += map_course_enrollment_role(e)
      end
    end
    lti_roles.uniq
  end

  def map_course_enrollment_role(enrollment)
    if enrollment.type == "StudentViewEnrollment"
      return [
        "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner",
        "http://purl.imsglobal.org/vocab/lti/system/person#TestUser"
      ]
    end

    case enrollment.role.base_role_type
    when "TeacherEnrollment"
      ["http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor"]
    when "TaEnrollment"
      ["http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor#TeachingAssistant",
       "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor"]
    when "DesignerEnrollment"
      ["http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper"]
    when "StudentEnrollment"
      ["http://purl.imsglobal.org/vocab/lis/v2/membership#Learner"]
    when "ObserverEnrollment"
      ["http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor"]
    else
      []
    end
  end

  def expected_group_lti_roles(membership)
    ["http://purl.imsglobal.org/vocab/lis/v2/membership#Member",
     *("http://purl.imsglobal.org/vocab/lis/v2/membership#Manager" if is_group_leader(membership))]
  end

  def is_group_leader(membership)
    membership.group.leader_id == membership.user.id
  end

  def expected_base_membership_context(context)
    {
      "id" => expected_lti_id(context),
      "title" => context.name
    }.compact
  end

  def expected_group_membership_context(context)
    expected_base_membership_context(context)
  end

  def expected_course_membership_context(context)
    expected_base_membership_context(context).merge!({ "label" => context.course_code }).compact
  end

  def expected_sourced_id(user)
    return user.sourced_id if user.respond_to?(:sourced_id)

    SisPseudonym.for(user, Account.default, type: :trusted, require_sis: false)&.sis_user_id
  end

  # Special defaulting as compared to #expected_sourced_id b/c that field is effectively NRPS-only and has special
  # logic in NamesAndRolesSerializer to just suppress the field if it's either disallowed or blank. But here, for
  # login ID, we're verifying existing extension rendering behaviors which rely on `$Canvas.user.loginId` expansion
  # which is guarded by a rule that requires a SIS Pseudonym. So even though the expansion might be _allowed_, if the
  # expanded field is blank, you'll get the custom param echoed back. (This way we get symmetry between NRPS and
  # LTI launches for this particular field.)
  def expected_login_id_extension(user)
    SisPseudonym.for(user, Account.default, type: :trusted, require_sis: false)&.unique_id.presence || "$Canvas.user.loginId"
  end

  def expected_base_membership(user, opts)
    {
      "status" => "Active",
      "name" => (user.name if %w[public name_only].include?(privacy(opts))),
      "picture" => (user.avatar_url if privacy(opts) == "public"),
      "given_name" => (user.first_name if %w[public name_only].include?(privacy(opts))),
      "family_name" => (user.last_name if %w[public name_only].include?(privacy(opts))),
      "email" => (user.email if %w[public email_only].include?(privacy(opts))),
      "lis_person_sourcedid" => (expected_sourced_id(user) if %w[public name_only].include?(privacy(opts))),
      "user_id" => expected_lti_id(Lti::IMS::Providers::MembershipsProvider.unwrap(user)),
      "lti11_legacy_user_id" => Lti::Asset.opaque_identifier_for(user)
    }.compact
  end

  def expected_message_array(user, opts)
    [
      {
        "https://purl.imsglobal.org/spec/lti/claim/message_type" => "LtiResourceLinkRequest",
        "locale" => user.locale || I18n.default_locale.to_s,
        "https://purl.imsglobal.org/spec/lti/claim/custom" => {},
        "https://purl.imsglobal.org/spec/lti/claim/lti11_legacy_user_id" => tool.opaque_identifier_for(user),
        "https://purl.imsglobal.org/spec/lti/claim/lti1p1" => {
          "user_id" => user.lti_context_id
        }
      }.merge!(opts[:message_matcher].presence || {}).compact
    ]
  end

  def expected_context_membership(user, roles_matcher, opts)
    expected_base_membership(user, opts)
      .merge!("roles" => roles_matcher.call)
      .merge("message" => opts[:message_matcher] ? match_array(expected_message_array(user, opts)) : nil)
      .compact
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

  def privacy(opts)
    opts[:privacy_level].presence || "public"
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
        "errors" => {
          "type" => expected_type,
          "message" => expected_message
        }
      }.compact

      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs
    attr_reader :actual, :expected
  end
end
