module DataFixup::DeleteDuplicateNotificationEndpoints
  def self.run
    while (arns = NotificationEndpoint.joins(:access_token).group("arn, access_tokens.user_id").having("COUNT(*) > 1").limit(1000).pluck("arn, access_tokens.user_id")).any?
      arns.each do |arn, user_id|
        NotificationEndpoint.joins(:access_token).where(:arn => arn).where("access_tokens.user_id = ?", user_id).order(:id).offset(1).delete_all
      end
    end
  end
end
