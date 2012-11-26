#
# Copyright (C) 2011 Instructure, Inc.
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
#

module CommunicationChannelsHelper
  def merge_or_login_link(pseudonym)
    if @current_user && pseudonym.user_id == @current_user.id
      registration_confirmation_path(@nonce, :enrollment => @enrollment.try(:uuid), :confirm => 1)
    else
      login_url(:host => HostUrl.context_host(pseudonym.account, @request.try(:host_with_port)), :confirm => @nonce, :enrollment => @enrollment.try(:uuid), :pseudonym_session => { :unique_id => pseudonym.unique_id }, :expected_user_id => pseudonym.user_id)
    end
  end

  def friendly_name(pseudonym, merge_opportunities)
    if pseudonym.is_a?(User)
      user = pseudonym
      pseudonym = user.all_active_pseudonyms.detect { |p| p.root_account_id == @root_account.id }
      pseudonym ||= user.pseudonym
      return user.name unless pseudonym
    end

    if !(conflicting_users = merge_opportunities.select { |(user, pseudonyms)| user != pseudonym.user && user.name == pseudonym.user.name }).empty?
      conflicting_pseudonyms = conflicting_users.map(&:last).flatten
      if conflicting_pseudonyms.find { |p| p.account != pseudonym.account}
        "#{pseudonym.user.name} (#{pseudonym.account.name} - #{pseudonym.unique_id})"
      else
        "#{pseudonym.user.name} (#{pseudonym.unique_id})"
      end
    else
      pseudonym.user.name
    end
  end
end
