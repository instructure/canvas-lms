module LtiOutbound
  class LTIRole
    INSTRUCTOR = 'Instructor'
    LEARNER = 'Learner'
    ADMIN = 'urn:lti:instrole:ims/lis/Administrator'
    CONTENT_DEVLOPER = 'ContentDeveloper'
    OBSERVER = 'urn:lti:instrole:ims/lis/Observer'
    TEACHING_ASSISTANT = 'urn:lti:role:ims/lis/TeachingAssistant'
    NONE = 'urn:lti:sysrole:ims/lis/None'

    attr_accessor :type, :state

    def active?
      @state == :active
    end
  end
end