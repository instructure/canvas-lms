require 'nokogiri'
require 'ritex'
require 'securerandom'

module UserContent
  def self.escape(str, current_host = nil)
    html = Nokogiri::HTML::DocumentFragment.parse(str)
    find_user_content(html) do |obj, uc|
      uuid = SecureRandom.uuid
      child = Nokogiri::XML::Node.new("iframe", html)
      child['class'] = 'user_content_iframe'
      child['name'] = uuid
      child['style'] = "width: #{uc.width}; height: #{uc.height}"
      child['frameborder'] = '0'

      form = Nokogiri::XML::Node.new("form", html)
      form['action'] = "//#{HostUrl.file_host(@domain_root_account || Account.default, current_host)}/object_snippet"
      form['method'] = 'post'
      form['class'] = 'user_content_post_form'
      form['target'] = uuid
      form['id'] = "form-#{uuid}"

      input = Nokogiri::XML::Node.new("input", html)
      input['type'] = 'hidden'
      input['name'] = 'object_data'
      input['value'] = uc.node_string
      form.add_child(input)

      s_input = Nokogiri::XML::Node.new("input", html)
      s_input['type'] = 'hidden'
      s_input['name'] = 's'
      s_input['value'] = uc.node_hmac
      form.add_child(s_input)

      obj.replace(child)
      child.add_next_sibling(form)
    end

    find_equation_images(html) do |node|
      mathml = latex_to_mathml(node['alt'])
      next if mathml.blank?

      mathml_span = Nokogiri::HTML::DocumentFragment.parse(
        "<span class=\"hidden-readable\">#{mathml}</span>"
      )
      node.add_next_sibling(mathml_span)
    end

    html.to_s.html_safe
  end

  def self.latex_to_mathml(latex)
    Latex.to_math_ml(latex: latex)
  end

  class Node < Struct.new(:width, :height, :node_string, :node_hmac)
  end

  # for each user content in the nokogiri document, yields |nokogiri_node, UserContent::Node|
  def self.find_user_content(html)
    html.css('object,embed').each do |obj|
      styles = {}
      params = {}
      obj.css('param').each do |param|
        params[param['key']] = param['value']
      end
      (obj['style'] || '').split(/\;/).each do |attr|
        key, value = attr.split(/\:/).map(&:strip)
        styles[key] = value
      end
      width = css_size(obj['width'])
      width ||= css_size(params['width'])
      width ||= css_size(styles['width'])
      width ||= '400px'
      height = css_size(obj['height'])
      height ||= css_size(params['height'])
      height ||= css_size(styles['height'])
      height ||= '300px'

      snippet = Base64.encode64(obj.to_s).gsub("\n", '')
      hmac = Canvas::Security.hmac_sha1(snippet)
      uc = Node.new(width, height, snippet, hmac)

      yield obj, uc
    end
  end

  def self.find_equation_images(html)
    html.css('img.equation_image').each do |node|
      yield node
    end
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
      'assignments' => :Assignment,
      'announcements' => :Announcement,
      'calendar_events' => :CalendarEvent,
      'discussion_topics' => :DiscussionTopic,
      'collaborations' => :Collaboration,
      'files' => :Attachment,
      'conferences' => :WebConference,
      'quizzes' => :"Quizzes::Quiz",
      'groups' => :Group,
      'wiki' => :WikiPage,
      'pages' => :WikiPage,
      'grades' => nil,
      'users' => nil,
      'external_tools' => nil,
      'file_contents' => nil,
      'modules' => :ContextModule,
      'items' => :ContentTag
    }
    DefaultAllowedTypes = AssetTypes.keys

    def initialize(context, user)
      raise(ArgumentError, "context required") unless context
      @context = context
      @user = user
      # capture group 1 is the object type, group 2 is the object id, if it's
      # there, and group 3 is the rest of the url, including any beginning '/'
      @toplevel_regex = %r{/#{context.class.name.tableize}/#{context.id}/(\w+)(?:/([^\s"<'\?\/]*)([^\s"<']*))?}
      @handlers = {}
      @default_handler = nil
      @unknown_handler = nil
      @allowed_types = DefaultAllowedTypes
    end

    attr_reader :user, :context

    class UriMatch < Struct.new(:url, :type, :obj_class, :obj_id, :rest)
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

      asset_types = AssetTypes.reject { |k,v| !@allowed_types.include?(k) }

      html.gsub(@toplevel_regex) do |relative_url|
        type, obj_id, rest = [$1, $2, $3]
        if type != "wiki" && type != "pages"
          if obj_id.to_i > 0
            obj_id = obj_id.to_i
          else
            rest = "/#{obj_id}#{rest}" if obj_id.present? || rest.present?
            obj_id = nil
          end
        end

        if module_item = rest.try(:match, %r{/items/(\d+)})
          type   = 'items'
          obj_id = module_item[1].to_i
        end

        if asset_types.key?(type)
          klass = asset_types[type]
          klass = klass.to_s.constantize if klass
          match = UriMatch.new(relative_url, type, klass, obj_id, rest)
          handler = @handlers[type] || @default_handler
          (handler && handler.call(match)) || relative_url
        else
          match = UriMatch.new(relative_url, type)
          (@unknown_handler && @unknown_handler.call(match)) || relative_url
        end
      end
    end

    # if content is nil, it'll query the block for the content if needed (lazy content load)
    def user_can_view_content?(content = nil, &get_content)
      return false if user.blank? && content.respond_to?(:locked?) && content.locked?
      return true unless user
      # if user given, check that the user is allowed to manage all
      # context content, or read that specific item (and it's not locked)
      @read_as_admin = context.grants_right?(user, :read_as_admin) if @read_as_admin.nil?
      return true if @read_as_admin
      content ||= get_content.call
      allow = true if content.respond_to?(:grants_right?) && content.grants_right?(user, :read)
      allow = false if allow && content.respond_to?(:locked_for?) && content.locked_for?(user)
      return allow
    end
  end
end
