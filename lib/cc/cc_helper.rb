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
module CCHelper
  
  CANVAS_NAMESPACE = 'http://canvas.instructure.com/xsd/cccv1p0'
  XSD_URI = 'http://canvas.instructure.com/xsd/cccv1p0.xsd'
  
  # IMS formats/types
  IMS_DATE = "%Y-%m-%d"
  IMS_DATETIME = "%Y-%m-%dT%H:%M:%S"
  CC_EXTENSION = 'imscc'
  QTI_EXTENSION = ".xml.qti"
  CANVAS_PLATFORM = 'canvas.instructure.com'
  
  # Common Cartridge 1.0
  # associatedcontent/imscc_xmlv1p0/learning-application-resource
  # imsdt_xmlv1p0
  # imswl_xmlv1p0
  # imsqti_xmlv1p2/imscc_xmlv1p0/assessment
  # imsqti_xmlv1p2/imscc_xmlv1p0/question-bank
  
  # Common Cartridge 1.1 (What Canvas exports)
  ASSESSMENT_TYPE = 'imsqti_xmlv1p2/imscc_xmlv1p1/assessment'
  QUESTION_BANK = 'imsqti_xmlv1p2/imscc_xmlv1p1/question-bank'
  DISCUSSION_TOPIC = "imsdt_xmlv1p1"
  LOR = "associatedcontent/imscc_xmlv1p1/learning-application-resource"
  WEB_LINK = "imswl_xmlv1p1"
  WEBCONTENT = "webcontent"
  BASIC_LTI = 'imsbasiclti_xmlv1p0'
  BLTI_NAMESPACE = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
  
  # Common Cartridge 1.2
  # associatedcontent/imscc_xmlv1p2/learning-application-resource
  # imsdt_xmlv1p2
  # imswl_xmlv1p2
  # imsqti_xmlv1p2/imscc_xmlv1p2/assessment
  # imsqti_xmlv1p2/imscc_xmlv1p2/question-bank
  # imsbasiclti_xmlv1p0
  
  # substitution tokens
  OBJECT_TOKEN = "$CANVAS_OBJECT_REFERENCE$"
  COURSE_TOKEN = "$CANVAS_COURSE_REFERENCE$"
  WIKI_TOKEN = "$WIKI_REFERENCE$"
  WEB_CONTENT_TOKEN = "$IMS_CC_FILEBASE$"

  # file names/paths
  ASSESSMENT_CC_QTI = "assessment_qti.xml"
  ASSESSMENT_NON_CC_FOLDER = 'non_cc_assessments'
  ASSESSMENT_META = "assessment_meta.xml"
  ASSIGNMENT_GROUPS = "assignment_groups.xml"
  ASSIGNMENT_SETTINGS = "assignment_settings.xml"
  COURSE_SETTINGS = "course_settings.xml"
  COURSE_SETTINGS_DIR = "course_settings"
  EXTERNAL_FEEDS = "external_feeds.xml"
  GRADING_STANDARDS = "grading_standards.xml"
  EVENTS = "events.xml"
  LEARNING_OUTCOMES = "learning_outcomes.xml"
  MANIFEST = 'imsmanifest.xml'
  MODULE_META = "module_meta.xml"
  RUBRICS = "rubrics.xml"
  EXTERNAL_TOOLS = "external_tools.xml"
  FILES_META = "files_meta.xml"
  SYLLABUS = "syllabus.html"
  WEB_RESOURCES_FOLDER = 'web_resources'
  WIKI_FOLDER = 'wiki_content'
  MEDIA_OBJECTS_FOLDER = 'media_objects'
  
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
    date.respond_to?(:utc) ? date.utc.strftime(IMS_DATE) : date.strftime(IMS_DATE)
  end
  
  def self.ims_datetime(date=nil)
    date ||= Time.now
    date.respond_to?(:utc) ? date.utc.strftime(IMS_DATETIME) : date.strftime(IMS_DATETIME)
  end
  
  def get_html_title_and_body_and_id(doc)
    id = get_node_val(doc, 'html head meta[name=identifier] @content')
    get_html_title_and_body(doc) << id
  end
  
  def get_html_title_and_body(doc)
    title = get_node_val(doc, 'html head title')
    body = doc.at_css('html body').to_s.gsub(%r{</?body>}, '').strip
    [title, body]
  end

  require 'set'
  class HtmlContentExporter
    attr_reader :used_media_objects, :media_object_flavor, :media_object_infos

    def initialize(opts = {})
      @media_object_flavor = opts[:media_object_flavor]
      @used_media_objects = Set.new
      @media_object_infos = {}
    end

    def html_page(html, title, course, user, id = nil)
      content = html_content(html, course, user)
      meta_html = id.nil? ? "" : %{<meta name="identifier" content="#{id}"/>\n}

      %{<html>\n<head>\n<title>#{title}</title>\n#{meta_html}</head>\n<body>\n#{content}\n</body>\n</html>}
    end

    def html_content(html, course, user)
      return html if html.blank?
      regex = Regexp.new(%r{/courses/#{course.id}/([^\s"]*)})
      html = html.gsub(regex) do |relative_url|
        sub_spot = $1
        new_url = nil

        if sub_spot =~ %r{\Afile_contents/(.*)$}
          new_url = $1.gsub(/course( |%20)files/, WEB_CONTENT_TOKEN)
        else
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
           'users' => nil,
           'modules' => ContextModule
          }.each do |type, obj_class|
            if type != 'wiki' && sub_spot =~ %r{\A#{type}/(\d+)([^\s"]*)$}
              # it's pointing to a specific file or object
              obj = obj_class.find_by_id($1)
              rest = $2
              if obj && obj.respond_to?(:grants_right?) && obj.grants_right?(user, nil, :read)
                if type == 'files'
                  folder = obj.folder.full_name.gsub(/course( |%20)files/, WEB_CONTENT_TOKEN)
                  new_url = "#{folder}/#{URI.escape(obj.display_name)}#{CCHelper.file_query_string(rest)}"
                elsif migration_id = CCHelper.create_key(obj)
                  new_url = "#{OBJECT_TOKEN}/#{type}/#{migration_id}"
                end
              end
              break
            elsif sub_spot =~ %r{\A#{type}(?:/([^\s"]*))?$}
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
        end

        new_url || relative_url
      end

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css('a.instructure_inline_media_comment').each do |anchor|
        media_id = anchor['id'].gsub(/^media_comment_/, '')
        obj = course.media_objects.by_media_id(media_id).first
        if obj && obj.context == course && migration_id = CCHelper.create_key(obj)
          @used_media_objects << obj
          info = CCHelper.media_object_info(obj, nil, media_object_flavor)
          @media_object_infos[obj.id] = info
          anchor['href'] = File.join(WEB_CONTENT_TOKEN, MEDIA_OBJECTS_FOLDER, info[:filename])
        end
      end

      doc.to_s
    end
  end

  def self.media_object_info(obj, client = nil, flavor = nil)
    unless client
      client = Kaltura::ClientV3.new
      client.startSession(Kaltura::SessionType::ADMIN)
    end
    if flavor
      assets = client.flavorAssetGetByEntryId(obj.media_id)
      asset = assets.sort_by { |f| f[:size].to_i }.reverse.find { |f| f[:containerFormat] == flavor }
      asset ||= assets.first
    else
      asset = client.flavorAssetGetOriginalAsset(obj.media_id)
    end
    # we use the media_id as the export filename, since it is guaranteed to
    # be unique
    filename = "#{obj.media_id}.#{asset[:fileExt]}" if asset
    { :asset => asset, :filename => filename }
  end

  # sub_path is the last part of a file url: /courses/1/files/1(/download)
  # we want to handle any sort of extra params to the file url, both in the
  # path components and the query string
  def self.file_query_string(sub_path)
    return if sub_path.blank?
    qs = []
    uri = URI.parse(sub_path)
    unless uri.path == "/preview" # defaults to preview, so no qs added
      qs << "canvas_#{Rack::Utils.escape(uri.path[1..-1])}=1"
    end

    Rack::Utils.parse_query(uri.query).each do |k,v|
      qs << "canvas_qs_#{Rack::Utils.escape(k)}=#{Rack::Utils.escape(v)}"
    end

    return nil if qs.blank?
    "?#{qs.join("&")}"
  end

end
end
