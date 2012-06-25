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

    driver.find_element(:css, '#tab-alerts-link').click
    driver.find_element(:css, '.add_alert_link').click
    wait_for_animations
    alert = driver.find_element(:css, '.alert.new')
    (add_criterion = alert.find_element(:css, '.add_criterion_link')).click
    wait_for_animations
    alert.find_element(:css, '.add_recipient_link').click
    wait_for_animations
    (submit = alert.find_element(:css, '.submit_button')).click
    wait_for_animations
    wait_for_ajax_requests

    keep_trying_until{
      @alerts.reload
      @alerts.length.should == 1
    }
    @alerts.first.criteria.length.should == 1

    wait_for_animations
    (edit = alert.find_element(:css, '.edit_link')).click
    add_criterion.click
    wait_for_animations
    submit.click
    wait_for_animations
    wait_for_ajax_requests

    keep_trying_until{
      @alerts.first.criteria.reload
      @alerts.first.criteria.length.should == 2
    }
    @alerts.reload
    @alerts.length.should == 1

    wait_for_animations
    edit.click
    alert.find_element(:css, '.criteria .delete_item_link').click
    wait_for_animations
    keep_trying_until { find_all_with_jquery('.alert .criteria li').length == 1 }
    submit.click

    keep_trying_until{
      @alerts.first.criteria.reload
      @alerts.first.criteria.length.should == 1
    }
    @alerts.reload
    @alerts.length.should == 1

    wait_for_animations
    alert.find_element(:css, '.delete_link img').click

    wait_for_ajaximations
    driver.find_element(:css, '.alert').should_not be_displayed

    keep_trying_until{
      @alerts.reload
      @alerts.length.should == 0
    }
  end

  it "should delete alerts" do
    alert = @alerts.create!(:recipients => [:student], :criteria => [:criterion_type => 'Interaction', :threshold => 7])
    get "/accounts/#{@context.id}/settings"

    driver.find_element(:css, '#tab-alerts-link').click
    driver.find_element(:css, "#edit_alert_#{alert.id} .delete_link").click
    keep_trying_until { find_with_jquery("#edit_alert_#{alert.id}").blank? }

    @alerts.reload
    @alerts.should be_empty
  end

  it "should remove non-created alerts by clicking delete link" do
    get "/accounts/#{@context.id}/settings"

    driver.find_element(:css, '#tab-alerts-link').click
    wait_for_ajax_requests
    driver.find_element(:css, '.add_alert_link').click
    wait_for_animations
    driver.find_element(:css, '.alert.new .delete_link').click
    wait_for_animations
    keep_trying_until { driver.find_elements(:css, ".alert.new").should be_empty }

    @alerts.should be_empty
  end

  it "should remove non-created alerts by clicking cancel button" do
    get "/accounts/#{@context.id}/settings"

    driver.find_element(:css, '#tab-alerts-link').click
    driver.find_element(:css, '.add_alert_link').click
    wait_for_animations
    driver.find_element(:css, '.alert.new .cancel_button').click
    wait_for_animations
    keep_trying_until { find_all_with_jquery(".alert.new").should be_empty }
    @alerts.should be_empty
  end

  context "recipients" do
    it "should hide the add link when all recipients are added" do
      get "/accounts/#{@context.id}/settings"

      driver.find_element(:css, '#tab-alerts-link').click
      driver.find_element(:css, '.add_alert_link').click
      alert = driver.find_element(:css, '.alert.new')
      link = alert.find_element(:css, '.add_recipient_link')

      keep_trying_until { find_all_with_jquery('.alert.new .add_recipients_line select option').length > 1 }
      for i in 1..alert.find_elements(:css, '.add_recipients_line select option').length do
        link.click
        wait_for_animations
      end
      driver.find_element(:css, '.alert.new .add_recipient_link').should_not be_displayed
    end

    it "should not show the add link when all recipients are already there" do
      alert = @alerts.create!(:recipients => [:student, :teachers, 'AccountAdmin'], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
      get "/accounts/#{@context.id}/settings"

      driver.find_element(:css, '#tab-alerts-link').click
      alertElement = driver.find_element(:css, "#edit_alert_#{alert.id}")
      alertElement.find_element(:css, ".edit_link").click
      find_with_jquery("#edit_alert_#{alert.id} .add_recipient_link:visible").should be_blank

      # Deleting a recipient should add it to the dropdown (which is now visible)
      alertElement.find_element(:css, '.recipients .delete_item_link').click
      wait_for_animations
      find_with_jquery("#edit_alert_#{alert.id} .add_recipient_link").should be_displayed
      alertElement.find_elements(:css, '.add_recipients_line select option').length.should == 1
      keep_trying_until { alertElement.find_elements(:css, '.recipients li').length == 2 }

      # Do it again, with the same results
      alertElement.find_element(:css, '.recipients .delete_item_link').click
      find_with_jquery("#edit_alert_#{alert.id} .add_recipient_link").should be_displayed
      alertElement.find_elements(:css, '.add_recipients_line select option').length.should == 2
      keep_trying_until { alertElement.find_elements(:css, '.recipients li').length == 1 }

      # Clicking cancel should restore the LIs
      alertElement.find_element(:css, '.cancel_button').click
      alertElement.find_elements(:css, '.recipients li').length.should == 3
    end
  end

  it "should validate the form" do
    get "/accounts/#{@context.id}/settings"
    driver.find_element(:css, '#tab-alerts-link').click
    driver.find_element(:css, '.add_alert_link').click
    alert = driver.find_element(:css, '.alert.new')
    alert.find_element(:css, 'input[name="repetition"][value="value"]').click
    sleep 2 #need to wait for javascript to process
    keep_trying_until do
      submit_form('#new_alert')
      wait_for_animations
      find_all_with_jquery('.error_box').length == 4
    end

    # clicking "do not repeat" should remove the number of days error
    alert.find_element(:css, 'input[name="repetition"][value="none"]').click
    keep_trying_until { find_all_with_jquery('.error_box').length == 3 }

    # adding recipients and criterion make the errors go away
    alert.find_element(:css, '.add_recipient_link').click
    alert.find_element(:css, '.add_criterion_link').click
    keep_trying_until { find_all_with_jquery('.error_box').length == 1 }

    alert.find_element(:css, '.criteria input[type="text"]').send_keys("abc")
    submit_form('#new_alert')
    keep_trying_until { find_all_with_jquery('.error_box').length == 2 }
  end
end
