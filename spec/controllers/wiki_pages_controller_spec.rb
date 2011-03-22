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
    it "should redirect on index request" do
      course_with_teacher(:active_all => true)
      get 'index', :course_id => @course.id
      response.should be_redirect
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>2,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end
    
    
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'show', :course_id => @course.id, :id => 'front-page'
      assert_unauthorized
    end
    
    it "should assign values" do
      course_with_teacher_logged_in(:active_all => true)
      get 'show', :course_id => @course.id, :id => 'front-page'
      response.should be_success
      assigns[:wiki].should_not be_nil
      assigns[:namespace].should_not be_nil
      assigns[:page].should_not be_nil
    end
    
    it "should create entities if not already existing" do
      course_with_teacher_logged_in(:active_all => true)
      get 'show', :course_id => @course.id, :id => 'front-page'
      response.should be_success
      assigns[:wiki].should_not be_nil
      assigns[:namespace].should_not be_nil
      assigns[:namespace].context.should eql(@course)
      assigns[:page].should_not be_nil
      assigns[:page].title.should eql("Front Page")
    end
    
    it "should retrieve existing entities" do
      course_with_teacher_logged_in(:active_all => true)
      page = WikiNamespace.default_for_context(@course).wiki.wiki_page
      page.save!
      get 'show', :course_id => @course.id, :id => 'front-page'
      response.should be_success
      assigns[:wiki].should_not be_nil
      assigns[:wiki].should eql(page.wiki)
      assigns[:namespace].should_not be_nil
      assigns[:namespace].context.should eql(@course)
      assigns[:page].should_not be_nil
      assigns[:page].title.should eql("Front Page")
      assigns[:page].should eql(page)
    end
    
  end
  
  describe "GET 'show'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'show', :course_id => @course.id, :id => "some-page"
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      get 'show', :course_id => @course.id, :id => "some-page"
      response.should be_success
      assigns[:wiki].should_not be_nil
      assigns[:namespace].should_not be_nil
      assigns[:page].should_not be_nil
      assigns[:page].title.should eql("Some Page")
    end
    
    it "should allow students when allowed" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :wiki_page => {:title => "Some Secret Page"}
      response.should be_redirect
      page = assigns[:page]
      page.should_not be_nil
      page.should_not be_new_record
      page.title.should == "Some Secret Page"
      student = user()
      enrollment = @course.enroll_student(student)
      enrollment.accept!
      @course.reload
      user_session(student)
      get 'show', :course_id => @course.id, :id => page.wiki_id
      response.should be_success
      assigns[:wiki].should_not be_nil
      assigns[:namespace].should_not be_nil
      assigns[:page].should_not be_nil
      assigns[:page].title.should eql("Some Secret Page")
      page.hide_from_students = true
      page.save
      page.reload
      get 'show', :course_id => @course.id, :id => page.wiki_id
      assert_unauthorized
    end
  end
  
  # describe "GET 'revisions'" do
  #   it "should require authorization" do
  #     course_with_teacher(:active_all => true)
  #     get 'show', :course_id => @course.id, :id => "some-page"
  #     assert_unauthorized
  #   end
  #   
  #   it "should assign variables" do
  #     course_with_teacher_logged_in(:active_all => true)
  #     get 'revisions', :course_id => @course.id, :id => "some-page", :format => 'html'
  #     response.should be_success
  #     assigns[:wiki].should_not be_nil
  #     assigns[:namespace].should_not be_nil
  #     assigns[:page].should_not be_nil
  #     assigns[:page].title.should eql("some_page")
  #   end
  # end
  
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id, :wiki_page => {:title => "Some Great Page"}
      assert_unauthorized
    end
    
    it "should create page" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :wiki_page => {:title => "Some Great Page"}
      response.should be_redirect
      assigns[:page].should_not be_nil
      assigns[:page].should_not be_new_record
      assigns[:page].title.should eql("Some Great Page")
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
      response.should be_redirect
      assigns[:page].should_not be_nil
      assigns[:page].title.should eql("Some Great Page")
      page = assigns[:page]
      
      put 'update', :course_id => @course.id, :id => page.url, :wiki_page => {:title => "New Name"}
      response.should be_redirect
      assigns[:page].should_not be_nil
      assigns[:page].title.should eql("New Name")
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      page = @course.wiki.wiki_page
      page.save!
      delete 'destroy', :course_id => @course.id, :id => page.url
      assert_unauthorized
    end
    
    it "should redirect on deleting front page" do
      course_with_teacher_logged_in(:active_all => true)
      page = @course.wiki.wiki_page
      page.save!
      delete 'destroy', :course_id => @course.id, :id => page.url
      flash[:error].should eql('You are not permitted to delete that page.')
      response.should be_redirect
    end
    
    it "should delete page" do
      course_with_teacher_logged_in(:active_all => true)
      page = @course.wiki.wiki_pages.create(:title => "a page")
      page.save!
      delete 'destroy', :course_id => @course.id, :id => page.url
      response.should be_redirect
      assigns[:page].should eql(page)
      assigns[:page].should be_deleted #frozen
      @course.wiki.wiki_pages.should be_include(page)
    end
  end
  
end
