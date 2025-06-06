# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
class Account::BulkUpdate
  include Api

  def initialize(context, user)
    @context = context
    @current_user = user
  end

  def update_users(progress = nil, user_ids:, user_params:)
    progress&.calculate_completion!(0, user_ids.size)
    errors = {}
    user_ids.each do |user_id|
      begin
        user = api_find(User, user_id, account: @context)
        errors[user_id] = "Not found" unless @context.user_account_associations.where(user_id: user).exists?
        if user_params[:event]
          event = user_params[:event]
          if %w[suspend unsuspend].include?(event) &&
             user != @current_user
            user.pseudonyms.active.shard(user).each do |p|
              next unless p.grants_right?(@current_user, :delete)
              next if p.active? && event == "unsuspend"
              next if p.suspended? && event == "suspend"

              p.update!(workflow_state: (event == "suspend") ? "suspended" : "active")
            end
          end
        end
      rescue => e
        errors[user_id] = "Error updating user: #{e.message}"
      end
      progress&.increment_completion!(1) if progress&.total
    end
    progress&.set_results(errors:)
  end

  def remove_users(progress = nil, user_ids:)
    progress&.calculate_completion!(0, user_ids.size)
    errors = {}
    user_ids.each do |user_id|
      begin
        user = api_find(User, user_id, account: @context)
        errors[user_id] = "Not found" unless @context.user_account_associations.where(user_id: user).exists?
        if user.allows_user_to_remove_from_account?(@context, @current_user)
          user.remove_from_root_account(@context.root_account, updating_user: @current_user)
        else
          errors[user_id] = "Can not be removed"
        end
      rescue => e
        errors[user_id] = "Error removing user: #{e.message}"
      end
      progress&.increment_completion!(1) if progress&.total
    end
    progress&.set_results(errors:)
  end
end
