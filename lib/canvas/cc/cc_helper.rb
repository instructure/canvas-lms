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
module CCHelper
  
  CANVAS_NAMESPACE = 'http://www.instructure.com/xsd/cccv0p1'
  XSD_URI = 'cccv0p1.xsd'
  
  # IMS formats/types
  IMS_DATE = "%Y-%m-%d"
  IMS_DATETIME = "%Y-%m-%dT%H:%M:%S"
  LOR = "associatedcontent/imscc_xmlv1p0/learning-application-resource"
  WEBCONTENT = "webcontent"
  CC_EXTENSION = 'imscc'
  # The IMS documentation for Common Cartridge has conflicting values
  # for these, and the validator wants different values as well
  # todo use the correct value once IMS documentation is updated
  #DISCUSSION_TOPIC = "imsccdt_xmlv1p1"
  #DISCUSSION_TOPIC = "imsdt_xmlv1p1"
  DISCUSSION_TOPIC = "imsdt_xmlv1p0"
  #WEB_LINK = "imsccwl_xmlv1p1"
  #WEB_LINK = "imswl_xmlv1p1"
  WEB_LINK = "imswl_xmlv1p0"
  
  # substitution tokens
  OBJECT_TOKEN = "$CANVAS_OBJECT_REFERENCE$"
  COURSE_TOKEN = "$CANVAS_COURSE_REFERENCE$"
  WIKI_TOKEN = "$WIKI_REFERENCE$"
  WEB_CONTENT_TOKEN = "$IMS_CC_FILEBASE$"

  # file names/paths
  COURSE_SETTINGS_DIR = "course_settings"
  COURSE_SETTINGS = "course_settings.xml"
  SYLLABUS = "syllabus.html"
  ASSIGNMENT_SETTINGS = "assignment_settings.xml"
  WIKI_FOLDER = 'wiki_content'
  MANIFEST = 'imsmanifest.xml'
  WEB_RESOURCES_FOLDER = 'web_resources'
  
  def create_key(object, prepend="")
    CCHelper.create_key(object, prepend)
  end
  
  def ims_date(date=nil)
    CCHelper.ims_date(date)
  end
  
  def ims_datetime(date=nil)
    CCHelper.ims_datetime(date)
  end
  
  def self.create_key(object, prepend="")
    if object.is_a? ActiveRecord::Base
      key = object.asset_string
    else
      key = object.to_s
    end
    "i" + Digest::MD5.hexdigest(prepend + key)
  end
  
  def self.ims_date(date=nil)
    date ||= Time.now
    date.strftime(IMS_DATE)
  end
  
  def self.ims_datetime(date=nil)
    date ||= Time.now
    date.strftime(IMS_DATETIME)
  end
  
  def self.html_page(html, title, course, user)
    content = html_content(html, course, user)
    "<html>\n<head>\n<title>#{title}</title>\n</head>\n<body>\n#{content}\n</body>\n</html>"
  end
  
  def self.html_content(html, course, user)
      regex = Regexp.new(%r{/courses/#{course.id}/([^\s"]*)})
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
            if obj && obj.respond_to?(:grants_right?) && obj.grants_right?(user, nil, :read)
              if type == 'files'
                folder = obj.folder.full_name.gsub("course files", WEB_CONTENT_TOKEN)
                new_url = "#{folder}/#{obj.display_name}"
              elsif migration_id = CCHelper.create_key(obj)
                new_url = "#{OBJECT_TOKEN}/#{type}/#{migration_id}"
              end
            end
            break
          elsif sub_spot =~ %r{#{type}(?:/([^\s"]*))?$}
            # it's pointing to a course content index or a wiki page
            if type == 'wiki' && $1
              new_url = "#{WIKI_TOKEN}/#{type}/#{$1}"
            else
              new_url = "#{COURSE_TOKEN}/#{type}"
              new_url += "/#{$1}" if $1
            end
            break
          end
        end
        new_url || relative_url
      end

      html
    end
  
end
end