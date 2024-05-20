# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require "folio/core_ext/enumerable"

module Folio
  PAGINATION_COUNT_TIMEOUT = "5s"
end

module Folio::WillPaginate::ActiveRecord::Pagination
  def paginate(options = {})
    unless options.key?(:total_entries)
      scope = if is_a?(::ActiveRecord::Relation)
                self
              elsif self < ::ActiveRecord::Base
                all
              else
                self.scope
              end
      group_values = scope.group_values
      unless group_values.empty?
        begin
          scope.connection.transaction(requires_new: true) do
            scope.connection.execute("SET LOCAL statement_timeout='#{Folio::PAGINATION_COUNT_TIMEOUT}'")
            # total_entries left to an auto-count, but the relation being
            # paginated has a grouping. we need to do a special count, lest
            # self.count give us a hash instead of the integer we expect.
            having_clause_empty = scope.having_clause.empty?
            options[:total_entries] = if having_clause_empty && group_values.length == 1 # multi-column distinct counts are broken right now (as of rails 4.2.5) :(
                                        except(:group, :select).select(group_values).distinct.count
                                      else
                                        unscoped.from("(#{to_sql}) a").count
                                      end
          end
        rescue ActiveRecord::QueryCanceled
          options[:total_entries] = nil
        end
      end
    end
    super(options).to_a
  end
end

module FolioARPagination
  def configure_pagination(page, options)
    if !options.key?(:total_entries) && respond_to?(:count)
      begin
        connection.transaction(requires_new: true) do
          connection.execute("SET LOCAL statement_timeout='#{Folio::PAGINATION_COUNT_TIMEOUT}'")
          options[:total_entries] = count(:all)
        end
      rescue ActiveRecord::QueryCanceled
        options[:total_entries] = nil
      end
    end
    super(page, options)
  end
end

ActiveRecord::Relation.prepend(FolioARPagination)
