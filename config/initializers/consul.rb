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

# Looking for the DynamicSettings initializer?
# It used to be here, but we actually need our consul
# initialization to happen early enough that other
# initializing things can read their consul settings,
# so all of the "setup" stuff for reading from consul is
# in lib/dynamic_settings_initializer.rb and it gets invoked
# from application.rb as the "canvas.init_dynamic_settings"
# initializer.
