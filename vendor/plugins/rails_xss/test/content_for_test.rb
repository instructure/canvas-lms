require 'test_helper'

class UrlHelperTest < ActionView::TestCase

  def test_content_for_should_yield_html_safe_string
    content_for(:testing, "Some <p>html</p>")
    content = instance_variable_get(:"@content_for_testing")
    assert content.html_safe?
  end

  def test_content_for_should_escape_content
    content_for(:testing, "Some <p>html</p>")
    content = instance_variable_get(:"@content_for_testing")
    expected = %{Some &lt;p&gt;html&lt;/p&gt;}
    assert_dom_equal expected, content
  end

  def test_content_for_should_not_escape_html_safe_content
    content_for(:testing, "Some <p>html</p>".html_safe)
    content = instance_variable_get(:"@content_for_testing")
    expected = %{Some <p>html</p>}
    assert_dom_equal expected, content
  end

  def test_content_for_should_escape_content_from_block
    content_for(:testing){ "Some <p>html</p>" }
    content = instance_variable_get(:"@content_for_testing")
    expected = %{Some &lt;p&gt;html&lt;/p&gt;}
    assert_dom_equal expected, content
  end

  def test_content_for_should_not_escape_html_safe_content_from_block
    content_for(:testing){ "Some <p>html</p>".html_safe }
    content = instance_variable_get(:"@content_for_testing")
    expected = %{Some <p>html</p>}
    assert_dom_equal expected, content
  end

end
