require 'test_helper'

class AssetTagHelperTest < ActionView::TestCase
  def setup
    @controller = Class.new do
      attr_accessor :request
      def url_for(*args) "http://www.example.com" end
    end.new
  end

  def test_auto_discovery_link_tag
    assert_dom_equal(%(<link href="http://www.example.com" rel="Not so alternate" title="ATOM" type="application/atom+xml" />),
                     auto_discovery_link_tag(:atom, {}, {:rel => "Not so alternate"}))
  end

  def test_javascript_include_tag_with_blank_asset_id
    ENV["RAILS_ASSET_ID"] = ""
    assert_dom_equal(%(<script src="/javascripts/test.js" type="text/javascript"></script>\n<script src="/javascripts/prototype.js" type="text/javascript"></script>\n<script src="/javascripts/effects.js" type="text/javascript"></script>\n<script src="/javascripts/dragdrop.js" type="text/javascript"></script>\n<script src="/javascripts/controls.js" type="text/javascript"></script>\n<script src="/javascripts/application.js" type="text/javascript"></script>),
                     javascript_include_tag("test", :defaults))
  end

  def test_javascript_include_tag_with_given_asset_id
    ENV["RAILS_ASSET_ID"] = "1"
    assert_dom_equal(%(<script src="/javascripts/prototype.js?1" type="text/javascript"></script>\n<script src="/javascripts/effects.js?1" type="text/javascript"></script>\n<script src="/javascripts/dragdrop.js?1" type="text/javascript"></script>\n<script src="/javascripts/controls.js?1" type="text/javascript"></script>\n<script src="/javascripts/application.js?1" type="text/javascript"></script>),
                     javascript_include_tag(:defaults))
    ENV["RAILS_ASSET_ID"] = ""
  end

  def test_javascript_include_tag_is_html_safe
    assert javascript_include_tag(:defaults).html_safe?
    assert javascript_include_tag("prototype").html_safe?
  end

  def test_stylesheet_link_tag
    assert_dom_equal(%(<link href="http://www.example.com/styles/style.css" media="screen" rel="stylesheet" type="text/css" />),
                     stylesheet_link_tag("http://www.example.com/styles/style"))
  end

  def test_stylesheet_link_tag_is_html_safe
    assert stylesheet_link_tag('dir/file').html_safe?
    assert stylesheet_link_tag('dir/other/file', 'dir/file2').html_safe?
    assert stylesheet_tag('dir/file', {}).html_safe?
  end

  def test_image_tag
    assert_dom_equal(%(<img alt="Mouse" onmouseover="this.src='/images/mouse_over.png'" onmouseout="this.src='/images/mouse.png'" src="/images/mouse.png" />),
                     image_tag("mouse.png", :mouseover => image_path("mouse_over.png")))
  end
end
