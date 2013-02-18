#
# Copyright (C) 2013 Instructure, Inc.
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

# Make 3rd party YAML safe for consumption. Note that this should not be
# included in Canvas proper, as we (de)serialize objects to/from yaml all
# over the place.

module I18nExtraction
  module SafeYAML
    def self.included(base)
      base.module_eval do
        class << self
          def load_with_discretion(io)
            data = io.respond_to?(:read) ? io.read : io
            # bail on anything that resembles an explicit type, except stuff we trust
            return false if data =~ /^([^"]+ )?!(?!binary|ruby\/symbol)/
            load_without_discretion(data)
          end

          alias_method_chain :load, :discretion

          def yolo!
            module_eval do
              class << self
                alias_method :load, :load_without_discretion
              end
            end
          end
        end
      end
    end
  end
end
