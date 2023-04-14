# frozen_string_literal: true

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

module I18n
  module Backend
    module CSV
      def load_csv(filename)
        data = ::CSV.read(filename, headers: true)
        csv_locales = data.headers - ["key"]
        basename = File.basename(filename, ".*")
        locale_data = csv_locales.index_with do |locale|
          { basename =>
              data.to_h { |row| [row["key"].to_sym, row[locale]] } }
        end
        [locale_data, false]
      end
    end
  end
end
