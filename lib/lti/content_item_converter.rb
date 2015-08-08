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
require 'ims/lti'

module Lti
  class ContentItemConverter

    def self.convert_resource_selection(opts)
      create_content_item(opts[:return_type],
                          {
                            id: opts[:url],
                            url: opts[:url],
                            text: opts[:text],
                            title: opts[:title],
                            placement_advice: placement_advice(opts[:return_type], opts),
                            media_type: media_type(opts[:return_type], opts)
                          })
    end


    def self.convert_oembed(data)
      data = data.with_indifferent_access
      return_type = {photo: 'image_url', link: 'url', video: 'rich_content', rich: 'rich_content'}[data['type'].to_sym]
      converted_opts = {
        id: data['url'],
        url: data['url'],
        title: data['title'],
        text: data['text'],
        placement_advice: placement_advice(return_type, data),
        media_type: media_type(return_type, data)
      }
      if data['type'] == 'photo' && data['url'].try(:match, /^http/)
        converted_opts[:text] = data['title']
        create_content_item(return_type, converted_opts)
      elsif data['type'] == 'link' && data['url'].try(:match, /^(http|https|mailto)/)
        create_content_item(return_type, converted_opts)
      elsif data['type'] == 'video' || data['type'] == 'rich'
        converted_opts[:text] = data['html']
        create_content_item(return_type, converted_opts)
      end
    end


    def self.create_content_item(return_type, converted_opts)
      case return_type
      when 'file'
        IMS::LTI::Models::ContentItems::FileItem.new(converted_opts)
      when 'lti_launch_url'
        IMS::LTI::Models::ContentItems::LtiLinkItem.new(converted_opts)
      else
        IMS::LTI::Models::ContentItems::ContentItem.new(converted_opts)
      end
    end

    private_class_method :create_content_item

    def self.placement_advice(return_type, opts = {})
      IMS::LTI::Models::ContentItemPlacement.new(
        display_height: opts[:height],
        display_width: opts[:width],
        presentation_document_target: presentation_document_target(return_type),
      )
    end

    private_class_method :placement_advice

    def self.presentation_document_target(return_type)
      case return_type
      when 'file'
        'download'
      when 'lti_launch_url'
        'frame'
      when 'image_url', 'rich_content'
        'embed'
      when 'iframe'
        'iframe'
      else # used for the url return_type as well
        'window'
      end
    end

    private_class_method :presentation_document_target

    def self.media_type(return_type, opts)
      case return_type
      when 'file'
        mime = opts[:content_type]
        mime.present? ? mime : lookup_mime(opts[:text], opts[:url])
      when 'image_url'
        lookup_mime(opts[:text], opts[:url]) || 'image'
      when 'lti_launch_url'
        'application/vnd.ims.lti.v1.ltilink'
      else # used for the following return_types url, iframe, default
        'text/html'
      end
    end

    private_class_method :media_type

    def self.lookup_mime(text, url)
      mime = MIME::Types.type_for(text || '').first || MIME::Types.type_for(url || '').first
      mime.present? ? mime.to_s : nil
    end

    private_class_method :lookup_mime


  end
end