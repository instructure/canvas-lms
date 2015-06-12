module Lti
  class LtiAccountCreator
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
      case @canvas_context
        when Account
          create_account(@canvas_context)
        when Course, Group
          create_account(@canvas_context.account)
        when User
          create_account(@root_account)
      end
    end

    private

    def create_account(canvas_account)
      LtiOutbound::LTIAccount.new.tap do |lti_account|
        lti_account.sis_source_id = canvas_account.sis_source_id
        lti_account.id = canvas_account.id
        lti_account.name = canvas_account.name
      end
    end

  end
end