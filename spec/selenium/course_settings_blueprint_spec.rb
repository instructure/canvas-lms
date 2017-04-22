require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings/blueprint" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature! :master_courses
    account_admin_user
    course_factory :active_all => true
  end

  describe "as admin" do
    before :each do
      user_session @admin
    end

    it "enables blueprint course and sets default restrictions" do
      get "/courses/#{@course.id}/settings"
      expect(f('#master_course_restrictions')).not_to be_displayed

      f('label[for="course_blueprint"]').click
      wait_for_animations
      expect(f('#master_course_restrictions')).to be_displayed
      expect(f('#course_blueprint_restrictions_content')).to be_disabled
      expect(is_checked('#course_blueprint_restrictions_content')).to be
      expect(is_checked('#course_blueprint_restrictions_points')).not_to be
      expect(is_checked('#course_blueprint_restrictions_due_dates')).not_to be
      expect(is_checked('#course_blueprint_restrictions_availability_dates')).not_to be

      f('label[for="course_blueprint_restrictions_points"]').click
      f('label[for="course_blueprint_restrictions_due_dates"]').click
      f('label[for="course_blueprint_restrictions_availability_dates"]').click
      expect_new_page_load { submit_form('#course_form') }

      expect(f('#master_course_restrictions')).to be_displayed
      expect(is_checked('#course_blueprint_restrictions_points')).to be
      expect(is_checked('#course_blueprint_restrictions_due_dates')).to be
      expect(is_checked('#course_blueprint_restrictions_availability_dates')).to be

      expect(MasterCourses::MasterTemplate.full_template_for(@course).default_restrictions).to eq(
        { :content => true, :points => true, :due_dates => true, :availability_dates => true }
      )
    end

    it "disables blueprint course and hides restrictions" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.default_restrictions = { :content => true, :due_dates => true }
      template.save!

      get "/courses/#{@course.id}/settings"

      expect(f('#master_course_restrictions')).to be_displayed
      expect(is_checked('#course_blueprint_restrictions_points')).not_to be
      expect(is_checked('#course_blueprint_restrictions_due_dates')).to be
      expect(is_checked('#course_blueprint_restrictions_availability_dates')).not_to be

      f('label[for="course_blueprint"]').click
      wait_for_animations
      expect_new_page_load { submit_form('#course_form') }

      expect(f('#master_course_restrictions')).not_to be_displayed
      # should still be checked even though it's not visible
      expect(is_checked('#course_blueprint_restrictions_due_dates')).to be

      expect(template.reload).to be_deleted
    end
  end

  describe "as teacher" do
    before :each do
      user_session @teacher
    end

    it "shows No instead of a checkbox for normal courses" do
      get "/courses/#{@course.id}/settings"
      expect(f('#course_blueprint').text).to include 'No'
    end

    it "shows Yes instead of a checkbox for blueprint courses" do
      MasterCourses::MasterTemplate.set_as_master_course(@course)
      get "/courses/#{@course.id}/settings"
      expect(f('#course_blueprint').text).to include 'Yes'
    end

  end
end
