require "jsduck/tag/member_tag"

# The :needs_cfg tag allows you specify dependency on configuration parameters.
# If your method relies on config params defined in the Config module, you can
# specify them like this:
#
#   @needs_cfg nameOfConfig
#
# These deps will show up in the member method documentation and will link to
# the configuration parameter docs.
class NeedsCfg < JsDuck::Tag::MemberTag
  def initialize
    @tagname = :needs_cfg
    @pattern = "needs_cfg"
    @repeatable = true
    @html_position = POS_DOC + 0.1
  end

  def parse_doc(scanner, position)
    text = scanner.match(/.*$/) || scanner.ident
    return { :tagname => :needs_cfg, :text => text }
  end

  def process_doc(context, tags, position)
    context[:needs_cfg] = tags.map do |tag|
      normalized_cfg = tag[:text].sub(/^Config\./, '')
      {
        owner: 'Config',
        name: normalized_cfg,
        id: 'cfg-' + normalized_cfg,
        tagname: tag[:tagname]
      }
    end
  end

  def to_html(context, *args)
    params = context[:needs_cfg].map do |tag|
      "<li>#{member_link(tag).sub('expandable', 'docClass')}</li>"
    end.join("\n")
    <<-HTML
      <h3 class="pa">Configuration Dependencies</h3>
      <p>This method requires the following configuration parameters to be set:</p>
      <ul>
        #{params}
      </ul>
    HTML
  end
end