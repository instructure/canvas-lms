# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler"
Bundler.self_manager.restart_with_locked_bundler_if_needed

# Default to loading :app_server gems for app servers, :jobs_server gems for jobs servers.
# Everything else (e.g. console, runner) will load both groups by default.
#
# Of course the default can be overridden by setting the RAILS_GROUPS env var explicitly.
ENV["RAILS_GROUPS"] ||= if ENV["RUNNING_AS_DAEMON"]
                          "jobs_server"
                        elsif ENV["RUNNING_IN_RACK"]
                          "app_server"
                        else
                          "app_server,jobs_server"
                        end

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])
require "bootsnap/setup" unless ENV["RAILS_ENV"] == "production"
