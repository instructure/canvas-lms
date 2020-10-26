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

module LtiOutbound
  # As defined at: http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560479
  module LTIRoles
    module System
      NONE = 'urn:lti:sysrole:ims/lis/None'
      SYS_ADMIN = 'urn:lti:sysrole:ims/lis/SysAdmin'
      USER = 'urn:lti:sysrole:ims/lis/User'
    end

    module Institution
      ADMIN = 'urn:lti:instrole:ims/lis/Administrator'
      INSTRUCTOR = 'urn:lti:instrole:ims/lis/Instructor'
      OBSERVER = 'urn:lti:instrole:ims/lis/Observer'
      STUDENT = 'urn:lti:instrole:ims/lis/Student'
    end

    module Context
      CONTENT_DEVELOPER = 'urn:lti:role:ims/lis/ContentDeveloper'
      INSTRUCTOR = 'urn:lti:role:ims/lis/Instructor'
      LEARNER = 'urn:lti:role:ims/lis/Learner'
      OBSERVER = 'urn:lti:role:ims/lis/Learner/NonCreditLearner,urn:lti:role:ims/lis/Mentor'
      TEACHING_ASSISTANT = 'urn:lti:role:ims/lis/TeachingAssistant'
    end

    # This format is deprecated, but depended on by some
    module ContextNotNamespaced
      CONTENT_DEVELOPER = 'ContentDeveloper'
      INSTRUCTOR = 'Instructor'
      LEARNER = 'Learner'
      OBSERVER = 'urn:lti:instrole:ims/lis/Observer,urn:lti:role:ims/lis/Mentor' # actually inst role, but left for backwards compatibility
      TEACHING_ASSISTANT = 'urn:lti:role:ims/lis/TeachingAssistant'
    end
  end
end
