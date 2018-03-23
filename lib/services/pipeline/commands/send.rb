module Services
  module Pipeline
    module Commands
      class Send
        MESSAGE_NAME = 'enrollment'
        SOURCE = 'canvas'

        def initialize(enrollment:)
          @host              = ENV['PIPELINE_ENDPOINT']
          @username          = ENV['PIPELINE_USER_NAME']
          @password          = ENV['PIPELINE_PASSWORD']
          @account_admin     = get_account_admin
          @enrollment        = enrollment
          @payload           = {}
          @publisher         = PipelinePublisher
          @api_instance      = publisher::MessagesApi.new
          @pipeline_user_api = Services::Pipeline::UserAPI
        end

        def call
          configure
          get_api_json
          build_pipeline_message
          post
          self
        end
        handle_asynchronously :call

        private

        attr_reader :payload, :message, :enrollment, :user_name, :password,
          :account_admin, :api_instance, :payload, :publisher

        def configure
          publisher.configure do |config|
            config.host = host
            config.username = username
            config.password = password
          end
        end

        def post
          api_instance.messages_post(message)
        end

        def get_account_admin
          @account_admin = Account.default.account_users.find do |account_user|
            account_user.role.name == 'AccountAdmin'
          end
        end

        def get_api_json
          @payload = pipeline_user_api.new.enrollment_json(
            enrollment,
            account_admin,
            {}
          )
        end

        def build_pipeline_message
          @message = publisher::Message.new(
            noun:         MESSAGE_NAME,
            meta:         {},
            identifiers:  { id: enrollment.id },
            data:         payload
          )
        end
      end
    end
  end
end
