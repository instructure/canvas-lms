#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "Alerts" do
  include_context "in-process server selenium tests"

  before (:each) do
    @context = Account.default
    @context.settings[:enable_alerts] = true
    @context.save!
    @alerts = @context.alerts
    admin_logged_in
    enable_all_rcs Account.default
    stub_rcs_config
  end

  it "should be able to create, then update, then delete" do
    get "/accounts/#{@context.id}/settings"
    expect(@alerts.length).to eq 0

    find('#tab-alerts-link').click
    wait_for_ajaximations
    find('.add_alert_link').click
    wait_for_ajaximations
    alert = find('.alert.new')
    (add_criterion = alert.find('.add_criterion_link')).click
    wait_for_ajaximations
    alert.find('.add_recipient_link').click
    wait_for_ajaximations
    (submit = alert.find('.submit_button')).click
    wait_for_ajaximations
    keep_trying_until do
      @alerts.reload
      expect(@alerts.length).to eq 1
    end

    expect(@alerts.first.criteria.length).to eq 1

    (edit = alert.find('.edit_link')).click
    add_criterion.click
    wait_for_ajaximations
    submit.click
    wait_for_ajaximations

    keep_trying_until do
      @alerts.first.criteria.reload
      expect(@alerts.first.criteria.length).to eq 2
    end

    @alerts.reload
    expect(@alerts.length).to eq 1

    wait_for_ajaximations
    edit.click
    alert.find('.criteria .delete_item_link').click
    expect(ff('.alert .criteria li')).to have_size(1)
    submit.click
    wait_for_ajaximations

    keep_trying_until do
      @alerts.first.criteria.reload
      expect(@alerts.first.criteria.length).to eq 1
    end

    @alerts.reload
    expect(@alerts.length).to eq 1

    wait_for_ajaximations
    alert.find('.delete_link').click

    wait_for_ajaximations
    expect(find('.alert')).not_to be_displayed

    keep_trying_until do
      @alerts.reload
      expect(@alerts.length).to eq 0
    end
  end

  it "should delete alerts" do
    alert = @alerts.create!(:recipients => [:student], :criteria => [:criterion_type => 'Interaction', :threshold => 7])
    get "/accounts/#{@context.id}/settings"

    find('#tab-alerts-link').click
    wait_for_ajaximations
    find("#edit_alert_#{alert.id} .delete_link").click
    expect(f("#content")).not_to contain_css("#edit_alert_#{alert.id}")

    @alerts.reload
    expect(@alerts).to be_empty
  end

  it "should remove non-created alerts by clicking delete link" do
    get "/accounts/#{@context.id}/settings"

    find('#tab-alerts-link').click
    wait_for_ajaximations
    find('.add_alert_link').click
    wait_for_ajaximations
    find('.alert.new .delete_link').click
    wait_for_ajaximations
    expect(f("#content")).not_to contain_css(".alert.new")

    expect(@alerts).to be_empty
  end

  it "should remove non-created alerts by clicking cancel button" do
    get "/accounts/#{@context.id}/settings"

    find('#tab-alerts-link').click
    wait_for_ajaximations
    find('.add_alert_link').click
    wait_for_ajaximations
    find('.alert.new .cancel_button').click
    expect(f("#content")).not_to contain_css(".alert.new")
    expect(@alerts).to be_empty
  end

  it "should validate the form" do
    get "/accounts/#{@context.id}/settings"
    find('#tab-alerts-link').click
    wait_for_ajaximations
    find('.add_alert_link').click
    wait_for_ajaximations
    alert = find('.alert.new')
    alert.find('input[name="repetition"][value="value"]').click

    submit_form('#new_alert')
    wait_for_ajaximations
    error_boxes = ff('.error_box')
    expect(error_boxes).to have_size(4)

    # clicking "do not repeat" should remove the number of days error
    alert.find('input[name="repetition"][value="none"]').click
    wait_for_ajaximations
    expect(error_boxes).to have_size(3)

    # adding recipient and criterion make the errors go away
    alert.find('.add_recipient_link').click
    alert.find('.add_criterion_link').click
    expect(error_boxes).to have_size(1)

    alert.find('.criteria input[type="text"]').send_keys("abc")
    submit_form('#new_alert')
    expect(error_boxes).to have_size(2)
  end

  context "recipients" do
    it "should hide the add link when all recipients are added" do
      skip_if_chrome('fragile in chrome')
      get "/accounts/#{@context.id}/settings"

      find('#tab-alerts-link').click
      wait_for_ajaximations
      find('.add_alert_link').click
      wait_for_ajaximations
      alert = find('.alert.new')
      link = alert.find('.add_recipient_link')

      expect(ff('.alert.new .add_recipients_line select option')).to have_size(3)
      alert.find_all('.add_recipients_line select option').each do
        link.click
      end
      wait_for_ajaximations
      expect(f('.add_recipients_line')).not_to contain_link('Recipient')
    end

    it "should not show the add link when all recipients are already there" do
      alert = @alerts.create!(:recipients => [:student, :teachers, {:role_id => admin_role.id}], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
      get "/accounts/#{@context.id}/settings"

      find('#tab-alerts-link').click
      wait_for_ajaximations
      alertElement = find("#edit_alert_#{alert.id}")
      alertElement.find(".edit_link").click
      wait_for_ajaximations
      expect(f("#edit_alert_#{alert.id}")).not_to contain_jqcss(".add_recipient_link:visible")

      # Deleting a recipient should add it to the dropdown (which is now visible)
      alertElement.find('.recipients .delete_item_link').click
      wait_for_ajaximations
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link")).to be_displayed
      expect(alertElement.find_all('.add_recipients_line select option').length).to eq 1
      expect(ff('.recipients li', alertElement)).to have_size(2)

      # Do it again, with the same results
      alertElement.find('.recipients .delete_item_link').click
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link")).to be_displayed
      expect(alertElement.find_all('.add_recipients_line select option').length).to eq 2
      expect(ff('.recipients li', alertElement)).to have_size(1)

      # Clicking cancel should restore the LIs
      alertElement.find('.cancel_button').click
      expect(alertElement.find_all('.recipients li').length).to eq 3
    end

    it "should work with custom roles" do
      role1 = custom_account_role('these rolls are delicious', :account => @context)
      role2 = custom_account_role('your just jelly', :account => @context)

      alert = @alerts.create!(:recipients => [{:role_id => role1.id}], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
      get "/accounts/#{@context.id}/settings"

      find('#tab-alerts-link').click
      wait_for_ajaximations
      alertElement = find("#edit_alert_#{alert.id}")
      alertElement.find(".edit_link").click
      wait_for_ajaximations

      recipients = find_all("#edit_alert_#{alert.id} .recipients li")
      expect(recipients.count).to eq 1
      expect(recipients.first.text).to match_ignoring_whitespace(role1.name)
      expect(find("#edit_alert_#{alert.id} .recipients li input")["value"].to_s).to eq role1.id.to_s

      set_value(find("#edit_alert_#{alert.id} .add_recipients_line select"), role2.id.to_s)
      fj("#edit_alert_#{alert.id} .add_recipient_link").click

      submit_form("#edit_alert_#{alert.id}")
      wait_for_ajaximations

      alert.reload
      expect(alert.recipients.map{|r| r[:role_id]}.sort).to eq [role1.id, role2.id].sort
    end
  end
end
