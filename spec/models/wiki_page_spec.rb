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
    p.created_at.should <= 3.days.ago
    p.update_attributes(:body => "Awgawg")
    p.messages_sent.should_not be_nil
    p.messages_sent.should_not be_empty
    p.messages_sent["Updated Wiki Page"].should_not be_nil
    p.messages_sent["Updated Wiki Page"].should_not be_empty
    p.messages_sent["Updated Wiki Page"].map(&:user).should be_include(@user)
  end

  it "should validate the title" do
    course_with_teacher(:active_all => true)
    @course.wiki.wiki_pages.new(:title => "").valid?.should_not be_true
    @course.wiki.wiki_pages.new(:title => "!!!").valid?.should_not be_true
    @course.wiki.wiki_pages.new(:title => "a"*256).valid?.should_not be_true
    @course.wiki.wiki_pages.new(:title => "asdf").valid?.should be_true
  end

  it "should set as front page" do
    course_with_teacher(:active_all => true)

    new_front_page = @course.wiki.wiki_pages.create!(:title => "asdf")
    new_front_page.set_as_front_page!.should == true

    @course.wiki.reload
    @course.wiki.front_page.should == new_front_page
  end

  it "should validate that the front page is always visible" do
    course_with_teacher(:active_all => true)
    front_page = @course.wiki.front_page
    front_page.save!
    front_page.hide_from_students = true
    front_page.valid?.should_not be_true

    new_front_page = @course.wiki.wiki_pages.create!(:title => "asdf")
    new_front_page.set_as_front_page!

    front_page.reload
    front_page.hide_from_students = true
    front_page.valid?.should be_true

    new_front_page.reload
    new_front_page.hide_from_students = true
    new_front_page.valid?.should_not be_true
  end

  it "should transliterate unicode characters in the title for the url" do
    course_with_teacher(:active_all => true)
    page = @course.wiki.wiki_pages.create!(:title => "æ vęrÿ ßpéçïâł なまえ ¼‽")
    page.url.should == 'ae-very-sspecial-namae-1-slash-4'
  end

  it "should make the title/url unique" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki.wiki_pages.create(:title => "Asdf")
    p2 = @course.wiki.wiki_pages.create(:title => "Asdf")
    p2.title.should eql('Asdf-2')
    p2.url.should eql('asdf-2')
  end

  it "should make the title unique and truncate to proper length" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki.wiki_pages.create!(:title => "a" * WikiPage::TITLE_LENGTH)
    p2 = @course.wiki.wiki_pages.create!(:title => p1.title)
    p3 = @course.wiki.wiki_pages.create!(:title => p1.title)
    p4 = @course.wiki.wiki_pages.create!(:title => "a" * (WikiPage::TITLE_LENGTH - 2) + "-2")
    p2.title.length.should == WikiPage::TITLE_LENGTH
    p2.title.end_with?('-2').should be_true
    p3.title.length.should == WikiPage::TITLE_LENGTH
    p3.title.end_with?('-3').should be_true
    p4.title.length.should == WikiPage::TITLE_LENGTH
    p4.title.end_with?('-4').should be_true
  end

  it "should let you reuse the title/url of a deleted page" do
    course_with_teacher(:active_all => true)
    p1 = @course.wiki.wiki_pages.create(:title => "Asdf")
    p1.workflow_state = 'deleted'
    p1.save

    p2 = @course.wiki.wiki_pages.create(:title => "Asdf")
    p2.reload
    p2.title.should eql('Asdf')
    p2.url.should eql('asdf')

    # so long as it's deleted, we don't care about uniqueness of the title/url
    p1.save.should be_true
    p1.title.should eql('Asdf')
    p1.url.should eql('asdf')

    p1.workflow_state = 'active'
    p1.save.should be_true
    p1.title.should eql('Asdf-2')
    p1.url.should eql('asdf-2')
  end

  context "unpublished" do
    before do
      teacher_in_course(:active_all => true)
      @page = @course.wiki.wiki_pages.create(:title => "some page")
      @page.workflow_state = :unpublished
      @page.save!
    end

    it "should not allow students to read" do
      student_in_course(:course => @course, :active_all => true)
      @page.can_read_page?(@student).should == false
    end

    it "should allow teachers to read" do
      @page.can_read_page?(@teacher).should == true
    end
  end


  context "clone_for" do
    it "should clone for another context" do
      course_with_teacher(:active_all => true)
      p = @course.wiki.wiki_pages.create(:title => "some page")
      p.save!
      course
      new_p = p.clone_for(@course)
      new_p.title.should eql(p.title)
      new_p.should_not eql(p)
      new_p.wiki.should_not eql(p.wiki)
    end
  end

  describe '#editing_role?' do
    it 'is true if the editing roles include teachers and the user is a teacher' do
      course_with_teacher(:active_all => true)
      page = @course.wiki.wiki_pages.create(:title => "some page", :editing_roles => 'teachers', :hide_from_students => true)
      teacher = @course.teachers.first
      page.editing_role?(teacher).should be_true
    end

    it 'is true for students who are in the course' do
      course_with_student(:active_all => true)
      page = @course.wiki.wiki_pages.create(:title => "some page", :editing_roles => 'students', :hide_from_students => false)
      student = @course.students.first
      page.editing_role?(student).should be_true
    end
  end

  context 'set policy' do
    before :each do
      course :active_all => true
    end

    context 'admins' do
      before :each do
        account_admin_user
        @page = @course.wiki.wiki_pages.create(:title => 'Some page')
        @page.workflow_state = 'active'
      end

      it 'should be given read rights' do
        @page.grants_right?(@admin, :read).should be_true
      end

      it 'should be given create rights' do
        @page.grants_right?(@admin, :create).should be_true
      end

      it 'should be given update rights' do
        @page.grants_right?(@admin, :update).should be_true
      end

      it 'should be given delete rights' do
        @page.grants_right?(@admin, :delete).should be_true
      end

      it 'should be given delete rights for unpublished pages' do
        @page.workflow_state = 'unpublished'
        @page.grants_right?(@admin, :delete).should be_true
      end
    end

    context 'teachers' do
      before :each do
        course_with_teacher :course => @course, :active_all => true
        @page = @course.wiki.wiki_pages.create(:title => 'Some page')
        @page.workflow_state = 'active'
      end

      it 'should be given read rights' do
        @page.grants_right?(@teacher, :read).should be_true
      end

      it 'should be given create rights' do
        @page.grants_right?(@teacher, :create).should be_true
      end

      it 'should be given update rights' do
        @page.grants_right?(@teacher, :update).should be_true
      end

      it 'should be given delete rights' do
        @page.grants_right?(@teacher, :delete).should be_true
      end

      it 'should be given delete rights for unpublished pages' do
        @page.workflow_state = 'unpublished'
        @page.grants_right?(@teacher, :delete).should be_true
      end
    end

    context 'students' do
      before :each do
        course_with_student :course => @course, :active_all => true
        @page = @course.wiki.wiki_pages.create(:title => 'Some page')
        @page.workflow_state = 'active'
        @page.save!
      end

      it 'should be given read rights' do
        @page.grants_right?(@user, :read).should be_true
      end

      it 'should be given read rights, unless hidden from students' do
        @page.hide_from_students = true
        @page.grants_right?(@user, :read).should be_false
      end

      it 'should be given read rights, unless unpublished' do
        @page.workflow_state = 'unpublished'
        @page.grants_right?(@user, :read).should be_false
      end

      it 'should not be given create rights' do
        @page.grants_right?(@user, :create).should be_false
      end

      it 'should not be given update rights' do
        @page.grants_right?(@user, :update).should be_false
      end

      it 'should not be given update_content rights' do
        @page.grants_right?(@user, :update_content).should be_false
      end

      it 'should not be given delete rights' do
        @page.grants_right?(@user, :delete).should be_false
      end

      context 'with editing roles' do
        before :each do
          @page.editing_roles = 'teachers,students'
        end

        it 'should be given update_content rights' do
          @page.grants_right?(@user, :update_content).should be_true
        end

        it 'should not be given create rights' do
          @page.grants_right?(@user, :create).should be_false
        end

        it 'should not be given update rights' do
          @page.grants_right?(@user, :update).should be_false
        end

        it 'should not be given delete rights' do
          @page.grants_right?(@user, :delete).should be_false
        end
      end

      context 'with course editing roles' do
        before :each do
          @course.default_wiki_editing_roles = 'teachers,students'
          @course.save!
          @page.reload
        end

        it 'should be given create rights' do
          @page.grants_right?(@user, :create).should be_true
        end

        it 'should be given update rights' do
          @page.grants_right?(@user, :update).should be_true
        end

        it 'should be given update_content rights' do
          @page.grants_right?(@user, :update_content).should be_true
        end

        it 'should not be given delete rights' do
          @page.grants_right?(@user, :delete).should be_false
        end
      end

      context 'with course editing roles for teacher only page' do
        before :each do
          @course.default_wiki_editing_roles = 'teachers,students'
          @course.save!
          @page.reload
          @page.editing_roles = 'teachers'
        end

        it 'should not be given create rights' do
          @page.grants_right?(@user, :create).should be_false
        end

        it 'should not be given update rights' do
          @page.grants_right?(@user, :update).should be_false
        end

        it 'should not be given update_content rights' do
          @page.grants_right?(@user, :update_content).should be_false
        end

        it 'should not be given delete rights' do
          @page.grants_right?(@user, :delete).should be_false
        end
      end

      context 'with course editing roles for unpublished pages' do
        before :each do
          @course.default_wiki_editing_roles = 'teachers,students'
          @course.save!
          @page.reload
          @page.workflow_state = 'unpublished'
        end

        it 'should not be given create rights' do
          @page.grants_right?(@user, :create).should be_false
        end

        it 'should not be given update rights' do
          @page.grants_right?(@user, :update).should be_false
        end

        it 'should not be given update_content rights' do
          @page.grants_right?(@user, :update_content).should be_false
        end

        it 'should not be given delete rights' do
          @page.grants_right?(@user, :delete).should be_false
        end
      end
    end
  end
end
