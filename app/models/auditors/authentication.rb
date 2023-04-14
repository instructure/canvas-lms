# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class Auditors::Authentication
  class Record < Auditors::Record
    attributes :pseudonym_id,
               :account_id,
               :user_id

    def self.generate(pseudonym, event_type)
      new("pseudonym" => pseudonym, "event_type" => event_type)
    end

    def initialize(*args)
      super(*args)

      if attributes["pseudonym"]
        self.pseudonym = attributes.delete("pseudonym")
      end
    end

    def pseudonym
      @pseudonym ||= Pseudonym.find(pseudonym_id)
    end

    def pseudonym=(pseudonym)
      @pseudonym = pseudonym
      attributes["pseudonym_id"] = @pseudonym.global_id
      attributes["account_id"] = Shard.global_id_for(@pseudonym.account_id)
      attributes["user_id"] = Shard.global_id_for(@pseudonym.user_id)
    end

    delegate :user, :account, to: :pseudonym
  end

  Stream = Auditors.stream do
    auth_ar_type = Auditors::ActiveRecord::AuthenticationRecord
    active_record_type auth_ar_type
    record_type Auditors::Authentication::Record

    add_index :pseudonym do
      table :authentications_by_pseudonym
      entry_proc ->(record) { record.pseudonym }
      key_proc ->(pseudonym) { pseudonym.global_id }
      ar_scope_proc ->(pseudonym) { auth_ar_type.where(pseudonym_id: pseudonym.id) }
    end

    add_index :user do
      table :authentications_by_user
      entry_proc ->(record) { record.user }
      key_proc ->(user) { user.global_id }
      ar_scope_proc ->(user) { auth_ar_type.where(user_id: user.id) }
    end

    add_index :account do
      table :authentications_by_account
      entry_proc ->(record) { record.account }
      key_proc ->(account) { account.global_id }
      ar_scope_proc ->(account) { auth_ar_type.where(account_id: account.id) }
    end
  end

  def self.record(pseudonym, event_type)
    return unless pseudonym

    event_record = nil
    pseudonym.shard.activate do
      event_record = Auditors::Authentication::Record.generate(pseudonym, event_type)
      Auditors::Authentication::Stream.insert(event_record)
    end
    event_record
  end

  def self.for_account(account, options = {})
    account.shard.activate do
      Auditors::Authentication::Stream.for_account(account, options)
    end
  end

  def self.for_pseudonym(pseudonym, options = {})
    pseudonym.shard.activate do
      Auditors::Authentication::Stream.for_pseudonym(pseudonym, options)
    end
  end

  def self.for_pseudonyms(pseudonyms, options = {})
    # each for_pseudonym does a shard.activate, so this partition_by_shard is
    # not necessary for correctness. but it improves performance (prevents
    # shard-thrashing)
    collections = Shard.partition_by_shard(pseudonyms) do |shard_pseudonyms|
      shard_pseudonyms.map do |pseudonym|
        [pseudonym.global_id, Auditors::Authentication.for_pseudonym(pseudonym, options)]
      end
    end
    BookmarkedCollection.merge(*collections)
  end

  def self.for_user(user, options = {})
    collections = []
    dbs_seen = Set.new
    Shard.with_each_shard(user.associated_shards) do
      # EventStream is shard-sensitive, but multiple shards may share
      # a database. if so, we only need to query from it once
      db_fingerprint = Auditors::Authentication::Stream.database_fingerprint
      next if dbs_seen.include?(db_fingerprint)

      dbs_seen << db_fingerprint

      # query from that database, and label it with the database server's id
      # for merge
      collections << [
        db_fingerprint,
        Auditors::Authentication::Stream.for_user(user, options)
      ]
    end
    BookmarkedCollection.merge(*collections)
  end
end
