require_relative '../../helpers/gradezilla_common'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla - permissions" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  context "as an admin" do

    let(:course) { Course.create! }

    it "should display for users with only :view_all_grades permissions" do
      user_logged_in

      role = custom_account_role('CustomAdmin', :account => Account.default)
      RoleOverride.create!(:role => role,
                           :permission => 'view_all_grades',
                           :context => Account.default,
                           :enabled => true)
      AccountUser.create!(:user => @user,
                          :account => Account.default,
                          :role => role)

      gradezilla_page.visit(course)
      expect_no_flash_message :error
    end

    it "should display for users with only :manage_grades permissions" do
      user_logged_in
      role = custom_account_role('CustomAdmin', :account => Account.default)
      RoleOverride.create!(:role => role,
                           :permission => 'manage_grades',
                           :context => Account.default,
                           :enabled => true)
      AccountUser.create!(:user => @user,
                          :account => Account.default,
                          :role => role)

      gradezilla_page.visit(course)
      expect_no_flash_message :error
    end
  end

  context "as a ta" do

    def disable_view_all_grades
      RoleOverride.create!(:role => ta_role,
                            :permission => 'view_all_grades',
                            :context => Account.default,
                            :enabled => false)
    end

    it "should not show gradebook after course conclude if view_all_grades disabled", priority: "1", test_id: 417601 do
      disable_view_all_grades
      concluded_course = course_with_ta_logged_in
      concluded_course.conclude
      gradezilla_page.visit(@course)
      expect(f('#unauthorized_message')).to be_displayed
    end
  end
end
