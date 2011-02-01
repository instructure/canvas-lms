require 'test_helper'

class TagHelperTest < ActionView::TestCase

  def test_content_tag
    assert_equal "<a href=\"create\">Create</a>", content_tag("a", "Create", "href" => "create")
    assert content_tag("a", "Create", "href" => "create").html_safe?
    assert_equal content_tag("a", "Create", "href" => "create"),
                 content_tag("a", "Create", :href => "create")
    assert_equal "<p>&lt;script&gt;evil_js&lt;/script&gt;</p>",
                 content_tag(:p, '<script>evil_js</script>')
    assert_equal "<p><script>evil_js</script></p>",
                 content_tag(:p, '<script>evil_js</script>', nil, false)
  end

  def test_tag_honors_html_safe_for_param_values
    ['1&amp;2', '1 &lt; 2', '&#8220;test&#8220;'].each do |escaped|
      assert_equal %(<a href="#{escaped}" />), tag('a', :href => escaped.html_safe)
    end
  end
end
