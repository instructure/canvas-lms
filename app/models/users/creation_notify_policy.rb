module Users
  class CreationNotifyPolicy
    def initialize(can_manage_users, opts={})
      @send_confirmation = opts[:send_confirmation]
      @is_manager = can_manage_users
      @force_self_registration = opts[:force_self_registration]
    end

    def should_notify?
      !!(is_self_registration? || send_confirmation)
    end

    def is_self_registration?
      !!(force_self_registration || !is_manager)
    end

    def dispatch!(user, pseudonym, channel)
      if is_self_registration?
        send_self_registration_email(user, pseudonym)
        return true
      elsif should_notify? && !user.registered?
        pseudonym.send_registration_notification!
        return true
      elsif channel.has_merge_candidates?
        channel.send_merge_notification!
      end
      false
    end

    private
    attr_reader :is_manager

    def send_self_registration_email(user, pseudonym)
      if user.pre_registered?
        pseudonym.send_confirmation!
      elsif !user.registered?
        pseudonym.send_registration_notification!
      end
    end

    def send_confirmation
      Canvas::Plugin.value_to_boolean(@send_confirmation)
    end

    def force_self_registration
      Canvas::Plugin.value_to_boolean(@force_self_registration)
    end
  end
end
