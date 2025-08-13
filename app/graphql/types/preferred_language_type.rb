# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Types
  class PreferredLanguageType < Types::BaseEnum
    graphql_name "PreferredLanguageType"
    description "The preferred language for the translation, currently supporting only Cedar languages."

    Translation::CedarTranslator.languages.each do |lang|
      value lang[:id].sub("-", "_").upcase, value: lang[:id], description: lang[:name]
    end
  end
end
