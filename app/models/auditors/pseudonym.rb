# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class Auditors::Pseudonym
  class Record < Auditors::Record
    attributes :performing_user_id,
               :root_account_id,
               :pseudonym_id,
               :action,
               :hostname,
               :pid

    def self.generate(pseudonym, performing_user, action:)
      hostname = Socket.gethostname
      pid = Process.pid.to_s

      new(
        "pseudonym_id" => pseudonym.id,
        "root_account_id" => pseudonym.root_account_id,
        "performing_user_id" => performing_user&.id || 0,
        "action" => action,
        "hostname" => hostname,
        "pid" => pid
      )
    end

    def pseudonym
      @pseudonym ||= Pseudonym.find(pseudonym_id)
    end
  end

  Stream = Auditors.stream do
    pseudonym_ar_type = Auditors::ActiveRecord::PseudonymRecord
    active_record_type pseudonym_ar_type
    record_type Auditors::Pseudonym::Record
    self.raise_on_error = true

    add_index :pseudonym do
      table :pseudonym_changes_by_pseudonym
      entry_proc ->(record) { record.pseudonym }
      key_proc ->(pseudonym) { pseudonym.global_id }
      ar_scope_proc ->(pseudonym) { pseudonym_ar_type.where(pseudonym_id: pseudonym.id) }
    end
  end

  def self.record(pseudonym, performing_user, action:)
    raise ArgumentError, "missing pseudonym" unless pseudonym.present?
    raise ArgumentError, "missing action" unless action.present?

    event_record = nil
    pseudonym.shard.activate do
      event_record = Auditors::Pseudonym::Record.generate(pseudonym, performing_user, action:)
      Auditors::Pseudonym::Stream.insert(event_record)
    end
    event_record
  end
end
