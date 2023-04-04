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

module I18nTasks
  module CsvBackend
    def load_csv(filename)
      scope = File.basename(filename, ".*")
      data = CSV.read(filename, headers: true)
      csv_locales = data.headers - ["key"]
      ret = {}
      csv_locales.each do |locale|
        ret[locale.to_sym] = {
          scope.to_sym => data.to_h { |row| [row["key"].to_sym, row[locale]] }.compact
        }
      end
      ret
    end
  end
end
