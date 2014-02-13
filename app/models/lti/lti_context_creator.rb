module Lti
  class LtiContextCreator
    def initialize(canvas_context, canvas_tool)
      @canvas_context = canvas_context
      @canvas_tool = canvas_tool

      if @canvas_context.respond_to? :root_account
        @root_account = @canvas_context.root_account
      elsif @canvas_tool.context.respond_to? :root_account
        @root_account = @canvas_tool.context.root_account
      end
    end

    def convert
      lti_context = case @canvas_context
                      when Account
                        LtiOutbound::LTIAccount.new.tap do |lti_account|
                          lti_account.sis_source_id = @canvas_context.sis_source_id
                        end
                      when Course
                        LtiOutbound::LTICourse.new.tap do |lti_course|
                          lti_course.course_code = @canvas_context.course_code
                          lti_course.sis_source_id = @canvas_context.sis_source_id
                        end
                      when User
                        LtiOutbound::LTIUser.new
                    end

      lti_context.consumer_instance = consumer_instance
      lti_context.id = @canvas_context.id
      lti_context.name = @canvas_context.name
      lti_context.opaque_identifier = @canvas_tool.opaque_identifier_for(@canvas_context)

      lti_context
    end

    private

    def consumer_instance
      Lti::LtiOutboundAdapter.consumer_instance_class.new.tap do |consumer_instance|
        consumer_instance.name = @root_account.name
        consumer_instance.lti_guid = @root_account.lti_guid
        consumer_instance.domain = @root_account.domain
        consumer_instance.id = @root_account.id
        consumer_instance.sis_source_id = @root_account.sis_source_id
      end
    end
  end
end