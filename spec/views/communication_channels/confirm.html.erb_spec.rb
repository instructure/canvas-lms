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
    user_factory
    assigns[:user] = @user
    assigns[:communication_channel] = @cc = @communication_channel = @user.communication_channels.create!(:path => 'johndoe@example.com')
    assigns[:nonce] = @cc.confirmation_code
    assigns[:body_classes] = []
    assigns[:domain_root_account] = assigns[:root_account] = Account.default
    view.stubs(:require_terms?).returns(nil) # since controller-defined helper methods don't get plumbed down here
  end

  shared_examples_for "user registration" do
    it "should only show the registration form if no merge opportunities" do
      assigns[:merge_opportunities] = []
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      expect(registration_form).not_to be_nil
      if @enrollment
        expect(registration_form['style']).to match /display:\s*none/
        expect(page.css('#register.btn').first).not_to be_nil
        expect(page.css('#back.btn').first).to be_nil
      else
        expect(registration_form['style']).to be_blank
        # no "back", "use this account", "new account", etc. buttons
        expect(page.css('a.btn')).to be_empty
      end
    end

    it "should follow the simple path for not logged in" do
      user_with_pseudonym(:active_all => 1)
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      expect(registration_form).not_to be_nil
      expect(registration_form['style']).to match /display:\s*none/
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css('#register.btn').first).not_to be_nil
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button['href']).to eq login_url(:host => HostUrl.default_host, :confirm => @communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :pseudonym_session => {:unique_id => @pseudonym.unique_id}, :expected_user_id => @pseudonym.user_id)
      expect(page.css('#back.btn').first).not_to be_nil
    end

    it "should follow the simple path for logged in as a matching user" do
      user_with_pseudonym(:active_all => 1)
      @user.communication_channels.create!(:path => 'johndoe@example.com') { |cc| cc.workflow_state = 'active' }
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym]]]
      assigns[:current_user] = @user
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      expect(registration_form).not_to be_nil
      expect(registration_form['style']).to match /display:\s*none/
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css('#register.btn').first).not_to be_nil
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq 'Yes'
      expect(merge_button['href']).to eq registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :confirm => 1)
      expect(page.css('#back.btn').first).not_to be_nil
    end

    it "should follow the simple path for logged in as a non-matching user" do
      user_with_pseudonym(:active_all => 1)
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym]]]
      assigns[:current_user] = @user
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      expect(registration_form).not_to be_nil
      expect(registration_form['style']).to match /display:\s*none/
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css('#register.btn').first).not_to be_nil
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button['href']).to eq registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :confirm => 1)
      expect(merge_button.text).to eq 'Yes, Add Email Address'
      expect(page.css('#back.btn').first).not_to be_nil
    end

    it "should follow the mostly-simple-path for not-logged in with multiple pseudonyms" do
      user_with_pseudonym(:active_all => 1)
      account2 = Account.create!
      assigns[:merge_opportunities] = [[@user, [@user.pseudonym, @user.pseudonyms.create!(:unique_id => 'johndoe', :account => account2)]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      registration_form = page.css('#registration_confirmation_form').first
      expect(registration_form).not_to be_nil
      expect(registration_form['style']).to match /display:\s*none/
      expect(page.css('input[type="radio"][name="pseudonym_select"]').length).to eq 2
      expect(page.css('#register.btn').first).not_to be_nil
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button['href']).to eq login_url(:host => HostUrl.default_host, :confirm => @communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :pseudonym_session => {:unique_id => @pseudonym.unique_id}, :expected_user_id => @pseudonym.user_id)
      expect(page.css('#back.btn').first).not_to be_nil
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
      expect(registration_form).not_to be_nil
      expect(registration_form['style']).to match /display:\s*none/
      expect(page.css('input[type="radio"][name="pseudonym_select"]').length).to eq 6
      expect(page.css('#register.btn')).to be_empty
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button['href']).to eq registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.try(:uuid), :confirm => 1)
      expect(page.css('#back.btn').first).not_to be_nil
    end
  end

  context "invitations" do
    before do
      course_factory(active_all: true)
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
      expect(page.css('#registration_confirmation_form').first).to be_nil
      transfer_button = page.css('#transfer.btn').first
      expect(transfer_button).not_to be_nil
      expect(transfer_button['href']).to eq registration_confirmation_path(@communication_channel.confirmation_code, :enrollment => @enrollment.uuid, :transfer_enrollment => 1)
      login_button = page.css('#login.btn').first
      expect(login_button).not_to be_nil
      expect(login_button['href']).to eq login_url(:enrollment => @enrollment.uuid, :pseudonym_session => { :unique_id => 'jt@instructure.com'}, :expected_user_id => @pseudonym1.user_id)
    end

    context "open registration" do
      before do
        @user.update_attribute(:workflow_state, 'creation_pending')
        assigns[:pseudonym] = @user.pseudonyms.build(:account => Account.default)
      end
      include_examples "user registration"
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
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css('#registration_confirmation_form').first).to be_nil
      expect(page.css('#register.btn').first).to be_nil
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq 'Combine'
      expect(merge_button['href']).to eq registration_confirmation_path(@communication_channel.confirmation_code, :confirm => 1, :enrollment => nil)
    end

    it "should render to merge with the current user that doesn't have a pseudonym in the default account" do
      account = Account.create!
      user_with_pseudonym(:active_all => 1, :account => account)
      assigns[:current_user] = @user
      assigns[:merge_opportunities] = [[@user, [@pseudonym]]]
      render
      page = Nokogiri::HTML('<document>' + response.body + '</document>')
      expect(page.css('input[type="radio"][name="pseudonym_select"]')).to be_empty
      expect(page.css('#registration_confirmation_form').first).to be_nil
      expect(page.css('#register.btn').first).to be_nil
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq 'Combine'
      expect(merge_button['href']).to eq registration_confirmation_path(@communication_channel.confirmation_code, :confirm => 1, :enrollment => nil)
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
      expect(page.css('input[type="radio"][name="pseudonym_select"]').length).to eq 2
      expect(page.css('#registration_confirmation_form').first).to be_nil
      expect(page.css('#register.btn').first).to be_nil
      merge_button = page.css('#merge.btn').first
      expect(merge_button).not_to be_nil
      expect(merge_button.text).to eq 'Continue'
      expect(merge_button['href']).to eq login_url(:host => HostUrl.default_host, :confirm => @communication_channel.confirmation_code, :pseudonym_session => {:unique_id => @pseudonym1.unique_id}, :expected_user_id => @pseudonym1.user_id)
    end
  end

  context "self-registration" do
    before do
      assigns[:pseudonym] = @user.pseudonyms.create!(:unique_id => 'johndoe@example.com')
    end

    include_examples "user registration"
  end
end
