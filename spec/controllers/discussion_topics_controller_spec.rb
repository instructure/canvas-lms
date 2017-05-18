#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe DiscussionTopicsController do
  before :once do
    course_with_teacher(:active_all => true)
    course_with_observer(:active_all => true, :course => @course)
    @observer_enrollment = @enrollment
    student_in_course(:active_all => true)
  end

  def course_topic(opts={})
    @topic = @course.discussion_topics.build(:title => "some topic", :pinned => opts.fetch(:pinned, false))
    user = opts[:user] || @user
    if user && !opts[:skip_set_user]
      @topic.user = user
    end

    if opts[:with_assignment]
      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @topic.assignment.infer_times
      @topic.assignment.saved_by = :discussion_topic
    end

    @topic.save
    @topic.reload
    @topic
  end

  def topic_entry
    @entry = @topic.discussion_entries.create(:message => "some message", :user => @user)
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should require the course to be published for students" do
      @course.claim
      user_session(@student)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it 'does not show announcements without :read_announcements' do
      @course.account.role_overrides.create!(permission: 'read_announcements', role: student_role, enabled: false)
      get 'index', course_id: @course.id
      assert_unauthorized
    end

    it "should load for :view_group_pages students" do
      @course.account.role_overrides.create!(
        role: student_role,
        permission: 'view_group_pages',
        enabled: true
      )
      @group_category = @course.group_categories.create(:name => 'gc')
      @group = @course.groups.create!(:group_category => @group_category)
      user_session(@student)

      get 'index', :group_id => @group.id
      expect(response).to be_success
    end

    context "graded group discussion" do
      before do
        @course.account.role_overrides.create!(
          role: student_role,
          permission: 'view_group_pages',
          enabled: true
        )

        group_discussion_assignment
        @child_topic = @topic.child_topics.first
        @group = @child_topic.context
        @group.add_user(@student)
        @assignment.only_visible_to_overrides = true
        @assignment.save!
      end

      it "should return graded and visible group discussions properly" do
        cs = @student.enrollments.first.course_section
        create_section_override_for_assignment(@assignment, {course_section: cs})

        user_session(@student)

        get 'index', :group_id => @group.id
        expect(response).to be_success
        expect(assigns["topics"]).to include(@child_topic)
      end

      it "should not return graded group discussions if a student has no visibility" do
        user_session(@student)

        get 'index', :group_id => @group.id
        expect(response).to be_success
        expect(assigns["topics"]).not_to include(@child_topic)
      end
    end

    context "cross-sharding" do
      specs_require_sharding

      it 'returns the topic across shards' do
        @topic = @course.discussion_topics.create!(title: 'student topic', message: 'Hello', user: @student)
        user_session(@student)
        @shard1.activate do
          get 'index', { format: :json, course_id: @course.id }
          expect(assigns[:topics]).to include(@topic)
        end

        @shard2.activate do
          get 'index', { format: :json, course_id: @course.id }
          expect(assigns[:topics]).to include(@topic)
        end
      end
    end

    it "should return non-graded group discussions properly" do
      @course.account.role_overrides.create!(
        role: student_role,
        permission: 'view_group_pages',
        enabled: true
      )

      group_category(context: @course)
      membership = group_with_user(group_category: @group_category, user: @student, context: @course)
      @topic = @group.discussion_topics.create(:title => "group topic")
      @topic.context = @group
      @topic.save!

      user_session(@student)

      get 'index', :group_id => @group.id
      expect(response).to be_success
      expect(assigns["topics"]).to include(@topic)
    end

    it "does not filter module locked discussion by default" do
      course_topic(user: @teacher)
      @locked_topic = @topic
      course_topic(user: @teacher)
      @module = @course.context_modules.create!(name: 'some module')
      @module.add_item(type: 'discussion_topic', id: @topic.id)
      @locked_module = @course.context_modules.create!(name: 'some locked module')
      @locked_module.add_item(type: 'discussion_topic', id: @locked_topic.id)
      @locked_module.unlock_at = 2.months.from_now
      @locked_module.save!
      user_session(@student)

      get 'index', course_id: @course.id
      expect(response).to be_success
      expect(assigns["topics"]).to include(@locked_topic)
    end

    it "filters module locked discussions when asked to" do
      course_topic(user: @teacher)
      @locked_topic = @topic
      course_topic(user: @teacher)
      @module = @course.context_modules.create!(name: 'some module')
      @module.add_item(type: 'discussion_topic', id: @topic.id)
      @locked_module = @course.context_modules.create!(name: 'some locked module')
      @locked_module.add_item(type: 'discussion_topic', id: @locked_topic.id)
      @locked_module.unlock_at = 2.months.from_now
      @locked_module.save!
      user_session(@student)

      get 'index', course_id: @course.id, exclude_context_module_locked_topics: true
      expect(response).to be_success
      expect(assigns["topics"]).not_to include(@locked_topic)
    end
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_topic
      get 'show', :course_id => @course.id, :id => @topic.id
      assert_unauthorized
    end

    it "should require the course to be published for students" do
      course_topic
      @course.claim
      user_session(@student)
      get 'show', :course_id => @course.id, :id => @topic.id
      assert_unauthorized
    end

    it "should not work for announcements in a public course" do
      @course.update_attribute(:is_public, true)
      @announcement = @course.announcements.create!(
        :title => "some announcement",
        :message => "some message"
      )
      get 'show', :course_id => @course.id, :id => @announcement.id
      expect(response).to_not be_success
    end

    it "should not display announcements in private courses to users who aren't logged in" do
      announcement = @course.announcements.create!(title: 'Test announcement', message: 'Message')
      get('show', course_id: @course.id, id: announcement.id)
      assert_unauthorized
    end

    context "discussion topic with assignment with overrides" do
      render_views

      before :once do
        course_topic(user: @teacher, with_assignment: true)
        @section = @course.course_sections.create!(:name => "I <3 Discusions")
        @override = assignment_override_model(:assignment => @topic.assignment,
                                  :due_at => Time.now,
                                  :set => @section)
      end

      it "doesn't show the topic to unassigned students" do
        @topic.assignment.update_attribute(:only_visible_to_overrides, true)
        user_session(@student)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(response).to be_redirect
        expect(response.location).to eq course_discussion_topics_url @course
      end

      it "doesn't show overrides to students" do
        user_session(@student)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(response).to be_success
        expect(response.body).not_to match 'discussion-topic-due-dates'
        due_date = OverrideListPresenter.new.due_at(@topic.assignment)
        expect(response.body).to match "due #{due_date}"
      end

      it "doesn't show overrides for observers" do
        user_session(@observer)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(response).to be_success
        expect(response.body).not_to match 'discussion-topic-due-dates'
        due_date = OverrideListPresenter.new.due_at(@topic.assignment.overridden_for(@observer))
        expect(response.body).to match "due #{due_date}"
      end

      it "does show overrides to teachers" do
        user_session(@teacher)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(response).to be_success
        expect(response.body).to match 'discussion-topic-due-dates'
      end

    end

    it "should assign variables" do
      user_session(@student)
      course_topic
      topic_entry
      @topic.reload
      expect(@topic.discussion_entries).not_to be_empty
      get 'show', :course_id => @course.id, :id => @topic.id
      expect(response).to be_success
      expect(assigns[:topic]).not_to be_nil
      expect(assigns[:topic]).to eql(@topic)
    end

    it "should display speedgrader when not for a large course" do
      user_session(@teacher)
      course_topic(user: @teacher, with_assignment: true)
      get 'show', :course_id => @course.id, :id => @topic.id
      expect(assigns[:js_env][:DISCUSSION][:SPEEDGRADER_URL_TEMPLATE]).to be_truthy
    end

    it "should hide speedgrader when for a large course" do
      user_session(@teacher)
      course_topic(user: @teacher, with_assignment: true)
      Course.any_instance.stubs(:large_roster?).returns(true)
      get 'show', :course_id => @course.id, :id => @topic.id
      expect(assigns[:js_env][:DISCUSSION][:SPEEDGRADER_URL_TEMPLATE]).to be_nil
    end

    it "should setup speedgrader template for variable substitution" do
      user_session(@teacher)
      course_topic(user: @teacher, with_assignment: true)
      get 'show', :course_id => @course.id, :id => @topic.id

      # this is essentially a unit test for app/coffeescripts/models/Entry.coffee,
      # making sure that we get back the expected format for this url template
      template = assigns[:js_env][:DISCUSSION][:SPEEDGRADER_URL_TEMPLATE]
      url = template.gsub(/%22:student_id%22/, '123')
      expect(url).to match "%7B%22student_id%22:123%7D"
    end

    it "should mark as read when viewed" do
      user_session(@student)
      course_topic(:skip_set_user => true)

      expect(@topic.read_state(@student)).to eq 'unread'
      get 'show', :course_id => @course.id, :id => @topic.id
      expect(@topic.reload.read_state(@student)).to eq 'read'
    end

    it "should not mark as read if not visible" do
      user_session(@student)
      course_topic(:skip_set_user => true)
      mod = @course.context_modules.create! name: 'no soup for you', unlock_at: 1.year.from_now
      mod.add_item(type: 'discussion_topic', id: @topic.id)
      mod.save!
      expect(@topic.read_state(@student)).to eq 'unread'
      get 'show', :course_id => @course.id, :id => @topic.id
      expect(@topic.reload.read_state(@student)).to eq 'unread'
    end

    it "should mark as read if visible but locked" do
      user_session(@student)
      course_topic(:skip_set_user => true)
      @announcement = @course.announcements.create!(
        :title => "some announcement",
        :message => "some message",
        :unlock_at => 1.week.ago,
        :lock_at => 1.day.ago
      )
      expect(@announcement.read_state(@student)).to eq 'unread'
      get 'show', :course_id => @course.id, :id => @announcement.id
      expect(@announcement.reload.read_state(@student)).to eq 'read'
    end

    it "should allow concluded teachers to see discussions" do
      user_session(@teacher)
      course_topic
      @enrollment.conclude
      get 'show', :course_id => @course.id, :id => @topic.id
      expect(response).to be_success
      get 'index', :course_id => @course.id
      expect(response).to be_success
    end

    it "should allow concluded students to see discussions" do
      user_session(@student)
      course_topic
      @enrollment.conclude
      get 'show', :course_id => @course.id, :id => @topic.id
      expect(response).to be_success
      get 'index', :course_id => @course.id
      expect(response).to be_success
    end

    context 'group discussions' do
      before(:once) do
        @group_category = @course.group_categories.create(:name => 'category 1')
        @group1 = @course.groups.create!(:group_category => @group_category)
        @group2 = @course.groups.create!(:group_category => @group_category)

        group_category2 = @course.group_categories.create(:name => 'category 2')
        @course.groups.create!(:group_category => group_category2)
      end

      it "should assign groups from the topic's category" do
        user_session(@teacher)

        course_topic(user: @teacher, with_assignment: true)
        @topic.group_category = @group_category
        @topic.save!

        get 'show', :course_id => @course.id, :id => @topic.id
        expect(assigns[:groups].size).to eql(2)
      end

      it "should only show applicable groups if DA applies" do
        user_session(@teacher)

        course_topic(user: @teacher, with_assignment: true)
        @topic.group_category = @group_category
        @topic.save!

        asmt = @topic.assignment
        asmt.only_visible_to_overrides = true
        override = asmt.assignment_overrides.build
        override.set = @group2
        override.save!
        asmt.save!

        get 'show', :course_id => @course.id, :id => @topic.id
        expect(response).to be_success
        expect(assigns[:groups]).to eq([@group2])
      end

      it "should redirect to group for student if DA applies to section" do
        user_session(@student)
        @group1.add_user(@student)

        course_topic(user: @teacher, with_assignment: true)
        @topic.group_category = @group_category
        @topic.save!

        asmt = @topic.assignment
        asmt.only_visible_to_overrides = true
        override = asmt.assignment_overrides.build
        override.set = @course.default_section
        override.save!
        asmt.save!

        get 'show', :course_id => @course.id, :id => @topic.id
        redirect_path = "/groups/#{@group1.id}/discussion_topics?root_discussion_topic_id=#{@topic.id}"
        expect(response).to redirect_to redirect_path
      end

      it "should redirect to the student's group" do
        user_session(@student)
        @group1.add_user(@student)

        course_topic(user: @teacher, with_assignment: true)
        @topic.group_category = @group_category
        @topic.save!

        get 'show', :course_id => @course.id, :id => @topic.id
        redirect_path = "/groups/#{@group1.id}/discussion_topics?root_discussion_topic_id=#{@topic.id}"
        expect(response).to redirect_to redirect_path
      end

      it "should redirect to the student's group even if students can view all groups" do
        @course.account.role_overrides.create!(
          role: student_role,
          permission: 'view_group_pages',
          enabled: true
        )
        user_session(@student)
        @group1.add_user(@student)

        course_topic(user: @teacher, with_assignment: true)
        @topic.group_category = @group_category
        @topic.save!

        get 'show', :course_id => @course.id, :id => @topic.id
        redirect_path = "/groups/#{@group1.id}/discussion_topics?root_discussion_topic_id=#{@topic.id}"
        expect(response).to redirect_to redirect_path
      end

      it "should not change the name of the child topic when navigating to it" do
        user_session(@student)
        @group1.add_user(@student)

        course_topic(user: @teacher, with_assignment: true)
        @topic.group_category = @group_category
        @topic.save!

        child_topic = @topic.child_topic_for(@student)
        old_title = child_topic.title

        get 'index', :group_id => @group1.id, :root_discussion_topic_id => @topic.id

        expect(@topic.child_topic_for(@student).title).to eq old_title
      end
    end

    context 'publishing' do
      render_views

      it "hides the publish icon for announcements" do
        user_session(@teacher)
        @context = @course
        @announcement = @course.announcements.create!(
          :title => "some announcement",
          :message => "some message"
        )
        get 'show', :course_id => @course.id, :id => @announcement.id
        expect(response.body).not_to match "topic_publish_button"
      end
    end

    context "posting first to view setting" do
      before(:once) do
        @observer_enrollment.associated_user = @student
        @observer_enrollment.save
        @observer.reload

        @context = @course
        discussion_topic_model
        @topic.require_initial_post = true
        @topic.save
      end

      it "should allow admins to see posts without posting" do
        @topic.reply_from(:user => @student, :text => 'hai')
        user_session(@teacher)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(assigns[:initial_post_required]).to be_falsey
      end

      it "shouldn't allow student who hasn't posted to see" do
        @topic.reply_from(:user => @teacher, :text => 'hai')
        user_session(@student)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(assigns[:initial_post_required]).to be_truthy
      end

      it "shouldn't allow student's observer who hasn't posted to see" do
        @topic.reply_from(:user => @teacher, :text => 'hai')
        user_session(@observer)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(assigns[:initial_post_required]).to be_truthy
      end

      it "should allow student who has posted to see" do
        @topic.reply_from(:user => @student, :text => 'hai')
        user_session(@student)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(assigns[:initial_post_required]).to be_falsey
      end

      it "should allow student's observer who has posted to see" do
        @topic.reply_from(:user => @student, :text => 'hai')
        user_session(@observer)
        get 'show', :course_id => @course.id, :id => @topic.id
        expect(assigns[:initial_post_required]).to be_falsey
      end
    end

    context "student context cards" do
      before(:once) do
        course_topic user: @teacher
        @course.root_account.enable_feature! :student_context_cards
      end

      it "is disabed for students" do
        user_session(@student)
        get :show, course_id: @course.id, id: @topic.id
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to be_falsey
      end

      it "is disabled for teachers when feature_flag is off" do
        @course.root_account.disable_feature! :student_context_cards
        user_session(@teacher)
        get :show, course_id: @course.id, id: @topic.id
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to be_falsey
      end

      it "is enabled for teachers when feature_flag is on" do
        user_session(@teacher)
        get :show, course_id: @course.id, id: @topic.id
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to eq true
      end
    end

  end

  describe "GET 'new'" do
    it "should maintain date and time when passed params" do
      user_session(@teacher)
      due_at = 1.day.from_now
      get 'new', course_id: @course.id, due_at: due_at.iso8601
      expect(assigns[:js_env][:DISCUSSION_TOPIC][:ATTRIBUTES][:assignment][:due_at]).to eq due_at.iso8601
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      AssignmentUtil.stubs(:due_date_required_for_account?).returns(true)
      get 'new', :course_id => @course.id
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      AssignmentUtil.stubs(:due_date_required_for_account?).returns(false)
      get 'new', :course_id => @course.id
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.name_length_required_for_account? == true" do
      user_session(@teacher)
      AssignmentUtil.stubs(:name_length_required_for_account?).returns(true)
      get 'new', :course_id => @course.id
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.name_length_required_for_account? == false" do
      user_session(@teacher)
      AssignmentUtil.stubs(:name_length_required_for_account?).returns(false)
      get 'new', :course_id => @course.id
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env MAX_NAME_LENGTH is a 15 when AssignmentUtil.assignment_max_name_length returns 15" do
      user_session(@teacher)
      AssignmentUtil.stubs(:assignment_max_name_length).returns(15)
      get 'new', :course_id => @course.id
      expect(assigns[:js_env][:MAX_NAME_LENGTH]).to eq(15)
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      AssignmentUtil.stubs(:post_to_sis_friendly_name).returns('Foo Bar')
      get 'new', :course_id => @course.id
      expect(assigns[:js_env][:SIS_NAME]).to eq('Foo Bar')
    end
  end

  describe "GET 'edit'" do
    before(:once) do
      course_topic
    end

    include_context "grading periods within controller" do
      let(:course) { @course }
      let(:teacher) { @teacher }
      let(:request_params) { [:edit, course_id: course, id: @topic] }
    end

    it "should not explode with mgp and group context" do
      group1 = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
      group1.enrollment_terms << @course.enrollment_term
      user_session(@teacher)
      group = group_model(:context => @course)
      group_topic = group.discussion_topics.create!(:title => "title")
      get(:edit, group_id: group, id: group_topic)
      expect(response).to be_success
      expect(assigns[:js_env]).to have_key(:active_grading_periods)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      user_session(@teacher)
      AssignmentUtil.stubs(:due_date_required_for_account?).returns(true)
      get :edit, course_id: @course.id, id: @topic.id
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      user_session(@teacher)
      AssignmentUtil.stubs(:due_date_required_for_account?).returns(false)
      get :edit, course_id: @course.id, id: @topic.id
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.name_length_required_for_account? == true" do
      user_session(@teacher)
      AssignmentUtil.stubs(:name_length_required_for_account?).returns(true)
      get :edit, course_id: @course.id, id: @topic.id
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to eq(true)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.name_length_required_for_account? == false" do
      user_session(@teacher)
      AssignmentUtil.stubs(:name_length_required_for_account?).returns(false)
      get :edit, course_id: @course.id, id: @topic.id
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to eq(false)
    end

    it "js_env MAX_NAME_LENGTH is a 15 when AssignmentUtil.assignment_max_name_length returns 15" do
      user_session(@teacher)
      AssignmentUtil.stubs(:assignment_max_name_length).returns(15)
      get :edit, course_id: @course.id, id: @topic.id
      expect(assigns[:js_env][:MAX_NAME_LENGTH]).to eq(15)
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      user_session(@teacher)
      AssignmentUtil.stubs(:post_to_sis_friendly_name).returns('Foo Bar')
      get :edit, :course_id => @course.id, :id => @topic.id
      expect(assigns[:js_env][:SIS_NAME]).to eq('Foo Bar')
    end

    context 'conditional-release' do
      before do
        user_session(@teacher)
      end

      it 'should include environment variables if enabled' do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
        ConditionalRelease::Service.stubs(:env_for).returns({ dummy: 'value' })
        get :edit, course_id: @course.id, id: @topic.id
        expect(response).to have_http_status :success
        expect(controller.js_env[:dummy]).to eq 'value'
      end

      it 'should not include environment variables when disabled' do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(false)
        ConditionalRelease::Service.stubs(:env_for).returns({ dummy: 'value' })
        get :edit, course_id: @course.id, id: @topic.id
        expect(response).to have_http_status :success
        expect(controller.js_env).not_to have_key :dummy
      end
    end
  end

  context 'student planner' do
    before do
      @course.root_account.enable_feature!(:student_planner)
    end

    before :each do
      course_topic
    end

    it 'js_env STUDENT_PLANNER_ENABLED is true for teachers' do
      user_session(@teacher)
      get :edit, course_id: @course.id, id: @topic.id
      expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be true
    end

    it 'js_env STUDENT_PLANNER_ENABLED is false for students' do
      user_session(@student)
      get :edit, course_id: @course.id, id: @topic.id
      expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be false
    end

    it 'should create a topic with a todo date' do
      user_session(@teacher)
      todo_date = 1.day.from_now.in_time_zone('America/New_York')
      post 'create', course_id: @course.id, todo_date: todo_date, format: 'json', title: 'Discussion 1'
      expect(JSON.parse(response.body)['todo_date']).to eq todo_date.in_time_zone('UTC').iso8601
    end

    it 'should update a topic with a todo date' do
      user_session(@teacher)
      todo_date = 1.day.from_now.in_time_zone('America/New_York')
      put 'update', course_id: @course.id, topic_id: @topic.id, todo_date: todo_date, format: 'json'
      expect(@topic.reload.todo_date).to eq todo_date
    end

    it 'should remove a todo date from a topic' do
      user_session(@teacher)
      @topic.update_attributes(todo_date: 1.day.from_now.in_time_zone('America/New_York'))
      put 'update', course_id: @course.id, topic_id: @topic.id, todo_date: nil, format: 'json'
      expect(@topic.reload.todo_date).to be nil
    end

    it 'should not allow a student to update the to-do date' do
      user_session(@student)
      put 'update', course_id: @course.id, topic_id: @topic.id, todo_date: 1.day.from_now, format: 'json'
      expect(@topic.reload.todo_date).to eq nil
    end

    it 'should not allow a todo date on a graded topic' do
      user_session(@teacher)
      assign = @course.assignments.create!(title: 'Graded Topic 1', submission_types: 'discussion_topic')
      topic = assign.discussion_topic
      put 'update', course_id: @course.id, topic_id: topic.id, todo_date: 1.day.from_now, format: 'json'
      expect(response.code).to eq '400'
    end

    it 'should not allow changing a topic to graded and adding a todo date' do
      user_session(@teacher)
      put 'update', course_id: @course.id, topic_id: @topic.id, format: 'json', todo_date: 1.day.from_now,
        assignment: {submission_types: ['discussion_topic'], name: 'Graded Topic 1'}
      expect(response.code).to eq '400'
    end

    it 'should allow a todo date when changing a topic from graded to ungraded' do
      user_session(@teacher)
      todo_date = 1.day.from_now
      assign = @course.assignments.create!(title: 'Graded Topic 1', submission_types: 'discussion_topic')
      topic = assign.discussion_topic
      put 'update', course_id: @course.id, topic_id: topic.id, todo_date: todo_date, format: 'json',
        assignment: {set_assignment: false, name: 'Graded Topic 1'}
      expect(response.code).to eq '200'
      expect(topic.reload.assignment).to be nil
      expect(topic.todo_date).to eq todo_date
    end

    it 'should remove an existing todo date when changing a topic from ungraded to graded' do
      user_session(@teacher)
      @topic.update_attributes(todo_date: 1.day.from_now)
      put 'update', course_id: @course.id, topic_id: @topic.id, format: 'json',
        assignment: {submission_types: ['discussion_topic'], name: 'Graded Topic 1'}
      expect(response.code).to eq '200'
      expect(@topic.reload.assignment).to be_truthy
      expect(@topic.todo_date).to be nil
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:once) do
      course_topic
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @course.feed_code + 'x'
      expect(assigns[:problem]).to eql("The verification code is invalid.")
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @course.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.links.first.rel).to match(/self/)
      expect(feed.links.first.href).to match(/http:\/\//)
    end

    it "should not include entries in an anonymous feed" do
      get 'public_feed', :format => 'atom', :feed_code => @course.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries).to be_empty
    end

    it "should include an author for each entry with an enrollment feed" do
      get 'public_feed', :format => 'atom', :feed_code => @course.teacher_enrollments.first.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all?{|e| e.authors.present?}).to be_truthy
    end
  end

  describe 'POST create:' do
    before(:once) do
      Setting.set('enable_page_views', 'db')
    end
    before(:each) do
      controller.stubs(:form_authenticity_token => 'abc', :form_authenticity_param => 'abc')
    end

    def topic_params(course, opts={})
      {
        :course_id => course.id,
        :title => 'Topic Title',
        :is_announcement => false,
        :discussion_type => 'side_comment',
        :require_initial_post => true,
        :podcast_has_student_posts => false,
        :delayed_post_at => '',
        :lock_at => '',
        :message => 'Message',
        :delay_posting => false,
        :threaded => false
      }.merge(opts)
    end

    def assignment_params(course, opts={})
      course.require_assignment_group
      {
        assignment: {
          points_possible: 1,
          grading_type: 'points',
          assignment_group_id: @course.assignment_groups.first.id,
        }.merge(opts)
      }
    end

    describe 'the new topic' do
      let(:topic) { assigns[:topic] }
      before(:each) do
        user_session(@student)
        post 'create', { :format => :json }.merge(topic_params(@course))
      end

      specify { expect(topic).to be_a DiscussionTopic }
      specify { expect(topic.user).to eq @user }
      specify { expect(topic.delayed_post_at).to be_nil }
      specify { expect(topic.lock_at).to be_nil }
      specify { expect(topic.workflow_state).to eq 'active' }
      specify { expect(topic.id).not_to be_nil }
      specify { expect(topic.title).to eq 'Topic Title' }
      specify { expect(topic.is_announcement).to be_falsey }
      specify { expect(topic.discussion_type).to eq 'side_comment' }
      specify { expect(topic.message).to eq 'Message' }
      specify { expect(topic.threaded).to be_falsey }
    end

    it 'logs an asset access record for the discussion topic' do
      user_session(@student)
      post 'create', { :format => :json }.merge(topic_params(@course))
      accessed_asset = assigns[:accessed_asset]
      expect(accessed_asset[:category]).to eq 'topics'
      expect(accessed_asset[:level]).to eq 'participate'
    end

    it 'registers a page view' do
      user_session(@student)
      post 'create', { :format => :json }.merge(topic_params(@course))
      page_view = assigns[:page_view]
      expect(page_view).not_to be_nil
      expect(page_view.http_method).to eq 'post'
      expect(page_view.url).to match %r{^http://test\.host/api/v1/courses/\d+/discussion_topics}
      expect(page_view.participated).to be_truthy
    end

    it 'does not dispatch assignment created notification for unpublished graded topics' do
      notification = Notification.create(:name => "Assignment Created")
      obj_params = topic_params(@course).merge(assignment_params(@course))
      user_session(@teacher)
      post 'create', { :format => :json }.merge(obj_params)
      json = JSON.parse response.body
      topic = DiscussionTopic.find(json['id'])
      expect(topic).to be_unpublished
      expect(topic.assignment).to be_unpublished
      expect(@student.recent_stream_items.map {|item| item.data['notification_id']}).not_to include notification.id
    end

    it 'does not dispatch new topic notification when hidden by selective release' do
      notification = Notification.create(name: 'New Discussion Topic', category: 'TestImmediately')
      @student.communication_channels.create!(path: 'student@example.com') {|cc| cc.workflow_state = 'active'}
      new_section = @course.course_sections.create!
      obj_params = topic_params(@course, published: true).merge(assignment_params(@course, only_visible_to_overrides: true, assignment_overrides: [{course_section_id: new_section.id}]))
      user_session(@teacher)
      post 'create', { :format => :json }.merge(obj_params)
      json = JSON.parse response.body
      topic = DiscussionTopic.find(json['id'])
      expect(topic).to be_published
      expect(topic.assignment).to be_published
      expect(@student.email_channel.messages).to be_empty
      expect(@student.recent_stream_items.map {|item| item.data}).not_to include topic
    end

    it 'does dispatch new topic notification when not hidden' do
      notification = Notification.create(name: 'New Discussion Topic', category: 'TestImmediately')
      @student.communication_channels.create!(path: 'student@example.com') {|cc| cc.workflow_state = 'active'}
      obj_params = topic_params(@course, published: true)
      user_session(@teacher)
      post 'create', { :format => :json }.merge(obj_params)
      json = JSON.parse response.body
      topic = DiscussionTopic.find(json['id'])
      expect(topic).to be_published
      expect(@student.email_channel.messages.map(&:context)).to include(topic)
    end

    it 'does dispatch new topic notification when published' do
      notification = Notification.create(name: 'New Discussion Topic', category: 'TestImmediately')
      @student.communication_channels.create!(path: 'student@example.com') {|cc| cc.workflow_state = 'active'}
      obj_params = topic_params(@course, published: false)
      user_session(@teacher)
      post 'create', { :format => :json }.merge(obj_params)

      json = JSON.parse response.body
      topic = DiscussionTopic.find(json['id'])
      expect(@student.email_channel.messages).to be_empty

      put 'update', course_id: @course.id, topic_id: topic.id, title: 'Updated Topic', format: 'json', published: true
      expect(@student.email_channel.messages.map(&:context)).to include(topic)
    end

    it 'dispatches an assignment stream item with the correct title' do
      notification = Notification.create(:name => "Assignment Created")
      obj_params = topic_params(@course).
        merge(assignment_params(@course)).
        merge({published: true})
      user_session(@teacher)
      post 'create', { :format => :json }.merge(obj_params)
      si = @student.recent_stream_items.detect do |item|
        item.data['notification_id'] == notification.id
      end
      expect(si.data['subject']).to eq "Assignment Created - #{obj_params[:title]}, #{@course.name}"
    end

    it 'does not allow for anonymous peer review assignment' do
      obj_params = topic_params(@course).merge(assignment_params(@course))
      obj_params[:assignment][:anonymous_peer_reviews] = true
      user_session(@teacher)
      post 'create', { :format => :json }.merge(obj_params)
      json = JSON.parse response.body
      expect(json['assignment']['anonymous_peer_reviews']).to be_falsey
    end
  end

  describe "PUT: update" do
    before(:once) do
      @topic = DiscussionTopic.create!(context: @course, title: 'Test Topic',
        delayed_post_at: '2013-01-01T00:00:00UTC', lock_at: '2013-01-02T00:00:00UTC')
    end
    before(:each) do
      user_session(@teacher)
    end

    it "should not clear lock_at if locked is not changed" do
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          locked: false)
      expect(@topic.reload).not_to be_locked
      expect(@topic.lock_at).not_to be_nil
    end

    it "should not change the editor if only pinned was changed" do
      put('update', course_id: @course.id, topic_id: @topic.id,
        format: 'json', pinned: '1')
      @topic.reload
      expect(@topic.pinned).to be_truthy
      expect(@topic.editor).to_not eq @teacher
    end

    it "should not clear delayed_post_at if published is not changed" do
      @topic.workflow_state = 'post_delayed'
      @topic.save!
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          published: false)
      expect(@topic.reload).not_to be_published
      expect(@topic.delayed_post_at).not_to be_nil
    end

    it "should unlock discussions with a lock_at attribute if lock state changes" do
      @topic.lock!
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          locked: false)

      expect(@topic.reload).not_to be_locked
      expect(@topic.lock_at).to be_nil
    end

    it "should still update a topic if it is a group discussion (that has submission replies)" do
      user_session(@teacher)

      student_in_course
      group_category = @course.group_categories.create(:name => 'category')
      group = @course.groups.create!(:group_category => group_category)
      group.add_user(@student)

      course_topic(user: @teacher, with_assignment: true)
      @topic.group_category = group_category
      @topic.save!
      @topic.publish!

      subtopic = @topic.child_topic_for(@student)
      subtopic.discussion_entries.create!(:message => "student message for grading", :user => @student)
      subtopic.ensure_submission(@student)
      subtopic.reply_from(:user => @student, :text => 'hai')

      expect(subtopic.can_unpublish?).to eq false

      put(:update, group_id: group.id, topic_id: subtopic.id,
          title: 'Updated Topic', format: 'json', locked: true)

      expect(response).to be_success
    end

    it "should set workflow to post_delayed when delayed_post_at and lock_at are in the future" do
      put(:update, course_id: @course.id, topic_id: @topic.id,
          title: 'Updated topic', format: 'json', delayed_post_at: Time.zone.now + 5.days)
      expect(@topic.reload).to be_post_delayed
    end

    it "should not clear lock_at if lock state hasn't changed" do
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json', lock_at: @topic.lock_at,
          locked: true)
      expect(@topic.reload).to be_locked
      expect(@topic.lock_at).not_to be_nil
    end

    it "should set draft state on discussions with delayed_post_at" do
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          published: false)

      expect(@topic.reload).not_to be_published
    end

    it "should delete attachments" do
      attachment = @topic.attachment = attachment_model(context: @course)
      @topic.lock_at = Time.now + 1.week
      @topic.unlock_at = Time.now - 1.week
      @topic.save!
      @topic.unlock!
      put('update', course_id: @course.id, topic_id: @topic.id,
          format: 'json', remove_attachment: '1')
      expect(response).to be_success

      expect(@topic.reload.attachment).to be_nil
      expect(attachment.reload).to be_deleted
    end
  end

  describe "POST 'reorder'" do
    it "should reorder pinned topics" do
      user_session(@teacher)

      # add noise
      @course.announcements.create!(message: 'asdf')
      course_topic

      topics = 3.times.map { course_topic(pinned: true) }
      expect(topics.map(&:position)).to eq [1, 2, 3]
      t1, t2, _ = topics
      post 'reorder', :course_id => @course.id, :order => "#{t2.id},#{t1.id}", :format => 'json'
      expect(response).to be_success
      topics.each &:reload
      expect(topics.map(&:position)).to eq [2, 1, 3]
    end
  end
end
