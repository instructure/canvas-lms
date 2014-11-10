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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WikiPagesController do
  describe "GET 'index'" do
    it "should redirect with draft state enabled" do
      course_with_teacher_logged_in(:active_all => true)
      @course.enable_feature!(:draft_state)
      get 'index', :course_id => @course.id
      expect(response).to be_redirect
      expect(response.location).to match(%r{/courses/#{@course.id}/pages})
    end
  end

  describe "GET 'show'" do
    it "should redirect with draft state enabled" do
      course_with_teacher_logged_in(:active_all => true)
      @course.enable_feature!(:draft_state)
      get 'show', :course_id => @course.id, :id => "some-page"
      expect(response).to be_redirect
      expect(response.location).to match(%r{/courses/#{@course.id}/pages})
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id, :wiki_page => {:title => "Some Great Page"}
      assert_unauthorized
    end

    it "should create page" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :wiki_page => {:title => "Some Great Page"}
      expect(response).to be_redirect
      expect(assigns[:page]).not_to be_nil
      expect(assigns[:page]).not_to be_new_record
      expect(assigns[:page].title).to eql("Some Great Page")
    end

    it "should allow users to create a page" do
      group_with_user_logged_in(:active_all => true)
      post 'create', :group_id => @group.id, :wiki_page => {:title => "Some Great Page"}
      expect(response).to be_redirect
      expect(assigns[:page]).not_to be_nil
      expect(assigns[:page]).not_to be_new_record
      expect(assigns[:page].title).to eql("Some Great Page")
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      put 'update', :course_id => @course.id, :id => 1, :wiki_page => {:title => "Some Great Page"}
      assert_unauthorized
    end

    it "should update page" do
      course_with_teacher_logged_in(:active_all => true)
      @course.wiki.wiki_pages.create!(:title => 'Test')
      put 'update', :course_id => @course.id, :id => @course.wiki.wiki_pages.first.url, :wiki_page => {:title => "Some Great Page"}
      expect(response).to be_redirect
      expect(assigns[:page]).not_to be_nil
      expect(assigns[:page].title).to eql("Some Great Page")
      page = assigns[:page]

      put 'update', :course_id => @course.id, :id => page.url, :wiki_page => {:title => "New Name"}
      expect(response).to be_redirect
      expect(assigns[:page]).not_to be_nil
      expect(assigns[:page].title).to eql("New Name")
    end

    describe 'when the user is not a teacher' do
      before do
        group_with_user_logged_in(:active_all => true)
        @group.wiki.wiki_pages.create!(:title => 'Test')
        put 'update', :group_id => @group.id, :id => @group.wiki.wiki_pages.first.url, :wiki_page => {:title => "Some Great Page"}
        @page = assigns[:page]
      end

      it 'redirects on success' do
        expect(response).to be_redirect
      end

      it 'creates the new page on the first put' do
        expect(@page).not_to be_nil
        expect(@page.title).to eql("Some Great Page")
      end

      describe 'and is updating an existing page' do
        before do
          Setting.set('enable_page_views', 'db')
          put 'update', :group_id => @group.id, :id => @page.url, :wiki_page => {:title => "New Name" }
          @page = assigns[:page]
        end

        after do
          Setting.set('enable_page_views', 'false')
        end

        it 'redirects on success' do
          expect(response).to be_redirect
        end

        it 'updates the page attributes' do
          expect(@page).not_to be_nil
          expect(@page.title).to eq 'New Name'
        end

        it 'logs an asset access record for the discussion topic' do
          accessed_asset = assigns[:accessed_asset]
          expect(accessed_asset[:category]).to eq 'wiki'
          expect(accessed_asset[:level]).to eq 'participate'
        end

        it 'registers a page view' do
          page_view = assigns[:page_view]
          expect(page_view).not_to be_nil
          expect(page_view.http_method).to eq 'put'
          expect(page_view.url).to match %r{^http://test\.host/groups/\d+/wiki/test}
          expect(page_view.participated).to be_truthy
        end


      end
    end

  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      page = @course.wiki.front_page
      page.save!
      delete 'destroy', :course_id => @course.id, :id => page.url
      assert_unauthorized
    end
    
    it "should redirect on deleting front page" do
      course_with_teacher_logged_in(:active_all => true)
      page = @course.wiki.front_page
      page.save!
      delete 'destroy', :course_id => @course.id, :id => page.url
      expect(flash[:error]).to eql('You cannot delete the front page.')
      expect(response).to be_redirect
    end
    
    it "should delete page" do
      course_with_teacher_logged_in(:active_all => true)
      page = @course.wiki.wiki_pages.create(:title => "a page")
      page.save!
      delete 'destroy', :course_id => @course.id, :id => page.url
      expect(response).to be_redirect
      expect(assigns[:page]).to eql(page)
      expect(assigns[:page]).to be_deleted #frozen
      expect(@course.wiki.wiki_pages).to be_include(page)
    end
    
    it "should allow users to delete a page" do
      group_with_user_logged_in(:active_all => true)
      page = @group.wiki.wiki_pages.create(:title => "a page")
      page.save!
      delete 'destroy', :group_id => @group.id, :id => page.url
      expect(response).to be_redirect
      expect(assigns[:page]).to eql(page)
      expect(assigns[:page]).to be_deleted #frozen
      expect(@group.wiki.wiki_pages).to be_include(page)
    end
  end

end
