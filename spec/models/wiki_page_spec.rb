# frozen_string_literal: true

# coding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe WikiPage do
  it "should send page updated notifications" do
    course_with_teacher(:active_all => true)
    n = Notification.create(:name => "Updated Wiki Page", :category => "TestImmediately")
    NotificationPolicy.create(:notification => n, :communication_channel => @user.communication_channel, :frequency => "immediately")
    p = @course.wiki_pages.create(:title => "some page")
    p.created_at = 3.days.ago
    p.notify_of_update = true
    p.save!
    expect(p.created_at).to be <= 3.days.ago
    p.update(:body => "Awgawg")
    expect(p.messages_sent).not_to be_nil
    expect(p.messages_sent).not_to be_empty
    expect(p.messages_sent["Updated Wiki Page"]).not_to be_nil
    expect(p.messages_sent["Updated Wiki Page"]).not_to be_empty
    expect(p.messages_sent["Updated Wiki Page"].map(&:user)).to be_include(@user)
  end

  it "should send page updated notifications to students if active" do
    course_with_student(:active_all => true)
    n = Notification.create(:name => "Updated Wiki Page", :category => "TestImmediately")
    NotificationPolicy.create(:notification => n, :communication_channel => @user.communication_channel, :frequency => "immediately")
    p = @course.wiki_pages.create(:title => "some page")
    p.created_at = 3.days.ago
    p.notify_of_update = true
    p.save!
    p.update(:body => "Awgawg")
    expect(p.messages_sent["Updated Wiki Page"].map(&:user)).to be_include(@student)
  end

  it "should not send page updated notifications to students if not active" do
    course_with_student(:active_all => true)
    n = Notification.create(:name => "Updated Wiki Page", :category => "TestImmediately")
    NotificationPolicy.create(:notification => n, :communication_channel => @user.communication_channel, :frequency => "immediately")
    @course.update(:start_at => 2.days.from_now, :restrict_enrollments_to_course_dates => true)
    p = @course.wiki_pages.create(:title => "some page")
    p.created_at = 3.days.ago
    p.notify_of_update = true
    p.save!
    p.update(:body => "Awgawg")
    expect(p.messages_sent["Updated Wiki Page"].map(&:user)).to_not be_include(@student)
  end

  describe "duplicate manages titles properly" do
    it "works on assignment" do
      course_with_teacher(:active_all => true)
      old_wiki = wiki_page_assignment_model({ :title => "Wiki Assignment" }).wiki_page
      old_wiki.workflow_state = "published"
      old_wiki.save!
      new_wiki = old_wiki.duplicate
      expect(new_wiki.new_record?).to be true
      expect(new_wiki.assignment).not_to be_nil
      expect(new_wiki.assignment.new_record?).to be true
      expect(new_wiki.title).to eq "Wiki Assignment Copy"
      expect(new_wiki.assignment.title).to eq "Wiki Assignment Copy"
      expect(new_wiki.workflow_state).to eq "unpublished"
      new_wiki.save!
      new_wiki2 = old_wiki.duplicate
      expect(new_wiki2.title).to eq "Wiki Assignment Copy 2"
      expect(new_wiki2.assignment.title).to eq "Wiki Assignment Copy 2"
      new_wiki2.save!
      new_wiki3 = new_wiki.duplicate
      expect(new_wiki3.title).to eq "Wiki Assignment Copy 3"
      expect(new_wiki3.assignment.title).to eq "Wiki Assignment Copy 3"
      new_wiki4 = new_wiki.duplicate({ :copy_title => "Stupid title" })
      expect(new_wiki4.title).to eq "Stupid title"
      expect(new_wiki4.assignment.title).to eq "Stupid title"
    end

    it "works on non-assignment" do
      course_with_teacher(:active_all => true)
      old_wiki = wiki_page_model({ :title => "Wiki Page" })
      old_wiki.workflow_state = "published"
      old_wiki.save!
      new_wiki = old_wiki.duplicate
      expect(new_wiki.new_record?).to be true
      expect(new_wiki.assignment).to be_nil
      expect(new_wiki.title).to eq "Wiki Page Copy"
      expect(new_wiki.workflow_state).to eq "unpublished"
    end
  end

  it "should validate the title" do
    course_with_teacher(:active_all => true)
    expect(@course.wiki_pages.new(:title => "").valid?).not_to be_truthy
    expect(@course.wiki_pages.new(:title => "!!!").valid?).not_to be_truthy
    expect(@course.wiki_pages.new(:title => "a"*256).valid?).not_to be_truthy
    expect(@course.wiki_pages.new(:title => "asdf").valid?).to be_truthy
  end

  it "should set as front page" do
    course_with_teacher(:active_all => true)

    new_front_page = @course.wiki_pages.create!(:title => "asdf")
    expect(new_front_page.set_as_front_page!).to eq true

    @course.wiki.reload
    expect(@course.wiki.front_page).to eq new_front_page
  end

  it "should validate that the front page is always visible" do
    course_with_teacher(:active_all => true)
    @course.wiki.set_front_page_url!('front-page')
    front_page = @course.wiki.front_page
    front_page.save!
    front_page.workflow_state = 'unpublished'
    expect(front_page.valid?).not_to be_truthy

    new_front_page = @course.wiki_pages.create!(:title => "asdf")
    new_front_page.set_as_front_page!

    front_page.reload
    front_page.workflow_state = 'unpublished'
    expect(front_page.valid?).to be_truthy

    new_front_page.reload
    new_front_page.workflow_state = 'unpublished'
    expect(new_front_page.valid?).not_to be_truthy
  end

  it "shouldn't allow the front page to be unpublished" do
    course_with_teacher(active_all: true)
    @course.wiki.set_front_page_url!('front-page')

    front_page = @course.wiki.front_page
    expect(front_page).not_to be_can_unpublish
    # the data model doesn't actually disallow this (yet)
    # front_page.workflow_state = 'unpublished'
    # front_page.should_not be_valid
  end

  it "should transliterate unicode characters in the title for the url" do
    course_with_teacher(:active_all => true)
    page = @course.wiki_pages.create!(:title => "æ vęrÿ ßpéçïâł なまえ ¼‽")
    expect(page.url).to eq 'ae-very-sspecial-namae-1-slash-4'
  end

  it "should make the title/url unique" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki_pages.create(:title => "Asdf")
    p2 = @course.wiki_pages.create(:title => "Asdf")
    expect(p2.title).to eql('Asdf-2')
    expect(p2.url).to eql('asdf-2')
  end

  it "should make the title unique and truncate to proper length" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki_pages.create!(:title => "a" * WikiPage::TITLE_LENGTH)
    p2 = @course.wiki_pages.create!(:title => p1.title)
    p3 = @course.wiki_pages.create!(:title => p1.title)
    p4 = @course.wiki_pages.create!(:title => "a" * (WikiPage::TITLE_LENGTH - 2) + "-2")
    expect(p2.title.length).to eq WikiPage::TITLE_LENGTH
    expect(p2.title.end_with?('-2')).to be_truthy
    expect(p3.title.length).to eq WikiPage::TITLE_LENGTH
    expect(p3.title.end_with?('-3')).to be_truthy
    expect(p4.title.length).to eq WikiPage::TITLE_LENGTH
    expect(p4.title.end_with?('-4')).to be_truthy
  end

  it "should let you reuse the title/url of a deleted page" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki_pages.create(:title => "Asdf")
    p1.workflow_state = 'deleted'
    p1.save

    p2 = @course.wiki_pages.create(:title => "Asdf")
    p2.reload
    expect(p2.title).to eql('Asdf')
    expect(p2.url).to eql('asdf')

    # so long as it's deleted, we don't care about uniqueness of the title/url
    expect(p1.save).to be_truthy
    expect(p1.title).to eql('Asdf')
    expect(p1.url).to eql('asdf')

    p1.workflow_state = 'active'
    expect(p1.save).to be_truthy
    expect(p1.title).to eql('Asdf-2')
    expect(p1.url).to eql('asdf-2')
  end

  it "sets root_account_id on create" do
    course_with_teacher(:active_all => true)
    wp = @course.wiki_pages.create!(:title => "Asdf")
    expect(wp.root_account_id).to eql @course.root_account_id
  end

  context "unpublished" do
    before :once do
      teacher_in_course(:active_all => true)
      @page = @course.wiki_pages.create(:title => "some page")
      @page.workflow_state = :unpublished
      @page.save!
    end

    it "should not allow students to read" do
      student_in_course(:course => @course, :active_all => true)
      expect(@page.can_read_page?(@student)).to eq false
    end

    it "should allow teachers to read" do
      expect(@page.can_read_page?(@teacher)).to eq true
    end

    context 'allows account admins to read' do
      [:manage_wiki_create, :manage_wiki_update, :manage_wiki_delete].each do |perm|
        it "with #{perm} rights" do
          account = @course.root_account
          role = custom_account_role('CustomAccountUser', :account => account)
          RoleOverride.manage_role_override(account, role, perm, :override => true)
          admin = account_admin_user(:account => account, :role => role, :active_all => true)
          expect(@page.can_read_page?(admin)).to eq true
        end
      end
    end
  end

  describe '#can_edit_page?' do
    it 'is true if the user has manage_wiki_update rights' do
      course_with_teacher(:active_all => true)
      page = @course.wiki_pages.create(:title => "some page", :editing_roles => 'teachers')
      page.workflow_state = 'unpublished'
      expect(page.can_edit_page?(@teacher)).to be_truthy
    end

    describe "without :manage_wiki_update rights" do
      before :once do
        course_with_teacher(:active_all => true)
        course_with_ta(:course => @course, :active_all => true)
        @course.account.role_overrides.create!(:role => teacher_role, :permission => 'manage_wiki_update', :enabled => false)
        @course.account.role_overrides.create!(:role => ta_role, :permission => 'manage_wiki_update', :enabled => false)
      end

      it 'does not grant teachers or TAs edit rights when editing roles are "Only teachers"' do
        page = @course.wiki_pages.create(:title => "some page", :editing_roles => 'teachers')
        page.workflow_state = 'unpublished'
        expect(page.can_edit_page?(@teacher)).to be_falsey
        expect(page.can_edit_page?(@ta)).to be_falsey
      end

      it 'grants teachers and TAs edit rights when editing roles are "Teachers and students"' do
        page = @course.wiki_pages.create(:title => "some page", :editing_roles => 'teachers,students')
        page.workflow_state = 'unpublished'
        expect(page.can_edit_page?(@teacher)).to be_truthy
        expect(page.can_edit_page?(@ta)).to be_truthy
      end
    end

    it 'is true for students who are in the course' do
      course_with_student(:active_all => true)
      page = @course.wiki_pages.create(:title => "some page", :editing_roles => 'students')
      student = @course.students.first
      expect(page.can_edit_page?(student)).to be_truthy
    end

    it 'is not true for users who are not in the course (if it is not public)' do
      course_factory(active_all: true)
      page = @course.wiki_pages.create(:title => "some page", :editing_roles => 'public')
      user_factory(active_all: true)
      expect(page.can_edit_page?(@user)).to be_falsey
    end

    it 'is true for users who are not in the course (if it is public)' do
      course_factory(active_all: true)
      @course.is_public = true
      @course.save!
      page = @course.wiki_pages.create(:title => "some page", :editing_roles => 'public')
      user_factory(active_all: true)
      expect(page.can_edit_page?(@user)).to be_truthy
    end
  end

  context 'initialize_wiki_page' do
    context 'on a course' do
      before :once do
        course_with_teacher
      end

      before :each do
        user_session(@user)
      end

      it 'should set the front page body' do
        @course.wiki.set_front_page_url!('front-page')
        front_page = @course.wiki.front_page
        expect(front_page.body).to be_nil
        front_page.initialize_wiki_page(@teacher)
        expect(front_page.body).not_to be_empty
      end

      it 'should publish the front page' do
        @course.wiki.set_front_page_url!('front-page')
        front_page = @course.wiki.front_page
        front_page.initialize_wiki_page(@teacher)
        expect(front_page).to be_published
      end

      it 'should not change the URL in a wiki page link' do
        allow_any_instance_of(UserContent::HtmlRewriter).to receive(:user_can_view_content?).and_return true
        course = course_factory()
        some_other_course = course_factory()

        file_url = "/courses/#{some_other_course.id}/files/1"
        link_string = "<a href='#{file_url}'>link</a>"
        page = course.wiki_pages.create!(title: 'New', body: "<p>#{link_string}</p>", user: @user)
        expect(page.body).to include(file_url)
      end
    end

    context 'on a group' do
      before do
        group_with_user
      end

      it 'should set the front page body' do
        @group.wiki.set_front_page_url!('front-page')
        front_page = @group.wiki.front_page
        expect(front_page.body).to be_nil
        front_page.initialize_wiki_page(@user)
        expect(front_page.body).not_to be_empty
      end
    end
  end

  context 'set policy' do
    before :once do
      course_factory :active_all => true
    end

    context 'admins' do
      before :once do
        account_admin_user
        @page = @course.wiki_pages.create!(:title => 'Some page')
        @page.workflow_state = 'active'
      end

      it 'should be given read rights' do
        expect(@page.grants_right?(@admin, :read)).to be_truthy
      end

      it 'should be given create rights' do
        expect(@page.grants_right?(@admin, :create)).to be_truthy
      end

      it 'should be given update rights' do
        expect(@page.grants_right?(@admin, :update)).to be_truthy
      end

      it 'should be given delete rights' do
        expect(@page.grants_right?(@admin, :delete)).to be_truthy
      end

      it 'should be given delete rights for unpublished pages' do
        @page.workflow_state = 'unpublished'
        expect(@page.grants_right?(@admin, :delete)).to be_truthy
      end
    end

    context 'teachers' do
      before :once do
        course_with_teacher :course => @course, :active_all => true
        @page = @course.wiki_pages.create!(:title => 'Some page')
        @page.workflow_state = 'active'
      end

      it 'should be given read rights' do
        expect(@page.grants_right?(@teacher, :read)).to be_truthy
      end

      it 'should be given create rights' do
        expect(@page.grants_right?(@teacher, :create)).to be_truthy
      end

      it 'should be given update rights' do
        expect(@page.grants_right?(@teacher, :update)).to be_truthy
      end

      it 'should be given delete rights' do
        expect(@page.grants_right?(@teacher, :delete)).to be_truthy
      end

      it 'should be given delete rights for unpublished pages' do
        @page.workflow_state = 'unpublished'
        expect(@page.grants_right?(@teacher, :delete)).to be_truthy
      end
    end

    context 'students' do
      before :once do
        course_with_student :course => @course, :active_all => true
        @page = @course.wiki_pages.create!(:title => 'Some page')
        @page.workflow_state = 'active'
      end

      it 'should be given read rights' do
        expect(@page.grants_right?(@user, :read)).to be_truthy
      end

      it 'should be given read rights, unless hidden from students' do
        @page.workflow_state = 'unpublished'
        expect(@page.grants_right?(@user, :read)).to be_falsey
      end

      it 'should be given read rights, unless unpublished' do
        @page.workflow_state = 'unpublished'
        expect(@page.grants_right?(@user, :read)).to be_falsey
      end

      it 'should not be given create rights' do
        expect(@page.grants_right?(@user, :create)).to be_falsey
      end

      it 'should not be given update rights' do
        expect(@page.grants_right?(@user, :update)).to be_falsey
      end

      it 'should not be given update_content rights' do
        expect(@page.grants_right?(@user, :update_content)).to be_falsey
      end

      it 'should not be given delete rights' do
        expect(@page.grants_right?(@user, :delete)).to be_falsey
      end

      context 'with editing roles' do
        before :each do
          @page.editing_roles = 'teachers,students'
        end

        it 'should be given update_content rights' do
          expect(@page.grants_right?(@user, :update_content)).to be_truthy
        end

        it 'should not be given create rights' do
          expect(@page.grants_right?(@user, :create)).to be_falsey
        end

        it 'should not be given update rights' do
          expect(@page.grants_right?(@user, :update)).to be_falsey
        end

        it 'should not be given delete rights' do
          expect(@page.grants_right?(@user, :delete)).to be_falsey
        end
      end

      context 'with course editing roles' do
        before :once do
          @page.context.default_wiki_editing_roles = 'teachers,students'
          @page.context.save!
          @page.reload
        end

        it 'should be given create rights' do
          expect(@page.grants_right?(@user, :create)).to be_truthy
        end

        it 'should be given update rights' do
          expect(@page.grants_right?(@user, :update)).to be_truthy
        end

        it 'should be given update_content rights' do
          expect(@page.grants_right?(@user, :update_content)).to be_truthy
        end

        it 'should not be given delete rights' do
          expect(@page.grants_right?(@user, :delete)).to be_falsey
        end
      end

      context 'with course editing roles for teacher only page' do
        before :each do
          @course.default_wiki_editing_roles = 'teachers,students'
          @page.editing_roles = 'teachers'
        end

        it 'should not be given create rights' do
          expect(@page.grants_right?(@user, :create)).to be_falsey
        end

        it 'should not be given update rights' do
          expect(@page.grants_right?(@user, :update)).to be_falsey
        end

        it 'should not be given update_content rights' do
          expect(@page.grants_right?(@user, :update_content)).to be_falsey
        end

        it 'should not be given delete rights' do
          expect(@page.grants_right?(@user, :delete)).to be_falsey
        end
      end

      context 'with course editing roles for unpublished pages' do
        before :each do
          @course.default_wiki_editing_roles = 'teachers,students'
          @page.workflow_state = 'unpublished'
        end

        it 'should not be given create rights' do
          expect(@page.grants_right?(@user, :create)).to be_falsey
        end

        it 'should not be given update rights' do
          expect(@page.grants_right?(@user, :update)).to be_falsey
        end

        it 'should not be given update_content rights' do
          expect(@page.grants_right?(@user, :update_content)).to be_falsey
        end

        it 'should not be given delete rights' do
          expect(@page.grants_right?(@user, :delete)).to be_falsey
        end
      end
    end
  end

  describe "destroy" do
    before (:once) { course_factory }

    it "should destroy its assignment if enabled" do
      @course.enable_feature!(:conditional_release)
      wiki_page_assignment_model course: @course
      @page.destroy
      expect(@page.reload).to be_deleted
      expect(@assignment.reload).to be_deleted
    end

    it "should not destroy its assignment" do
      wiki_page_assignment_model course: @course
      @page.destroy
      expect(@page.reload).to be_deleted
      expect(@assignment.reload).not_to be_deleted
    end

    it "should destroy its content tags" do
      @page = @course.wiki_pages.create! title: 'destroy me'
      @module = @course.context_modules.create!(:name => "module")
      tag = @module.add_item(type: 'WikiPage', title: 'kill meeee', id: @page.id)
      @page.destroy
      expect(@page.reload).to be_deleted
      expect(tag.reload).to be_deleted
    end
  end

  describe "restore" do
    before (:once) { course_factory }

    it "should restore to unpublished state" do
      @page = @course.wiki_pages.create! title: 'dot dot dot'
      @page.update_attribute(:workflow_state, 'deleted')
      @page.restore
      expect(@page.reload).to be_unpublished
    end

    it "should restore a linked assignment if enabled" do
      @course.enable_feature!(:conditional_release)
      wiki_page_assignment_model course: @course
      @page.workflow_state = 'deleted'
      @page.save!
      expect(@assignment.reload).to be_deleted
      @page.restore
      expect(@page.reload).to be_unpublished
      expect(@page.assignment).to be_unpublished
    end

    it "should not restore a linked assignment" do
      wiki_page_assignment_model course: @course
      @page.workflow_state = 'deleted'
      expect { @page.save! }.not_to change { @assignment.workflow_state }
      expect { @page.restore }.not_to change { @assignment.workflow_state }
    end

    it "should not restore its content tags" do
      @page = @course.wiki_pages.create! title: 'dot dot dot'
      @module = @course.context_modules.create!(:name => "module")
      tag = @module.add_item(type: 'WikiPage', title: 'dash dash dash', id: @page.id)
      @page.update_attribute(:workflow_state, 'deleted')
      @page.restore
      expect(@page.reload).to be_unpublished
      expect(tag.reload).to be_deleted
    end
  end

  describe "context_module_action" do
    it "should process all content tags" do
      course_with_student active_all: true
      page = @course.wiki_pages.create! title: 'teh page'
      mod1 = @course.context_modules.create name: 'module1'
      tag1 = mod1.add_item type: 'wiki_page', id: page.id
      mod1.completion_requirements = { tag1.id => { type: 'must_view' } }
      mod1.save
      mod2 = @course.context_modules.create name: 'module2'
      tag2 = mod2.add_item type: 'wiki_page', id: page.id
      mod2.completion_requirements = { tag2.id => { type: 'must_view' } }
      mod2.save
      page.context_module_action(@student, @course, :read)
      expect(mod1.evaluate_for(@student).requirements_met.detect { |rm| rm[:id] == tag1.id && rm[:type] == 'must_view' }).not_to be_nil
      expect(mod2.evaluate_for(@student).requirements_met.detect { |rm| rm[:id] == tag2.id && rm[:type] == 'must_view' }).not_to be_nil
    end
  end

  describe "locked_for?" do
    it "should lock by preceding item and sequential progress" do
      course_with_student active_all: true
      pageB = @course.wiki_pages.create! title: 'B'
      pageC = @course.wiki_pages.create! title: 'C'
      mod = @course.context_modules.create name: 'teh module'
      tagB = mod.add_item type: 'wiki_page', id: pageB.id
      tagC = mod.add_item type: 'wiki_page', id: pageC.id
      mod.completion_requirements = { tagB.id => { type: 'must_view' } }
      mod.require_sequential_progress = true
      mod.save
      expect(pageC.reload).to be_locked_for @student
    end

    it "includes a future unlock date" do
      course_with_student active_all: true
      page = @course.wiki_pages.create! title: 'page'
      mod = @course.context_modules.create name: 'teh module', unlock_at: 1.week.from_now
      mod.add_item type: 'wiki_page', id: page.id
      mod.workflow_state = 'unpublished'
      mod.save!
      expect(page.reload.locked_for?(@student)[:unlock_at]).to eq mod.unlock_at
    end

    it "doesn't reference an expired unlock-at date" do
      course_with_student active_all: true
      page = @course.wiki_pages.create! title: 'page'
      mod = @course.context_modules.create name: 'teh module', unlock_at: 1.week.ago
      mod.add_item type: 'wiki_page', id: page.id
      mod.workflow_state = 'unpublished'
      mod.save!
      expect(page.reload.locked_for?(@student)).not_to have_key :unlock_at
    end
  end

  describe 'revised_at' do
    before(:once) do
      Timecop.freeze(1.hour.ago) do
        course_factory
        @page = @course.wiki_pages.create! title: 'page'
        @old_timestamp = @page.revised_at
      end
    end

    it 'changes when the page title changes' do
      @page.title = 'changed'
      @page.save!
      expect(@page.reload.revised_at).to be > @old_timestamp
    end

    it 'changes when the content changes' do
      @page.body = 'changed'
      @page.save!
      expect(@page.reload.revised_at).to be > @old_timestamp
    end

    it "doesn't change when the page is touched" do
      @page.touch
      expect(@page.updated_at).to be > @old_timestamp
      expect(@page.reload.revised_at).to eq @old_timestamp
    end
  end

  describe "visible_to_students_in_course_with_da" do
    before :once do
      @course = course_factory(active_course: true)
      @page_unassigned = wiki_page_model(:title => "plain old page", :course => @course)
      @page_assigned = wiki_page_model(:title => "page with assignment", :course => @course)
      @student1, @student2 = create_users(2, return_type: :record)

      @assignment = @course.assignments.create!(:title => "page assignment", only_visible_to_overrides: true)
      @assignment.submission_types = 'wiki_page'
      @assignment.save!
      @page_assigned.assignment_id = @assignment.id
      @page_assigned.save!

      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student1)
      create_section_override_for_assignment(@assignment, {course_section: @section})

      @course.enroll_student(@student2, :enrollment_state => 'active')
      @course.reload
    end

    it "returns pages with no assignment" do
      expect(WikiPage.visible_to_students_in_course_with_da([@student2.id], [@course.id]))
        .to include @page_unassigned
    end

    it "does not return pages with assignment and no visibility" do
      expect(WikiPage.visible_to_students_in_course_with_da([@student2.id], [@course.id]))
        .not_to include @page_assigned
    end

    it "returns pages with assignment and student visibility" do
      expect(WikiPage.visible_to_students_in_course_with_da([@student1.id], [@course.id]))
        .to include @page_assigned, @page_unassigned
    end
  end

  describe ".reinterpret_version_yaml" do
    it "replaces the unescaped media comments" do
      bad_yaml = <<-YAML
