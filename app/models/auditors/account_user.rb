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

class Auditors::AccountUser
  class Record < Auditors::Record
    attributes :performing_user_id,
               :root_account_id,
               :account_user_id,
               :action,
               :hostname,
               :pid

    def self.generate(account_user, performing_user, action:)
      new(
        "account_user_id" => account_user.id,
        "root_account_id" => account_user.root_account_id,
        "performing_user_id" => performing_user&.id || nil,
        "action" => action,
        "hostname" => Socket.gethostname
      )
    end

    def account_user
      @account_user ||= AccountUser.find(account_user_id)
    end
  end

  Stream = Auditors.stream do
    account_user_ar_type = Auditors::ActiveRecord::AccountUserRecord
    record_type account_user_ar_type
    self.raise_on_error = true

    add_index :account_user do
      ar_scope_proc ->(account_user) { account_user_ar_type.where(account_user_id: account_user.id) }
    end
  end

  def self.record(account_user, performing_user, action:)
    raise ArgumentError, "missing account_user" unless account_user.present?
    raise ArgumentError, "missing action" unless action.present?

    event_record = nil
    account_user.shard.activate do
      event_record = Auditors::AccountUser::Record.generate(account_user, performing_user, action:)
      Auditors::AccountUser::Stream.insert(event_record)
    end
    event_record
  end
end
