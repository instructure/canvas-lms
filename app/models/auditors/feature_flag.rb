# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Auditors::FeatureFlag
  class Record < Auditors::Record
    attributes :feature_flag_id,
               :user_id,
               :root_account_id,
               :state_before,
               :state_after,
               :context_id,
               :context_type,
               :feature_name

    # usually we can infer the "after the change" state
    # from the feature flag object itself.  Sometimes that doesn't
    # make sense, though, like when "deleting" a feature flag.  In that
    # case the "after" state is going to be something explicit like "removed",
    # but there would be no reason to put that on the object-that's-being-deleted.
    # the "post_state" argument here lets the caller specify an explicit state
    # if they need to.
    def self.generate(feature_flag, user, previous_state, post_state = nil)
      new(
        "feature_flag" => feature_flag,
        "user" => user,
        "state_before" => previous_state,
        "state_after" => post_state || feature_flag.state
      )
    end

    def initialize(*args)
      super(*args)

      if attributes["feature_flag"]
        self.feature_flag = attributes.delete("feature_flag")
      end

      if attributes.key?("user")
        # might be nil in a rare circumstance with an unprovisioned console user
        self.user = attributes.delete("user")
      end
    end

    def feature_flag
      @feature_flag ||= FeatureFlag.find(feature_flag_id)
    end

    # this method is used to infer all the "event stream"
    # attributes for this stream from the model.  Later, if
    # the write destination is postgres, we can transform
    # some of these into the necessary attributes for storing
    # in the shard db itself (especially things like global vs local ids).
    # That's taken care of in the active_record/feature_flag_record.rb file.
    def feature_flag=(feature_flag)
      @feature_flag = feature_flag
      attributes["feature_flag_id"] = @feature_flag.global_id
      attributes["context_id"] = Shard.global_id_for(@feature_flag.context_id)
      attributes["context_type"] = @feature_flag.context_type
      attributes["feature_name"] = @feature_flag.feature
      # this should be safe because we don't care about auditing feature
      # flags that are for specific users.
      attributes["root_account_id"] =
        if @feature_flag.context.is_a?(Account) && @feature_flag.context.root_account?
          # if the context IS a root account, we still need to tie it to this record
          @feature_flag.context.global_id
        else
          Shard.global_id_for(@feature_flag.context.root_account_id)
        end
    end

    def user
      @user ||= user_id && User.find(user_id)
    end

    def user=(user)
      @user ||= user
      # might be nil in a rare circumstance with an unprovisioned console user
      attributes["user_id"] = @user&.global_id
    end
  end

  Stream = Auditors.stream do
    ff_ar_type = Auditors::ActiveRecord::FeatureFlagRecord
    active_record_type ff_ar_type
    record_type Auditors::FeatureFlag::Record
    self.raise_on_error = true

    add_index :feature_flag do
      table :feature_flag_changes_by_feature_flag
      entry_proc ->(record) { record.feature_flag }
      key_proc ->(feature_flag) { feature_flag.global_id }
      ar_scope_proc ->(feature_flag) { ff_ar_type.where(feature_flag_id: feature_flag.id) }
    end
  end

  def self.for_feature_flag(feature_flag, options = {})
    feature_flag.shard.activate do
      Auditors::FeatureFlag::Stream.for_feature_flag(feature_flag, options)
    end
  end

  def self.record(feature_flag, user, previous_state, post_state: nil)
    return unless feature_flag

    event_record = nil
    post_state ||= feature_flag.state
    feature_flag.shard.activate do
      event_record = Auditors::FeatureFlag::Record.generate(feature_flag, user, previous_state, post_state)
      Auditors::FeatureFlag::Stream.insert(event_record)
    end
    event_record
  end
end
