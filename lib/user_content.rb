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

require "nokogiri"
require "ritex"

module UserContent
  def self.escape(
    str,
    current_host = nil,
    use_updated_math_rendering = true
  )
    html = Nokogiri::HTML5.fragment(str, nil, **CanvasSanitize::SANITIZE[:parser_options])
    find_user_content(html) do |obj, uc|
      uuid = SecureRandom.uuid
      child = Nokogiri::XML::Node.new("iframe", html)
      child["class"] = "user_content_iframe"
      child["name"] = uuid
      child["style"] = "width: #{uc.width}; height: #{uc.height}"
      child["frameborder"] = "0"

      form = Nokogiri::XML::Node.new("form", html)
      form["action"] = "//#{HostUrl.file_host(@domain_root_account || Account.default, current_host)}/object_snippet"
      form["method"] = "post"
      form["class"] = "user_content_post_form"
      form["target"] = uuid
      form["id"] = "form-#{uuid}"

      input = Nokogiri::XML::Node.new("input", html)
      input["type"] = "hidden"
      input["name"] = "object_data"
      input["value"] = uc.node_string
      form.add_child(input)

      s_input = Nokogiri::XML::Node.new("input", html)
      s_input["type"] = "hidden"
      s_input["name"] = "s"
      s_input["value"] = uc.node_hmac
      form.add_child(s_input)

      obj.replace(child)
      child.add_next_sibling(form)
    end

    find_equation_images(html) do |node|
      equation = node["data-equation-content"] || node["alt"]
      next if equation.blank?

      # there are places in canvas (e.g. classic quizzes) that
      # inadvertently saved the hidden-readable span, causing
      # them to multiply everytime the entity is edited.
      # Strip the ones that shouldn't be there before adding a new one
      node.next_element.remove while node.next_element && node.next_element["class"] == "hidden-readable"

      unless use_updated_math_rendering
        mathml = UserContent.latex_to_mathml(equation)
        next if mathml.blank?

        mathml_span = node.fragment(
          "<span class=\"hidden-readable\">#{mathml}</span>"
        ).children.first
        node.add_next_sibling(mathml_span)
      end
    end

    html.to_s.html_safe
  end

  def self.latex_to_mathml(latex)
    Latex.to_math_ml(latex:)
  end

  Node = Struct.new(:width, :height, :node_string, :node_hmac)

  # for each user content in the nokogiri document, yields |nokogiri_node, UserContent::Node|
  def self.find_user_content(html)
    html.css("object,embed").each do |obj|
      styles = {}
      params = {}
      obj.css("param").each do |param|
        params[param["key"]] = param["value"]
      end
      (obj["style"] || "").split(";").each do |attr|
        key, value = attr.split(":").map(&:strip)
        styles[key] = value
      end
      width = css_size(obj["width"])
      width ||= css_size(params["width"])
      width ||= css_size(styles["width"])
      width ||= "400px"
      height = css_size(obj["height"])
      height ||= css_size(params["height"])
      height ||= css_size(styles["height"])
      height ||= "300px"

      snippet = Base64.encode64(obj.to_s).delete("\n")
      hmac = Canvas::Security.hmac_sha1(snippet)
      uc = Node.new(width, height, snippet, hmac)

      yield obj, uc
    end
  end

  def self.find_equation_images(html, &)
    html.css("img.equation_image").each(&)
  end

  # TODO: try and discover the motivation behind the "huhs"
  def self.css_size(val)
    to_f = TextHelper.round_if_whole(val.to_f)
    if !val || to_f == 0
      # no value, non-numeric value, or 0 value (whether "0", "0px", "0%",
      # etc.); ignore
      nil
    elsif val == "#{to_f}%" || val == "#{to_f}px"
      # numeric percentage or specific px value; use as is
      val
    elsif to_f.to_s == val
      # unadorned numeric value; make px (after adding 10... huh?)
      (to_f + 10).to_s + "px"
    else
      # numeric value embedded, but has additional text we didn't recognize;
      # just extract the numeric part (without a px... huh?)
      to_f.to_s
    end
  end

  class HtmlRewriter
    AssetTypes = {
      "assignments" => :Assignment,
      "announcements" => :Announcement,
      "calendar_events" => :CalendarEvent,
      "courses" => :Course,
      "discussion_topics" => :DiscussionTopic,
      "collaborations" => :Collaboration,
      "files" => :Attachment,
      "media_attachments_iframe" => :Attachment,
      "conferences" => :WebConference,
      "quizzes" => :"Quizzes::Quiz",
      "groups" => :Group,
      "wiki" => :WikiPage,
      "pages" => :WikiPage,
      "grades" => nil,
      "users" => nil,
      "external_tools" => nil,
      "file_contents" => nil,
      "modules" => :ContextModule,
      "items" => :ContentTag
    }.freeze
    DefaultAllowedTypes = AssetTypes.keys

    def initialize(context, user, contextless_types: [])
      raise(ArgumentError, "context required") unless context

      @context = context
      @user = user
      @contextless_types = contextless_types
      @context_prefix = "/#{context.class.name.tableize}/#{context.id}"
      @context_regex = %r{(?:/(#{context.class.name.tableize})/(#{context.id})|/(assessment_questions)/(\d+))}
      @absolute_part = '(https?://[\w-]+(?:\.[\w-]+)*(?:\:\d{1,5})?)?'
      @toplevel_regex = %r{#{@absolute_part}#{@context_regex}?/(\w+)(?:/([^\s"<'?/]*)([^\s"<']*))?}
      @handlers = {}
      @default_handler = nil
      @unknown_handler = nil
      @allowed_types = DefaultAllowedTypes
    end

    attr_reader :user, :context

    UriMatch = Struct.new(:url, :type, :obj_class, :obj_id, :rest, :prefix, :context_type, :context_id) do
      def query
        rest && rest[/\?.*/]
      end
    end

    # specify a url type like "assignments" or "file_contents"
    def set_handler(type, &handler)
      @handlers[type] = handler
    end

    def set_default_handler(&handler)
      @default_handler = handler
    end

    def set_unknown_handler(&handler)
      @unknown_handler = handler
    end

    def allowed_types=(new_types)
      @allowed_types = Array(new_types)
    end

    def translate_content(html)
      return html if html.blank?

      return precise_translate_content(html) if Account.site_admin.feature_enabled?(:precise_link_replacements)

      html.gsub(@toplevel_regex) { |url| replacement(url) }
    end

    def precise_translate_content(html)
      doc = Nokogiri::HTML5::DocumentFragment.parse(html, nil, { max_tree_depth: 10_000 })
      attributes = %w[value href longdesc src srcset title]

      doc.css("img, iframe, video, source, param, a").each do |e|
        attributes.each do |attr|
          attribute_value = e.attributes[attr]&.value
          if attribute_value&.match?(@toplevel_regex)
            e.inner_html = e.inner_html.gsub(@toplevel_regex) { |url| replacement(url) } if e.name == "a" && e["href"] && e.inner_html.delete("\n").strip.include?(e["href"].strip)
            e.set_attribute(attr, attribute_value.gsub(@toplevel_regex) { |url| replacement(url) })
          end
        end
      end
      doc.inner_html
    end

    def replacement(url)
      asset_types = AssetTypes.slice(*@allowed_types)
      matched = url.match(@toplevel_regex)
      context_type, context_id, type, obj_id, rest = [matched[2] || matched[4], matched[3] || matched[5], matched[6], matched[7], matched[8]]
      prefix = "/#{context_type}/#{context_id}" if context_type && context_id
      return url if !@contextless_types.include?(type) && prefix != @context_prefix && url.split("?").first != @context_prefix

      if type != "wiki" && type != "pages"
        if obj_id.to_i > 0
          obj_id = obj_id.to_i
        else
          rest = "/#{obj_id}#{rest}" if obj_id.present? || rest.present?
          obj_id = nil
        end
      end

      if (module_item = rest.try(:match, %r{/items/(\d+)}))
        type   = "items"
        obj_id = module_item[1].to_i
      end

      if asset_types.key?(type)
        klass = asset_types[type]
        klass = klass.to_s.constantize if klass
        match = UriMatch.new(url, type, klass, obj_id, rest, prefix, context_type, context_id)
        handler = @handlers[type] || @default_handler
        converted = handler&.call(match)
      else
        match = UriMatch.new(url, type)
        converted = @unknown_handler&.call(match)
      end
      converted ||= url
      converted.gsub("&amp;", "&") # get rid of ampersand conversions, it can trip up logic that runs after this
    end

    # if content is nil, it'll query the block for the content if needed (lazy content load)
    def user_can_view_content?(content = nil)
      return false if user.blank? && content.respond_to?(:locked?) && content.locked?
      return true unless user

      # if user given, check that the user is allowed to manage all
      # context content, or read that specific item (and it's not locked)
      @read_as_admin = context.grants_right?(user, :read_as_admin) if @read_as_admin.nil?
      return true if @read_as_admin

      content ||= yield
      allow = true if content.respond_to?(:grants_right?) && content.grants_right?(user, :read)
      allow = false if allow && content.respond_to?(:locked_for?) && content.locked_for?(user)
      allow
    end
  end
end
