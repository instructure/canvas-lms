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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe Wiki do
  before :once do
    course
    @wiki = @course.wiki
  end

  context "get_front_page_url" do
    it "should return default url if front_page_url is not set" do
      @wiki.get_front_page_url.should == Wiki::DEFAULT_FRONT_PAGE_URL # 'front-page'
    end
  end

  context "unset_front_page!" do
    it "should unset front page" do
      @wiki.unset_front_page!

      @wiki.has_front_page?.should == false
      @wiki.front_page_url.should == nil
    end
  end

  context "set_front_page_url!" do
    it "should set front_page_url" do
      @wiki.unset_front_page!
      new_url = "ponies4ever"
      @wiki.set_front_page_url!(new_url).should == true

      @wiki.has_front_page?.should == true
      @wiki.front_page_url.should == new_url
    end
  end

  context "front_page" do
    it "should build a default page if not found" do
      @wiki.wiki_pages.count.should == 0

      page = @wiki.front_page
      page.new_record?.should == true
      page.url.should == @wiki.get_front_page_url
    end

    it "should build a custom front page if not found" do
      new_url = "whyyyyy"
      @wiki.set_front_page_url!(new_url)

      page = @wiki.front_page
      page.new_record?.should == true
      page.url.should == new_url
    end

    it "should find front_page by url" do
      page = @wiki.wiki_pages.create!(:title => "stuff and stuff")

      @wiki.set_front_page_url!(page.url)
      page.should == @wiki.front_page
    end
  end

  context 'set policy' do
    before :once do
      @course.offer!
      user :active_all => true
    end

    it 'should give read rights to public courses' do
      @course.is_public = true
      @course.save!
      @course.wiki.grants_right?(@user, :read).should be_true
    end

    it 'should give manage rights to teachers' do
      course_with_teacher
      @course.wiki.grants_right?(@teacher, :manage).should be_true
    end

    it 'should give manage rights to admins' do
      account_admin_user
      @course.wiki.grants_right?(@admin, :manage).should be_true
    end

    context 'allow student wiki edits' do
      before :once do
        course_with_student :course => @course, :user => @user, :active_all => true
        @course.default_wiki_editing_roles = 'teachers,students'
        @course.save!
      end

      it 'should not give manage rights to students' do
        @course.wiki.grants_right?(@user, :manage).should be_false
      end

      it 'should not give update rights to students' do
        @course.wiki.grants_right?(@user, :update).should be_false
      end

      it 'should give read rights to students' do
        @course.wiki.grants_right?(@user, :read).should be_true
      end

      it 'should give create_page rights to students' do
        @course.wiki.grants_right?(@user, :create_page).should be_true
      end

      it 'should not give delete_page rights to students' do
        @course.wiki.grants_right?(@user, :delete_page).should be_false
      end

      it 'should give update_page rights to students' do
        @course.wiki.grants_right?(@user, :update_page).should be_true
      end

      it 'should give update_page_content rights to students' do
        @course.wiki.grants_right?(@user, :update_page_content).should be_true
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should find the wiki's context from another shard" do
      @shard1.activate do
        @wiki.context.should == @course
      end
    end
  end
end
