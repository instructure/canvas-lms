# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

def init
  options[:objects] = run_verifier(options[:objects])

  regex = Regexp.new("^(#{MODEL_REGEX})$")
  options[:objects]
    .group_by { |o| o.tags("API").first.text }
    .sort_by  { |o| o.first.downcase }
    .each do |_r, cs|
      cs.each do |controller|
        (controller.tags(:object) + controller.tags(:model)).each do |obj|
          name, json = obj.text.split(/\n+/, 2).map(&:strip)
          next unless name.match(regex)

          $generated_schemas << name
          filename = name.underscore
          Templates::Engine.with_serializer("#{filename}.rb", options[:serializer]) do
            T("layout").run({ name:, json: })
          end
        end
      end
    end
end
