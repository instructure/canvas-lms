require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Alerts" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    @context = Account.default
    @context.settings[:enable_alerts] = true
    @context.save!
    @alerts = @context.alerts
    admin_logged_in
  end

  it "should be able to create, then update, then delete" do
    get "/accounts/#{@context.id}/settings"
    @alerts.length.should == 0

    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    alert = f('.alert.new')
    (add_criterion = alert.find_element(:css, '.add_criterion_link')).click
    wait_for_ajaximations
    alert.find_element(:css, '.add_recipient_link').click
    wait_for_ajaximations
    (submit = alert.find_element(:css, '.submit_button')).click
    wait_for_ajaximations
    keep_trying_until do
      @alerts.reload
      @alerts.length.should == 1
    end

    @alerts.first.criteria.length.should == 1

    (edit = alert.find_element(:css, '.edit_link')).click
    add_criterion.click
    wait_for_ajaximations
    submit.click
    wait_for_ajaximations

    keep_trying_until do
      @alerts.first.criteria.reload
      @alerts.first.criteria.length.should == 2
    end

    @alerts.reload
    @alerts.length.should == 1

    wait_for_ajaximations
    edit.click
    alert.find_element(:css, '.criteria .delete_item_link').click
    wait_for_ajaximations
    keep_trying_until { ffj('.alert .criteria li').length == 1 }
    submit.click
    wait_for_ajaximations

    keep_trying_until do
      @alerts.first.criteria.reload
      @alerts.first.criteria.length.should == 1
    end

    @alerts.reload
    @alerts.length.should == 1

    wait_for_ajaximations
    alert.find_element(:css, '.delete_link').click

    wait_for_ajaximations
    f('.alert').should_not be_displayed

    keep_trying_until do
      @alerts.reload
      @alerts.length.should == 0
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
    @alerts.should be_empty
  end

  it "should remove non-created alerts by clicking delete link" do
    get "/accounts/#{@context.id}/settings"

    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    f('.alert.new .delete_link').click
    wait_for_ajaximations
    keep_trying_until { ff(".alert.new").should be_empty }

    @alerts.should be_empty
  end

  it "should remove non-created alerts by clicking cancel button" do
    get "/accounts/#{@context.id}/settings"

    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    f('.alert.new .cancel_button').click
    wait_for_ajaximations
    keep_trying_until { ffj(".alert.new").should be_empty }
    @alerts.should be_empty
  end

  it "should validate the form" do
    get "/accounts/#{@context.id}/settings"
    f('#tab-alerts-link').click
    wait_for_ajaximations
    f('.add_alert_link').click
    wait_for_ajaximations
    alert = f('.alert.new')
    alert.find_element(:css, 'input[name="repetition"][value="value"]').click
    sleep 2 #need to wait for javascript to process
    wait_for_ajaximations
    keep_trying_until do
      submit_form('#new_alert')
      wait_for_ajaximations
      ffj('.error_box').length == 4
    end

    # clicking "do not repeat" should remove the number of days error
    alert.find_element(:css, 'input[name="repetition"][value="none"]').click
    wait_for_ajaximations
    keep_trying_until { ffj('.error_box').length == 3 }

    # adding recipient and criterion make the errors go away
    alert.find_element(:css, '.add_recipient_link').click
    alert.find_element(:css, '.add_criterion_link').click
    keep_trying_until { ffj('.error_box').length == 1 }

    alert.find_element(:css, '.criteria input[type="text"]').send_keys("abc")
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
      link = alert.find_element(:css, '.add_recipient_link')

      keep_trying_until { ffj('.alert.new .add_recipients_line select option').length > 1 }
      for i in 1..alert.find_elements(:css, '.add_recipients_line select option').length do
        link.click
        wait_for_ajaximations
      end
      f('.alert.new .add_recipient_link').should_not be_displayed
    end

    it "should not show the add link when all recipients are already there" do
      alert = @alerts.create!(:recipients => [:student, :teachers, 'AccountAdmin'], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
      get "/accounts/#{@context.id}/settings"

      f('#tab-alerts-link').click
      wait_for_ajaximations
      alertElement = f("#edit_alert_#{alert.id}")
      alertElement.find_element(:css, ".edit_link").click
      wait_for_ajaximations
      fj("#edit_alert_#{alert.id} .add_recipient_link:visible").should be_blank

      # Deleting a recipient should add it to the dropdown (which is now visible)
      alertElement.find_element(:css, '.recipients .delete_item_link').click
      wait_for_ajaximations
      fj("#edit_alert_#{alert.id} .add_recipient_link").should be_displayed
      alertElement.find_elements(:css, '.add_recipients_line select option').length.should == 1
      keep_trying_until { alertElement.find_elements(:css, '.recipients li').length == 2 }

      # Do it again, with the same results
      alertElement.find_element(:css, '.recipients .delete_item_link').click
      fj("#edit_alert_#{alert.id} .add_recipient_link").should be_displayed
      alertElement.find_elements(:css, '.add_recipients_line select option').length.should == 2
      keep_trying_until { alertElement.find_elements(:css, '.recipients li').length == 1 }

      # Clicking cancel should restore the LIs
      alertElement.find_element(:css, '.cancel_button').click
      alertElement.find_elements(:css, '.recipients li').length.should == 3
    end
  end
end