---
id: 787500
wiki_id: 15160
title: \"\\U0001F4D8\\U0001F4D5Ss10.20 | Social Studies: Warm Up - Las Cruces, New Mexico\"
body: \"<p style=\\\"text-align: center;\\\"><a id=\"media_comment_m-5Ej8kqbPvbAhbBX7zWCEtynxijhqH27P\" class=\"instructure_inline_media_comment audio_comment\" data-media_comment_type=\"audio\" data-alt=\"\" href=\"/media_objects/m-5Ej8kqbPvbAhbBX7zWCEtynxijhqH27P\"/></p>\\r\
<p style=\\\"text-align: center;\\\"> </p>\\r\
<p
  style=\\\"text-align: center;\\\"><span style=\\\"font-size: 18pt;\\\">Geography is the
  study of Earth and its land, water, air and people. We are concentrating on learning
  about the physical features, climate and natural resources that affect an area and
  its people.</span></p>\\r\
  center;\\\"> </p>\"
user_id: 
created_at: !ruby/object:ActiveSupport::TimeWithZone
  utc: &1 2020-11-05 20:24:57.390301492 Z
  zone: &2 !ruby/object:ActiveSupport::TimeZone
    name: Etc/UTC
  time: *1
updated_at: !ruby/object:ActiveSupport::TimeWithZone
  utc: *1
  zone: *2
  time: *1
