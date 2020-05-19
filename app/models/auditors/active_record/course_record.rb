#
# Copyright (C) 2020 - present Instructure, Inc.
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
module Auditors::ActiveRecord
  class CourseRecord < ActiveRecord::Base
    include CanvasPartman::Concerns::Partitioned
    self.partitioning_strategy = :by_date
    self.partitioning_interval = :months
    self.partitioning_field = 'created_at'
    self.table_name = 'auditor_course_records'

    belongs_to :course, class_name: '::Course', inverse_of: :auditor_course_records
    belongs_to :user, inverse_of: :auditor_course_records
    belongs_to :account, inverse_of: :auditor_course_records
    belongs_to :sis_batch, inverse_of: :auditor_course_records

    class << self
      include Auditors::ActiveRecord::Model

      def ar_attributes_from_event_stream(record)
        attrs_hash = record.attributes.except('id')
        attrs_hash['request_id'] ||= "MISSING"
        attrs_hash['uuid'] = record.id
        attrs_hash['course_id'] = Shard.relative_id_for(record.course_id, Shard.current, Shard.current)
        attrs_hash['account_id'] = Shard.relative_id_for(record.account_id, Shard.current, Shard.current)
        attrs_hash['user_id'] = Shard.relative_id_for(record.user_id, Shard.current, Shard.current)
        attrs_hash['sis_batch_id'] = Shard.relative_id_for(record.sis_batch_id, Shard.current, Shard.current)
        attrs_hash
      end
    end
  end
end