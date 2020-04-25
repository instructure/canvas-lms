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
  # The classes that include this are adapters taking the event_stream
  # view of attributes for a log and mapping them
  # the way we would store such data in the db itself.
  # shard-local ids is the main change, but also sometimes
  # transforming reserved attribute names like "version_id".
  # the only required method for each includer is
  # "ar_attributes_from_event_stream"
  module Model
    def ar_attributes_from_event_stream(_record)
      # here is where hash of attributes should be produced
      raise "Not Implemented!"
    end

    def create_from_event_stream!(record)
      create!(ar_attributes_from_event_stream(record))
    end

    def update_from_event_stream!(record)
      db_rec = find_by!(uuid: record.attributes['id'])
      db_rec.update_attributes!(ar_attributes_from_event_stream(record))
    end
  end
end