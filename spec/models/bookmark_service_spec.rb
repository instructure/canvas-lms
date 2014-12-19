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

describe BookmarkService do
  before :once do
    bookmark_service_model
  end
  
  it "should include Delicious" do
    expect(BookmarkService.included_modules).to be_include(Delicious)
  end

  context "post_bookmark" do
    before do
      # For safety, that we don't mess with external services at all.
      @bookmark_service.stubs(:delicious_post_bookmark).returns(true)
      @bookmark_service.stubs(:diigo_post_bookmark).returns(true)
    end
    
    it "should be able to post a bookmark for diigo" do
      expect(@bookmark_service.service).to eql('diigo')
      
      Diigo::Connection.expects(:diigo_post_bookmark).with(
        @bookmark_service, 
        'google.com', 
        'some title', 
        'some comments', 
        ['some', 'tags']
      ).returns(true)
      
      @bookmark_service.post_bookmark(
        :title => 'some title', 
        :url => 'google.com', 
        :comments => 'some comments', 
        :tags => %w(some tags)
      )
    end
    
    it "should be able to post a bookmark for delicious" do
      bookmark_service_model(:service => 'delicious')

      expect(@bookmark_service.service).to eql('delicious')
      
      @bookmark_service.expects(:delicious_post_bookmark).with(
        @bookmark_service, 
        'google.com', 
        'some title', 
        'some comments', 
        ['some', 'tags']
      ).returns(true)
      
      @bookmark_service.post_bookmark(
        :title => 'some title', 
        :url => 'google.com', 
        :comments => 'some comments', 
        :tags => %w(some tags)
      )
    end
    
    it "should rescue silently if something happens during the process" do
      def @bookmark_service.diigo_post_bookmark(*args)
        raise ArgumentError
      end
      
      expect{@bookmark_service.post_bookmark(
        :title => 'some title', 
        :url => 'google.com', 
        :comments => 'some comments', 
        :tags => %w(some tags)
      )}.not_to raise_error
    end
  end
end
