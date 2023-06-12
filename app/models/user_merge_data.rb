# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
class UserMergeData < ActiveRecord::Base
  belongs_to :user
  belongs_to :from_user, class_name: "User"
  has_many :records, class_name: "UserMergeDataRecord", inverse_of: :merge_data, autosave: false
  has_many :items, class_name: "UserMergeDataItem", inverse_of: :merge_data, autosave: false

  scope :active, -> { where.not(workflow_state: %w[deleted failed]) }
  scope :splitable, -> { where("created_at > ?", split_time) }

  def self.split_time
    Time.zone.now - Setting.get("user_merge_to_split_time", "180").to_i.days
  end

  def add_more_data(objects, user: nil, workflow_state: nil, data: [])
    data = build_more_data(objects, user:, workflow_state:, data:)
    bulk_insert_merge_data(data)
  end

  def build_more_data(objects, user: nil, workflow_state: nil, data: [])
    # to get relative ids in previous_user_id, we need to be on the records shard
    shard.activate do
      objects.each do |o|
        user ||= o.user_id
        r = records.new(context: o, previous_user_id: user)
        r.previous_workflow_state = o.workflow_state if o.class.columns_hash.key?("workflow_state")
        r.previous_workflow_state = o.file_state if o.instance_of?(Attachment)
        r.previous_workflow_state = workflow_state if workflow_state
        data << r
      end
    end
    data
  end

  def bulk_insert_merge_data(data)
    shard.activate do
      data.each_slice(1000) { |batch| UserMergeDataRecord.bulk_insert_objects(batch) }
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end
end
