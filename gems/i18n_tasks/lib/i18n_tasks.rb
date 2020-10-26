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

require "utf8_cleaner"
require "i18n"
require "sexp_processor"
require "ruby_parser"
require "json"

module I18nTasks
  require "i18n_tasks/hash_extensions"
  require "i18n_tasks/lolcalize"
  require "i18n_tasks/utils"
  require "i18n_tasks/i18n_import"

  require_relative "i18n_tasks/railtie" if defined?(Rails)
end
