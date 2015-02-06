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

  before :once do
    eportfolio_with_user(:active_all => true)
    eportfolio_category
  end

  describe "GET 'show'" do
    before(:once) { eportfolio_entry(@category) }
    it "should require authorization" do
      get 'show', :eportfolio_id => @portfolio.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      user_session(@user)
      attachment = @portfolio.user.attachments.build(:filename => 'some_file.pdf')
      attachment.content_type = ''
      attachment.save!
      @entry.content = [{:section_type => 'attachment', :attachment_id => attachment.id}]
      @entry.save!
      get 'show', :eportfolio_id => @portfolio.id, :id => @entry.id
      expect(response).to be_success
      expect(assigns[:category]).to eql(@category)
      expect(assigns[:page]).to eql(@entry)
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      expect(assigns[:attachments]).not_to be_nil
      expect(assigns[:attachments]).not_to be_empty
    end
    
    it "should work off of category and entry names" do
      user_session(@user)
      @category.name = "some category"
      @category.save!
      @entry.name = "some entry"
      @entry.save!
      get 'show', :eportfolio_id => @portfolio.id, :category_name => @category.slug, :entry_name => @entry.slug
      expect(assigns[:category]).to eql(@category)
      expect(assigns[:page]).to eql(@entry)
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
    end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :eportfolio_id => @portfolio.id
      assert_unauthorized
    end
    
    it "should create entry" do
      user_session(@user)
      post 'create', :eportfolio_id => @portfolio.id, :eportfolio_entry => {:eportfolio_category_id => @category.id, :name => "some entry"}
      expect(response).to be_redirect
      expect(assigns[:category]).to eql(@category)
      expect(assigns[:page]).not_to be_nil
      expect(assigns[:page].name).to eql("some entry")
    end
  end
  
  describe "PUT 'update'" do
    before(:once) { eportfolio_entry(@category) }
    it "should require authorization" do
      put 'update', :eportfolio_id => @portfolio.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should update entry" do
      user_session(@user)
      put 'update', :eportfolio_id => @portfolio.id, :id => @entry.id, :eportfolio_entry => {:name => "new name"}
      expect(response).to be_redirect
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry].name).to eql("new name")
    end
  end
  
  describe "DELETE 'destroy'" do
    before(:once) { eportfolio_entry(@category) }
    it "should require authorization" do
      delete 'destroy', :eportfolio_id => @portfolio.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should delete entry" do
      user_session(@user)
      delete 'destroy', :eportfolio_id => @portfolio.id, :id => @entry.id
      expect(response).to be_redirect
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry]).to be_frozen
    end
  end
  
  describe "GET 'attachment'" do
    before(:once) { eportfolio_entry(@category) }
    it "should require authorization" do
      get 'attachment', :eportfolio_id => @portfolio.id, :entry_id => @entry.id, :attachment_id => 1
      assert_unauthorized
    end
    
    it "should redirect to page" do
      user_session(@user)
      begin
        get 'attachment', :eportfolio_id => @portfolio.id, :entry_id => @entry.id, :attachment_id => CanvasUUID.generate
      rescue => e
        expect(e.to_s).to eql("Not Found")
      end
    end
  end
end
