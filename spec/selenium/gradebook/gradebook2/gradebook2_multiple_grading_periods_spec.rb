require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/groups_common'

describe "gradebook2 - multiple grading periods" do
  include_context "in-process server selenium tests"
  include Gradebook2Common
  include GroupsCommon

  let!(:enable_mgp) do
    course_with_admin_logged_in
    student_in_course
    @course.root_account.enable_feature!(:multiple_grading_periods)
  end

  it "loads gradebook when no grading periods have been created", priority: "1", test_id: 210011 do
    get "/courses/#{@course.id}/gradebook2"
    expect(f('#gradebook-grid-wrapper')).to be_displayed
  end

  context 'with a current and past grading period' do
    let!(:create_period_group_and_default_periods) do
      group = @course.root_account.grading_period_groups.create
      group.grading_periods.create(
        start_date: 4.months.ago,
        end_date:   2.months.ago,
        title: "Period in the Past"
      )
      group.grading_periods.create(
        start_date: 1.month.ago,
        end_date:   2.months.from_now,
        title: "Current Period"
      )
    end

    let(:select_period_in_the_past) do
      f(".grading-period-select-button").click
      f("#ui-id-3").click # The id of the Period in the Past
    end

    let(:sign_in_as_a_teacher) do
      teacher_in_course
      user_session(@teacher)
    end

    let(:uneditable_cells) { f('.cannot_edit') }
    let(:gradebook_header) { f('#gradebook_grid .container_1 .slick-header') }

    context "assignments in past grading periods" do
      let!(:assignment_in_the_past) do
        @course.assignments.create!(
          due_at: 3.months.ago,
          title: "past-due assignment"
        )
      end

      it "admins should be able to edit", priority: "1", test_id: 210012 do
        get "/courses/#{@course.id}/gradebook2"

        select_period_in_the_past
        expect(gradebook_header).to include_text("past-due assignment")
        expect(uneditable_cells).to_not be_present
      end

      it "teachers should not be able to edit", priority: "1", test_id: 210023 do
        sign_in_as_a_teacher

        get "/courses/#{@course.id}/gradebook2"

        select_period_in_the_past
        expect(gradebook_header).to include_text("past-due assignment")
        expect(uneditable_cells).to be_present
      end
    end

    context "assignments with no due_at" do
      let!(:assignment_without_due_at) do
        @course.assignments.create! title: "No Due Date"
      end

      it "admins should be able to edit", priority: "1", test_id: 210014 do
        get "/courses/#{@course.id}/gradebook2"

        expect(gradebook_header).to include_text("No Due Date")
        expect(uneditable_cells).to_not be_present
      end

      it "teachers should be able to edit", priority: "1", test_id: 210015 do
        sign_in_as_a_teacher

        get "/courses/#{@course.id}/gradebook2"

        expect(gradebook_header).to include_text("No Due Date")
        expect(uneditable_cells).to_not be_present
      end
    end
  end
end
