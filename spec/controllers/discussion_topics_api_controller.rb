require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DiscussionTopicsApiController do
  describe 'POST add_entry' do
    before :once do
      Setting.set('enable_page_views', 'db')
      course_with_student :active_all => true
      @topic = @course.discussion_topics.create!(:title => 'discussion')
    end

    before :each do
      user_session(@student)
      controller.stubs(:form_authenticity_token => 'abc', :form_authenticity_param => 'abc')
      post 'add_entry', :format => 'json', :topic_id => @topic.id, :course_id => @course.id, :user_id => @user.id, :message => 'message', :read_state => 'read'
    end

    after { Setting.set 'enable_page_views', 'false' }

    it 'creates a new discussion entry' do
      entry = assigns[:entry]
      entry.discussion_topic.should == @topic
      entry.id.should_not be_nil
      entry.message.should == 'message'
    end


    it 'logs an asset access record for the discussion topic' do
      accessed_asset = assigns[:accessed_asset]
      accessed_asset[:code].should == @topic.asset_string
      accessed_asset[:category].should == 'topics'
      accessed_asset[:level].should == 'participate'
    end

    it 'registers a page view' do
      page_view = assigns[:page_view]
      page_view.should_not be_nil
      page_view.http_method.should == 'post'
      page_view.url.should =~ %r{^http://test\.host/api/v1/courses/\d+/discussion_topics}
      page_view.participated.should be_true
    end

  end
end
