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

  def expected_course_lti_roles(enrollment)
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

  RSpec::Matchers.define :be_lti_course_membership do |expected|
    match do |actual|
      @expected = {
        'status' => 'Active',
        'context_id' => expected_lti_id(expected.course),
        'context_label' => expected.course.course_code,
        'context_title' => expected.course.name,
        'name' => expected.user.name,
        'picture' => expected.user.avatar_image_url,
        'given_name' => expected.user.first_name,
        'family_name' => expected.user.last_name,
        'email' => expected.user.email,
        'user_id' => expected_lti_id(expected.user),
        'roles' => expected_course_lti_roles(expected)
      }.compact

      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs (w/o this will compare 'actual' JSON to 'expected' AR model)
    attr_reader :actual, :expected
  end

  RSpec::Matchers.define :be_lti_group_membership do |expected|
    match do |actual|
      @expected = {
        'status' => 'Active',
        'context_id' => expected_lti_id(expected.group),
        'context_title' => expected.group.name,
        'name' => expected.user.name,
        'picture' => expected.user.avatar_image_url,
        'given_name' => expected.user.first_name,
        'family_name' => expected.user.last_name,
        'email' => expected.user.email,
        'user_id' => expected_lti_id(expected.user),
        'roles' => expected_group_lti_roles(expected)
      }.compact

      values_match? @expected, actual
    end

    diffable

    # Make sure a failure diffs the two JSON structs (w/o this will compare 'actual' JSON to 'expected' AR model)
    attr_reader :actual, :expected
  end
end


