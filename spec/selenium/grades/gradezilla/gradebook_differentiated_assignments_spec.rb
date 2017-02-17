require_relative '../../helpers/gradezilla_common'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  context "differentiated assignments" do
    before :once do
      gradebook_data_setup
      @da_assignment = assignment_model({
        :course => @course,
        :name => 'DA assignment',
        :points_possible => @assignment_1_points,
        :submission_types => 'online_text_entry',
        :assignment_group => @group,
        :only_visible_to_overrides => true
      })
      @override = create_section_override_for_assignment(@da_assignment, course_section: @other_section)
    end

    before(:each) do
      user_session(@teacher)
    end

    it "should gray out cells" do
      gradezilla_page.visit(@course)
      # student 3, assignment 4
      selector = '#gradebook_grid .container_1 .slick-row:nth-child(3) .l5'
      cell = f(selector)
      expect(cell.find_element(:css, '.gradebook-cell')).to have_class('grayed-out')
      cell.click
      expect(cell).not_to contain_css('.grade')
      # student 2, assignment 4 (not grayed out)
      cell = f('#gradebook_grid .container_1 .slick-row:nth-child(2) .l5')
      expect(cell.find_element(:css, '.gradebook-cell')).not_to have_class('grayed-out')
    end

    it "should gray out cells after removing a score which removes visibility" do
      selector = '#gradebook_grid .container_1 .slick-row:nth-child(1) .l5'
      @da_assignment.grade_student(@student_1, grade: 42, grader: @teacher)
      @override.destroy
      gradezilla_page.visit(@course)
      edit_grade(selector, '')
      cell = f(selector)
      expect(cell.find_element(:css, '.gradebook-cell')).to have_class('grayed-out')
    end
  end
end
