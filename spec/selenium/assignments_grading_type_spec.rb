require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "assignments" do
  include_examples "in-process server selenium tests"

  def point_validation
    assignment_name = 'first test assignment'
    @assignment = @course.assignments.create({
                    :name => assignment_name,
                    :assignment_group => @course.assignment_groups.create!(:name => "default")
                  })

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
    yield if block_given?
    f('.btn-primary[type=submit]').click
    wait_for_ajaximations
    expect(fj('.error_text div').text).to eq "Points possible must be more than 0 for selected grading type"
  end

  before(:each) do
      course_with_teacher_logged_in(:draft_state => true)
      set_course_draft_state
  end

  %w(points percent pass_fail letter_grade gpa_scale).each do |grading_option|
    it "should create assignment with #{grading_option} grading option" do
      assignment_title = 'grading options assignment'
      manually_create_assignment(assignment_title)
      wait_for_ajaximations
      click_option('#assignment_grading_type', grading_option, :value)
      if grading_option == "percent"
        replace_content f('#assignment_points_possible'), ('1')
      end
      click_option('#assignment_submission_type', 'No Submission')
      assignment_points_possible = f("#assignment_points_possible")
      replace_content(assignment_points_possible, "5")
      submit_assignment_form
      expect(f('.title')).to include_text(assignment_title)
      expect(Assignment.find_by_title(assignment_title).grading_type).to eq grading_option
    end
  end

  it "should validate points for percentage grading (> 0)" do
    point_validation {
      click_option('#assignment_grading_type', 'Percentage')
    }
  end

  it "should validate points for percentage grading (!= '')" do
    point_validation {
      click_option('#assignment_grading_type', 'Percentage')
      replace_content f('#assignment_points_possible'), ('')
    }
  end

  it "should validate points for percentage grading (digits only)" do
    point_validation {
      click_option('#assignment_grading_type', 'Percentage')
      replace_content f('#assignment_points_possible'), ('taco')
    }
  end

  it "should validate points for letter grading (> 0)" do
    point_validation {
      click_option('#assignment_grading_type', 'Letter Grade')
    }
  end

  it "should validate points for letter grading (!= '')" do
    point_validation {
      click_option('#assignment_grading_type', 'Letter Grade')
      replace_content f('#assignment_points_possible'), ('')
    }
  end

  it "should validate points for letter grading (digits only)" do
    point_validation {
      click_option('#assignment_grading_type', 'Letter Grade')
      replace_content f('#assignment_points_possible'), ('taco')
    }
  end

  it "should validate points for GPA scale grading (> 0)" do
    point_validation {
      click_option('#assignment_grading_type', 'GPA Scale')
    }
  end

  it "should validate points for GPA scale grading (!= '')" do
    point_validation {
      click_option('#assignment_grading_type', 'GPA Scale')
      replace_content f('#assignment_points_possible'), ('')
    }
  end

  it "should validate points for GPA scale grading (digits only)" do
    point_validation {
      click_option('#assignment_grading_type', 'GPA Scale')
      replace_content f('#assignment_points_possible'), ('taco')
    }
  end
end