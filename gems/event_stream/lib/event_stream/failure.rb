#
# Copyright (C) 2013 Instructure, Inc.
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

class EventStream::Failure < ActiveRecord::Base
  self.table_name = :event_stream_failures

  serialize :payload, Hash
  serialize :backtrace, Array

  def self.log!(operation, stream, record, exception)
    return if stream.raise_on_error
    create!(:operation => operation.to_s,
            :event_stream => stream.identifier,
            :record_id => record.id.to_s,
            :payload => stream.operation_payload(operation, record),
            :exception => exception.message.to_s,
            :backtrace => exception.backtrace)
  end
end
