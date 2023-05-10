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
    module Definition
      def initialize(lockfile, *args)
        # we changed the default lockfile in BundlerLockfileExtensions.add_lockfile
        # since DSL.evaluate was called (re-entrantly); sub the proper value in
        if !lockfile.equal?(::Bundler.default_lockfile) && ::Bundler.default_lockfile(force_original: true) == lockfile
          lockfile = ::Bundler.default_lockfile
        end
        super
      end
    end
  end
end
