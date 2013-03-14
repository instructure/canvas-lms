require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')

describe "admin_tools" do
  it_should_behave_like "in-process server selenium tests"

  context "View Notifications" do
    before :each do
      setup_users
      @account = Account.default.tap do |a|
        a.settings[:admins_can_view_notifications] = true
        a.save!
      end
    end

    def setup_users
      # Setup a student (@student)
      course_with_student(:active_all => true, :account => @account, :name => 'Student TestUser')
      user_with_pseudonym(:user => @student, :account => @account)

      setup_account_admin
    end

    def setup_account_admin(permissions = {:view_notifications => true})
      # Setup an account admin (@account_admin) and logged in.
      account_admin_user_with_role_changes(:account => @account, :role_changes => permissions)
      @account_admin = @admin
      user_with_pseudonym(:user => @account_admin, :account => @account)
      user_session(@account_admin)
    end

    def load_admin_tools_page
      get "/accounts/#{@account.id}/admin_tools"
      wait_for_ajaximations
    end

    def click_view_notifications_tab
      wait_for_ajaximations
      tab = fj('#adminToolsTabs .notifications > a')
      tab.should_not be_nil
      tab.should be_displayed
      tab.click
      wait_for_ajaximations
    end

    context "as SiteAdmin" do
      it "should perform search without account setting or user permission" do
        @account.settings[:admins_can_view_notifications] = false
        @account.save!
        site_admin_user
        user_with_pseudonym(:user => @admin, :account => @account)
        user_session(@admin)
        message(:user_id => @student.id, :body => 'this is my message', :account_id => @account.id)

        load_admin_tools_page
        click_view_notifications_tab
        set_value f('#userIdSearchField'), @student.id
        f('#notificationsSearchBtn').click
        wait_for_ajaximations
        f('#commMessagesSearchResults .message-body').text.should contain('this is my message')
      end
    end

    context "as AccountAdmin" do
      context "with permissions" do
        it "should perform search" do
          message(:user_id => @student.id)
          load_admin_tools_page
          click_view_notifications_tab
          set_value f('#userIdSearchField'), @student.id
          f('#notificationsSearchBtn').click
          wait_for_ajaximations
          f('#commMessagesSearchResults .message-body').text.should contain('nice body')
        end

        it "should display nothing found" do
          message(:user_id => @student.id)
          load_admin_tools_page
          click_view_notifications_tab
          set_value f('#userIdSearchField'), @student.id
          set_value f('#dateEndSearchField'), 2.months.ago
          f('#notificationsSearchBtn').click
          wait_for_ajaximations
          f('#commMessagesSearchResults .alert').text.should contain('No messages found')
          f('#commMessagesSearchResults .message-body').should be_nil
        end

        it "should display valid search params used" do
          message(:user_id => @student.id)
          load_admin_tools_page
          click_view_notifications_tab
          # Search with no dates
          set_value f('#userIdSearchField'), @student.id
          f('#notificationsSearchBtn').click
          wait_for_ajaximations
          f('#commMessagesSearchOverview').text.should contain("Notifications sent to #{@student.name} from the beginning to now.")
          # Search with begin date and end date - should show time actually being used
          set_value f('#userIdSearchField'), @student.id
          set_value f('#dateStartSearchField'), 'Mar 3, 2001'
          set_value f('#dateEndSearchField'), 'Mar 9, 2001'
          f('#notificationsSearchBtn').click
          wait_for_ajaximations
          f('#commMessagesSearchOverview').text.should contain("Notifications sent to #{@student.name} from Mar 3, 2001 at 12am to Mar 9, 2001 at 12am.")
          # Search with begin date/time and end date/time - should use and show given time
          set_value f('#userIdSearchField'), @student.id
          set_value f('#dateStartSearchField'), 'Mar 3, 2001 1:05p'
          set_value f('#dateEndSearchField'), 'Mar 9, 2001 3p'
          f('#notificationsSearchBtn').click
          wait_for_ajaximations
          f('#commMessagesSearchOverview').text.should contain("Notifications sent to #{@student.name} from Mar 3, 2001 at 1:05pm to Mar 9, 2001 at 3pm.")
        end

        it "should display search params used when given invalid input data" do
          load_admin_tools_page
          click_view_notifications_tab
          set_value f('#userIdSearchField'), @student.id
          # Search with invalid dates
          set_value f('#dateStartSearchField'), 'couch'
          set_value f('#dateEndSearchField'), 'pillow'
          f('#notificationsSearchBtn').click
          wait_for_ajaximations
          f('#commMessagesSearchOverview').text.should contain("Notifications sent to #{@student.name} from the beginning to now.")
        end

        it "should hide tab if account setting disabled" do
          @account.settings[:admins_can_view_notifications] = false
          @account.save!

          load_admin_tools_page
          wait_for_ajaximations
          tab = fj('#adminToolsTabs .notifications > a')
          tab.should be_nil
        end
      end

      context "without permissions" do
        it "should not see tab" do
          setup_account_admin({:view_notifications => false})
          load_admin_tools_page
          wait_for_ajaximations
          tab = fj('#adminToolsTabs .notifications > a')
          tab.should be_nil
        end
      end
    end
  end
end