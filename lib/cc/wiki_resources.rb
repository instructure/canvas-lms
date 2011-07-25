#
# Copyright (C) 2011 Instructure, Inc.
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
      
      @course.wiki.wiki_pages.active.each do |page|
        begin
          migration_id = CCHelper.create_key(page)
          file_name = "#{page.url}.html"
          relative_path = File.join(CCHelper::WIKI_FOLDER, file_name)
          path = File.join(wiki_folder, file_name)

          File.open(path, 'w') do |file|
            file << @html_exporter.html_page(page.body, page.title, @course, @manifest.exporter.user, migration_id)
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
