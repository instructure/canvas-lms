require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context modules" do
  include_examples "in-process server selenium tests"
  context "progressions", :priority => "1" do
    before :each do
      course_with_teacher_logged_in

      @module1 = @course.context_modules.create!(:name => "module1")
      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
      @assignment.publish
      @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
      @external_url_tag = @module1.add_item(:type => 'external_url', :url => 'http://example.com/lolcats',
                                            :title => 'pls view', :indent => 1)
      @external_url_tag.publish
      @module1.completion_requirements = {
          @assignment_tag.id => {:type => 'must_submit'},
          @external_url_tag.id => {:type => 'must_view'}}
      @module1.save!

      @christmas = Time.zone.local(Time.zone.now.year + 1, 12, 25, 7, 0)
      @module2 = @course.context_modules.create!(:name => "do not open until christmas",
                                                 :unlock_at => @christmas,
                                                 :require_sequential_progress => true)
      @module2.prerequisites = "module_#{@module1.id}"
      @module2.save!

      @module3 = @course.context_modules.create(:name => "module3")
      @module3.workflow_state = 'unpublished'
      @module3.save!

      @students = []
      4.times do |i|
        student = User.create!(:name => "hello student #{i}")
        @course.enroll_student(student).accept!
        @students << student
      end

      # complete for student 0
      @assignment.submit_homework(@students[0], :body => "done!")
      @external_url_tag.context_module_action(@students[0], :read)
      # in progress for student 1-2
      @assignment.submit_homework(@students[1], :body => "done!")
      @external_url_tag.context_module_action(@students[2], :read)
      # unlocked for student 3
    end

    it "should show student progressions to teachers" do
      get "/courses/#{@course.id}/modules/progressions"

      expect(f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text).to include("Complete")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text).to include("Locked")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module3.id}")).to be_nil

      f("#progression_student_#{@students[1].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).not_to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text).to include("Locked")

      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).not_to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text).to include("Locked")

      f("#progression_student_#{@students[3].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[3].id}_module_#{@module1.id} .status").text).to include("Unlocked")
      expect(f("#progression_student_#{@students[3].id}_module_#{@module2.id} .status").text).to include("Locked")
    end

    it "should show progression to individual students" do
      user_session(@students[1])
      get "/courses/#{@course.id}/modules/progressions"
      expect(f("#progression_students")).not_to be_displayed
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).not_to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text).to include("Locked")
    end

    it "should show multiple student progressions to observers" do
      @observer = user
      @course.enroll_user(@observer, 'ObserverEnrollment', {:allow_multiple_enrollments => true,
                                                            :associated_user_id => @students[0].id})
      @course.enroll_user(@observer, 'ObserverEnrollment', {:allow_multiple_enrollments => true,
                                                            :associated_user_id => @students[2].id})

      user_session(@observer)

      get "/courses/#{@course.id}/modules/progressions"

      expect(f("#progression_student_#{@students[1].id}")).to be_nil
      expect(f("#progression_student_#{@students[3].id}")).to be_nil
      expect(f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text).to include("Complete")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text).to include("Locked")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module3.id}")).to be_nil
      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).not_to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text).to include("Locked")
    end
  end

  context "progression link", :priority => "2" do
    before(:each) do
      course_with_teacher_logged_in
    end

    it "should show progressions link in modules home page" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.save!
      get "/courses/#{@course.id}"
      link = f('.module_progressions_link')
      expect(link).to be_displayed
      expect_new_page_load { link.click }
    end

    it "should not show progressions link in modules home page for large rosters (MOOCs)" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.large_roster = true
      @course.save!
      get "/courses/#{@course.id}"
      expect(f('.module_progressions_link')).to be_nil
    end
  end
end