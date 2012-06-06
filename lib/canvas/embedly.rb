#
# Copyright (C) 2012 Instructure, Inc.
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

class Canvas::Embedly < Struct.new(:title, :description, :images, :object_html, :data_type)

  class Image < Struct.new(:url)
    def as_json(*a)
      { 'url' => self.url }
    end
  end

  def initialize(url)
    self.images = []
    # if embedly returns any kind of error, we return a valid object with
    # all fields set to null
    get_data_for(url)
  end

  MAXWIDTH = 640

  def as_json(*a)
    { 'title' => self.title, 'description' => self.description, 'images' => self.images.map { |i| i.as_json(*a) }, 'object_html' => self.object_html, 'data_type' => self.data_type }
  end

  protected

  def get_data_for(url)
    data = get_embedly_data(url)

    return unless data
    if data.type == "error"
      ErrorReport.log_error :embedly, :message => "Error from embedly: #{data.inspect}"
      return
    end

    self.data_type = data.type
    self.title = data.title
    self.description = data.description
    if data.images
      self.images = data.images.map { |i| Image.new(i['url']) }
    elsif data.object && data.object.url
      self.images = [Image.new(data.url)]
    elsif data.thumbnail_url
      self.images = [Image.new(data.thumbnail_url)]
    end

    if data.object && data.object.html
      self.object_html = data.object.html
    elsif data.html
      self.object_html = data.html
    end

    # reject non-iframe html embeds
    if self.object_html.present?
      doc = Nokogiri::HTML::DocumentFragment.parse(self.object_html)
      if doc.children.map { |c| c.name.downcase } != ['iframe']
        self.object_html = nil
      end
    end

    @raw_response = data
  end

  def get_embedly_data(url)
    return unless settings
    Bundler.require "embedly"

    data = Canvas.timeout_protection("embedly") do
      embedly_api = ::Embedly::API.new(:key => settings[:api_key])
      api_method = settings[:plan_type] == "paid" ? :preview : :oembed
      embedly_api.send(api_method, {
        :url => url,
        :maxwidth => MAXWIDTH,
      }).first
    end
  end

  def settings
    @settings ||= PluginSetting.settings_for_plugin(:embedly)
  end

  def embedly_timeout
    Setting.get_cached('embedly_request_timeout', 15.seconds.to_s).to_f
  end
end
