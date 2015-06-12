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
      OBSERVER = 'urn:lti:role:ims/lis/Learner/NonCreditLearner'
      TEACHING_ASSISTANT = 'urn:lti:role:ims/lis/TeachingAssistant'
    end

    # This format is deprecated, but depended on by some
    module ContextNotNamespaced
      CONTENT_DEVELOPER = 'ContentDeveloper'
      INSTRUCTOR = 'Instructor'
      LEARNER = 'Learner'
      OBSERVER = 'urn:lti:instrole:ims/lis/Observer' # actually inst role, but left for backwards compatibility
      TEACHING_ASSISTANT = 'urn:lti:role:ims/lis/TeachingAssistant'
    end
  end
end