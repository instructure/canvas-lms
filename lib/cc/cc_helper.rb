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

require 'nokogiri'
require 'nokogumbo'

module CC
module CCHelper

  CANVAS_NAMESPACE = 'http://canvas.instructure.com/xsd/cccv1p0'
  XSD_URI = 'https://canvas.instructure.com/xsd/cccv1p0.xsd'

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
  BASIC_LTI_1_DOT_3 = 'imsbasiclti_xmlv1p3'
  BLTI_NAMESPACE = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"

  # Common Cartridge 1.2
  # associatedcontent/imscc_xmlv1p2/learning-application-resource
  # imsdt_xmlv1p2
  # imswl_xmlv1p2
  # imsqti_xmlv1p2/imscc_xmlv1p2/assessment
  # imsqti_xmlv1p2/imscc_xmlv1p2/question-bank
  # imsbasiclti_xmlv1p0

  # Common Cartridge 1.3
  ASSIGNMENT_TYPE = "assignment_xmlv1p0"
  ASSIGNMENT_NAMESPACE = "http://www.imsglobal.org/xsd/imscc_extensions/assignment"
  ASSIGNMENT_XSD_URI = "http://www.imsglobal.org/profile/cc/cc_extensions/cc_extresource_assignmentv1p0_v1p0.xsd"

  # QTI-only export
  QTI_ASSESSMENT_TYPE = 'imsqti_xmlv1p2'

  # substitution tokens
  OBJECT_TOKEN = "$CANVAS_OBJECT_REFERENCE$"
  COURSE_TOKEN = "$CANVAS_COURSE_REFERENCE$"
  WIKI_TOKEN = "$WIKI_REFERENCE$"
  WEB_CONTENT_TOKEN = "$IMS-CC-FILEBASE$"

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
  CANVAS_EXPORT_FLAG = 'canvas_export.txt'
  MEDIA_TRACKS = 'media_tracks.xml'
  ASSIGNMENT_XML = 'assignment.xml'
  EXTERNAL_CONTENT_FOLDER = 'external_content'
  RESOURCE_LINK_FOLDER = 'lti_resource_links'

  def ims_date(date=nil,default=Time.now)
    CCHelper.ims_date(date, default)
  end

  def ims_datetime(date=nil,default=Time.now)
    CCHelper.ims_datetime(date, default)
  end

  def self.create_key(object, prepend="", global: false)
    if object.is_a? ActiveRecord::Base
      key = global ? object.global_asset_string : object.asset_string
    elsif global && (md = object.to_s.match(/^(.*)_(\d+)$/))
      key = "#{md[1]}_#{Shard.global_id_for(md[2])}" # globalize asset strings
    else
      key = object.to_s
    end
    # make it obvious if we're using new identifiers now
    (global ? "g" : "i") + Digest::SHA256.hexdigest(prepend + key)
  end

  def self.ims_date(date=nil,default=Time.now)
    date ||= default
    return nil unless date
    date.respond_to?(:utc) ? date.utc.strftime(IMS_DATE) : date.strftime(IMS_DATE)
  end

  def self.ims_datetime(date=nil,default=Time.now)
    date ||= default
    return nil unless date
    date.respond_to?(:utc) ? date.utc.strftime(IMS_DATETIME) : date.strftime(IMS_DATETIME)
  end

  def get_html_title_and_body_and_id(doc)
    id = get_node_val(doc, 'html head meta[name=identifier] @content')
    get_html_title_and_body(doc) << id
  end

  def get_html_title_and_body_and_meta_fields(doc)
    meta_fields = {}
    doc.css('html head meta').each do |meta_node|
      if key = meta_node['name']
        meta_fields[key] = meta_node['content']
      end
    end
    get_html_title_and_body(doc) << meta_fields
  end

  def get_html_title_and_body(doc)
    title = get_node_val(doc, 'html head title')
    body = doc.at_css('html body').to_s.force_encoding(Encoding::UTF_8).gsub(%r{</?body>}, '').strip
    [title, body]
  end

  SPECIAL_REFERENCE_REGEX = /(?:\$|%24)[^%$]*(?:\$|%24)/
  WEB_CONTENT_REFERENCE_REGEX = Regexp.union(Regexp.new(Regexp.escape(CC::CCHelper::WEB_CONTENT_TOKEN)),
    Regexp.new(Regexp.escape(CGI.escape(CC::CCHelper::WEB_CONTENT_TOKEN))))

  def self.map_linked_objects(content)
    linked_objects = []
    html = Nokogiri::HTML5.fragment(content)
    html.css('a, img').each do |atag|
      source = atag['href'] || atag['src']
      next unless source =~ SPECIAL_REFERENCE_REGEX
      if source =~ WEB_CONTENT_REFERENCE_REGEX
        attachment_key = source.sub(WEB_CONTENT_REFERENCE_REGEX, '')
        attachment_key = attachment_key.split('?').first
        attachment_key = attachment_key.split('/').map {|ak| CGI.unescape(ak)}.join('/')
        linked_objects.push({local_path: attachment_key, type: 'Attachment'})
      else
        type, object_key = source.split('/').last 2
        if type =~ SPECIAL_REFERENCE_REGEX
          type = object_key
          object_key = nil
        end
        linked_objects.push({identifier: object_key, type: type})
      end
    end
    linked_objects
  end

  require 'set'
  class HtmlContentExporter
    attr_reader :used_media_objects, :media_object_flavor, :media_object_infos
    attr_accessor :referenced_files

    def initialize(course, user, opts = {})
      @media_object_flavor = opts[:media_object_flavor]
      @used_media_objects = Set.new
      @media_object_infos = {}
      @rewriter = UserContent::HtmlRewriter.new(course, user, contextless_types: ['files'])
      @course = course
      @user = user
      @track_referenced_files = opts[:track_referenced_files]
      @for_course_copy = opts[:for_course_copy]
      @for_epub_export = opts[:for_epub_export]
      @key_generator = opts[:key_generator] || CC::CCHelper
      @referenced_files = {}

      @rewriter.set_handler('file_contents') do |match|
        if match.url =~ %r{/media_objects/(\d_\w+)}
          # This is a media object referencing an attachment that it shouldn't be
          "/media_objects/#{$1}"
        else
          match.url.sub(/course( |%20)files/, WEB_CONTENT_TOKEN)
        end
      end
      @rewriter.set_handler('files') do |match|
        if match.obj_id.nil?
          if match_data = match.url.match(%r{/files/folder/(.*)})
            # this might not be the best idea but let's keep going and see what happens
            "#{COURSE_TOKEN}/files/folder/#{match_data[1]}"
          elsif match.prefix.present?
            # If match.obj_id is nil, it's because we're actually linking to a page
            # (the /courses/:id/files page) and not to a specific file. In this case,
            # just pass it straight through.
            "#{COURSE_TOKEN}/files"
          end
        else
          if @course && match.obj_class == Attachment
            obj = @course.attachments.find_by_id(match.obj_id)
          else
            obj = match.obj_class.where(id: match.obj_id).first
          end
          next(match.url) unless obj && (@rewriter.user_can_view_content?(obj) || @for_epub_export)

          @referenced_files[obj.id] = @key_generator.create_key(obj) if @track_referenced_files && !@referenced_files[obj.id]

          if @for_course_copy
            "#{COURSE_TOKEN}/file_ref/#{@key_generator.create_key(obj)}#{match.rest}"
          else
            # for files in exports, turn it into a relative link by path, rather than by file id
            # we retain the file query string parameters
            folder = obj.folder.full_name.sub(/course( |%20)files/, WEB_CONTENT_TOKEN)
            folder = folder.split("/").map{|part| URI.escape(part)}.join("/")
            path = "#{folder}/#{URI.escape(obj.display_name)}"
            path = HtmlTextHelper.escape_html(path)
            "#{path}#{CCHelper.file_query_string(match.rest)}"
          end
        end
      end
      wiki_handler = Proc.new do |match|
        # WikiPagesController allows loosely-matching URLs; fix them before exporting
        if match.obj_id.present?
          url_or_title = match.obj_id
          page = @course.wiki_pages.deleted_last.where(url: url_or_title).first ||
                 @course.wiki_pages.deleted_last.where(url: url_or_title.to_url).first ||
                 @course.wiki_pages.where(id: url_or_title.to_i).first
        end
        if page
          query = translate_module_item_query(match.query)
          "#{WIKI_TOKEN}/#{match.type}/#{page.url}#{query}"
        else
          "#{WIKI_TOKEN}/#{match.type}/#{match.obj_id}#{match.query}"
        end
      end
      @rewriter.set_handler('wiki', &wiki_handler)
      @rewriter.set_handler('pages', &wiki_handler)
      @rewriter.set_handler('items') do |match|
        item = ContentTag.find(match.obj_id)
        migration_id = @key_generator.create_key(item)
        new_url = "#{COURSE_TOKEN}/modules/#{match.type}/#{migration_id}#{match.query}"
      end
      @rewriter.set_default_handler do |match|
        new_url = match.url
        if match.obj_id && match.obj_class
          obj = match.obj_class.where(id: match.obj_id).first
          if obj && (@rewriter.user_can_view_content?(obj) || @for_epub_export)
            # for all other types,
            # create a migration id for the object, and use that as the new link
            migration_id = @key_generator.create_key(obj)
            query = translate_module_item_query(match.query)
            new_url = "#{OBJECT_TOKEN}/#{match.type}/#{migration_id}#{query}"
          end
        elsif match.obj_id
          new_url = "#{COURSE_TOKEN}/#{match.type}/#{match.obj_id}#{match.rest}"
        else
          new_url = "#{COURSE_TOKEN}/#{match.type}#{match.rest}"
        end
        new_url
      end

      protocol = HostUrl.protocol
      host = HostUrl.context_host(@course)
      port = ConfigFile.load("domain").try(:[], :domain).try(:split, ':').try(:[], 1)
      @url_prefix = "#{protocol}://#{host}"
      @url_prefix += ":#{port}" if !host.include?(':') && port.present?
    end

    def translate_module_item_query(query)
      return query unless query&.include?("module_item_id=")
      original_param = query.sub("?", "").split("&").detect{|p| p.include?("module_item_id=")}
      tag_id = original_param.split("=").last
      new_param = "module_item_id=#{@key_generator.create_key(ContentTag.new(:id => tag_id))}"
      query.sub(original_param, new_param)
    end

    attr_reader :course, :user

    def html_page(html, title, meta_fields={})
      content = html_content(html)
      meta_html = ""
      meta_fields.each_pair do |k, v|
        next unless v.present?
        meta_html += %{<meta name="#{HtmlTextHelper.escape_html(k.to_s)}" content="#{HtmlTextHelper.escape_html(v.to_s)}"/>\n}
      end

      %{<html>\n<head>\n<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>\n<title>#{HtmlTextHelper.escape_html(title)}</title>\n#{meta_html}</head>\n<body>\n#{content}\n</body>\n</html>}
    end

    def html_content(html)
      html = @rewriter.translate_content(html)
      return html if html.blank? || @for_course_copy

      # keep track of found media comments, and translate them into links into the files tree
      # if imported back into canvas, they'll get uploaded to the media server
      # and translated back into media comments
      doc = Nokogiri::HTML5.fragment(html)
      doc.css('a.instructure_inline_media_comment').each do |anchor|
        next unless anchor['id']
        media_id = anchor['id'].gsub(/^media_comment_/, '')
        obj = MediaObject.by_media_id(media_id).first
        if obj && migration_id = @key_generator.create_key(obj)
          @used_media_objects << obj
          info = CCHelper.media_object_info(obj, course: @course, flavor: media_object_flavor)
          @media_object_infos[obj.id] = info
          anchor['href'] = File.join(WEB_CONTENT_TOKEN, info[:path])
        end
      end

      # process new RCE media iframes too
      doc.css('iframe[data-media-id]').each do |iframe|
        media_id = iframe['data-media-id']
        obj = MediaObject.by_media_id(media_id).take
        if obj && migration_id = @key_generator.create_key(obj)
          @used_media_objects << obj
          info = CCHelper.media_object_info(obj, course: @course, flavor: media_object_flavor)
          @media_object_infos[obj.id] = info
          iframe['src'] = File.join(WEB_CONTENT_TOKEN, info[:path])
        end
      end

      # prepend the Canvas domain to remaining absolute paths that are missing the host
      # (those in the course are already "$CANVAS_COURSE_REFERENCE$/...", but links
      #  outside the course need a domain to be meaningful in the export)
      # see also Api#api_user_content, which does a similar thing
      Api::Html::Content::URL_ATTRIBUTES.each do |tag, attributes|
        doc.css(tag).each do |element|
          attributes.each do |attribute|
            url_str = element[attribute]
            begin
              url = URI.parse(url_str)
              if !url.host && url_str[0] == '/'[0]
                element[attribute] = "#{@url_prefix}#{url_str}"
              end
            rescue URI::Error => e
              # leave it as is
            end
          end
        end
      end

      return doc.to_s
    end
  end

  def self.media_object_info(obj, course: nil, client: nil, flavor: nil)
    unless client
      client = CanvasKaltura::ClientV3.new
      client.startSession(CanvasKaltura::SessionType::ADMIN)
    end
    if flavor
      assets = client.flavorAssetGetByEntryId(obj.media_id)
      asset = assets.sort_by { |f| f[:size].to_i }.reverse.find { |f| f[:containerFormat] == flavor }
      asset ||= assets.first
    else
      asset = client.flavorAssetGetOriginalAsset(obj.media_id)
    end
    attachment = course && obj.attachment_id && course.attachments.not_deleted.find_by_id(obj.attachment_id)
    path = if attachment
      # if the media object is associated with a file in the course, use the file's path in the export, to avoid exporting it twice
      attachment.full_display_path.sub(/^#{Regexp.quote(Folder::ROOT_FOLDER_NAME)}/, '')
    else
      # otherwise export to a file named after the media id
      filename = obj.media_id
      filename += ".#{asset[:fileExt]}" if asset
      File.join(MEDIA_OBJECTS_FOLDER, filename)
    end
    { :asset => asset, :path => path }
  end

  # sub_path is the last part of a file url: /courses/1/files/1(/download)
  # we want to handle any sort of extra params to the file url, both in the
  # path components and the query string
  def self.file_query_string(sub_path)
    return if sub_path.blank?
    qs = []
    begin
      uri = URI.parse(sub_path)
      unless uri.path == "/preview" # defaults to preview, so no qs added
        qs << "canvas_#{Rack::Utils.escape(uri.path[1..-1])}=1"
      end

      Rack::Utils.parse_query(uri.query).each do |k,v|
        qs << "canvas_qs_#{Rack::Utils.escape(k)}=#{Rack::Utils.escape(v)}"
      end
    rescue URI::Error => e
      # if we can't parse the url, we can't preserve canvas query params
    end
    return nil if qs.blank?
    "?#{qs.join("&")}"
  end

end
end
