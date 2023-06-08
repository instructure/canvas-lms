# frozen_string_literal: true

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

require "active_record/migration"

module CanvasPartman
  parent = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration

  class Migration < parent
    class << self
      # @attr [CanvasPartman::Partitioned] base_class
      #  The partitioned ActiveRecord::Base model _class_ we're modifying
      attr_accessor :base_class
    end

    def with_each_partition(&)
      find_partition_tables.each(&)
    end

    # Bind the migration to apply only on a certain partition table. Routines
    # like #with_each_partition will yield only the specified table instead.
    #
    # @param [String] table_name
    #   Name of the **existing** partition table.
    def restrict_to_partition(table_name)
      @partition_scope = table_name
      yield
    ensure
      @partition_scope = nil
    end

    def self.connection
      (base_class || ActiveRecord::Base).connection
    end

    private

    def partition_manager
      @partition_manager ||= PartitionManager.create(self.class.base_class)
    end

    def find_partition_tables
      return [@partition_scope] if @partition_scope

      partition_manager.partition_tables
    end
  end
end
