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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "communication_channels/confirm.html.erb" do
  before do
    user
    assigns[:user] = @user
    assigns[:communication_channel] = @cc = @communication_channel = @user.communication_channels.create!(:path => 'johndoe@example.com')
    assigns[:nonce] = @cc.confirmation_code
    assigns[:body_classes] = []
    assigns[:root_account] = Account.default
  end

  shared_examples_for "user registration" do
    it "should only show the registration form if no merge opportunities" do
      assigns[:merge_opportunities] = []
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      registration_form.should_not be_nil
      if @enrollment
        registration_form['style'].should match /display:\s*none/
        page.css('#register.button').first.should_not be_nil
        page.css('#back.button').first.should be_nil
      else
        registration_form['style'].should be_blank
        # no "back", "use this account", "new account", etc. buttons
        page.css('a.button').should be_empty
      end
    end

    it "should follow the simple path for not logged in" do
      user_with_pseudonym(:active_all => 1)
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      registration_form.should_not be_nil
      registration_form['style'].should match /display:\s*none/
      page.css('input[type="radio"][name="pseudonym_select"]').should be_empty
      page.css('#register.button').first.should_not be_nil
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button['href'].should == login_url(:host => HostUrl.default_host, :confirm => @communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :pseudonym_session => {:unique_id => @pseudonym.unique_id}, :expected_user_id => @pseudonym.user_id)
      page.css('#back.button').first.should_not be_nil
    end

    it "should follow the simple path for logged in as a matching user" do
      user_with_pseudonym(:active_all => 1)
      @user.communication_channels.create!(:path => 'johndoe@example.com') { |cc| cc.workflow_state = 'active' }
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym]]]
      assigns[:current_user] = @user
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      registration_form.should_not be_nil
      registration_form['style'].should match /display:\s*none/
      page.css('input[type="radio"][name="pseudonym_select"]').should be_empty
      page.css('#register.button').first.should_not be_nil
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button.text.should == 'Yes'
      merge_button['href'].should == registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :confirm => 1)
      page.css('#back.button').first.should_not be_nil
    end

    it "should follow the simple path for logged in as a non-matching user" do
      user_with_pseudonym(:active_all => 1)
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym]]]
      assigns[:current_user] = @user
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      registration_form.should_not be_nil
      registration_form['style'].should match /display:\s*none/
      page.css('input[type="radio"][name="pseudonym_select"]').should be_empty
      page.css('#register.button').first.should_not be_nil
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button['href'].should == registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :confirm => 1)
      merge_button.text.should == 'Yes, Add Email Address'
      page.css('#back.button').first.should_not be_nil
    end

    it "should follow the mostly-simple-path for not-logged in with multiple pseudonyms" do
      user_with_pseudonym(:active_all => 1)
      account2 = Account.create!
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym, @user.pseudonyms.create!(:unique_id => 'johndoe', :account => account2)]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      registration_form.should_not be_nil
      registration_form['style'].should match /display:\s*none/
      page.css('input[type="radio"][name="pseudonym_select"]').length.should == 2
      page.css('#register.button').first.should_not be_nil
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button['href'].should == login_url(:host => HostUrl.default_host, :confirm => @communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :pseudonym_session => {:unique_id => @pseudonym.unique_id}, :expected_user_id => @pseudonym.user_id)
      page.css('#back.button').first.should_not be_nil
    end

    it "should render for multiple merge opportunities" do
      @user1 = user_with_pseudonym(:active_all => 1)
      @user2 = user_with_pseudonym(:active_all => 1, :username => 'janedoe@example.com')
      @user3 = user_with_pseudonym(:active_all => 1, :username => 'freddoe@example.com')
      account2 = Account.create!
      @user3.pseudonyms.create!(:unique_id => 'johndoe', :account => account2)
      @user4 = user_with_pseudonym(:active_all => 1, :username => 'georgedoe@example.com', :account => account2)
      assigns[:merge_opportunities] = [
          [@user1, [@user1.pseudonym]],
          [@user2, [@user2.pseudonym]],
          [@user3, @user3.pseudonyms],
          [@user4, [@user4.pseudonym]]
      ]
      assigns[:current_user] = @user1
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      registration_form.should_not be_nil
      registration_form['style'].should match /display:\s*none/
      page.css('input[type="radio"][name="pseudonym_select"]').length.should == 6
      page.css('#register.button').should be_empty
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button['href'].should == registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :confirm => 1)
      page.css('#back.button').first.should_not be_nil
    end
  end

  context "invitations" do
    before do
      course(:active_all => true)
      assigns[:course] = @course
      assigns[:enrollment] = @enrollment = @course.enroll_user(@user)
    end

    it "should render transfer enrollment form" do
      assigns[:merge_opportunities] = []
      @user.register
      @pseudonym1 = @user.pseudonyms.create!(:unique_id => 'jt@instructure.com')
      user_with_pseudonym(:active_all => 1)
      assigns[:current_user] = @user

      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      page.css('#registration_confirmation_form').first.should be_nil
      transfer_button = page.css('#transfer.button').first
      transfer_button.should_not be_nil
      transfer_button['href'].should == registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.uuid, :transfer_enrollment => 1)
      login_button = page.css('#login.button').first
      login_button.should_not be_nil
      login_button['href'].should == login_url(:enrollment => @enrollment.uuid, :pseudonym_session => { :unique_id => 'jt@instructure.com'}, :expected_user_id => @pseudonym1.user_id)
    end

    context "open registration" do
      before do
        @user.update_attribute(:workflow_state, 'creation_pending')
        assigns[:pseudonym] = @user.pseudonyms.build(:account => Account.default)
      end
      it_should_behave_like "user registration"
    end
  end

  context "merging" do
    before do
      @user.register
    end

    it "should render to merge with the current user" do
      user_with_pseudonym(:active_all => 1)
      assigns[:current_user] = @user
      assigns[:merge_opportunities] = [[@user, [@pseudonym]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      page.css('input[type="radio"][name="pseudonym_select"]').should be_empty
      page.css('#registration_confirmation_form').first.should be_nil
      page.css('#register.button').first.should be_nil
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button.text.should == 'Combine'
      merge_button['href'].should == registration_confirmation_path(@communication_channel.confirmation_code, :confirm => 1, :enrollment => nil)
    end

    it "should render to merge with the current user that doesn't have a pseudonym in the default account" do
      account = Account.create!
      user_with_pseudonym(:active_all => 1, :account => account)
      assigns[:current_user] = @user
      assigns[:merge_opportunities] = [[@user, [@pseudonym]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      page.css('input[type="radio"][name="pseudonym_select"]').should be_empty
      page.css('#registration_confirmation_form').first.should be_nil
      page.css('#register.button').first.should be_nil
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button.text.should == 'Combine'
      merge_button['href'].should == registration_confirmation_path(@communication_channel.confirmation_code, :confirm => 1, :enrollment => nil)
    end

    it "should render to merge multiple users" do
      user_with_pseudonym(:active_all => 1)
      @user1 = @user
      @pseudonym1 = @pseudonym
      user_with_pseudonym(:active_all => 1, :username => 'georgedoe@example.com')
      @user2 = @user
      assigns[:merge_opportunities] = [[@user1, [@user1.pseudonym]], [@user2, [@user2.pseudonym]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      page.css('input[type="radio"][name="pseudonym_select"]').length.should == 2
      page.css('#registration_confirmation_form').first.should be_nil
      page.css('#register.button').first.should be_nil
      merge_button = page.css('#merge.button').first
      merge_button.should_not be_nil
      merge_button.text.should == 'Continue'
      merge_button['href'].should == login_url(:host => HostUrl.default_host, :confirm => @communication_channel.confirmation_code, :pseudonym_session => {:unique_id => @pseudonym1.unique_id}, :expected_user_id => @pseudonym1.user_id)
    end
  end

  context "self-registration" do
    before do
      assigns[:pseudonym] = @user.pseudonyms.create!(:unique_id => 'johndoe@example.com')
    end

    it_should_behave_like "user registration"
  end
end
