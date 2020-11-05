# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module AcademicBenchmark
  module OutcomeData
    def self.load_data(options={})
      if options.key?(:archive_file)
        OutcomeData::FromFile.new(options.slice(:archive_file))
      elsif options.key?(:authority) || options.key?(:document)
        OutcomeData::FromApi.new(options)
      else
        raise Canvas::Migration::Error, "No outcome file or guid given"
      end
    end
  end
end
