#
# Copyright (C) 2012-2014 Instructure, Inc.
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

module PaginatedCollection
  class Proxy
    attr_accessor :block

    def initialize(block)
      @block = block
    end

    def paginate(options = {})
      execute_pager(configure_pager(new_pager, options))
    end

    def new_pager
      PaginatedCollection::Collection.new
    end

    def configure_pager(pager, options)
      raise(ArgumentError, "per_page required") unless options[:per_page] && options[:per_page] > 0
      current_page = options.fetch(:page) { nil }
      current_page = pager.first_page if current_page.nil?
      pager.current_page = current_page
      pager.per_page = options[:per_page]
      pager.total_entries = options[:total_entries]
      pager
    end

    def execute_pager(pager)
      pager = @block.call(pager)
      if !pager.respond_to?(:current_page)
        raise(ArgumentError, "The PaginatedCollection block needs to return a WillPaginate-style object")
      end
      return pager
    end
  end
end