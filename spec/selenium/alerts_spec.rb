require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Alerts" do
  include_context "in-process server selenium tests"

  before (:each) do
    @context = Account.default
    @context.settings[:enable_alerts] = true
    @context.save!
    @alerts = @context.alerts
    admin_logged_in
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
    wait_for_ajaximations
    keep_trying_until { ffj('.alert .criteria li').length == 1 }
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
    wait_for_ajaximations
    keep_trying_until { fj("#edit_alert_#{alert.id}").blank? }

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
    keep_trying_until { expect(find_all(".alert.new")).to be_empty }

    expect(@alerts).to be_empty
  end

  it "should remove non-created alerts by clicking cancel button" do
    get "/accounts/#{@context.id}/settings"

    find('#tab-alerts-link').click
    wait_for_ajaximations
    find('.add_alert_link').click
    wait_for_ajaximations
    find('.alert.new .cancel_button').click
    wait_for_ajaximations
    keep_trying_until { expect(ffj(".alert.new")).to be_empty }
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
    sleep 2 #need to wait for javascript to process
    wait_for_ajaximations
    keep_trying_until do
      submit_form('#new_alert')
      wait_for_ajaximations
      ffj('.error_box').length == 4
    end

    # clicking "do not repeat" should remove the number of days error
    alert.find('input[name="repetition"][value="none"]').click
    wait_for_ajaximations
    keep_trying_until { ffj('.error_box').length == 3 }

    # adding recipient and criterion make the errors go away
    alert.find('.add_recipient_link').click
    alert.find('.add_criterion_link').click
    keep_trying_until { ffj('.error_box').length == 1 }

    alert.find('.criteria input[type="text"]').send_keys("abc")
    submit_form('#new_alert')
    keep_trying_until { ffj('.error_box').length == 2 }
  end

  context "recipients" do
    it "should hide the add link when all recipients are added" do
      get "/accounts/#{@context.id}/settings"

      find('#tab-alerts-link').click
      wait_for_ajaximations
      find('.add_alert_link').click
      wait_for_ajaximations
      alert = find('.alert.new')
      link = alert.find('.add_recipient_link')

      keep_trying_until { ffj('.alert.new .add_recipients_line select option').length > 1 }
      alert.find_all('.add_recipients_line select option').each do
        link.click
        wait_for_ajaximations
      end
      expect(find('.alert.new .add_recipient_link')).not_to be_displayed
    end

    it "should not show the add link when all recipients are already there" do
      alert = @alerts.create!(:recipients => [:student, :teachers, {:role_id => admin_role.id}], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
      get "/accounts/#{@context.id}/settings"

      find('#tab-alerts-link').click
      wait_for_ajaximations
      alertElement = find("#edit_alert_#{alert.id}")
      alertElement.find(".edit_link").click
      wait_for_ajaximations
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link:visible")).to be_blank

      # Deleting a recipient should add it to the dropdown (which is now visible)
      alertElement.find('.recipients .delete_item_link').click
      wait_for_ajaximations
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link")).to be_displayed
      expect(alertElement.find_all('.add_recipients_line select option').length).to eq 1
      keep_trying_until { alertElement.find_all('.recipients li').length == 2 }

      # Do it again, with the same results
      alertElement.find('.recipients .delete_item_link').click
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link")).to be_displayed
      expect(alertElement.find_all('.add_recipients_line select option').length).to eq 2
      keep_trying_until { alertElement.find_all('.recipients li').length == 1 }

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
