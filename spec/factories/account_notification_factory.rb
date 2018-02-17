#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Factories
  def account_notification(opts={})
    req_service = opts[:required_account_service] || nil
    role_ids = opts[:role_ids] || []
    message = opts[:message] || "hi there"
    subj = opts[:subject] || "this is a subject"
    @account = opts[:account] || Account.default
    @announcement = @account.announcements.build(subject: subj, message: message, required_account_service: req_service)
    @announcement.start_at = opts[:start_at] || 5.minutes.ago.utc
    @announcement.end_at = opts[:end_at] || 1.day.from_now.utc
    @announcement.user = opts[:user]
    @announcement.account_notification_roles.build(role_ids.map { |r_id| {account_notification_id: @announcement.id, role: Role.get_role_by_id(r_id)} }) unless role_ids.empty?
    @announcement.domain_specific = !!opts[:domain_specific]
    @announcement.save!
    @announcement
  end

  def sub_account_notification(opts={})
    req_service = opts[:required_account_service] || nil
    role_ids = opts[:role_ids] || []
    message = opts[:message] || "hi there"
    subj = opts[:subject] || "sub account notification"
    account = opts[:account] || Account.default
    sub_account_announcement = account.announcements.build(subject: subj, message: message, required_account_service: req_service)
    sub_account_announcement.start_at = opts[:start_at] || 5.minutes.ago.utc
    sub_account_announcement.end_at = opts[:end_at] || 1.day.from_now.utc
    sub_account_announcement.account_notification_roles.build(role_ids.map { |r_id| {account_notification_id: sub_account_announcement.id, role: Role.get_role_by_id(r_id)} }) unless role_ids.empty?
    sub_account_announcement.save!
    sub_account_announcement
  end
end
