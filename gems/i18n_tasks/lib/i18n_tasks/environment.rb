# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module I18nTasks
  class Environment
    def self.apply
      require "bundler"
      Bundler.setup
      # for consistency in how canvas does json ... this way our specs can
      # verify _core_en is up to date
      require_relative "../../../../config/initializers/json"

      # set up rails i18n paths ... normally rails env does this for us :-/
      require "action_controller"
      require "active_record"
      require "will_paginate"
      I18n.load_path.unshift(*WillPaginate::I18n.load_path)
      I18n.load_path += Dir[Rails.root.join("gems/plugins/*/config/locales/*.{rb,yml}")]
      I18n.load_path += Dir[Rails.root.join("config/locales/*.{rb,yml}")]
      I18n.load_path += Dir[Rails.root.join("config/locales/locales.yml")]
      I18n.load_path += Dir[Rails.root.join("config/locales/community.csv")]

      I18n::Backend::Simple.include I18nTasks::CsvBackend
      I18n::Backend::Simple.include I18n::Backend::Fallbacks

      require "i18nliner/extractors/translation_hash"
      I18nliner::Extractors::TranslationHash.class_eval do
        def encode_with(coder)
          coder.represent_map nil, self # make translation hashes encode to yaml like a regular hash
        end
      end
    end
  end
end
