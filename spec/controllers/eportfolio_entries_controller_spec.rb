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

describe EportfolioEntriesController do
  def eportfolio_category
    @category = @portfolio.eportfolio_categories.create
  end
  def eportfolio_entry(category=nil)
    @entry = @portfolio.eportfolio_entries.new
    @entry.eportfolio_category_id = category.id if category
    @entry.save!
  end

  describe "GET 'show'" do
    it "should require authorization" do
      eportfolio_with_user(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      get 'show', :eportfolio_id => @portfolio.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      eportfolio_with_user_logged_in(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      attachment = @portfolio.user.attachments.build(:filename => 'some_file.pdf')
      attachment.content_type = ''
      attachment.save!
      @entry.content = [{:section_type => 'attachment', :attachment_id => attachment.id}]
      @entry.save!
      get 'show', :eportfolio_id => @portfolio.id, :id => @entry.id
      response.should be_success
      assigns[:category].should eql(@category)
      assigns[:page].should eql(@entry)
      assigns[:entries].should_not be_nil
      assigns[:entries].should_not be_empty
      assigns[:attachments].should_not be_nil
      assigns[:attachments].should_not be_empty
    end
    
    it "should work off of category and entry names" do
      eportfolio_with_user_logged_in(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      @category.name = "some category"
      @category.save!
      @entry.name = "some entry"
      @entry.save!
      get 'show', :eportfolio_id => @portfolio.id, :category_name => @category.slug, :entry_name => @entry.slug
      assigns[:category].should eql(@category)
      assigns[:page].should eql(@entry)
      assigns[:entries].should_not be_nil
      assigns[:entries].should_not be_empty
    end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      eportfolio_with_user(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      post 'create', :eportfolio_id => @portfolio.id
      assert_unauthorized
    end
    
    it "should create entry" do
      eportfolio_with_user_logged_in(:active_all => true)
      eportfolio_category
      post 'create', :eportfolio_id => @portfolio.id, :eportfolio_entry => {:eportfolio_category_id => @category.id, :name => "some entry"}
      response.should be_redirect
      assigns[:category].should eql(@category)
      assigns[:page].should_not be_nil
      assigns[:page].name.should eql("some entry")
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      eportfolio_with_user(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      put 'update', :eportfolio_id => @portfolio.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should update entry" do
      eportfolio_with_user_logged_in(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      put 'update', :eportfolio_id => @portfolio.id, :id => @entry.id, :eportfolio_entry => {:name => "new name"}
      response.should be_redirect
      assigns[:entry].should_not be_nil
      assigns[:entry].name.should eql("new name")
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      eportfolio_with_user(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      delete 'destroy', :eportfolio_id => @portfolio.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should delete entry" do
      eportfolio_with_user_logged_in(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      delete 'destroy', :eportfolio_id => @portfolio.id, :id => @entry.id
      response.should be_redirect
      assigns[:entry].should_not be_nil
      assigns[:entry].should be_frozen
    end
  end
  
  describe "GET 'attachment'" do
    it "should require authorization" do
      eportfolio_with_user(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      get 'attachment', :eportfolio_id => @portfolio.id, :entry_id => @entry.id, :attachment_id => 1
      assert_unauthorized
    end
    
    it "should redirect to page" do
      eportfolio_with_user_logged_in(:active_all => true)
      eportfolio_category
      eportfolio_entry(@category)
      begin
        get 'attachment', :eportfolio_id => @portfolio.id, :entry_id => @entry.id, :attachment_id => CanvasUUID.generate
      rescue => e
        e.to_s.should eql("Not Found")
      end
    end
  end
end
