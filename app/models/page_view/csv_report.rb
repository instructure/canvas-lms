#
# Copyright (C) 2016 - present Instructure, Inc.
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

class PageView
  class CsvReport

    attr_reader :user, :limit

    def initialize(user, viewer = nil)
      @user = user
      @viewer = viewer
      @limit = Setting.get('page_views_csv_export_rows', '300').to_i
    end

    def generate
      csv = ""
      if records.any?
        rows = Array(records.map { |view| view.to_row.to_csv })
        csv = (header + rows).join
      end
      csv
    end

    def records
      @records ||= begin
        accum = []
        batch = page_views(1)
        while accum.length < limit
          accum.concat(batch)
          break unless batch.next_page
          batch = page_views(batch.next_page)
        end
        accum.take(limit)
      end
    end

    def page_views(page)
      user.page_views(viewer: @viewer).paginate(page: page, per_page: limit)
    end

    def header
      Array(PageView::EXPORTED_COLUMNS.to_csv)
    end
  end
end
