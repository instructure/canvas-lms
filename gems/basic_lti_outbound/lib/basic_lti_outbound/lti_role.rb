module BasicLtiOutbound
  class LTIRole
    INSTRUCTOR = "Instructor"
    LEARNER = "Learner"
    ADMIN = "urn:lti:instrole:ims/lis/Administrator"
    CONTENT_DEVLOPER = "ContentDeveloper"
    OBSERVER = "urn:lti:instrole:ims/lis/Observer"
    TEACHING_ASSISTANT = "urn:lti:role:ims/lis/TeachingAssistant"
    NONE = "urn:lti:sysrole:ims/lis/None"



    #def self.enrollment_to_membership(membership)
    #  case membership
    #    when StudentEnrollment, StudentViewEnrollment
    #      'Learner'
    #    when TeacherEnrollment
    #      'Instructor'
    #    when TaEnrollment
    #      'urn:lti:role:ims/lis/TeachingAssistant'
    #    when DesignerEnrollment
    #      'ContentDeveloper'
    #    when ObserverEnrollment
    #      'urn:lti:instrole:ims/lis/Observer'
    #    when AccountUser
    #      'urn:lti:instrole:ims/lis/Administrator'
    #    else
    #      'urn:lti:instrole:ims/lis/Observer'
    #  end
    #end

    attr_accessor :type, :state

    def active?
      @state == :active
    end
  end
end