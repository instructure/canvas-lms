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

module RuboCop::Canvas
  module LegacyMigrations
    def self.prepended(klass)
      klass.singleton_class.attr_accessor :legacy_cutoff_date
    end

    attr_reader :migration_date

    def legacy_migration?
      self.class.legacy_cutoff_date && migration_date && migration_date <= self.class.legacy_cutoff_date
    end

    def on_new_investigation
      file_path = processed_source.file_path
      @migration_date = $1 if File.basename(file_path) =~ /^(\d+)_/

      super
    end

    # we have to defer overridding methods until Rubocop sets up callbacks, since
    # any given callback method may or may not exist for a particular cop
    def callbacks_needed
      @legacy_migrations_anon_module ||= begin
        anon_module = Module.new
        super.each do |method|
          next unless respond_to?(method)

          anon_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}(*)               # def on_send(*)
              return if legacy_migration?  #   return if legacy_migration?
                                           #
              super                        #   super
            end                            # end
          RUBY
        end
        self.class.prepend(anon_module)
        anon_module
      end

      super
    end
  end
end
