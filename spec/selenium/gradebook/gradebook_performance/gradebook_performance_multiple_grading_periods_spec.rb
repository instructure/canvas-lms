require_relative '../../helpers/gradebook2_common'

describe "gradebook performance" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let(:uneditable_cells) { '.cannot_edit' }
  let(:gradebook_headers) { ff('#gradebook_grid .gradebook-header-column') }
  let(:header_titles) { gradebook_headers.map { |header| header.attribute('title') } }

  describe "multiple grading periods" do
    let!(:enable_mgp_and_gradebook_performance) do
      course_with_admin_logged_in
      student_in_course
      @course.root_account.enable_feature!(:multiple_grading_periods)
      @course.root_account.enable_feature!(:gradebook_performance)
    end

    it "loads gradebook when no grading periods have been created" do
      get "/courses/#{@course.id}/gradebook"
      wait_for_ajax_requests
      expect(f('#react-gradebook-canvas')).to be_displayed
    end

    describe 'with a current and past grading period' do
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
        f("#ui-id-2").click # The id of the Period in the Past
      end

      let(:sign_in_as_a_teacher) do
        teacher_in_course
        user_session(@teacher)
      end


      context "assignments in past grading periods" do
        let!(:assignment_in_the_past) do
          @course.assignments.create!(
            due_at: 3.months.ago,
            title: "past-due assignment"
          )
        end

        it "admins can edit" do
          get "/courses/#{@course.id}/gradebook"

          select_period_in_the_past
          expect(header_titles).to include 'past-due assignment'
          expect(f("#content")).not_to contain_css(uneditable_cells)
        end

        it "teachers cannot edit" do
          pending "WIP: still in development"
          sign_in_as_a_teacher

          get "/courses/#{@course.id}/gradebook"

          select_period_in_the_past
          expect(header_titles).to include 'past-due assignment'
          expect(f("#content")).to contain_css(uneditable_cells)
        end
      end

      context "assignments with no due_at" do
        let!(:assignment_without_due_at) do
          @course.assignments.create! title: "No Due Date"
        end

        it "admins can edit" do
          get "/courses/#{@course.id}/gradebook"

          expect(header_titles).to include "No Due Date"
          expect(f("#content")).not_to contain_css(uneditable_cells)
        end

        it "teachers can edit" do
          sign_in_as_a_teacher

          get "/courses/#{@course.id}/gradebook"

          expect(header_titles).to include "No Due Date"
          expect(f("#content")).not_to contain_css(uneditable_cells)
        end
      end
    end
  end
end
