require 'test_helper'

class UrlHelperTest < ActionView::TestCase

  def abcd(hash = {})
    hash_for(:a => :b, :c => :d).merge(hash)
  end

  def hash_for(opts = {})
    {:controller => "foo", :action => "bar"}.merge(opts)
  end

  def test_url_for_does_not_escape_urls_if_explicitly_stated
    assert_equal "/foo/bar?a=b&c=d", url_for(abcd(:escape => false))
  end

  def test_link_tag_with_img
    link = link_to("<img src='/favicon.jpg' />".html_safe, "/")
    expected = %{<a href="/"><img src='/favicon.jpg' /></a>}
    assert_dom_equal expected, link
  end

  def test_link_to_should_not_escape_content_for_html_safe
    link = link_to("Some <p>html</p>".html_safe, "/")
    expected = %{<a href="/">Some <p>html</p></a>}
    assert_dom_equal link, expected
  end

  def test_link_to_escapes_content_for_non_safe
    link = link_to("Some <p>html</p>", "/")
    expected = %{<a href="/">Some &lt;p&gt;html&lt;/p&gt;</a>}
    assert_dom_equal link, expected
  end

  def test_url_for_escaping_is_safety_aware
    assert url_for(abcd(:escape => true)).html_safe?, "escaped urls should be html_safe?"
    assert !url_for(abcd(:escape => false)).html_safe?, "non-escaped urls should not be html_safe?"
  end
end
