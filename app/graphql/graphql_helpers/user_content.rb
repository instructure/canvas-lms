# frozen_string_literal: true

# provides a wrapper with all the methods needed to call `api_user_content`
# like we do in the app controllers
module GraphQLHelpers
  class UserContent
    include Api
    include UrlHelpers

    attr_reader :request, :user, :context

    # NOTE: context here is *not* referring to graphql context, it is
    # referring to a canvas context (typically a course)
    def self.process(content, request:, context:, user:, in_app:,
                     preloaded_attachments: {}, options: {})
      new(request:, context:, user:, in_app:)
        .api_user_content(content, preloaded_attachments, options)
    end

    def initialize(request:, context:, user:, in_app:)
      @request = request
      @context = context
      @user = user
      @in_app = in_app
    end

    def api_user_content(html, preloaded_attachments = {}, options = {})
      super(html, context, user, preloaded_attachments, options)
    end

    def in_app?
      @in_app
    end
  end
end
