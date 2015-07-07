def account_notification(opts={})
  req_service = opts[:required_account_service] || nil
  role_ids = opts[:role_ids] || []
  message = opts[:message] || "hi there"
  subj = opts[:subject] || "this is a subject"
  @account = opts[:account] || Account.default
  @announcement = @account.announcements.build(subject: subj, message: message, required_account_service: req_service)
  @announcement.start_at = opts[:start_at] || 5.minutes.ago.utc
  @announcement.end_at = opts[:end_at] || 1.day.from_now.utc
  @announcement.account_notification_roles.build(role_ids.map { |r_id| {account_notification_id: @announcement.id, role: Role.get_role_by_id(r_id)} }) unless role_ids.empty?
  @announcement.save!
  @announcement
end
