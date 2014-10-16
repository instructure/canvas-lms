require 'net/http'

module Lti
  class XapiService
    class Token < Struct.new(:tool, :user, :course, :timestamp, :nonce)
      def self.create(tool, user, course)
        Token.new(tool, user, course, Time.now, SecureRandom.hex(8))
      end

      def serialize
        key = tool.shard.settings[:encryption_key]
        payload = [tool.id, user.id, course.id, timestamp.to_i, nonce].join('-')
        "#{payload}-#{Canvas::Security.hmac_sha1(payload, key)}"
      end

      def self.parse_and_validate(serialized_token)
        parts = serialized_token.split('-')
        tool = ContextExternalTool.find(parts[0].to_i)
        key = tool.shard.settings[:encryption_key]
        unless parts.size == 6 && Canvas::Security.hmac_sha1(parts[0..-2].join('-'), key) == parts[-1]
          raise BasicLTI::BasicOutcomes::Unauthorized, "Invalid xapi service token"
        end
        user = User.find(parts[1].to_i)
        course = Course.find(parts[2].to_i)
        timestamp = parts[3].to_i
        nonce = parts[4]
        Token.new(tool, user, course, timestamp, nonce)
      end
    end

    def self.create_token(tool, user, course)
      Token.create(tool, user, course).serialize
    end

    def self.log_page_view(token, params)
      course = token.course
      user = token.user
      tool = token.tool
      duration = params[:result] ? params[:result]['duration'] : nil
      seconds = duration ? Duration.new(duration).to_i : nil

      if duration
        course.enrollments.where(:user_id => user).
          update_all(['total_activity_time = COALESCE(total_activity_time, 0) + ?', seconds])
      end

      access = AssetUserAccess.where(user_id: user, asset_code: tool.asset_string).first_or_initialize
      access.log(course, group_code: "external_tools", category: "external_tools")

      if PageView.page_views_enabled?
        PageView.new(user: user, context: course, account: course.account).tap { |p|
          p.request_id = CanvasUUID.generate
          p.url = params[:object][:id]
          # TODO: override 10m cap?
          p.interaction_seconds = seconds
        }.save
      end
    end
  end
end
