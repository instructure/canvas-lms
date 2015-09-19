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

    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    alert = f('.alert.new')
    (add_criterion = alert.f('.add_criterion_link')).click
    wait_for_ajaximations
    alert.f('.add_recipient_link').click
    wait_for_ajaximations
    (submit = alert.f('.submit_button')).click
    wait_for_ajaximations
    keep_trying_until do
      @alerts.reload
      expect(@alerts.length).to eq 1
    end

    expect(@alerts.first.criteria.length).to eq 1

    (edit = alert.f('.edit_link')).click
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
    alert.f('.criteria .delete_item_link').click
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
    alert.f('.delete_link').click

    wait_for_ajaximations
    expect(f('.alert')).not_to be_displayed

    keep_trying_until do
      @alerts.reload
      expect(@alerts.length).to eq 0
    end
  end

  it "should delete alerts" do
    alert = @alerts.create!(:recipients => [:student], :criteria => [:criterion_type => 'Interaction', :threshold => 7])
    get "/accounts/#{@context.id}/settings"

    f('#tab-alerts-link').click
    wait_for_ajaximations
    f("#edit_alert_#{alert.id} .delete_link").click
    wait_for_ajaximations
    keep_trying_until { fj("#edit_alert_#{alert.id}").blank? }

    @alerts.reload
    expect(@alerts).to be_empty
  end

  it "should remove non-created alerts by clicking delete link" do
    get "/accounts/#{@context.id}/settings"

    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    f('.alert.new .delete_link').click
    wait_for_ajaximations
    keep_trying_until { expect(ff(".alert.new")).to be_empty }

    expect(@alerts).to be_empty
  end

  it "should remove non-created alerts by clicking cancel button" do
    get "/accounts/#{@context.id}/settings"

    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    f('.alert.new .cancel_button').click
    wait_for_ajaximations
    keep_trying_until { expect(ffj(".alert.new")).to be_empty }
    expect(@alerts).to be_empty
  end

  it "should validate the form" do
    get "/accounts/#{@context.id}/settings"
    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    alert = f('.alert.new')
    alert.f('input[name="repetition"][value="value"]').click
    sleep 2 #need to wait for javascript to process
    wait_for_ajaximations
    keep_trying_until do
      submit_form('#new_alert')
      wait_for_ajaximations
      ffj('.error_box').length == 4
    end

    # clicking "do not repeat" should remove the number of days error
    alert.f('input[name="repetition"][value="none"]').click
    wait_for_ajaximations
    keep_trying_until { ffj('.error_box').length == 3 }

    # adding recipient and criterion make the errors go away
    alert.f('.add_recipient_link').click
    alert.f('.add_criterion_link').click
    keep_trying_until { ffj('.error_box').length == 1 }

    alert.f('.criteria input[type="text"]').send_keys("abc")
    submit_form('#new_alert')
    keep_trying_until { ffj('.error_box').length == 2 }
  end

  context "recipients" do
    it "should hide the add link when all recipients are added" do
      get "/accounts/#{@context.id}/settings"

      f('#tab-alerts-link').click
      wait_for_ajaximations
      f('.add_alert_link').click
      wait_for_ajaximations
      alert = f('.alert.new')
      link = alert.f('.add_recipient_link')

      keep_trying_until { ffj('.alert.new .add_recipients_line select option').length > 1 }
      alert.ff('.add_recipients_line select option').each do
        link.click
        wait_for_ajaximations
      end
      expect(f('.alert.new .add_recipient_link')).not_to be_displayed
    end

    it "should not show the add link when all recipients are already there" do
      alert = @alerts.create!(:recipients => [:student, :teachers, {:role_id => admin_role.id}], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
      get "/accounts/#{@context.id}/settings"

      f('#tab-alerts-link').click
      wait_for_ajaximations
      alertElement = f("#edit_alert_#{alert.id}")
      alertElement.f(".edit_link").click
      wait_for_ajaximations
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link:visible")).to be_blank

      # Deleting a recipient should add it to the dropdown (which is now visible)
      alertElement.f('.recipients .delete_item_link').click
      wait_for_ajaximations
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link")).to be_displayed
      expect(alertElement.ff('.add_recipients_line select option').length).to eq 1
      keep_trying_until { alertElement.ff('.recipients li').length == 2 }

      # Do it again, with the same results
      alertElement.f('.recipients .delete_item_link').click
      expect(fj("#edit_alert_#{alert.id} .add_recipient_link")).to be_displayed
      expect(alertElement.ff('.add_recipients_line select option').length).to eq 2
      keep_trying_until { alertElement.ff('.recipients li').length == 1 }

      # Clicking cancel should restore the LIs
      alertElement.f('.cancel_button').click
      expect(alertElement.ff('.recipients li').length).to eq 3
    end

    it "should work with custom roles" do
      role1 = custom_account_role('these rolls are delicious', :account => @context)
      role2 = custom_account_role('your just jelly', :account => @context)

      alert = @alerts.create!(:recipients => [{:role_id => role1.id}], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
      get "/accounts/#{@context.id}/settings"

      f('#tab-alerts-link').click
      wait_for_ajaximations
      alertElement = f("#edit_alert_#{alert.id}")
      alertElement.f(".edit_link").click
      wait_for_ajaximations

      recipients = ff("#edit_alert_#{alert.id} .recipients li")
      expect(recipients.count).to eq 1
      expect(recipients.first.text).to match_ignoring_whitespace(role1.name)
      expect(f("#edit_alert_#{alert.id} .recipients li input")["value"].to_s).to eq role1.id.to_s

      set_value(f("#edit_alert_#{alert.id} .add_recipients_line select"), role2.id.to_s)
      fj("#edit_alert_#{alert.id} .add_recipient_link").click

      submit_form("#edit_alert_#{alert.id}")
      wait_for_ajaximations

      alert.reload
      expect(alert.recipients.map{|r| r[:role_id]}.sort).to eq [role1.id, role2.id].sort
    end
  end
end
