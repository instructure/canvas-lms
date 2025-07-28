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
#
module CC
  module WikiResources
    def add_wiki_pages
      wiki_folder = File.join(@export_dir, CCHelper::WIKI_FOLDER)
      FileUtils.mkdir_p wiki_folder

      scope = @course.wiki_pages.not_deleted
      # @user is nil if it's kicked off by the system, like a course template
      scope = WikiPages::ScopedToUser.new(@course, @user, scope).scope if @user
      scope.each do |page|
        next unless export_object?(page)
        next if @user && page.locked_for?(@user, check_policies: true)

        begin
          add_exported_asset(page)

          migration_id = create_key(page)
          name_max = path_max = nil
          File.open(wiki_folder) do |f|
            name_max = f.pathconf(Etc::PC_NAME_MAX)
            path_max = f.pathconf(Etc::PC_PATH_MAX)
          end
          name_max -= 5 if name_max
          path_max -= 5 + wiki_folder.length + 1 if path_max
          max = [name_max, path_max].compact.min
          file_name = page.block_editor ? "#{page.url[0...max]}.json" : "#{page.url[0...max]}.html"
          relative_path = File.join(CCHelper::WIKI_FOLDER, file_name)
          path = File.join(wiki_folder, file_name)
          meta_fields = { identifier: migration_id }
          meta_fields[:editing_roles] = page.editing_roles
          meta_fields[:notify_of_update] = page.notify_of_update
          meta_fields[:workflow_state] = page.workflow_state
          meta_fields[:front_page] = page.is_front_page?
          meta_fields[:module_locked] = page.locked_by_module_item?(@user, deep_check_if_needed: true).present?
          if page.for_assignment?
            meta_fields[:assignment_identifier] = create_key(page.assignment)
            meta_fields[:only_visible_to_overrides] = page.assignment.only_visible_to_overrides
            meta_fields[:assignment_overrides] = map_assignment_overrides(page.assignment)
          end
          meta_fields[:todo_date] = page.todo_date
          meta_fields[:publish_at] = page.publish_at
          meta_fields[:unlock_at] = page.unlock_at
          meta_fields[:lock_at] = page.lock_at

          File.open(path, "w") do |file|
            file << if page.block_editor
                      @html_exporter.json_page(page.block_editor, page.title, meta_fields)
                    else
                      @html_exporter.html_page(page.body, page.title, meta_fields)
                    end
          end

          @resources.resource(
            :identifier => migration_id,
            "type" => CCHelper::WEBCONTENT,
            :href => relative_path
          ) do |res|
            res.file(href: relative_path)
          end
        rescue
          add_error(I18n.t("course_exports.errors.wiki_page", "The wiki page \"%{title}\" failed to export", title: page.title), $!)
        end
      end
    end

    def map_assignment_overrides(assignment)
      assignment_overrides = assignment&.assignment_overrides
      active_overrides = assignment_overrides&.active
      return [] if active_overrides.blank?

      active_overrides.where(set_type: "Noop", quiz_id: nil).map do |o|
        override_attrs = o.slice(:set_type, :set_id, :title)
        AssignmentOverride.overridden_dates.each do |field|
          next unless o.send(:"#{field}_overridden")

          override_attrs["field"] = o[field]
        end
        override_attrs
      end.to_json
    end
  end
end
