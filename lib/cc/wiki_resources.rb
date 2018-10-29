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
      FileUtils::mkdir_p wiki_folder

      scope = @course.wiki_pages.not_deleted
      WikiPages::ScopedToUser.new(@course, @user, scope).scope.each do |page|
        next unless export_object?(page)
        next if @user && page.locked_for?(@user)

        begin
          add_exported_asset(page)

          migration_id = create_key(page)
          file_name = "#{page.url}.html"
          relative_path = File.join(CCHelper::WIKI_FOLDER, file_name)
          path = File.join(wiki_folder, file_name)
          meta_fields = {:identifier => migration_id}
          meta_fields[:editing_roles] = page.editing_roles
          meta_fields[:notify_of_update] = page.notify_of_update
          meta_fields[:workflow_state] = page.workflow_state
          meta_fields[:front_page] = page.is_front_page?
          meta_fields[:module_locked] = page.locked_by_module_item?(@user, deep_check_if_needed: true).present?
          if page.for_assignment?
            meta_fields[:assignment_identifier] = create_key(page.assignment)
            meta_fields[:only_visible_to_overrides] = page.assignment.only_visible_to_overrides
          end
          meta_fields[:todo_date] = page.todo_date

          File.open(path, 'w') do |file|
            file << @html_exporter.html_page(page.body, page.title, meta_fields)
          end

          @resources.resource(
                  :identifier => migration_id,
                  "type" => CCHelper::WEBCONTENT,
                  :href => relative_path
          ) do |res|
            res.file(:href=>relative_path)
          end
        rescue
          title = page.title rescue I18n.t('course_exports.unknown_titles.wiki_page', "Unknown wiki page")
          add_error(I18n.t('course_exports.errors.wiki_page', "The wiki page \"%{title}\" failed to export", :title => title), $!)
        end
      end
    end
  end
end
