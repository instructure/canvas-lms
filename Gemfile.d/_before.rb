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
#

# rubocop:disable Style/GlobalVars
if $ruby_version_warning.nil? && !ENV["SUPPRESS_RUBY_WARNING"]
  $ruby_version_warning = true
  if RUBY_ENGINE == "truffleruby"
    warn "TruffleRuby support is experimental"
  elsif RUBY_VERSION >= "3.2.0"
    warn "Ruby 3.2+ support is experimental"
  end
end
# rubocop:enable Style/GlobalVars
ruby ">= 3.1.0"
