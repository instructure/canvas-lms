require 'test_helper'

class TextHelperTest < ActionView::TestCase

  def setup
    @controller = Class.new do
      attr_accessor :request
      def url_for(*args) "http://www.example.com" end
    end.new
  end

  def test_simple_format_with_escaping_html_options
    assert_dom_equal(%(<p class="intro">It's nice to have options.</p>),
                     simple_format("It's nice to have options.", :class=>"intro"))
  end

  def test_simple_format_should_not_escape_safe_content
    assert_dom_equal(%(<p>This is <script>safe_js</script>.</p>),
                     simple_format('This is <script>safe_js</script>.'.html_safe))
  end

  def test_simple_format_escapes_unsafe_content
    assert_dom_equal(%(<p>This is &lt;script&gt;evil_js&lt;/script&gt;.</p>),
                     simple_format('This is <script>evil_js</script>.'))
  end

  def test_truncate_should_not_be_html_safe
    assert !truncate("Hello World!", :length => 12).html_safe?
  end
end
