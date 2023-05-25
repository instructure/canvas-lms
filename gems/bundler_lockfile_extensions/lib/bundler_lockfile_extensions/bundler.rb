# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module BundlerLockfileExtensions
  module Bundler
    module ClassMethods
      def self.prepended(klass)
        super

        klass.attr_writer :cache_root, :default_lockfile, :root
      end

      def app_cache(custom_path = nil)
        super(custom_path || @cache_root)
      end

      def default_lockfile(force_original: false)
        return @default_lockfile if @default_lockfile && !force_original

        super()
      end

      def with_default_lockfile(lockfile)
        previous_default_lockfile, @default_lockfile = @default_lockfile, lockfile
        yield
      ensure
        @default_lockfile = previous_default_lockfile
      end
    end
  end
end
