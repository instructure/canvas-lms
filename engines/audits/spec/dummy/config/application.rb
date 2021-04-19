# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require 'active_record/railtie'
# require 'action_controller/railtie'
# require 'action_mailer/railtie'
# require "action_view/railtie"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

# require the engine under test
require 'audits'

module Dummy
  class Application < Rails::Application
    # config.secret_key_base = ENV['SECRET_KEY_BASE']
    # config.action_mailer.default_options = {from: 'audit_engine@instructure.com'}
    config.domain = 'http://test.host'
  end
end

Rails.application.require_environment!
