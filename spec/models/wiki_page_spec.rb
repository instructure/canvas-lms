# coding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe WikiPage do
  it "should send page updated notifications" do
    course_with_teacher(:active_all => true)
    n = Notification.create(:name => "Updated Wiki Page", :category => "TestImmediately")
    NotificationPolicy.create(:notification => n, :communication_channel => @user.communication_channel, :frequency => "immediately")
    p = @course.wiki.wiki_pages.create(:title => "some page")
    p.created_at = 3.days.ago
    p.notify_of_update = true
    p.save!
    expect(p.created_at).to be <= 3.days.ago
    p.update_attributes(:body => "Awgawg")
    expect(p.messages_sent).not_to be_nil
    expect(p.messages_sent).not_to be_empty
    expect(p.messages_sent["Updated Wiki Page"]).not_to be_nil
    expect(p.messages_sent["Updated Wiki Page"]).not_to be_empty
    expect(p.messages_sent["Updated Wiki Page"].map(&:user)).to be_include(@user)
  end

  it "should validate the title" do
    course_with_teacher(:active_all => true)
    expect(@course.wiki.wiki_pages.new(:title => "").valid?).not_to be_truthy
    expect(@course.wiki.wiki_pages.new(:title => "!!!").valid?).not_to be_truthy
    expect(@course.wiki.wiki_pages.new(:title => "a"*256).valid?).not_to be_truthy
    expect(@course.wiki.wiki_pages.new(:title => "asdf").valid?).to be_truthy
  end

  it "should set as front page" do
    course_with_teacher(:active_all => true)

    new_front_page = @course.wiki.wiki_pages.create!(:title => "asdf")
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

    new_front_page = @course.wiki.wiki_pages.create!(:title => "asdf")
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
    page = @course.wiki.wiki_pages.create!(:title => "æ vęrÿ ßpéçïâł なまえ ¼‽")
    expect(page.url).to eq 'ae-very-sspecial-namae-1-slash-4'
  end

  it "should make the title/url unique" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki.wiki_pages.create(:title => "Asdf")
    p2 = @course.wiki.wiki_pages.create(:title => "Asdf")
    expect(p2.title).to eql('Asdf-2')
    expect(p2.url).to eql('asdf-2')
  end

  it "should make the title unique and truncate to proper length" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki.wiki_pages.create!(:title => "a" * WikiPage::TITLE_LENGTH)
    p2 = @course.wiki.wiki_pages.create!(:title => p1.title)
    p3 = @course.wiki.wiki_pages.create!(:title => p1.title)
    p4 = @course.wiki.wiki_pages.create!(:title => "a" * (WikiPage::TITLE_LENGTH - 2) + "-2")
    expect(p2.title.length).to eq WikiPage::TITLE_LENGTH
    expect(p2.title.end_with?('-2')).to be_truthy
    expect(p3.title.length).to eq WikiPage::TITLE_LENGTH
    expect(p3.title.end_with?('-3')).to be_truthy
    expect(p4.title.length).to eq WikiPage::TITLE_LENGTH
    expect(p4.title.end_with?('-4')).to be_truthy
  end

  it "should let you reuse the title/url of a deleted page" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki.wiki_pages.create(:title => "Asdf")
    p1.workflow_state = 'deleted'
    p1.save

    p2 = @course.wiki.wiki_pages.create(:title => "Asdf")
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

  it "should preserve course links when in a group belonging to the course" do
    other_course = Course.create!
    course_with_teacher
    group(:group_context => @course)
    page = @group.wiki.wiki_pages.create(:title => "poni3s")
    page.user = @teacher
    page.update_attribute(:body, %{<a href='/courses/#{@course.id}/files#oops'>click meh</a>
                                  <a href='/courses/#{other_course.id}/files#whoops'>click meh too</a>})

    page.reload
    expect(page.body).to include("/courses/#{@course.id}/files#oops")
    expect(page.body).to include("/groups/#{@group.id}/files#whoops")
  end

  context "unpublished" do
    before :once do
      teacher_in_course(:active_all => true)
      @page = @course.wiki.wiki_pages.create(:title => "some page")
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

    it "allows account admins with :manage_wiki rights to read" do
      account = @course.root_account
      role = custom_account_role('CustomAccountUser', :account => account)
      RoleOverride.manage_role_override(account, role, 'manage_wiki', :override => true)
      admin = account_admin_user(:account => account, :role => role, :active_all => true)
      expect(@page.can_read_page?(admin)).to eq true
    end
  end

  describe '#can_edit_page?' do
    it 'is true if the user has manage_wiki rights' do
      course_with_teacher(:active_all => true)
      page = @course.wiki.wiki_pages.create(:title => "some page", :editing_roles => 'teachers')
      page.workflow_state = 'unpublished'
      expect(page.can_edit_page?(@teacher)).to be_truthy
    end

    describe "without :manage_wiki rights" do
      before :once do
        course_with_teacher(:active_all => true)
        course_with_ta(:course => @course, :active_all => true)
        @course.account.role_overrides.create!(:role => teacher_role, :permission => 'manage_wiki', :enabled => false)
        @course.account.role_overrides.create!(:role => ta_role, :permission => 'manage_wiki', :enabled => false)
      end

      it 'does not grant teachers or TAs edit rights when editing roles are "Only teachers"' do
        page = @course.wiki.wiki_pages.create(:title => "some page", :editing_roles => 'teachers')
        page.workflow_state = 'unpublished'
        expect(page.can_edit_page?(@teacher)).to be_falsey
        expect(page.can_edit_page?(@ta)).to be_falsey
      end

      it 'grants teachers and TAs edit rights when editing roles are "Teachers and students"' do
        page = @course.wiki.wiki_pages.create(:title => "some page", :editing_roles => 'teachers,students')
        page.workflow_state = 'unpublished'
        expect(page.can_edit_page?(@teacher)).to be_truthy
        expect(page.can_edit_page?(@ta)).to be_truthy
      end
    end

    it 'is true for students who are in the course' do
      course_with_student(:active_all => true)
      page = @course.wiki.wiki_pages.create(:title => "some page", :editing_roles => 'students')
      student = @course.students.first
      expect(page.can_edit_page?(student)).to be_truthy
    end

    it 'is true for users who are not in the course' do
      course(:active_all => true)
      page = @course.wiki.wiki_pages.create(:title => "some page", :editing_roles => 'public')
      user(:active_all => true)
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
    end

    context 'on a group' do
      before do
        group_with_user_logged_in
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
      course :active_all => true
    end

    context 'admins' do
      before :once do
        account_admin_user
        @page = @course.wiki.wiki_pages.build(:title => 'Some page')
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
        @page = @course.wiki.wiki_pages.build(:title => 'Some page')
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
        @page = @course.wiki.wiki_pages.build(:title => 'Some page')
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

  describe "restore" do
    it "should restore to unpublished state" do
      course
      @page = @course.wiki.wiki_pages.create! title: 'dot dot dot'
      @page.update_attribute(:workflow_state, 'deleted')
      @page.restore
      expect(@page.reload).to be_unpublished
    end
  end

  describe "context_module_action" do
    it "should process all content tags" do
      course_with_student_logged_in active_all: true
      page = @course.wiki.wiki_pages.create! title: 'teh page'
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
      course_with_student_logged_in active_all: true
      pageB = @course.wiki.wiki_pages.create! title: 'B'
      pageC = @course.wiki.wiki_pages.create! title: 'C'
      mod = @course.context_modules.create name: 'teh module'
      tagB = mod.add_item type: 'wiki_page', id: pageB.id
      tagC = mod.add_item type: 'wiki_page', id: pageC.id
      mod.completion_requirements = { tagB.id => { type: 'must_view' } }
      mod.require_sequential_progress = true
      mod.save
      expect(pageC.reload).to be_locked_for @student
    end
  end
end
