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
module Canvas::CC
  module WikiResources
    
    def add_wiki_pages
      wiki_folder = File.join(@export_dir, CCHelper::WIKI_FOLDER)
      FileUtils::mkdir_p wiki_folder
      
      @course.wiki.wiki_pages.active.each do |page|
        migration_id = CCHelper.create_key(page)
        file_name = "#{page.url}.html"
        relative_path = File.join(CCHelper::WIKI_FOLDER, file_name)
        path = File.join(wiki_folder, file_name)
        
        File.open(path, 'w') do |file|
          file << wiki_content(page)
        end
        
        @resources.resource(
                :identifier => migration_id,
                "type" => CCHelper::WEBCONTENT,
                :href => relative_path
        ) do |res|
          res.file(:href=>relative_path)
        end
      end
    end

    def wiki_content(wiki)
      regex = Regexp.new(%r{/courses/#{@course.id}/([^\s"]*)})
      html = wiki.body
      html = html.gsub(regex) do |relative_url|
        sub_spot = $1
        new_url = nil
        
        {'assignments' => Assignment,
         'announcements' => Announcement,
         'calendar_events' => CalendarEvent,
         'discussion_topics' => DiscussionTopic,
         'collaborations' => Collaboration,
         'files' => Attachment,
         'conferences' => WebConference,
         'quizzes' => Quiz,
         'groups' => Group,
         'wiki' => WikiPage,
         'grades' => nil,
         'users' => nil
        }.each do |type, obj_class|
          if type != 'wiki' && sub_spot =~ %r{#{type}/(\d+)[^\s"]*$}
            # it's pointing to a specific file or object
            obj = obj_class.find($1) rescue nil
            if obj && obj.respond_to?(:grants_right?) && obj.grants_right?(@manifest.exporter.user, nil, :read)
              if type == 'files'
                folder = obj.folder.full_name.gsub("course files", CCHelper::WEB_CONTENT_TOKEN)
                new_url = "#{folder}/#{obj.display_name}"
              elsif migration_id = CCHelper.create_key(obj)
                new_url = "#{CCHelper::OBJECT_TOKEN}/#{type}/#{migration_id}"
              end
            end
            break
          elsif sub_spot =~ %r{#{type}(?:/([^\s"]*))?$}
            # it's pointing to a course content index or a wiki page
            if type == 'wiki' && $1
              new_url = "#{CCHelper::WIKI_TOKEN}/#{type}/#{$1}"
            else
              new_url = "#{CCHelper::COURSE_TOKEN}/#{type}"
              new_url += "/#{$1}" if $1
            end
            break
          end
        end
        new_url || relative_url
      end

      "<html>\n<head>\n<title>#{wiki.title}</title>\n</head>\n<body>\n#{html}\n</body>\n</html>"
    end
    
  end
end
