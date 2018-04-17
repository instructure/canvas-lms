#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe Autoextend do
  it "all extensions get used" do
    Autoextend.extensions.each do |extension|
      next if extension.optional || extension.used

      # try to force it to be used, via autoloading
      begin
        extension.const_name.to_s.constantize
      rescue NameError
      end

      # not found via autoloading? maybe it's a migration
      if !extension.used
        if CANVAS_RAILS5_1
          ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths).map(&:disable_ddl_transaction)
        else
          ActiveRecord::Base.connection.migration_context.migrations.map(&:disable_ddl_transaction)
        end
      end

      extension_name = if extension.module.is_a?(Module)
                         extension.module.name
                       elsif extension.module
                         extension.module
                       else
                         extension.block
                       end
      expect(extension.used).to(eq(true), "expected extension #{extension_name} to hook into #{extension.const_name}")
    end
  end
end
