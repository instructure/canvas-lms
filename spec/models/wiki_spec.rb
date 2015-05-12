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

  context "unset_front_page!" do
    it "should unset front page" do
      @wiki.unset_front_page!

      expect(@wiki.has_front_page?).to eq false
      expect(@wiki.front_page_url).to eq nil
    end
  end

  context "set_front_page_url!" do
    it "should set front_page_url" do
      @wiki.unset_front_page!
      new_url = "ponies4ever"
      expect(@wiki.set_front_page_url!(new_url)).to eq true

      expect(@wiki.has_front_page?).to eq true
      expect(@wiki.front_page_url).to eq new_url
    end
  end

  context "front_page" do
    it "should build a custom front page if not found" do
      new_url = "whyyyyy"
      @wiki.set_front_page_url!(new_url)

      page = @wiki.front_page
      expect(page.new_record?).to eq true
      expect(page.url).to eq new_url
    end

    it "should find front_page by url" do
      page = @wiki.wiki_pages.create!(:title => "stuff and stuff")

      @wiki.set_front_page_url!(page.url)
      expect(page).to eq @wiki.front_page
    end

    it "should find front_page by default url (legacy support)" do
      page = @wiki.wiki_pages.create!(:title => "front page")
      page.update_attribute(:url, Wiki::DEFAULT_FRONT_PAGE_URL )
      @wiki.update_attribute(:has_no_front_page, false)

      expect(page).to eq @wiki.front_page
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
      expect(@course.wiki.grants_right?(@user, :read)).to be_truthy
    end

    it 'should give manage rights to teachers' do
      course_with_teacher
      expect(@course.wiki.grants_right?(@teacher, :manage)).to be_truthy
    end

    it 'should give manage rights to admins' do
      account_admin_user
      expect(@course.wiki.grants_right?(@admin, :manage)).to be_truthy
    end

    it 'should give publish page rights to admins' do
      account_admin_user
      expect(@course.wiki.grants_right?(@admin, :publish_page)).to be_truthy
    end

    it 'should not give publish page rights to admins when the context is a group' do
      account_admin_user
      group
      expect(@group.wiki.grants_right?(@admin, :publish_page)).to be_falsey
    end

    context 'allow student wiki edits' do
      before :once do
        course_with_student :course => @course, :user => @user, :active_all => true
        @course.default_wiki_editing_roles = 'teachers,students'
        @course.save!
      end

      it 'should not give manage rights to students' do
        expect(@course.wiki.grants_right?(@user, :manage)).to be_falsey
      end

      it 'should not give update rights to students' do
        expect(@course.wiki.grants_right?(@user, :update)).to be_falsey
      end

      it 'should give read rights to students' do
        expect(@course.wiki.grants_right?(@user, :read)).to be_truthy
      end

      it 'should give create_page rights to students' do
        expect(@course.wiki.grants_right?(@user, :create_page)).to be_truthy
      end

      it 'should not give publish page rights to students' do
        expect(@course.wiki.grants_right?(@user, :publish_page)).to be_falsey
      end

      it 'should not give publish page rights to students when the context is a group' do
        group
        expect(@group.wiki.grants_right?(@user, :publish_page)).to be_falsey
      end

      it 'should not give delete_page rights to students' do
        expect(@course.wiki.grants_right?(@user, :delete_page)).to be_falsey
      end

      it 'should give update_page rights to students' do
        expect(@course.wiki.grants_right?(@user, :update_page)).to be_truthy
      end

      it 'should give update_page_content rights to students' do
        expect(@course.wiki.grants_right?(@user, :update_page_content)).to be_truthy
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should find the wiki's context from another shard" do
      @shard1.activate do
        expect(@wiki.context).to eq @course
      end
    end
  end
end
