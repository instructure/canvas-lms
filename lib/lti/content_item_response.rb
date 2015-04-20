#
# Copyright (C) 2015 Instructure, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  class ContentItemResponse

    MEDIA_TYPES = [:assignments, :discussion_topics, :modules, :module_items, :pages, :quizzes, :files]
    SUPPORTED_EXPORT_TYPES = %w(common_cartridge)

    def initialize(context, controller, current_user, media_types, export_type)
      @context = context
      @media_types = media_types.with_indifferent_access
      @canvas_media_type = @media_types.keys.size == 1 ? @media_types.keys.first.to_s.singularize : 'course'
      @current_user = current_user
      @controller = controller #for url generation
      @export_type = export_type || 'common_cartridge' #legacy API behavior defaults to common cartridge
      raise Lti::UnsupportedExportTypeError unless SUPPORTED_EXPORT_TYPES.include? @export_type
    end

    def query_params
      unless @query_params
        select = {}
        @media_types.each { |k, v| select[k] = v }
        @query_params = {"export_type" => @export_type}
        @query_params['select'] = select if select.present?
      end
      @query_params
    end

    def media_type
      unless @media_type
        if @canvas_media_type == 'module_item'
          case tag.content
            when Assignment
              @media_type = 'assignment'
            when DiscussionTopic
              @media_type = 'discussion_topic'
            when Quizzes::Quiz
              @media_type = 'quiz'
            when WikiPage
              @media_type = 'page'
          end
        else
          @media_type = @canvas_media_type
        end
      end
      @media_type
    end

    def tag
      unless @tag
        if @media_types.include? :module_items
          @tag = @context.context_module_tags.where(id: @media_types[:module_items].first).first
        end
      end
      @tag
    end


    def file
      return unless @media_types.include? :files
      unless @file
        @file = Attachment.where(:id => @media_types[:files].first).first
        if @context.is_a?(Account)
          raise ActiveRecord::RecordNotFound unless @file.context == @current_user
        elsif @file.context.is_a?(Course)
          raise ActiveRecord::RecordNotFound unless @file.context == @context
        elsif @file.context.is_a?(Group)
          raise ActiveRecord::RecordNotFound unless @file.context.context == @context
        end
        raise Lti::UnauthorizedError if @file.locked_for?(@current_user, check_policies: true)
      end
      @file
    end

    def title
      @title ||= case @canvas_media_type
                   when 'file'
                     file.display_name
                   when 'assignment'
                     @context.assignments.where(id: @media_types[:assignments].first).first.title
                   when 'discussion_topic'
                     @context.discussion_topics.where(id: @media_types[:discussion_topics].first).first.title
                   when 'module'
                     @context.context_modules.where(id: @media_types[:modules].first).first.name
                   when 'page'
                     @context.wiki.wiki_pages.where(id: @media_types[:pages].first).first.title
                   when 'module_item'
                     tag.title
                   when 'quiz'
                     @context.quizzes.where(id: @media_types[:quizzes].first).first.title
                   when 'course'
                     @context.name
                 end
    end

    def content_type
      @content_type ||= @media_types.include?(:files) ? file.content_type : "application/vnd.instructure.api.content-exports.#{media_type}"
    end

    def url
      @url ||= @media_types.include?(:files) ? @controller.file_download_url(file, {:verifier => file.uuid, :download => '1', :download_frd => '1'}) : @controller.api_v1_course_content_exports_url(@context) + '?' + query_params.to_query
    end

    def as_json(opts={})
      case opts[:lti_message_type]
        when 'ContentItemSelectionResponse'
          content_item_selection_response_json
        when 'ContentItemSelection'
          content_item_selection_json
        else
          raise Lti::UnsupportedMessageTypeError
      end
    end


    private

    ##
    # This message type is deprecated, please use content_item_selection_json
    ##
    def content_item_selection_response_json
      {
        "@context" => "http://purl.imsglobal.org/ctx/lti/v1/ContentItemPlacement",
        "@graph" => [
          {
            "@type" => "ContentItemPlacement",
            "placementOf" => {
              "@type" => "FileItem",
              "@id" => url,
              "mediaType" => content_type,
              "title" => title
            }
          }
        ]
      }
    end

    def content_item_selection_json
      {
        "@context" => "http://purl.imsglobal.org/ctx/lti/v1/ContentItem",
        "@graph" => [
          {
            "@type" => "FileItem",
            "url" => url,
            "mediaType" => content_type,
            "title" => title,
            "copyAdvice" => true
          }
        ]
      }
    end

  end

  class UnauthorizedError < StandardError
  end

  class UnsupportedExportTypeError < StandardError
  end

  class UnsupportedMessageTypeError < StandardError
  end

end