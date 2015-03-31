#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../locked_spec')

class DiscussionTopicsTestCourseApi
  include Api
  include Api::V1::DiscussionTopics
  def feeds_topic_format_path(topic_id, code, format); "feeds_topic_format_path(#{topic_id.inspect}, #{code.inspect}, #{format.inspect})"; end
  def named_context_url(*args); "named_context_url(#{args.inspect[1..-2]})"; end
  def course_assignment_url(*args); "course_assignment_url(#{args.inspect[1..-2]})"; end
end

describe Api::V1::DiscussionTopics do
  before :once do
    @test_api = DiscussionTopicsTestCourseApi.new
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @me = @user
    student_in_course(:active_all => true, :course => @course)
    @topic = @course.discussion_topics.create
  end

  it 'should render a podcast_url using the discussion topic\'s context if there is no @context_enrollment/@context' do
    @topic.update_attribute :podcast_enabled, true
    data = nil
    expect {
      data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, {})
    }.not_to raise_error
    expect(data[:podcast_url]).to match /feeds_topic_format_path/
  end

  it "should set can_post_attachments" do
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
    expect(data[:permissions][:attach]).to eq true # teachers can always attach

    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @student, nil)
    expect(data[:permissions][:attach]).to eq false # students can't attach by default

    @topic.context.update_attribute(:allow_student_forum_attachments, true)
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @student, nil)
    expect(data[:permissions][:attach]).to eq true
  end

  it "should recognize include_assignment flag" do
    #set @domain_root_account
    @test_api.instance_variable_set(:@domain_root_account, Account.default)

    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
    expect(data[:assignment]).to be_nil

    @topic.assignment = assignment_model(:course => @course)
    @topic.save!

    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil, include_assignment: true)
    expect(data[:assignment]).not_to be_nil
  end
end

