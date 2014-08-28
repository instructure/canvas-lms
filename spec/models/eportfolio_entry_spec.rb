#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe EportfolioEntry do

  describe 'validation' do
    before(:once) do
      eportfolio_model
      @long_string = 'qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm'
    end

    it "should validate the length of attributes" do
      @eportfolio_entry.name = @long_string
      @eportfolio_entry.slug = @long_string
      (lambda { @eportfolio_entry.save! }).should raise_error("Validation failed: Name is too long (maximum is 255 characters), Slug is too long (maximum is 255 characters)")
    end

    it "should validate the length of slug" do
      @eportfolio_entry.slug = @long_string
      (lambda { @eportfolio_entry.save! }).should raise_error("Validation failed: Slug is too long (maximum is 255 characters)")
    end

    it "should validate the length of name" do
      @eportfolio_entry.name = @long_string
      (lambda { @eportfolio_entry.save! }).should raise_error("Validation failed: Name is too long (maximum is 255 characters)")
    end
  end

  context "parse_content" do
    before :once do
      eportfolio_model
    end

    it "should accept valid attachments" do
      eportfolio_model
      attachment_model(:context => @user)
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'attachment', :attachment_id => @attachment.id}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0][:section_type].should eql('attachment')
      @eportfolio_entry.content[0][:attachment_id].should eql(@attachment.id)
    end

    it "should not accept invalid attachments" do
      attachment_model(:context => User.create)
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'attachment', :attachment_id => @attachment.id}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0].should eql("No Content Added Yet")

      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'attachment'}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0].should eql("No Content Added Yet")
    end

    it "should accept valid submissions" do
      submission_model(:user => @user)
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'submission', :submission_id => @submission.id}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0][:section_type].should eql('submission')
      @eportfolio_entry.content[0][:submission_id].should eql(@submission.id)
    end

    it "should not accept invalid submissions" do
      submission_model
      @bad_submission = @submission
      eportfolio_model
      submission_model(:user => @user)
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'submission', :submission_id => @bad_submission.id}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0].should eql("No Content Added Yet")

      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'submission'}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0].should eql("No Content Added Yet")
    end

    it "should accept valid html content" do
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'html', :content => "<a onclick='javascript: alert(5);' href='#bob;'>link</a>"}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0][:section_type].should eql('html')
      @eportfolio_entry.content[0][:content].should match(/\#bob/)
      @eportfolio_entry.content[0][:content].should match(/link/)
      @eportfolio_entry.content[0][:content].should_not match(/alert/)
      @eportfolio_entry.content[0][:content].should_not match(/javascript/)
    end

    it "should not accept invalid html content" do
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'html'}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0].should eql("No Content Added Yet")
    end

    it "should accept valid rich content" do
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'rich_text', :content => "<a onclick='javascript: alert(5);' href='#bob;'>link</a>"}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0][:section_type].should eql('rich_text')
      @eportfolio_entry.content[0][:content].should match(/\#bob/)
      @eportfolio_entry.content[0][:content].should match(/link/)
      @eportfolio_entry.content[0][:content].should_not match(/alert/)
      @eportfolio_entry.content[0][:content].should_not match(/javascript/)
    end

    it "should not accept invalid rich content" do
      @eportfolio_entry.parse_content({:section_count => 1, :section_1 => {:section_type => 'rich_text', :content => "<blink/>"}})
      @eportfolio_entry.content.should_not be_nil
      @eportfolio_entry.content.length.should eql(1)
      @eportfolio_entry.content[0].should eql("No Content Added Yet")
    end
  end
end
