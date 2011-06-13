module UserContent
  def self.escape(str)
    html = Nokogiri::HTML::DocumentFragment.parse(str)
    html.css('object,embed').each_with_index do |obj, idx|
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

      uuid = UUIDSingleton.instance.generate
      child = Nokogiri::XML::Node.new("iframe", html)
      child['class'] = 'user_content_iframe'
      child['name'] = uuid
      child['style'] = "width: #{width}; height: #{height}"
      child['frameborder'] = '0'

      form = Nokogiri::XML::Node.new("form", html)
      form['action'] = "//#{HostUrl.file_host(@domain_root_account || Account.default)}/object_snippet"
      form['method'] = 'post'
      form['class'] = 'user_content_post_form'
      form['target'] = uuid
      form['id'] = "form-#{uuid}"

      input = Nokogiri::XML::Node.new("input", html)
      input['type'] = 'hidden'
      input['name'] = 'object_data'
      snippet = Base64.encode64(obj.to_s).gsub("\n", '')
      input['value'] = snippet
      form.add_child(input)

      s_input = Nokogiri::XML::Node.new("input", html)
      s_input['type'] = 'hidden'
      s_input['name'] = 's'
      s_input['value'] = Canvas::Security.hmac_sha1(snippet)
      form.add_child(s_input)

      obj.replace(child)
      child.add_next_sibling(form)
    end
    html.css('img.equation_image').each do |node|
      mathml = Nokogiri::HTML::DocumentFragment.parse('<span class="hidden-readable">' + Ritex::Parser.new.parse(node.delete('alt').value) + '</span>') rescue next
      node.add_next_sibling(mathml)
    end

    html.to_s.html_safe
  end

  def self.css_size(val)
    res = val.to_f
    res = nil if res == 0
    res = (res + 10).to_s + "px" if res && res.to_s == val
    res
  end
end
