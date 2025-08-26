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

require_relative "../../../config/initializers/permissions_groups"

class PermissionsMarkdownCreator
  TEMPLATE = "doc/api/permissions/permissions.md.erb"
  OUTPUT_FILE = "doc/api/permissions/md/dynamic/permissions.md"

  AVAILABLE_TO_ABBREVIATIONS = {
    "StudentEnrollment" => "s",
    "TeacherEnrollment" => "t",
    "TaEnrollment" => "a",
    "DesignerEnrollment" => "d",
    "ObserverEnrollment" => "o"
  }.freeze

  def self.available_defaults(permission_info)
    AVAILABLE_TO_ABBREVIATIONS.map do |enrollment_type, abbreviation|
      if permission_info[:true_for].include?(enrollment_type)
        abbreviation.upcase
      elsif permission_info[:available_to].include?(enrollment_type)
        abbreviation
      else
        " "
      end
    end.join
  end

  def self.run
    require Rails.root.join("config/initializers/permissions_registry.rb")

    account_perms, course_perms = BASE_PERMISSIONS.partition do |_, info|
      (info[:available_to] - %w[AccountAdmin AccountMembership]).empty?
    end

    account_perms = account_perms
                    .reject { |_, info| info[:account_only] == :site_admin }
                    .map do |key, info|
                      { key:,
                        group: (info[:group] && PERMISSION_GROUPS.dig(info[:group], :label)&.call) || "",
                        label: info[:label].call }
                    end
                    .sort_by { |entry| [entry[:group], entry[:key]] }
                    .group_by { |entry| entry[:group] }

    course_perms = course_perms
                   .map do |key, info|
                     { key:,
                       group: (info[:group] && PERMISSION_GROUPS.dig(info[:group], :label)&.call) || "",
                       label: info[:label].call,
                       available_to: available_defaults(info) }
                   end
                   .sort_by { |entry| [entry[:group], entry[:key]] }
                   .group_by { |entry| entry[:group] }

    erb_renderer = ERB.new(Rails.root.join(TEMPLATE).read)
    Rails.root.join(OUTPUT_FILE).binwrite(erb_renderer.result(binding))
  end
end