describe DiscussionTopicsController, type: :request do
  include Api::V1::User

  context 'locked api item' do
    include_examples 'a locked api item'

    let(:item_type) { 'discussion_topic' }

    let_once(:locked_item) do
      @course.discussion_topics.create!(:user => @user, :message => 'Locked Discussion')
    end

    def api_get_json
      @course.clear_permissions_cache(@user)
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{locked_item.id}",
        {:controller => 'discussion_topics_api', :action => 'show', :format => 'json', :course_id => @course.id.to_s, :topic_id => locked_item.id.to_s},
      )
    end
  end

  before(:once) do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
  end

  # needed for user_display_json
  def avatar_url_for_user(user, *a)
    User.avatar_fallback_url
  end
  def blank_fallback
    nil
  end

  describe "user_display_json" do
    it "should return a html_url based on parent_context" do
      expect(user_display_json(@user)[:html_url]).to eq "http://www.example.com/users/#{@user.id}"
      expect(user_display_json(@user, nil)[:html_url]).to eq "http://www.example.com/users/#{@user.id}"
      expect(user_display_json(@user, :profile)[:html_url]).to eq "http://www.example.com/about/#{@user.id}"
      expect(user_display_json(@user, @course)[:html_url]).to eq "http://www.example.com/courses/#{@course.id}/users/#{@user.id}"
    end
  end

  context "create topic" do
    it "should check permissions" do
      @user = user(:active_all => true)
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "hai", :message => "test message" }, {}, :expected_status => 401)
    end

    it "should make a basic topic" do
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>" })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.message).to eq "test <b>message</b>"
      expect(@topic.threaded?).to be_falsey
      expect(@topic.published?).to be_falsey
      expect(@topic.post_delayed?).to be_falsey
      expect(@topic.podcast_enabled?).to be_falsey
      expect(@topic.podcast_has_student_posts?).to be_falsey
      expect(@topic.require_initial_post?).to be_falsey
    end

    it 'should process html content in message on create' do
      should_process_incoming_user_content(@course) do |content|
        api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
                 { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
                 { :title => "test title", :message => content })

        @topic = @course.discussion_topics.order(:id).last
        @topic.message
      end
    end

    it "should post an announcment" do
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>", :is_announcement => true, :published => true })
      @topic = @course.announcements.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.message).to eq "test <b>message</b>"
    end

    it "should create a topic with all the bells and whistles" do
      post_at = 1.month.from_now
      lock_at = 2.months.from_now
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>", :discussion_type => "threaded", :published => true,
                 :delayed_post_at => post_at.as_json, :lock_at => lock_at.as_json, :podcast_has_student_posts => '1', :require_initial_post => '1' })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.message).to eq "test <b>message</b>"
      expect(@topic.threaded?).to eq true
      expect(@topic.post_delayed?).to eq true
      expect(@topic.published?).to be_truthy
      expect(@topic.delayed_post_at.to_i).to eq post_at.to_i
      expect(@topic.lock_at.to_i).to eq lock_at.to_i
      expect(@topic.podcast_enabled?).to eq true
      expect(@topic.podcast_has_student_posts?).to eq true
      expect(@topic.require_initial_post?).to eq true
    end

    context "publishing" do
      it "should create a draft state topic" do
        api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
                 { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
                 { :title => "test title", :message => "test <b>message</b>", :published => "false" })
        @topic = @course.discussion_topics.order(:id).last
        expect(@topic.published?).to be_falsey
      end

      it "should not allow announcements to be draft state" do
        result = api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
                 { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
                 { :title => "test title", :message => "test <b>message</b>", :published => "false", :is_announcement => true },
                 {}, {:expected_status => 400})
        expect(result["errors"]["published"]).to be_present
      end

      it "should require moderation permissions to create a draft state topic" do
        course_with_student_logged_in(:course => @course, :active_all => true)
        result = api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
                 { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
                 { :title => "test title", :message => "test <b>message</b>", :published => "false" },
                 {}, {:expected_status => 400})
        expect(result["errors"]["published"]).to be_present
      end

      it "should allow non-moderators to set published" do
        course_with_student_logged_in(:course => @course, :active_all => true)
        api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
                 { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
                 { :title => "test title", :message => "test <b>message</b>", :published => "true" })
        @topic = @course.discussion_topics.order(:id).last
        expect(@topic.published?).to be_truthy
      end

    end

    it "should allow creating a discussion assignment" do
      due_date = 1.week.from_now
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>", :assignment => { :points_possible => 15, :grading_type => "percent", :due_at => due_date.as_json, :name => "override!" } })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.assignment).to be_present
      expect(@topic.assignment.points_possible).to eq 15
      expect(@topic.assignment.grading_type).to eq "percent"
      expect(@topic.assignment.due_at.to_i).to eq due_date.to_i
      expect(@topic.assignment.submission_types).to eq "discussion_topic"
      expect(@topic.assignment.title).to eq "test title"
    end

    it "should not create an assignment on a discussion topic when set_assignment is false" do
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>", :assignment => { :set_assignment => 'false' } })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.assignment).to be_nil
    end
  end

  context "With item" do
    before :once do
      @attachment = create_attachment(@course)
      @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>", :podcast_enabled => true, :attachment => @attachment)
      @sub = create_subtopic(@topic, :title => "Sub topic", :message => "<p>i'm subversive</p>")
    end

    before :each do
      @response_json =
                 {"read_state"=>"read",
                  "unread_count"=>0,
                  "podcast_url"=>"/feeds/topics/#{@topic.id}/enrollment_randomness.rss",
                  "user_can_see_posts"=>@topic.user_can_see_posts?(@user),
                  "subscribed"=>@topic.subscribed?(@user),
                  "require_initial_post"=>nil,
                  "title"=>"Topic 1",
                  "discussion_subentry_count"=>0,
                  "assignment_id"=>nil,
                  "published"=>true,
                  "can_unpublish"=>true,
                  "delayed_post_at"=>nil,
                  "lock_at"=>nil,
                  "id"=>@topic.id,
                  "user_name"=>@user.name,
                  "last_reply_at"=>@topic.last_reply_at.as_json,
                  "message"=>"<p>content here</p>",
                  "posted_at"=>@topic.posted_at.as_json,
                  "root_topic_id"=>nil,
                  "pinned"=>false,
                  "position"=>@topic.position,
                  "url" => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                  "html_url" => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                  "podcast_has_student_posts" => nil,
                  "attachments"=>[{"content-type"=>"unknown/unknown",
                                   "url"=>"http://www.example.com/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}",
                                   "filename"=>"content.txt",
                                   "display_name"=>"content.txt",
                                   "id"=>@attachment.id,
                                   "folder_id" => @attachment.folder_id,
                                   "size"=>@attachment.size,
                                   'unlock_at' => nil,
                                   'locked' => false,
                                   'hidden' => false,
                                   'lock_at' => nil,
                                   'locked_for_user' => false,
                                   'hidden_for_user' => false,
                                   'created_at' => @attachment.created_at.as_json,
                                   'updated_at' => @attachment.updated_at.as_json,
                                   'thumbnail_url' => @attachment.thumbnail_url,
                  }],
                  "topic_children"=>[@sub.id],
                  "discussion_type" => 'side_comment',
                  "locked"=>false,
                  "can_lock"=>true,
                  "locked_for_user"=>false,
                  "author" => user_display_json(@topic.user, @topic.context).stringify_keys!,
                  "permissions" => { "delete"=>true, "attach"=>true, "update"=>true },
                  "group_category_id" => nil,
                  "can_group" => true,
      }
    end

    describe "GET 'index'" do
      it "should return discussion topic list" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s})

        expect(json.size).to eq 2
        # get rid of random characters in podcast url
        json.last["podcast_url"].gsub!(/_[^.]*/, '_randomness')
        expect(json.last).to eq @response_json.merge("subscribed" => @sub.subscribed?(@user))
      end

      it "should search discussion topics by title" do
        ids = @course.discussion_topics.map(&:id)
        create_topic(@course, :title => "ignore me", :message => "<p>i'm subversive</p>")
        create_topic(@course, :title => "ignore me2", :message => "<p>i'm subversive</p>")
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?search_term=topic",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s,
                         :search_term => 'topic'})

        expect(json.map{|h| h['id']}.sort).to eq ids.sort
      end

      it "should order topics by descending position by default" do
        @topic2 = create_topic(@course, :title => "Topic 2", :message => "<p>content here</p>")
        @topic3 = create_topic(@course, :title => "Topic 3", :message => "<p>content here</p>")
        topics = [@topic3, @topic, @topic2, @sub]
        topics.reverse.each_with_index do |topic, index|
          topic.position = index + 1
          topic.save!
        end

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s})
        expect(json.map {|j| j['id']}).to eq topics.map(&:id)
      end

      it "should order topics by descending last_reply_at when order_by parameter is specified" do
        @topic2 = create_topic(@course, :title => "Topic 2", :message => "<p>content here</p>")
        @topic3 = create_topic(@course, :title => "Topic 3", :message => "<p>content here</p>")

        topics = [@topic3, @topic, @topic2, @sub]
        topic_reply_date = Time.zone.now - 1.day
        topics.each do |topic|
          topic.last_reply_at = topic_reply_date
          topic.save!
          topic_reply_date -= 1.day
        end

        # topic that hasn't had a reply yet should be at the top
        @topic4 = create_topic(@course, :title => "Topic 4", :message => "<p>content here</p>")
        topics.unshift(@topic4)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?order_by=recent_activity",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s, :order_by => 'recent_activity'})
        expect(json.map {|j| j['id']}).to eq topics.map(&:id)
      end

      it "should only include topics with a given scope when specified" do
        @topic2 = create_topic(@course, :title => "Topic 2", :message => "<p>content here</p>")
        @topic3 = create_topic(@course, :title => "Topic 3", :message => "<p>content here</p>")
        [@topic, @sub, @topic2, @topic3].each do |topic|
          topic.save!
        end
        [@sub, @topic2, @topic3].each(&:lock!)
        @topic2.update_attribute(:pinned, true)

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=unlocked",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s,
                          :per_page => '10', :scope => 'unlocked'})
        expect(json.size).to eq 1
        links = response.headers['Link'].split(',')
        links.each do |link|
          expect(link).to match('scope=unlocked')
        end

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=locked",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s,
                          :per_page => '10', :scope => 'locked'})
        expect(json.size).to eq 3
        links = response.headers['Link'].split(',')
        links.each do |link|
          expect(link).to match('scope=locked')
        end

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=pinned",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s,
                         :per_page => '10', :scope => 'pinned'})
        expect(json.size).to eq 1

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=unpinned",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s,
                         :per_page => '10', :scope => 'unpinned'})
        expect(json.size).to eq 3

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=locked,unpinned",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s,
                         :per_page => '10', :scope => 'locked,unpinned'})
        expect(json.size).to eq 2
      end

      it "should include all parameters in pagination urls" do
        @topic2 = create_topic(@course, :title => "Topic 2", :message => "<p>content here</p>")
        @topic3 = create_topic(@course, :title => "Topic 3", :message => "<p>content here</p>")
        [@topic, @sub, @topic2, @topic3].each do |topic|
          topic.type = 'Announcement'
          topic.save!
        end

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=2&only_announcements=true&order_by=recent_activity&scope=unlocked",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s,
                          :per_page => '2', :order_by => 'recent_activity', :only_announcements => 'true', :scope => 'unlocked'})
        expect(json.size).to eq 2
        links = response.headers['Link'].split(',')
        links.each do |link|
          expect(link).to match('only_announcements=true')
          expect(link).to match('order_by=recent_activity')
          expect(link).to match('scope=unlocked')
        end
      end
    end

    describe "GET 'show'" do
      it "should return an individual topic" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        {:controller => 'discussion_topics_api', :action => 'show', :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s})

        # get rid of random characters in podcast url
        json["podcast_url"].gsub!(/_[^.]*/, '_randomness')
        expect(json).to eq @response_json.merge("subscribed" => @topic.subscribed?(@user))
      end

      it "should require course to be published for students" do
        @course.claim
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        {:controller => 'discussion_topics_api', :action => 'show', :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s},
                        {}, :expected_status => 401)
      end

      it "should properly translate a video media comment in the discussion topic's message" do
        @topic.update_attributes(
          message: '<p><a id="media_comment_m-spHRwKY5ATHvPQAMKdZV_g" class="instructure_inline_media_comment video_comment" href="/media_objects/m-spHRwKY5ATHvPQAMKdZV_g">this is a media comment</a></p>'
        )

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        {:controller => 'discussion_topics_api', :action => 'show', :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s})

        video_tag = Nokogiri::XML(json["message"]).css("p video").first
        expect(video_tag["poster"]).to eq "http://www.example.com/media_objects/m-spHRwKY5ATHvPQAMKdZV_g/thumbnail?height=448&type=3&width=550"
        expect(video_tag["data-media_comment_type"]).to eq "video"
        expect(video_tag["preload"]).to eq "none"
        expect(video_tag["class"]).to eq "instructure_inline_media_comment"
        expect(video_tag["data-media_comment_id"]).to eq "m-spHRwKY5ATHvPQAMKdZV_g"
        expect(video_tag["controls"]).to eq "controls"
        expect(video_tag["src"]).to eq "http://www.example.com/courses/#{@course.id}/media_download?entryId=m-spHRwKY5ATHvPQAMKdZV_g&media_type=video&redirect=1"
        expect(video_tag.inner_text).to eq "this is a media comment"

      end

      it "should properly translate a audio media comment in the discussion topic's message" do
        @topic.update_attributes(
          message: '<p><a id="media_comment_m-QgvagKCQATEtJAAMKdZV_g" class="instructure_inline_media_comment audio_comment"></a>this is a media comment</p>'
        )

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        {:controller => 'discussion_topics_api', :action => 'show', :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s})

        message = Nokogiri::XML(json["message"])
        audio_tag = message.css("p audio").first
        expect(audio_tag["data-media_comment_type"]).to eq "audio"
        expect(audio_tag["preload"]).to eq "none"
        expect(audio_tag["class"]).to eq "instructure_inline_media_comment"
        expect(audio_tag["data-media_comment_id"]).to eq "m-QgvagKCQATEtJAAMKdZV_g"
        expect(audio_tag["controls"]).to eq "controls"
        expect(audio_tag["src"]).to eq "http://www.example.com/courses/#{@course.id}/media_download?entryId=m-QgvagKCQATEtJAAMKdZV_g&media_type=audio&redirect=1"
        expect(message.css("p").inner_text).to eq "this is a media comment"
      end
    end

    describe "PUT 'update'" do
      it "should require authorization" do
        @user = user(:active_all => true)
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :title => "hai", :message => "test message" }, {}, :expected_status => 401)
      end

      it "should update the entry" do
        post_at = 1.month.from_now
        lock_at = 2.months.from_now
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :title => "test title",
                   :message => "test <b>message</b>",
                   :discussion_type => "threaded",
                   :delayed_post_at => post_at.as_json,
                   :lock_at => lock_at.as_json,
                   :podcast_has_student_posts => '1',
                   :require_initial_post => '1' })
        @topic.reload
        expect(@topic.title).to eq "test title"
        expect(@topic.message).to eq "test <b>message</b>"
        expect(@topic.threaded?).to eq true
        expect(@topic.post_delayed?).to eq true
        expect(@topic.delayed_post_at.to_i).to eq post_at.to_i
        expect(@topic.lock_at.to_i).to eq lock_at.to_i
        expect(@topic.podcast_enabled?).to eq true
        expect(@topic.podcast_has_student_posts?).to eq true
        expect(@topic.require_initial_post?).to eq true
      end

      it "should not unlock topic if lock_at changes but is still in the past" do
        lock_at = 1.month.ago
        new_lock_at = 1.week.ago
        @topic.workflow_state = 'active'
        @topic.locked = true
        @topic.lock_at = lock_at
        @topic.save!

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :lock_at => new_lock_at.as_json })
        @topic.reload
        expect(@topic.lock_at.to_i).to eq new_lock_at.to_i
        expect(@topic).to be_locked
      end

      it "should update workflow_state if delayed_post_at changed to future" do
        post_at = 1.month.from_now
        @topic.workflow_state = 'active'
        @topic.locked = true
        @topic.save!

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :delayed_post_at => post_at.as_json })
        @topic.reload
        expect(@topic.delayed_post_at.to_i).to eq post_at.to_i
        expect(@topic).to be_post_delayed
      end

      it "should not change workflow_state if lock_at does not change" do
        lock_at = 1.month.from_now.change(:usec => 0)
        @topic.lock_at = lock_at
        @topic.workflow_state = 'active'
        @topic.save!

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :lock_at => lock_at.as_json })

        @topic.reload
        expect(@topic.lock_at).to eq lock_at
        expect(@topic).to be_active
      end

      it "should unlock topic if lock_at is changed to future" do
        old_lock_at = 1.month.ago
        new_lock_at = 1.month.from_now
        @topic.lock_at = old_lock_at
        @topic.workflow_state = 'active'
        @topic.locked = true
        @topic.save!

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :lock_at => new_lock_at.as_json })

        @topic.reload
        expect(@topic.lock_at.to_i).to eq new_lock_at.to_i
        expect(@topic).to be_active
        expect(@topic).not_to be_locked
      end

      it "should lock the topic if lock_at is changed to the past" do
        old_lock_at = 1.month.from_now
        new_lock_at = 1.month.ago
        @topic.lock_at = old_lock_at
        @topic.workflow_state = 'active'
        @topic.save!

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :lock_at => new_lock_at.as_json })

        @topic.reload
        expect(@topic.lock_at.to_i).to eq new_lock_at.to_i
        expect(@topic).to be_locked
      end

      it "should not lock the topic if lock_at is cleared" do
        @topic.lock_at = 1.month.ago
        @topic.workflow_state = 'active'
        @topic.save!

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :lock_at => '' })

        @topic.reload
        expect(@topic.lock_at).to be_nil
        expect(@topic).to be_active
        expect(@topic).not_to be_locked
      end

      context "publishing" do
        it "should publish a draft state topic" do
          @topic.workflow_state = 'unpublished'
          @topic.save!
          expect(@topic).not_to be_published
          api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                   { :published => "true"})
          expect(@topic.reload).to be_published
        end

        it "should not allow announcements to be draft state" do
          @topic.type = 'Announcement'
          @topic.save!
          result = api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                   { :published => "false" },
                   {}, {:expected_status => 400})
          expect(result["errors"]["published"]).to be_present
        end


        it "should allow a topic with no posts to set draft state" do
          api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                   { :published => "false"})
          expect(@topic.reload).not_to be_published
        end

        it "should prevent a topic with posts from setting draft state" do
          student_in_course(:course => @course, :active_all => true)
          create_entry(@topic, :user => @student)

          @user = @teacher
          api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                   { :published => "false"}, {}, {:expected_status => 400})
          expect(@topic.reload).to be_published
        end

        it "should require moderation permissions to set draft state" do
          course_with_student_logged_in(:course => @course, :active_all => true)
          @topic = create_topic(@course, :user => @student)
          api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                   { :published => "false"}, {}, {:expected_status => 400})
          expect(@topic.reload).to be_published
        end

        it "should allow non-moderators to set published" do
          course_with_student_logged_in(:course => @course, :active_all => true)
          @topic = create_topic(@course, :user => @student)
          api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                   { :published => "true"})
          expect(@topic.reload).to be_published
        end
      end

      it 'should process html content in message on update' do
        should_process_incoming_user_content(@course) do |content|
          api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                   { :message => content })

          @topic.reload
          @topic.message
        end
      end

      it "should set the editor_id to whoever edited to entry" do
        @original_user = @user
        @editing_user = user_model
        @course.enroll_teacher(@editing_user).accept

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :title => "edited by someone else"})
        @topic.reload
        expect(@topic.editor).to eql(@editing_user)
        expect(@topic.user).to eql(@original_user)
      end

      it "should not drift when saving delayed_post_at with user-preferred timezone set" do
        @user.time_zone = 'Alaska'
        @user.save

        user_tz = Time.use_zone(@user.time_zone) { Time.zone }
        expected_time = user_tz.parse("Fri Aug 26, 2031 8:39AM")

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :delayed_post_at => expected_time.as_json})

        @topic.reload
        expect(@topic.delayed_post_at).to eq expected_time
      end

      it "should allow creating assignment on update" do
        due_date = 1.week.ago
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :assignment => { :points_possible => 15, :grading_type => "percent", :due_at => due_date.as_json, :name => "override!" } })
        @topic.reload

        expect(@topic.title).to eq "Topic 1"
        expect(@topic.assignment).to be_present
        expect(@topic.assignment.points_possible).to eq 15
        expect(@topic.assignment.grading_type).to eq "percent"
        expect(@topic.assignment.due_at.to_i).to eq due_date.to_i
        expect(@topic.assignment.submission_types).to eq "discussion_topic"
        expect(@topic.assignment.title).to eq "Topic 1"
      end

      it "should allow removing assignment on update" do
        @assignment = @topic.context.assignments.build
        @topic.assignment = @assignment
        @topic.save!
        expect(@topic.assignment).to be_present

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :assignment => { :set_assignment => false } })
        @topic.reload
        @assignment.reload

        expect(@topic.title).to eq "Topic 1"
        expect(@topic.assignment).to be_nil
        expect(@topic.old_assignment_id).to eq @assignment.id
        expect(@assignment).to be_deleted
      end

      it "should update due dates with cache enabled" do
        old_due_date = 1.day.ago
        @assignment = @topic.context.assignments.build
        @assignment.due_at = old_due_date
        @topic.assignment = @assignment
        @topic.save!
        expect(@topic.assignment).to be_present

        new_due_date = 2.days.ago
        enable_cache do
          Timecop.freeze do
            api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                     { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                     { :assignment => { :due_at => new_due_date.iso8601} })
            @topic.reload
          end
          expect(@topic.assignment.overridden_for(@user).due_at.iso8601).to eq new_due_date.iso8601
        end
      end

      it "should update due dates with cache enabled and overrides already present" do
        old_due_date = 1.day.ago
        @assignment = @topic.context.assignments.build
        @assignment.due_at = old_due_date
        @topic.assignment = @assignment
        @topic.save!
        expect(@topic.assignment).to be_present

        lock_at_date = 1.day.from_now
        assignment_override_model(:assignment => @assignment, :lock_at => lock_at_date)
        @override.set = @course.default_section
        @override.save!

        new_due_date = 2.days.ago
        enable_cache do
          Timecop.freeze do
            api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                     { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                     { :assignment => { :due_at => new_due_date.iso8601} })
            @topic.reload
          end
          expect(@topic.assignment.overridden_for(@user).due_at.iso8601).to eq new_due_date.iso8601
        end
      end

      it "should transfer assignment group category to the discussion" do
        group_category = @course.group_categories.create(:name => 'watup')
        group = group_category.groups.create!(:name => "group1", :context => @course)
        group.add_user(@user)
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :assignment => { :group_category_id => group_category.id } })
        @topic.reload

        expect(@topic.title).to eq "Topic 1"
        expect(@topic.group_category).to eq group_category
        expect(@topic.assignment).to be_present
        expect(@topic.assignment.group_category).to be_nil
      end

      it "should allow pinning a topic" do
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: 'discussion_topics', action: 'update', format: 'json', course_id: @course.to_param, topic_id: @topic.to_param },
                 { pinned: true })
        expect(@topic.reload).to be_pinned
      end

      it "should allow unpinning a topic" do
        @topic.update_attribute(:pinned, true)
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: 'discussion_topics', action: 'update', format: 'json', course_id: @course.to_param, topic_id: @topic.to_param },
                 { pinned: false })
        expect(@topic.reload).not_to be_pinned
      end

      it "should allow unlocking a locked topic" do
        @topic.lock!

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :locked => false})

        @topic.reload
        expect(@topic).not_to be_locked
      end

      it "should allow locking a topic after due date" do
        due_date = 1.week.ago
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :assignment => { :due_at => due_date.as_json } })
        @topic.reload
        expect(@topic.assignment.due_at.to_i).to eq due_date.to_i

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :locked => true})

        @topic.reload
        expect(@topic).to be_locked

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :locked => false})

        @topic.reload
        expect(@topic).not_to be_locked
      end

      it "should not allow locking a topic before due date" do
        due_date = 1.week.from_now
        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :assignment => { :due_at => due_date.as_json } })
        @topic.reload
        expect(@topic.assignment.due_at.to_i).to eq due_date.to_i

        api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "update", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 { :locked => true}, {}, :expected_status => 500)

        @topic.reload
        expect(@topic).not_to be_locked
      end
    end

    describe "DELETE 'destroy'" do
      it "should require authorization" do
        @user = user(:active_all => true)
        api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "destroy", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param },
                 {}, {}, :expected_status => 401)
        expect(@topic.reload).not_to be_deleted
      end

      it "should delete the topic" do
        api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { :controller => "discussion_topics", :action => "destroy", :format => "json", :course_id => @course.to_param, :topic_id => @topic.to_param })
        expect(@topic.reload).to be_deleted
      end
    end
  end

  context "differentiated assignments" do

    def calls_display_topic(topic, opts={except: []})
      get_index(topic.context)
      expect(JSON.parse(response.body).to_s).to include("#{topic.assignment.title}")

      calls = [:get_show, :get_entries, :get_replies, :add_entry, :add_reply]
      calls.reject!{|call| opts[:except].include?(call) }
      calls.each{ |call| expect(self.send(call, topic).to_s).not_to eq "401"}
    end

    def calls_do_not_show_topic(topic)
      get_index(topic.context)
      expect(JSON.parse(response.body).to_s).not_to include("#{topic.assignment.title}")

      calls = [:get_show, :get_entries, :get_replies, :add_entry, :add_reply]
      calls.each{ |call| expect(self.send(call, topic).to_s).to eq "401"}
    end

    def get_index(course)
      raw_api_call(:get, "/api/v1/courses/#{course.id}/discussion_topics.json",
                        {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => course.id.to_s})
    end

    def get_show(topic)
      raw_api_call(:get, "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}",
                        {:controller => 'discussion_topics_api', :action => 'show', :format => 'json', :course_id => topic.context.id.to_s, :topic_id => topic.id.to_s})
    end

    def get_entries(topic)
      url = "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries"
      raw_api_call(:get, url, controller: 'discussion_topics_api',action: 'entries', format: 'json', course_id: topic.context.to_param, topic_id: topic.id.to_s)
    end

    def get_replies(topic)
      raw_api_call(:get, "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries/#{topic.discussion_entries.last.id}/replies",
         { :controller => "discussion_topics_api", :action => "replies", :format => "json", :course_id => topic.context.id.to_s, :topic_id => topic.id.to_s, :entry_id => topic.discussion_entries.last.id.to_s })
    end

    def add_entry(topic)
      raw_api_call( :post, "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => topic.context.id.to_s, :topic_id => topic.id.to_s },
        { :message => "example entry"})
    end

    def add_reply(topic)
      raw_api_call( :post, "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries/#{topic.discussion_entries.last.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => topic.context.id.to_s, :topic_id => topic.id.to_s, :entry_id => topic.discussion_entries.last.id.to_s },
        { :message => "example reply" })
    end


    def create_graded_discussion_for_da(assignment_opts={})
      assignment = @course.assignments.create!(assignment_opts)
      assignment.submission_types = 'discussion_topic'
      assignment.save!
      topic = @course.discussion_topics.create!(:user => @teacher, :title => assignment_opts[:title], :message => "woo", :assignment => assignment)
      entry = topic.discussion_entries.create!(:message => "second message", :user => @student)
      entry.save
      [assignment, topic]
    end

    before do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      @student_with_override, @student_without_override= create_users(2, return_type: :record)

      @assignment_1, @topic_with_restricted_access = create_graded_discussion_for_da(title: "only visible to student one", only_visible_to_overrides: true)
      @assignment_2, @topic_visible_to_all = create_graded_discussion_for_da(title: "assigned to all", only_visible_to_overrides: false)

      @course.enroll_student(@student_without_override, :enrollment_state => 'active')
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student_with_override)
      create_section_override_for_assignment(@assignment_1, {course_section: @section})

      @observer = User.create
      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @course.course_sections.first, :enrollment_state => 'active')
      @observer_enrollment.update_attribute(:associated_user_id, @student_with_override.id)
    end

    context "feature flag on" do
      before {@course.enable_feature!(:differentiated_assignments)}
      it "lets the teacher see all topics" do
        @user = @teacher
        [@topic_with_restricted_access,@topic_visible_to_all].each{|t| calls_display_topic(t) }
      end

      it "lets students with visibility see topics" do
        @user = @student_with_override
        [@topic_with_restricted_access,@topic_visible_to_all].each{|t| calls_display_topic(t) }
      end

      it 'gives observers the same visibility as their student' do
        @user = @observer
        [@topic_with_restricted_access,@topic_visible_to_all].each{|t| calls_display_topic(t, except: [:add_entry, :add_reply] ) }
      end

      it 'observers without students see all' do
        @observer_enrollment.update_attribute(:associated_user_id, nil)
        @user = @observer
        [@topic_with_restricted_access,@topic_visible_to_all].each{|t| calls_display_topic(t, except: [:add_entry, :add_reply] ) }
      end

      it "restricts access to students without visibility" do
        @user = @student_without_override
        calls_do_not_show_topic(@topic_with_restricted_access)
        calls_display_topic(@topic_visible_to_all)
      end

      it "doesnt show extra assignments with overrides in the index" do
        @assignment_3, @topic_assigned_to_empty_section = create_graded_discussion_for_da(title: "assigned to none", only_visible_to_overrides: true)
        @unassigned_section = @course.course_sections.create!(name: "unassigned section")
        create_section_override_for_assignment(@assignment_3, {course_section: @unassigned_section})

        @user = @student_with_override
        get_index(@course)
        expect(JSON.parse(response.body).to_s).not_to include("#{@assignment_3.title}")
      end

      it "doesnt hide topics without assignment" do
        @non_graded_topic = @course.discussion_topics.create!(:user => @teacher, :title => "non_graded_topic", :message => "hi")

        @user = @student_without_override
        get_index(@course)
        expect(JSON.parse(response.body).to_s).to include("#{@non_graded_topic.title}")
      end
    end

    context "feature flag off" do
      before {@course.disable_feature!(:differentiated_assignments)}
      it "lets the teacher see all topics" do
        @user = @teacher
        [@topic_with_restricted_access,@topic_visible_to_all].each{|t| calls_display_topic(t) }
      end

      it "lets students with visibility see topics" do
        @user = @student_with_override
        [@topic_with_restricted_access,@topic_visible_to_all].each{|t| calls_display_topic(t) }
      end

      it "lets students without visibility see all topics" do
        @user = @student_without_override
        [@topic_with_restricted_access,@topic_visible_to_all].each{|t| calls_display_topic(t) }
      end
    end
  end

  it "should translate user content in topics" do
    should_translate_user_content(@course) do |user_content|
      @topic ||= create_topic(@course, :title => "Topic 1", :message => user_content)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics",
        { :controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s })
      expect(json.size).to eq 1
      json.first['message']
    end
  end

  it "should paginate and return proper pagination headers for courses" do
    7.times { |i| @course.discussion_topics.create!(:title => i.to_s, :message => i.to_s) }
    expect(@course.discussion_topics.count).to eq 7
    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s, :per_page => '3'})

    expect(json.length).to eq 3
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/discussion_topics/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2&per_page=3>/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/

    # get the last page
    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?page=3&per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s, :page => '3', :per_page => '3'})
    expect(json.length).to eq 1
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/discussion_topics/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2&per_page=3>/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/
  end

  it "should work with groups" do
    group_category = @course.group_categories.create(:name => 'watup')
    group = group_category.groups.create!(:name => "group1", :context => @course)
    group.add_user(@user)
    attachment = create_attachment(group)
    gtopic = create_topic(group, :title => "Group Topic 1", :message => "<p>content here</p>", :attachment => attachment)

    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s}).first
    expected = {
      "read_state"=>"read",
      "unread_count"=>0,
      "user_can_see_posts"=>true,
      "subscribed"=>true,
      "podcast_url"=>nil,
      "podcast_has_student_posts"=>nil,
      "require_initial_post"=>nil,
      "title"=>"Group Topic 1",
      "discussion_subentry_count"=>0,
      "assignment_id"=>nil,
      "published"=>true,
      "can_unpublish"=>true,
      "delayed_post_at"=>nil,
      "lock_at"=>nil,
      "id"=>gtopic.id,
      "user_name"=>@user.name,
      "last_reply_at"=>gtopic.last_reply_at.as_json,
      "message"=>"<p>content here</p>",
      "pinned"=>false,
      "position"=>gtopic.position,
      "url" => "http://www.example.com/groups/#{group.id}/discussion_topics/#{gtopic.id}",
      "html_url" => "http://www.example.com/groups/#{group.id}/discussion_topics/#{gtopic.id}",
      "attachments"=>
              [{"content-type"=>"unknown/unknown",
                "url"=>"http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}",
                "filename"=>"content.txt",
                "display_name"=>"content.txt",
                "id" => attachment.id,
                "folder_id" => attachment.folder_id,
                "size" => attachment.size,
                'unlock_at' => nil,
                'locked' => false,
                'hidden' => false,
                'lock_at' => nil,
                'locked_for_user' => false,
                'hidden_for_user' => false,
                'created_at' => attachment.created_at.as_json,
                'updated_at' => attachment.updated_at.as_json,
                'thumbnail_url' => attachment.thumbnail_url,
              }],
      "posted_at"=>gtopic.posted_at.as_json,
      "root_topic_id"=>nil,
      "topic_children"=>[],
      "discussion_type" => 'side_comment',
      "permissions" => {"delete"=>true, "attach"=>true, "update"=>true},
      "locked" => false,
      "can_lock" => true,
      "locked_for_user" => false,
      "author" => user_display_json(gtopic.user, gtopic.context).stringify_keys!,
      "group_category_id" => nil,
      "can_group" => true,
    }
    expect(json).to eq expected
  end

  it "should paginate and return proper pagination headers for groups" do
    group_category = @course.group_categories.create(:name => "watup")
    group = group_category.groups.create!(:name => "group1", :context => @course)
    7.times { |i| create_topic(group, :title => i.to_s, :message => i.to_s) }
    expect(group.discussion_topics.count).to eq 7
    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json?per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s, :per_page => '3'})

    expect(json.length).to eq 3
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/groups\/#{group.id}\/discussion_topics/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2&per_page=3>/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/

      # get the last page
    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json?page=3&per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s, :page => '3', :per_page => '3'})
    expect(json.length).to eq 1
    links = response.headers['Link'].split(",")
    expect(links.all?{ |l| l =~ /api\/v1\/groups\/#{group.id}\/discussion_topics/ }).to be_truthy
    expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2&per_page=3>/
    expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
    expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/
  end

  it "should fulfill module viewed requirements when marking a topic read" do
    @module = @course.context_modules.create!(:name => "some module")
    @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>")
    tag = @module.add_item(:id => @topic.id, :type => 'discussion_topic')
    @module.completion_requirements = { tag.id => {:type => 'must_view'} }
    @module.save!
    course_with_student(:course => @course)

    expect(@module.evaluate_for(@user)).to be_unlocked
    raw_api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read",
                 { :controller => 'discussion_topics_api', :action => 'mark_topic_read', :format => 'json',
                   :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
    expect(@module.evaluate_for(@user)).to be_completed
  end

  it "should fulfill module viewed requirements when re-marking a topic read" do
    @module = @course.context_modules.create!(:name => "some module")
    @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>")
    course_with_student(:course => @course)
    raw_api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read",
                 { :controller => 'discussion_topics_api', :action => 'mark_topic_read', :format => 'json',
                   :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })

    tag = @module.add_item(:id => @topic.id, :type => 'discussion_topic')
    @module.completion_requirements = { tag.id => {:type => 'must_view'} }
    @module.save!

    expect(@module.evaluate_for(@user)).to be_unlocked
    raw_api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read",
                 { :controller => 'discussion_topics_api', :action => 'mark_topic_read', :format => 'json',
                   :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
    expect(@module.evaluate_for(@user)).to be_completed
  end

  it "should fulfill module viewed requirements when marking a topic and all its entries read" do
    @module = @course.context_modules.create!(:name => "some module")
    @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>")
    tag = @module.add_item(:id => @topic.id, :type => 'discussion_topic')
    @module.completion_requirements = { tag.id => {:type => 'must_view'} }
    @module.save!
    course_with_student(:course => @course)

    expect(@module.evaluate_for(@user)).to be_unlocked
    raw_api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read_all",
                 { :controller => 'discussion_topics_api', :action => 'mark_all_read', :format => 'json',
                   :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
    expect(@module.evaluate_for(@user)).to be_completed
  end

  context "creating an entry under a topic" do
    before :once do
      @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>")
      @message = "my message"
    end

    it "should allow creating an entry under a topic and create it correctly" do
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message })
      expect(json).not_to be_nil
      expect(json['id']).not_to be_nil
      @entry = DiscussionEntry.where(id: json['id']).first
      expect(@entry).not_to be_nil
      expect(@entry.discussion_topic).to eq @topic
      expect(@entry.user).to eq @user
      expect(@entry.parent_entry).to be_nil
      expect(@entry.message).to eq @message
    end
    
    it "should not allow students to create an entry under a topic that is closed for comments" do
      @topic.lock!
      student_in_course(:course => @course, :active_all => true)
      api_call(
          :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
          { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
            :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
          { :message => @message }, {}, :expected_status => 401)
    end

    it "should return json representation of the new entry" do
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message })
      @entry = DiscussionEntry.where(id: json['id']).first
      expect(json).to eq({
        "id" => @entry.id,
        "parent_id" => @entry.parent_id,
        "user_id" => @user.id,
        "user_name" => @user.name,
        "read_state" => "read",
        "forced_read_state" => false,
        "message" => @message,
        "created_at" => @entry.created_at.utc.iso8601,
        "updated_at" => @entry.updated_at.as_json,
      })
    end

    it "should allow creating a reply to an existing top-level entry" do
      top_entry = create_entry(@topic, :message => 'top-level message')
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => top_entry.id.to_s },
        { :message => @message })
      @entry = DiscussionEntry.where(id: json['id']).first
      expect(@entry.parent_entry).to eq top_entry
    end

    it "should allow including attachments on top-level entries" do
      data = fixture_file_upload("scribd_docs/txt.txt", "text/plain", true)
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message, :attachment => data })
      @entry = DiscussionEntry.where(id: json['id']).first
      expect(@entry.attachment).not_to be_nil
      expect(@entry.attachment.context).to eql @user
    end

    it "should include attachments on replies to top-level entries" do
      top_entry = create_entry(@topic, :message => 'top-level message')
      data = fixture_file_upload("scribd_docs/txt.txt", "text/plain", true)
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => top_entry.id.to_s },
        { :message => @message, :attachment => data })
      @entry = DiscussionEntry.where(id: json['id']).first
      expect(@entry.attachment).not_to be_nil
      expect(@entry.attachment.context).to eql @user
    end

    it "should include attachment info in the json response" do
      data = fixture_file_upload("scribd_docs/txt.txt", "text/plain", true)
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message, :attachment => data })
      expect(json['attachment']).not_to be_nil
      expect(json['attachment']).not_to be_empty
      expect(json['attachment']['url']).to be_include 'verifier='
    end

    it "should create a submission from an entry on a graded topic" do
      @topic.assignment = assignment_model(:course => @course)
      @topic.save

      student_in_course(:active_all => true)
      expect(@user.submissions).to be_empty

      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message })

      @user.reload
      expect(@user.submissions.size).to eq 1
      expect(@user.submissions.first.submission_type).to eq 'discussion_topic'
    end

    it "should create a submission from a reply on a graded topic" do
      top_entry = create_entry(@topic, :message => 'top-level message')

      @topic.assignment = assignment_model(:course => @course)
      @topic.save

      student_in_course(:active_all => true)
      expect(@user.submissions).to be_empty

      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => top_entry.id.to_s },
        { :message => @message })

      @user.reload
      expect(@user.submissions.size).to eq 1
      expect(@user.submissions.first.submission_type).to eq 'discussion_topic'
    end
  end

  context "listing top-level discussion entries" do
    before :once do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @attachment = create_attachment(@course)
      @entry = create_entry(@topic, :message => "first top-level entry", :attachment => @attachment)
      @reply = create_reply(@entry, :message => "reply to first top-level entry")
    end

    it "should return top level entries for a topic" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      expect(json.size).to eq 1
      entry_json = json.first
      expect(entry_json['id']).to eq @entry.id
    end

    it "should return attachments on top level entries" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      entry_json = json.first
      expect(entry_json['attachment']).not_to be_nil
      expect(entry_json['attachment']['url']).to eq "http://www.example.com/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}"
    end

    it "should include replies on top level entries" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      entry_json = json.first
      expect(entry_json['recent_replies'].size).to eq 1
      expect(entry_json['has_more_replies']).to be_falsey
      reply_json = entry_json['recent_replies'].first
      expect(reply_json['id']).to eq @reply.id
    end

    it "should sort top-level entries by descending created_at" do
      @older_entry = create_entry(@topic, :message => "older top-level entry", :created_at => Time.now - 1.minute)
      @newer_entry = create_entry(@topic, :message => "newer top-level entry", :created_at => Time.now + 1.minute)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      expect(json.size).to eq 3
      expect(json.first['id']).to eq @newer_entry.id
      expect(json.last['id']).to eq @older_entry.id
    end

    it "should sort replies included on top-level entries by descending created_at" do
      @older_reply = create_reply(@entry, :message => "older reply", :created_at => Time.now - 1.minute)
      @newer_reply = create_reply(@entry, :message => "newer reply", :created_at => Time.now + 1.minute)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      expect(json.size).to eq 1
      reply_json = json.first['recent_replies']
      expect(reply_json.size).to eq 3
      expect(reply_json.first['id']).to eq @newer_reply.id
      expect(reply_json.last['id']).to eq @older_reply.id
    end

    it "should paginate top-level entries" do
      # put in lots of entries
      entries = []
      7.times{ |i| entries << create_entry(@topic, :message => i.to_s, :created_at => Time.now + (i+1).minutes) }

      # first page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json?per_page=3",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :per_page => '3' })
      expect(json.length).to eq 3
      expect(json.map{ |e| e['id'] }).to eq entries.last(3).reverse.map{ |e| e.id }
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/discussion_topics\/#{@topic.id}\/entries/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/

      # last page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json?page=3&per_page=3",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :page => '3', :per_page => '3' })
      expect(json.length).to eq 2
      expect(json.map{ |e| e['id'] }).to eq [entries.first, @entry].map{ |e| e.id }
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/discussion_topics\/#{@topic.id}\/entries/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/
    end

    it "should only include the first 10 replies for each top-level entry" do
      # put in lots of replies
      replies = []
      12.times{ |i| replies << create_reply(@entry, :message => i.to_s, :created_at => Time.now + (i+1).minutes) }

      # get entry
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      expect(json.length).to eq 1
      reply_json = json.first['recent_replies']
      expect(reply_json.length).to eq 10
      expect(reply_json.map{ |e| e['id'] }).to eq replies.last(10).reverse.map{ |e| e.id }
      expect(json.first['has_more_replies']).to be_truthy
    end
  end

  context "listing replies" do
    before :once do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "top-level entry")
      @reply = create_reply(@entry, :message => "first reply")
    end

    it "should return replies for an entry" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      expect(json.size).to eq 1
      expect(json.first['id']).to eq @reply.id
    end

    it "should translate user content in replies" do
      should_translate_user_content(@course) do |user_content|
        @reply.update_attribute('message', user_content)
        json = api_call(
          :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
          { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
            :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
        expect(json.size).to eq 1
        json.first['message']
      end
    end

    it "should sort replies by descending created_at" do
      @older_reply = create_reply(@entry, :message => "older reply", :created_at => Time.now - 1.minute)
      @newer_reply = create_reply(@entry, :message => "newer reply", :created_at => Time.now + 1.minute)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      expect(json.size).to eq 3
      expect(json.first['id']).to eq @newer_reply.id
      expect(json.last['id']).to eq @older_reply.id
    end

    it "should paginate replies" do
      # put in lots of replies
      replies = []
      7.times{ |i| replies << create_reply(@entry, :message => i.to_s, :created_at => Time.now + (i+1).minutes) }

      # first page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json?per_page=3",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s, :per_page => '3' })
      expect(json.length).to eq 3
      expect(json.map{ |e| e['id'] }).to eq replies.last(3).reverse.map{ |e| e.id }
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/discussion_topics\/#{@topic.id}\/entries\/#{@entry.id}\/replies/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/

      # last page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json?page=3&per_page=3",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s, :page => '3', :per_page => '3' })
      expect(json.length).to eq 2
      expect(json.map{ |e| e['id'] }).to eq [replies.first, @reply].map{ |e| e.id }
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/discussion_topics\/#{@topic.id}\/entries\/#{@entry.id}\/replies/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/
    end
  end

  # stolen and adjusted from spec/controllers/discussion_topics_controller_spec.rb
  context "require initial post" do
    before(:once) do
      course_with_student(:active_all => true)

      @observer = user(:name => "Observer", :active_all => true)
      e = @course.enroll_user(@observer, 'ObserverEnrollment')
      e.associated_user = @student
      e.save
      @observer.reload

      course_with_teacher(:course => @course, :active_all => true)
      @context = @course
      discussion_topic_model
      @topic.require_initial_post = true
      @topic.save
    end

    describe "teacher" do
      before(:each) do
        @user = @teacher
        @url  = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries"
      end

      it "should see topic entries without posting" do
        @topic.reply_from(user: @student, text: 'hai')
        json = api_call(:get, @url, controller: 'discussion_topics_api',
          action: 'entries', format: 'json', course_id: @course.to_param,
          topic_id: @topic.to_param)

        expect(json.length).to eq 1
      end
    end

    describe "student" do
      before(:once) do
        @topic.reply_from(user: @teacher, text: 'Lorem ipsum dolor')
        @user = @student
        @url  = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      end

      it "should see topic information before posting" do
        json = api_call(:get, @url, controller: 'discussion_topics_api',
          action: 'show', format: 'json', course_id: @course.to_param,
          topic_id: @topic.to_param)
        expect(response.code).to eq '200'
      end

      it "should not see entries before posting" do
        raw_api_call(:get, "#{@url}/entries", controller: 'discussion_topics_api',
          action: 'entries', format: 'json', course_id: @course.to_param,
          topic_id: @topic.to_param)
        expect(response.body).to eq 'require_initial_post'
        expect(response.code).to eq '403'
      end

      it "should see entries after posting" do
        @topic.reply_from(:user => @student, :text => 'hai')
        json = api_call(:get, "#{@url}/entries", controller: 'discussion_topics_api',
          action: 'entries', format: 'json', course_id: @course.to_param,
          topic_id: @topic.to_param)
        expect(response.code).to eq '200'
      end
    end

    describe "observer" do
      before(:once) do
        @topic.reply_from(user: @teacher, text: 'Lorem ipsum')
        @user = @observer
        @url  = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries"
      end

      it "should not see entries before posting" do
        raw_api_call(:get, @url, controller: 'discussion_topics_api',
          action: 'entries', format: 'json', course_id: @course.to_param,
          topic_id: @topic.to_param)
        expect(response.body).to eq 'require_initial_post'
        expect(response.code).to eq '403'
      end

      it "should see entries after posting" do
        @topic.reply_from(user: @student, text: 'Lorem ipsum dolor')
        json = api_call(:get, @url, controller: 'discussion_topics_api',
          action: 'entries', format: 'json', course_id: @course.to_param,
          topic_id: @topic.to_param)
        expect(response.code).to eq '200'
      end
    end
  end

  context "update entry" do
    before :once do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "<p>top-level entry</p>")
    end

    it "should 401 if the user can't update" do
      student_in_course(:course => @course, :user => user_with_pseudonym)
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => 'haxor' }, {}, :expected_status => 401)
      expect(@entry.reload.message).to eq '<p>top-level entry</p>'
    end

    it "should 404 if the entry is deleted" do
      @entry.destroy
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => 'haxor' }, {}, :expected_status => 404)
    end

    it "should update the message" do
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => '<p>i had a spleling error</p>' })
      expect(@entry.reload.message).to eq '<p>i had a spleling error</p>'
    end

    it "should allow passing an plaintext message (undocumented)" do
      # undocumented but used by the dashboard right now (this'll go away eventually)
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :plaintext_message => 'i had a spleling error' })
      expect(@entry.reload.message).to eq 'i had a spleling error'
    end

    it "should allow teachers to edit student entries" do
      @teacher = @user
      student_in_course(:course => @course, :user => user_with_pseudonym)
      @student = @user
      @user = @teacher
      @entry = create_entry(@topic, :message => 'i am a student', :user => @student)
      expect(@entry.user).to eq @student
      expect(@entry.editor).to be_nil

      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => '<p>denied</p>' })
      expect(@entry.reload.message).to eq '<p>denied</p>'
      expect(@entry.editor).to eq @teacher
    end
  end

  context "delete entry" do
    before :once do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "top-level entry")
    end

    it "should 401 if the user can't delete" do
      student_in_course(:course => @course, :user => user_with_pseudonym)
      api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "destroy", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, {}, {}, :expected_status => 401)
      expect(@entry.reload).not_to be_deleted
    end

    it "should soft-delete the entry" do
      raw_api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "destroy", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, {}, {}, :expected_status => 204)
      expect(response.body).to be_blank
      expect(@entry.reload).to be_deleted
    end

    it "should allow teachers to delete student entries" do
      @teacher = @user
      student_in_course(:course => @course, :user => user_with_pseudonym)
      @student = @user
      @user = @teacher
      @entry = create_entry(@topic, :message => 'i am a student', :user => @student)
      expect(@entry.user).to eq @student
      expect(@entry.editor).to be_nil

      raw_api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "destroy", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, {}, {}, :expected_status => 204)
      expect(@entry.reload).to be_deleted
      expect(@entry.editor).to eq @teacher
    end
  end

  context "observer" do
    it "should allow observer by default" do
      course_with_teacher
      create_topic(@course, :title => "topic", :message => "topic")
      course_with_observer_logged_in(:course => @course)
      @course.offer
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { :controller => 'discussion_topics', :action => 'index', :format => 'json',
                        :course_id => @course.id.to_s })

      expect(json).not_to be_nil
      expect(json).not_to be_empty
    end

    it "should reject observer if read_forum role is false" do
      course_with_teacher
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      course_with_observer_logged_in(:course => @course)
      RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                           :role => observer_role, :enabled => false)

      expect { api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { :controller => 'discussion_topics', :action => 'index', :format => 'json',
                        :course_id => @course.id.to_s }) }.to raise_error
    end
  end

  context "read/unread state" do
    before(:once) do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "top-level entry")
      @reply = create_reply(@entry, :message => "first reply")
    end

    it "should immediately mark messages you write as 'read'" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { :controller => 'discussion_topics', :action => 'index', :format => 'json',
                        :course_id => @course.id.to_s })
      expect(json.first["read_state"]).to eq "read"
      expect(json.first["unread_count"]).to eq 0

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      expect(json.first["read_state"]).to eq "read"

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      expect(json.first["read_state"]).to eq "read"
    end

    it "should be unread by default for a new user" do
      student_in_course(:active_all => true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { :controller => 'discussion_topics', :action => 'index', :format => 'json',
                        :course_id => @course.id.to_s })
      expect(json.first["read_state"]).to eq "unread"
      expect(json.first["unread_count"]).to eq 2

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      expect(json.first["read_state"]).to eq "unread"

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      expect(json.first["read_state"]).to eq "unread"
    end

    def call_mark_topic_read(course, topic)
      raw_api_call(:put, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/read.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_topic_read', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s })
    end

    def call_mark_topic_unread(course, topic)
      raw_api_call(:delete, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/read.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_topic_unread', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s })
    end

    it "should set the read state for a topic" do
      student_in_course(:active_all => true)
      call_mark_topic_read(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 2

      call_mark_topic_unread(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_falsey
      expect(@topic.unread_count(@user)).to eq 2
    end

    it "should be idempotent for setting topic read state" do
      student_in_course(:active_all => true)
      call_mark_topic_read(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 2

      call_mark_topic_read(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 2
    end

    def call_mark_entry_read(course, topic, entry)
      raw_api_call(:put, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/entries/#{entry.id}/read.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_entry_read', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s, :entry_id => entry.id.to_s })
    end

    def call_mark_entry_unread(course, topic, entry)
      raw_api_call(:delete, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/entries/#{entry.id}/read.json?forced_read_state=true",
                      { :controller => 'discussion_topics_api', :action => 'mark_entry_unread', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s, :entry_id => entry.id.to_s, :forced_read_state => "true" })
    end

    it "should set the read state for a entry" do
      student_in_course(:active_all => true)
      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@entry.find_existing_participant(@user)).not_to be_forced_read_state
      expect(@topic.unread_count(@user)).to eq 1

      call_mark_entry_unread(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_falsey
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state
      expect(@topic.unread_count(@user)).to eq 2

      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state
      expect(@topic.unread_count(@user)).to eq 1
    end

    it "should be idempotent for setting entry read state" do
      student_in_course(:active_all => true)
      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 1

      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 1
    end

    def call_mark_all_as_read_state(new_state, opts = {})
      method = new_state == 'read' ? :put : :delete
      url = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read_all.json"
      expected_params = { :controller => 'discussion_topics_api', :action => "mark_all_#{new_state}", :format => 'json',
                        :course_id => @course.id.to_s, :topic_id => @topic.id.to_s }
      if opts.has_key?(:forced)
        url << "?forced_read_state=#{opts[:forced]}"
        expected_params[:forced_read_state] = opts[:forced].to_s
      end
      raw_api_call(method, url, expected_params)
    end

    it "should allow mark all as read without forced update" do
      student_in_course(:active_all => true)
      @entry.change_read_state('read', @user, :forced => true)

      call_mark_all_as_read_state('read')
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy

      expect(@entry.read?(@user)).to be_truthy
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state

      expect(@reply.read?(@user)).to be_truthy
      expect(@reply.find_existing_participant(@user)).not_to be_forced_read_state

      expect(@topic.unread_count(@user)).to eq 0
    end

    it "should allow mark all as unread with forced update" do
      [@topic, @entry].each { |e| e.change_read_state('read', @user) }

      call_mark_all_as_read_state('unread', :forced => true)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_falsey

      expect(@entry.read?(@user)).to be_falsey
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state

      expect(@reply.read?(@user)).to be_falsey
      expect(@reply.find_existing_participant(@user)).to be_forced_read_state

      expect(@topic.unread_count(@user)).to eq 2
    end
  end

  context "subscribing" do
    before :once do
      student_in_course(:active_all => true)
      @topic1 = create_topic(@course, :user => @student)
      @topic2 = create_topic(@course, :user => @teacher, :require_initial_post => true)
    end

    def call_subscribe(topic, user, course=@course)
      @user = user
      raw_api_call(:put, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/subscribed",
                   { :controller => "discussion_topics_api", :action => "subscribe_topic", :format => "json", :course_id => course.id.to_s, :topic_id => topic.id.to_s})
    end

    def call_unsubscribe(topic, user, course=@course)
      @user = user
      raw_api_call(:delete, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/subscribed",
                   { :controller => "discussion_topics_api", :action => "unsubscribe_topic", :format => "json", :course_id => course.id.to_s, :topic_id => topic.id.to_s})
    end

    it "should allow subscription" do
      expect(call_subscribe(@topic1, @teacher)).to eq 204
      expect(@topic1.subscribed?(@teacher)).to be_truthy
    end

    it "should allow unsubscription" do
      expect(call_unsubscribe(@topic2, @teacher)).to eq 204
      expect(@topic2.subscribed?(@teacher)).to be_falsey
    end

    it "should be idempotent" do
      expect(call_unsubscribe(@topic1, @teacher)).to eq 204
      expect(call_subscribe(@topic1, @student)).to eq 204
    end

    context "when initial_post_required" do
      it "should allow subscription with an initial post" do
        @user = @student
        create_reply(@topic2, :message => 'first post!')
        expect(call_subscribe(@topic2, @student)).to eq 204
        expect(@topic2.subscribed?(@student)).to be_truthy
      end

      it "should not allow subscription without an initial post" do
        expect(call_subscribe(@topic2, @student)).to eq 403
      end

      it "should allow unsubscription even without an initial post" do
        @topic2.subscribe(@student)
        expect(@topic2.subscribed?(@student)).to be_truthy
        expect(call_unsubscribe(@topic2, @student)).to eq 204
        expect(@topic2.subscribed?(@student)).to be_falsey
      end

      it "should unsubscribe a user if all their posts get deleted" do
        @user = @student
        @entry = create_reply(@topic2, :message => 'first post!')
        expect(call_subscribe(@topic2, @student)).to eq 204
        expect(@topic2.subscribed?(@student)).to be_truthy
        @entry.destroy
        expect(@topic2.subscribed?(@student)).to be_falsey
      end
    end
  end

  context "subscription holds" do
    it "should hold when an initial post is required" do
      @topic = create_topic(@course, :require_initial_post => true)
      student_in_course(:active_all => true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics",
                      { :controller => "discussion_topics", :action => "index", :format => "json", :course_id => @course.id.to_s })
      expect(json[0]['subscription_hold']).to eql('initial_post_required')
    end

    it "should hold when the user isn't in a group set" do
      teacher_in_course(:active_all => true)
      group_discussion_assignment
      @topic.publish if @topic.unpublished?
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics",
                      { :controller => "discussion_topics", :action => "index", :format => "json", :course_id => @course.id.to_s })
      expect(json[0]['subscription_hold']).to  eql('not_in_group_set')
    end

    it "should hold when the user isn't in a group" do
      teacher_in_course(:active_all => true)
      group_discussion_assignment
      @topic.publish if @topic.unpublished?
      child = @topic.child_topics.first
      group = child.context
      json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics",
                      { :controller => "discussion_topics", :action => "index", :format => "json", :group_id => group.id.to_s })
      expect(json[0]['subscription_hold']).to eql('not_in_group')
    end
  end

  describe "threaded discussions" do
    before :once do
      student_in_course(:active_all => true)
      @topic = create_topic(@course, :threaded => true)
      @entry = create_entry(@topic)
      @sub1 = create_reply(@entry)
      @sub2 = create_reply(@sub1)
      @sub3 = create_reply(@sub2)
      @side2 = create_reply(@entry)
      @entry2 = create_entry(@topic)
    end

    context "in the original API" do
      it "should respond with information on the threaded discussion" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics",
                 { :controller => "discussion_topics", :action => "index", :format => "json", :course_id => @course.id.to_s })
        expect(json[0]['discussion_type']).to eq 'threaded'
      end

      it "should return nested discussions in a flattened format" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries",
                 { :controller => "discussion_topics_api", :action => "entries", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
        expect(json.size).to eq 2
        expect(json[0]['id']).to eq @entry2.id
        e1 = json[1]
        expect(e1['id']).to eq @entry.id
        expect(e1['recent_replies'].map { |r| r['id'] }).to eq [@side2.id, @sub3.id, @sub2.id, @sub1.id]
        expect(e1['recent_replies'].map { |r| r['parent_id'] }).to eq [@entry.id, @sub2.id, @sub1.id, @entry.id]

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies",
                 { :controller => "discussion_topics_api", :action => "replies", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
        expect(json.size).to eq 4
        expect(json.map { |r| r['id'] }).to eq [@side2.id, @sub3.id, @sub2.id, @sub1.id]
        expect(json.map { |r| r['parent_id'] }).to eq [@entry.id, @sub2.id, @sub1.id, @entry.id]
      end

      it "should allow posting a reply to a sub-entry" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@sub2.id}/replies",
                 { :controller => "discussion_topics_api", :action => "add_reply", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @sub2.id.to_s },
                 { :message => "ohai" })
        expect(json['parent_id']).to eq @sub2.id
        @sub4 = DiscussionEntry.order(:id).last
        expect(@sub4.id).to eq json['id']

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies",
                 { :controller => "discussion_topics_api", :action => "replies", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
        expect(json.size).to eq 5
        expect(json.map { |r| r['id'] }).to eq [@sub4.id, @side2.id, @sub3.id, @sub2.id, @sub1.id]
        expect(json.map { |r| r['parent_id'] }).to eq [@sub2.id, @entry.id, @sub2.id, @sub1.id, @entry.id]
      end

      it "should set and return editor_id if editing another user's post" do
        pending "WIP: Not implemented"
        fail
      end

      it "should fail if the max entry depth is reached" do
        entry = @entry
        (DiscussionEntry.max_depth - 1).times do
          entry = create_reply(entry)
        end
        json = api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{entry.id}/replies",
                 { :controller => "discussion_topics_api", :action => "add_reply", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => entry.id.to_s },
                 { :message => "ohai" }, {}, {:expected_status => 400})
      end
    end

    context "in the updated API" do
      it "should return a paginated entry_list" do
        entries = [@entry2, @sub1, @side2]
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entry_list?per_page=2",
                  { :controller => "discussion_topics_api", :action => "entry_list", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :per_page => '2' },
                 { :ids => entries.map(&:id) })
        expect(json.size).to eq 2
        # response order is by id
        expect(json.map { |e| e['id'] }).to eq [@sub1.id, @side2.id]
        expect(response['Link']).to match(/next/)
      end

      it "should return deleted entries, but with limited data" do
        @sub1.destroy
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entry_list",
                  { :controller => "discussion_topics_api", :action => "entry_list", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
                 { :ids => @sub1.id })
        expect(json.size).to eq 1
        expect(json.first['id']).to eq @sub1.id
        expect(json.first['deleted']).to eq true
        expect(json.first['read_state']).to eq 'read'
        expect(json.first['parent_id']).to eq @entry.id
        expect(json.first['updated_at']).to eq @sub1.updated_at.as_json
        expect(json.first['created_at']).to eq @sub1.created_at.as_json
        expect(json.first['edited_by']).to be_nil
      end
    end
  end

  context "materialized view API" do
    it "should respond with the materialized information about the discussion" do
      begin
        topic_with_nested_replies
        # mark a couple entries as read
        @user = @student
        @root2.change_read_state("read", @user)
        @reply3.change_read_state("read", @user)
        # have the teacher edit one of the student's replies
        @reply_reply1.editor = @teacher
        @reply_reply1.update_attributes(:message => '<p>censored</p>')

        @all_entries.each &:reload

        # materialized view jobs are now delayed
        Timecop.travel(Time.now + 20.seconds)
        run_jobs

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                  { :controller => "discussion_topics_api", :action => "view", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })

        expect(json['unread_entries'].size).to eq 2 # two marked read, then ones this user wrote are never unread
        expect(json['unread_entries'].sort).to eq (@topic.discussion_entries - [@root2, @reply3] - @topic.discussion_entries.select { |e| e.user == @user }).map(&:id).sort

        expect(json['participants'].sort_by { |h| h['id'] }).to eq [
          { 'id' => @student.id, 'display_name' => @student.short_name, 'avatar_image_url' => User.avatar_fallback_url, "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student.id}" },
          { 'id' => @teacher.id, 'display_name' => @teacher.short_name, 'avatar_image_url' => User.avatar_fallback_url, "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}" },
        ].sort_by { |h| h['id'] }

        reply_reply1_attachment_json = {
          "content-type"=>"application/loser",
          "url"=>"http://www.example.com/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}",
          "filename"=>"unknown.loser",
          "display_name"=>"unknown.loser",
          "id" => @attachment.id,
          "folder_id" => @attachment.folder_id,
          "size" => 100,
          'unlock_at' => nil,
          'locked' => false,
          'hidden' => false,
          'lock_at' => nil,
          'locked_for_user' => false,
          'hidden_for_user' => false,
          'created_at' => @attachment.created_at.as_json,
          'updated_at' => @attachment.updated_at.as_json,
          'thumbnail_url' => @attachment.thumbnail_url,
        }

        v0 = json['view'][0]
        expect(v0['id']).to         eq @root1.id
        expect(v0['user_id']).to    eq @student.id
        expect(v0['message']).to    eq 'root1'
        expect(v0['parent_id']).to     be nil
        expect(v0['created_at']).to eq @root1.created_at.as_json
        expect(v0['updated_at']).to eq @root1.updated_at.as_json

        v0_r0 = v0['replies'][0]
        expect(v0_r0['id']).to         eq @reply1.id
        expect(v0_r0['deleted']).to       be true
        expect(v0_r0['parent_id']).to  eq @root1.id
        expect(v0_r0['created_at']).to eq @reply1.created_at.as_json
        expect(v0_r0['updated_at']).to eq @reply1.updated_at.as_json

        v0_r0_r0 = v0_r0['replies'][0]
        expect(v0_r0_r0['id']).to         eq @reply_reply2.id
        expect(v0_r0_r0['user_id']).to    eq @student.id
        expect(v0_r0_r0['message']).to    eq 'reply_reply2'
        expect(v0_r0_r0['parent_id']).to  eq @reply1.id
        expect(v0_r0_r0['created_at']).to eq @reply_reply2.created_at.as_json
        expect(v0_r0_r0['updated_at']).to eq @reply_reply2.updated_at.as_json

        v0_r1 = v0['replies'][1]
        expect(v0_r1['id']).to         eq @reply2.id
        expect(v0_r1['user_id']).to    eq @teacher.id

        message = Nokogiri::HTML::DocumentFragment.parse(v0_r1["message"])

        a_tag = message.css("p a").first
        expect(a_tag["href"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{@reply2_attachment.id}/download"
        expect(a_tag["data-api-endpoint"]).to eq "http://www.example.com/api/v1/courses/#{@course.id}/files/#{@reply2_attachment.id}"
        expect(a_tag["data-api-returntype"]).to eq "File"
        expect(a_tag.inner_text).to eq "This is a file link"

        video_tag = message.css("p video").first
        expect(video_tag["poster"]).to eq "http://www.example.com/media_objects/0_abcde/thumbnail?height=448&type=3&width=550"
        expect(video_tag["data-media_comment_type"]).to eq "video"
        expect(video_tag["preload"]).to eq "none"
        expect(video_tag["class"]).to eq "instructure_inline_media_comment"
        expect(video_tag["data-media_comment_id"]).to eq "0_abcde"
        expect(video_tag["controls"]).to eq "controls"
        expect(video_tag["src"]).to eq "http://www.example.com/courses/#{@course.id}/media_download?entryId=0_abcde&media_type=video&redirect=1"
        expect(video_tag.inner_text).to eq "link"

        expect(v0_r1['parent_id']).to  eq @root1.id
        expect(v0_r1['created_at']).to eq @reply2.created_at.as_json
        expect(v0_r1['updated_at']).to eq @reply2.updated_at.as_json

        v0_r1_r0 = v0_r1['replies'][0]
        expect(v0_r1_r0['id']).to          eq @reply_reply1.id
        expect(v0_r1_r0['user_id']).to     eq @student.id
        expect(v0_r1_r0['editor_id']).to   eq @teacher.id
        expect(v0_r1_r0['message']).to     eq '<p>censored</p>'
        expect(v0_r1_r0['parent_id']).to   eq @reply2.id
        expect(v0_r1_r0['created_at']).to  eq @reply_reply1.created_at.as_json
        expect(v0_r1_r0['updated_at']).to  eq @reply_reply1.updated_at.as_json
        expect(v0_r1_r0['attachment']).to  eq reply_reply1_attachment_json
        expect(v0_r1_r0['attachments']).to eq [reply_reply1_attachment_json]

        v1 = json['view'][1]
        expect(v1['id']).to         eq @root2.id
        expect(v1['user_id']).to    eq @student.id
        expect(v1['message']).to    eq 'root2'
        expect(v1['parent_id']).to     be nil
        expect(v1['created_at']).to eq @root2.created_at.as_json
        expect(v1['updated_at']).to eq @root2.updated_at.as_json

        v1_r0 = v1['replies'][0]
        expect(v1_r0['id']).to         eq @reply3.id
        expect(v1_r0['user_id']).to    eq @student.id
        expect(v1_r0['message']).to    eq 'reply3'
        expect(v1_r0['parent_id']).to  eq @root2.id
        expect(v1_r0['created_at']).to eq @reply3.created_at.as_json
        expect(v1_r0['updated_at']).to eq @reply3.updated_at.as_json
      ensure
        Timecop.return
      end
    end

    it "should include new entries if the flag is given" do
      begin
        course_with_teacher(:active_all => true)
        student_in_course(:course => @course, :active_all => true)
        @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher, :discussion_type => 'threaded')
        @root1 = @topic.reply_from(:user => @student, :html => "root1")

        # materialized view jobs are now delayed
        Timecop.travel(Time.now + 20.seconds)
        run_jobs

        # make everything slightly in the past to test updating
        DiscussionEntry.update_all(:updated_at => 5.minutes.ago)
        @reply1 = @root1.reply_from(:user => @teacher, :html => "reply1")
        @reply2 = @root1.reply_from(:user => @teacher, :html => "reply2")

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                  { :controller => "discussion_topics_api", :action => "view", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s }, { :include_new_entries => '1' })
        expect(json['unread_entries'].size).to eq 2
        expect(json['unread_entries'].sort).to eq [@reply1.id, @reply2.id]

        expect(json['participants'].map { |h| h['id'] }.sort).to eq [@teacher.id, @student.id]

        expect(json['view']).to eq [
          'id' => @root1.id,
          'parent_id' => nil,
          'user_id' => @student.id,
          'message' => 'root1',
          'created_at' => @root1.created_at.as_json,
          'updated_at' => @root1.updated_at.as_json,
        ]

        # it's important that these are returned in created_at order
        expect(json['new_entries']).to eq [
          {
            'id' => @reply1.id,
            'created_at' => @reply1.created_at.as_json,
            'updated_at' => @reply1.updated_at.as_json,
            'message' => 'reply1',
            'parent_id' => @root1.id,
            'user_id' => @teacher.id,
          },
          {
            'id' => @reply2.id,
            'created_at' => @reply2.created_at.as_json,
            'updated_at' => @reply2.updated_at.as_json,
            'message' => 'reply2',
            'parent_id' => @root1.id,
            'user_id' => @teacher.id,
          },
        ]
      ensure
        Timecop.return
      end
    end
  end

  it "returns due dates as they apply to the user" do
    course_with_student(:active_all => true)
    @user = @student
    @student.enrollments.map(&:destroy!)
    @section = @course.course_sections.create! :name => "afternoon delight"
    @course.enroll_user(@student,'StudentEnrollment',
                        :section => @section,
                        :enrollment_state => :active)

    @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher, :discussion_type => 'threaded')
    @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title, :due_at => 1.day.from_now)
    @assignment.saved_by = :discussion_topic
    @topic.assignment = @assignment
    @topic.save

    override = @assignment.assignment_overrides.build
    override.set = @section
    override.title = "extension"
    override.due_at = 2.day.from_now
    override.due_at_overridden = true
    override.save!

    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
              { :controller => "discussion_topics_api", :action => "show", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
    expect(json['assignment']).not_to be_nil
    expect(json['assignment']['due_at']).to eq override.due_at.iso8601.to_s
  end

  context "public courses" do
    let(:announcements_view_api) {
      ->(user, course_id, announcement_id, status = 200) do
        old_at_user = @user
        @user = user # this is required because of api_call :-(
        json = api_call(
          :get,
          "/api/v1/courses/#{course_id}/discussion_topics/#{announcement_id}/view?include_new_entries=1",
          {
            controller: "discussion_topics_api",
            action: "view",
            format: "json",
            course_id: course_id.to_s,
            topic_id: announcement_id.to_s,
            include_new_entries: 1
          },
          {},
          {},
          {
            expected_status: status
          }
        )
        @user = old_at_user
        json
      end
    }

    before :each do
      course_with_teacher(active_all: true, is_public: true) # sets @teacher and @course
      expect(@course.is_public).to be_truthy
      account_admin_user(account: @course.account) # sets @admin
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user

      @context = @course
      @announcement = announcement_model(user: @teacher) # sets @a

      s1e = @announcement.discussion_entries.create!(:user => @student1, :message => "Hello I'm student 1!")
      @announcement.discussion_entries.create!(:user => @student2, :parent_entry => s1e, :message => "Hello I'm student 2!")
    end

    context "should be shown" do
      let(:check_access) {
        ->(json) do
          expect(json["new_entries"]).not_to be_nil
          expect(json["new_entries"].count).to eq(2)
          expect(json["new_entries"].first["user_id"]).to  eq(@student1.id)
          expect(json["new_entries"].second["user_id"]).to eq(@student2.id)
        end
      }

      it "shows student comments to students" do
        check_access.call(announcements_view_api.call(@student1, @course.id, @announcement.id))
      end

      it "shows student comments to teachers" do
        check_access.call(announcements_view_api.call(@teacher, @course.id, @announcement.id))
      end

      it "shows student comments to admins" do
        check_access.call(announcements_view_api.call(@admin, @course.id, @announcement.id))
      end
    end

    context "should not be shown" do
      let(:check_access) {
        ->(json) do
          expect(json["new_entries"]).to be_nil
          expect(%w[unauthorized unauthenticated]).to include(json["status"])
        end
      }

      before :each do
        prev_course = @course
        course_with_teacher
        @student = student_in_course.user
        @course = prev_course
      end

      it "does not show student comments to unauthenticated users" do
        check_access.call(announcements_view_api.call(nil, @course.id, @announcement.id, 401))
      end

      it "does not show student comments to other students not in the course" do
        check_access.call(announcements_view_api.call(@student, @course.id, @announcement.id, 401))
      end

      it "does not show student comments to other teachers not in the course" do
        check_access.call(announcements_view_api.call(@teacher, @course.id, @announcement.id, 401))
      end
    end
  end
end

def create_attachment(context, opts={})
  opts[:uploaded_data] ||= StringIO.new('attachment content')
  opts[:filename] ||= 'content.txt'
  opts[:display_name] ||= opts[:filename]
  opts[:folder] ||= Folder.unfiled_folder(context)
  attachment = context.attachments.build(opts)
  attachment.save!
  attachment
end

def create_topic(context, opts={})
  attachment = opts.delete(:attachment)
  opts[:user] ||= @user
  topic = context.discussion_topics.build(opts)
  topic.attachment = attachment if attachment
  topic.save!
  topic.publish if topic.unpublished?
  topic
end

def create_subtopic(topic, opts={})
  opts[:user] ||= @user
  subtopic = topic.context.discussion_topics.build(opts)
  subtopic.root_topic_id = topic.id
  subtopic.save!
  subtopic
end

def create_entry(topic, opts={})
  attachment = opts.delete(:attachment)
  created_at = opts.delete(:created_at)
  opts[:user] ||= @user
  entry = topic.discussion_entries.build(opts)
  entry.attachment = attachment if attachment
  entry.created_at = created_at if created_at
  entry.save!
  entry
end

def create_reply(entry, opts={})
  created_at = opts.delete(:created_at)
  opts[:user] ||= @user
  opts[:html] ||= opts.delete(:message)
  opts[:html] ||= "<p>This is a test message</p>"
  reply = entry.reply_from(opts)
  reply.created_at = created_at if created_at
  reply.save!
  reply
end
