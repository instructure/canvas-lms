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

#
# Wraps GraphService, which provides lower-level access to the Microsoft Graph API, with
# functions specific to canvas models and the particular Microsoft API fields we use.
#
module MicrosoftSync
  class CanvasGraphService
    attr_reader :graph_service

    def initialize(tenant)
      @graph_service = GraphService.new(tenant)
    end

    def list_education_classes_for_course(course)
      graph_service.list_education_classes(filter: {externalId: course.uuid})
    end

    # Returns the hash of the new course, including the 'id' key
    def create_education_class(course)
      graph_service.create_education_class(
        description: course.public_description,
        displayName: course.name,
        externalId: course.uuid,
        externalName: course.name,
        externalSource: 'manual',
        mailNickname: "Course_#{course.uuid}",
      )
    end

    def update_group_with_course_data(ms_group_id, course)
      graph_service.update_group(
        ms_group_id,
        microsoft_EducationClassLmsExt: {
          ltiContextId: course.lti_context_id || Lti::Asset.opaque_identifier_for(course),
          lmsCourseId: course.uuid,
          lmsCourseName: course.name,
          lmsCourseDescription: course.public_description,
        },
        microsoft_EducationClassSisExt: {
          sisCourseId: course.sis_source_id,
        }
      )
    end

    USERS_UPNS_TO_AADS_BATCH_SIZE = 15 # According to Microsoft

    # Returns a hash from UPN -> AAD. Accepts 15 at a time.
    def users_upns_to_aads(upns)
      if upns.length > USERS_UPNS_TO_AADS_BATCH_SIZE
        raise ArgumentError, "Can't look up #{upns.length} UPNs at once"
      end

      graph_service.list_users(
        select: %w[id userPrincipalName],
        filter: {userPrincipalName: upns}
      ).map do |result|
        [result['userPrincipalName'], result['id']]
      end.to_h
    end
  end
end
