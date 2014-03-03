module Lti
  class LtiUserCreator
    def initialize(canvas_user, pseudonym, opaque_identifier)
      @canvas_user = canvas_user
      @pseudonym = pseudonym
      @opaque_identifier = opaque_identifier
    end

    def convert
      ::LtiOutbound::LTIUser.new.tap do |user|
        user.id = @canvas_user.id
        user.avatar_url = @canvas_user.avatar_url
        user.email = @canvas_user.email
        user.first_name = @canvas_user.first_name
        user.last_name = @canvas_user.last_name
        user.name = @canvas_user.name
        user.opaque_identifier = @opaque_identifier
        user.timezone = Time.zone.tzinfo.name

        if @pseudonym
          user.login_id = @pseudonym.unique_id
          user.sis_source_id = @pseudonym.sis_user_id
        end
      end
    end
  end
end