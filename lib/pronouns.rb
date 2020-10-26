# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Pronouns

  DEFAULT_PRONOUNS = {
    "she_her" => -> { I18n.t('She/Her') },
    "he_him" => -> { I18n.t('He/Him') },
    "they_them" => -> { I18n.t('They/Them') }
  }.freeze

  def self.default_pronouns
    DEFAULT_PRONOUNS.values.map(&:call)
  end

  def clean_pronouns(string)
    string&.strip.presence
  end

  def translate_pronouns(pronouns)
    DEFAULT_PRONOUNS[pronouns]&.call || pronouns
  end

  def untranslate_pronouns(pronouns)
    pronouns = clean_pronouns(pronouns)
    DEFAULT_PRONOUNS.each do |k,v|
      return k if pronouns == v.call
    end
    pronouns
  end

end
