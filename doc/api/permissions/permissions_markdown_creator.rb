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
  DETAILS_TEMPLATE = "doc/api/permissions/permission_details.md.erb"
  OUTPUT_PATH = "doc/api/permissions/md/dynamic"
  DETAILS_KEYS = %i[account_details
                    course_details
                    details].freeze
  CONSIDERATIONS_KEYS = %i[account_considerations
                           course_considerations
                           considerations].freeze

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

  def self.run(format)
    raise ArgumentError, "format must be :html or :md" unless %i[html md].include?(format)

    require Rails.root.join("config/initializers/permissions_registry.rb")

    erb_renderer = ERB.new(Rails.root.join(TEMPLATE).read)
    details_renderer = ERB.new(Rails.root.join(DETAILS_TEMPLATE).read)

    group_names = PERMISSION_GROUPS.transform_values { |g| g[:label].call }.sort_by(&:last).to_h

    account_perms, course_perms = BASE_PERMISSIONS.partition do |_, info|
      (info[:available_to] - %w[AccountAdmin AccountMembership]).empty?
    end
    account_perms = account_perms
                    .reject { |_, info| info[:account_only] == :site_admin }
                    .map do |key, info|
                      { key:,
                        group: info[:group],
                        label: info[:label].call }
                    end
                    .sort_by { |entry| [group_names[entry[:group]] || "", entry[:key]] }
                    .group_by { |entry| entry[:group] }

    course_perms = course_perms
                   .map do |key, info|
                     { key:,
                       group: info[:group],
                       label: info[:label].call,
                       available_to: available_defaults(info) }
                   end
                   .sort_by { |entry| [group_names[entry[:group]] || "", entry[:key]] }
                   .group_by { |entry| entry[:group] }

    documented_perms = Set.new
    write_perm_docs = lambda do |perm_or_group, info|
      details = info.values_at(*DETAILS_KEYS).find(&:present?)&.map { it.transform_values(&:call) }
      considerations = info.values_at(*CONSIDERATIONS_KEYS).find(&:present?)&.map { it.transform_values(&:call) }
      if details || considerations
        documented_perms << perm_or_group
        Rails.root.join(OUTPUT_PATH, "permissions_#{perm_or_group}.md").binwrite(
          details_renderer.result_with_hash(name: info[:label].call, details:, considerations:)
        )
      end
    end
    BASE_PERMISSIONS.each { |perm, info| write_perm_docs.call(perm, info) }
    PERMISSION_GROUPS.each { |group, info| write_perm_docs.call(group, info) }

    group_name_with_link = lambda do |group|
      documented_perms.include?(group) ? "[#{group_names[group]}](file.permissions_#{group}.#{format})" : group_names[group]
    end

    perm_name_with_link = lambda do |perm, name|
      documented_perms.include?(perm) ? "[#{name}](file.permissions_#{perm}.#{format})" : name
    end

    Rails.root.join(OUTPUT_PATH, "permissions.md").binwrite(
      erb_renderer.result_with_hash(course_perms:, account_perms:, group_name_with_link:, perm_name_with_link:)
    )
  end
end
