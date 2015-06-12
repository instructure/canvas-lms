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
      expect(entry.discussion_topic).to eq @topic
      expect(entry.id).not_to be_nil
      expect(entry.message).to eq 'message'
    end


    it 'logs an asset access record for the discussion topic' do
      accessed_asset = assigns[:accessed_asset]
      expect(accessed_asset[:code]).to eq @topic.asset_string
      expect(accessed_asset[:category]).to eq 'topics'
      expect(accessed_asset[:level]).to eq 'participate'
    end

    it 'registers a page view' do
      page_view = assigns[:page_view]
      expect(page_view).not_to be_nil
      expect(page_view.http_method).to eq 'post'
      expect(page_view.url).to match %r{^http://test\.host/api/v1/courses/\d+/discussion_topics}
      expect(page_view.participated).to be_truthy
    end
  end
end
