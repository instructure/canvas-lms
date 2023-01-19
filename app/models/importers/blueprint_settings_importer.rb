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

module Importers
  class BlueprintSettingsImporter < Importer
    def self.process_migration(data, migration)
      course = migration.context
      unless MasterCourses::MasterTemplate.blueprint_eligible?(course)
        migration.add_warning(I18n.t("Course is ineligible to be set as a blueprint"))
        return
      end

      bs = data[:blueprint_settings]
      return if bs.blank?

      template = MasterCourses::MasterTemplate.set_as_master_course(course)
      template.use_default_restrictions_by_type = bs["use_default_restrictions_by_type"]
      template.default_restrictions_by_type = bs["restrictions"].to_hash.transform_values(&:symbolize_keys)
      template.default_restrictions = template.default_restrictions_by_type.delete("default")
      unless template.save
        migration.add_warning(I18n.t("Invalid blueprint restriction types in imported package; using defaults"))
      end

      bs["restricted_items"].each do |item_hash|
        klass = item_hash["content_type"].constantize
        scope = if klass.new.respond_to?(:context_type)
                  klass.where(context_type: "Course", context_id: course.id)
                else
                  klass.where(course_id: course.id)
                end
        item = scope.find_by(migration_id: item_hash["migration_id"])
        next unless item

        tag = template.content_tag_for(item)
        tag.restrictions = item_hash["restrictions"].to_hash.symbolize_keys
        tag.use_default_restrictions = item_hash["use_default_restrictions"]
        tag.save!
      rescue NameError
        migration.add_warning(I18n.t("Invalid blueprint locked item type %{type} for item %{id}", type: item_hash["content_type"], id: item_hash["migration_id"]))
      rescue ActiveRecord::RecordInvalid
        migration.add_warning(I18n.t("Invalid blueprint restrictions for item %{id}", id: item_hash["migration_id"]))
      end
    end
  end
end
