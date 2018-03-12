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

require_relative "generic_detector"

module Selinimum
  module Detectors
    # we try to map out dependents of any ruby files when we generate the
    # spec dependency graph. because ruby and rails are so crazy/magical,
    # currently this is only possible for:
    #  * _spec.rb files
    #  * views
    #  * controllers
    #  * gems/models/lib/etc. that are autoloaded after specs start
    class RubyDetector < GenericDetector
      def can_process?(file, map)
        return false if file =~ GLOBAL_FILES
        return true if file =~ %r{\A(
                                   app/views/.*\.erb |
                                   app/controllers/.*\.rb |
                                   spec/.*_spec\.rb
                                 )\z}x
        return true if map["__all_autoloads"] && map["__all_autoloads"].include?(file)
        false
      end

      # we don't find dependents at this point; we do that during the
      # capture phase. so here we just return the file itself
      def dependents_for(file)
        ["file:#{file}"]
      end

      # stuff not worth tracking, since they are literally used everywhere.
      # so if they change, we test all the things
      GLOBAL_FILES = %r{\A(
        app/views/(layouts|shared)/.*\.erb |
        app/controllers/application_controller.rb |
        app/graphql/.*\.rb
      )\z}x
    end
  end
end

