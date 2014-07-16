module Messages
  class AssetContext
    attr_reader :asset, :notification_name
    def initialize(asset, name)
      @asset = asset
      @notification_name = name
    end

    def from_name
      return nil unless has_named_source?
      source_user.short_name
    end

    def reply_to_name
      return nil unless has_named_source?
      I18n.t(:reply_from_name, "%{name} via Canvas Notifications", name: from_name)
    end

    private

    def source_user
      if is_author_asset?
        asset.author
      elsif is_user_asset?
        asset.user
      end
    end

    def has_named_source?
      is_author_asset? || is_user_asset?
    end

    SOURCE_AUTHOR_NOTIFICATIONS = [
      "Conversation Message",
      "Submission Comment",
      "Submission Comment For Teacher"
    ]

    SOURCE_USER_NOTIFICATIONS = [
      "New Discussion Entry",
      "Assignment Submitted",
      "Assignment Resubmitted"
    ]

    def is_author_asset?
      SOURCE_AUTHOR_NOTIFICATIONS.include?(notification_name)
    end

    def is_user_asset?
      SOURCE_USER_NOTIFICATIONS.include?(notification_name)
    end

  end
end
