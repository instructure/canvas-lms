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
  belongs_to :from_user, class_name: 'User'
  has_many :user_merge_data_records

  scope :active, -> { where.not(workflow_state: 'deleted') }
  scope :splitable, -> { where('created_at > ?', split_time) }

  def self.split_time
    Time.zone.now - Setting.get('user_merge_to_split_time', 180.days.to_i).to_i
  end

  def add_more_data(objects, user: nil, workflow_state: nil)
    objects.each do |o|
      user ||= o.user_id
      r = self.user_merge_data_records.new(context: o, previous_user_id: user)
      r.previous_workflow_state = o.workflow_state if o.class.columns_hash.key?('workflow_state')
      r.previous_workflow_state = o.file_state if o.class == Attachment
      r.previous_workflow_state = workflow_state if workflow_state
      r.save!
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save!
  end

end
