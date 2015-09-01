require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_context "in-process server selenium tests"

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:teacher_topic) { course.discussion_topics.create!(user: teacher, title: 'teacher topic title', message: 'teacher topic message') }

  context "menu tools" do
    before do
      @topic = teacher_topic
      user_session(teacher)
      Account.default.enable_feature!(:lor_for_account)

      @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.discussion_topic_menu = {:url => "http://www.example.com", :text => "Export Topic"}
      @tool.save!
    end

    it "should show tool launch links in the gear for items on the index", priority: "1", test_id: 298757 do
      get "/courses/#{@course.id}/discussion_topics"

      gear = fj("##{@topic.id}_discussion_content .al-trigger")
      gear.click
      link = fj("##{@topic.id}_discussion_content li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:discussion_topic_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=discussion_topic_menu&discussion_topics[]=#{@topic.id}"
    end

    it "should show tool launch links in the gear for items on the show page", priority: "1", test_id: 298758 do
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

      gear = f("#discussion-managebar .al-trigger")
      gear.click
      link = f("#discussion-managebar li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:discussion_topic_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=discussion_topic_menu&discussion_topics[]=#{@topic.id}"
    end
  end
end