url: ss10-dot-20-|-social-studies-warm-up-las-cruces-new-mexico
protected_editing: false
revised_at: !ruby/object:ActiveSupport::TimeWithZone
  utc: &3 2020-11-05 20:24:57.386639804 Z
  zone: *2
  time: *3
context_id: 23167
context_type: Course
root_account_id: 1
YAML
      good_yaml = WikiPage.reinterpret_version_yaml(bad_yaml)
      expect(good_yaml).to include("style=\\\"text-align: center;\\\">")
      expect(good_yaml).to include("<a id=\\\"media_comment_m-5Ej8kqbPvbAhbBX7zWCEtynxijhqH27P\\\"")
    end

    it "isn't overly greedy in matching other anchor tags" do
      bad_yaml = <<-YAML
---
id: 19903
wiki_id: 513
title: Jason otitis media treatment
body: \"<ul>\\r\\n
                <li\n  class=\\\"distractors\\\"><a class=\\\"radio_link\\\" href=\\\"#\\\">Yes</a></li>\\r\\n
                <li class=\\\"distractors\\\"><a\n  class=\\\"radio_link answer\\\" href=\\\"#\\\">No</a></li>\\r\\n
              </ul>\\r\\n</div>\\r\\n
              <div class=\\\"col-md-4\\\">
                <img\n  src=\\\"/courses/348/files/102814/preview\\\" alt=\\\"Antibiotics\\\" width=\\\"100%\\\"\n  height=\\\"auto\\\" data-api-endpoint=\\\"https://dev.iheed.org/api/v1/courses/328/files/41094\\\"\n  data-api-returntype=\\\"File\\\">
              </div>\\r\\n
            </div>\\r\\n
            <div class=\\\"feedback\\\">\\r\\n
              <p>Jason\n  does not need antibiotics at this time. He is not systemically unwell, he has no\n  high-risk complications and there is no discharge from his ear.</p>\\r\\n
            </div>\\r\\n
            <div\n  class=\\\"feedback correct\\\">\\r\\n<p>Correct.</p>\\r\\n</div>\\r\\n
            <div class=\\\"feedback\n  incorrect\\\">\\r\\n<p>Incorrect.</p>\\r\\n</div>\\r\\n
          </div>\\r\\n
        </div>\\r\\n<div class=\\\"content-box\\\">\\r\\n<div\n  class=\\\"grid-row spacer center-xs\\\">\\r\\n
        <div class=\\\"col-md-4 text-left\\\">\\r\\n<p\n  class=\\\"text-info\\\">Listen to the audio to hear the advice you give Laura about\n  what to do next.</p>\\r\\n</div>\\r\\n<div class=\\\"col-md-4\\\">
        <a id=\"media_comment_m-52Qmsrg9rxySvtzA6e9VdzxrB9FHZBVx\" class=\"instructure_inline_media_comment audio_comment\" href=\"/media_objects/m-52Qmsrg9rxySvtzA6e9VdzxrB9FHZBVx\"/>\"
YAML
      good_yaml = WikiPage.reinterpret_version_yaml(bad_yaml)
      expect(good_yaml).to include("<a id=\\\"media_comment_m-52Qmsrg9rxySvtzA6e9VdzxrB9FHZBVx\\\"")
    end
  end
end
