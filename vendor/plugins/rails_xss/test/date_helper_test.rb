require 'test_helper'

class DateHelperTest < ActionView::TestCase
  silence_warnings do
    Post = Struct.new("Post", :id, :written_on, :updated_at)
  end

  def test_select_html_safety
    assert select_day(16).html_safe?
    assert select_month(8).html_safe?
    assert select_year(Time.mktime(2003, 8, 16, 8, 4, 18)).html_safe?
    assert select_minute(Time.mktime(2003, 8, 16, 8, 4, 18)).html_safe?
    assert select_second(Time.mktime(2003, 8, 16, 8, 4, 18)).html_safe?

    assert select_minute(8, :use_hidden => true).html_safe?
    assert select_month(8, :prompt => 'Choose month').html_safe?

    assert select_time(Time.mktime(2003, 8, 16, 8, 4, 18), {}, :class => 'selector').html_safe?
    assert select_date(Time.mktime(2003, 8, 16), :date_separator => " / ", :start_year => 2003, :end_year => 2005, :prefix => "date[first]").html_safe?
  end
  
  def test_object_select_html_safety
    @post = Post.new
    @post.written_on = Date.new(2004, 6, 15)

    assert date_select("post", "written_on", :default => Time.local(2006, 9, 19, 15, 16, 35), :include_blank => true).html_safe?    
    assert time_select("post", "written_on", :ignore_date => true).html_safe?    
  end
end
