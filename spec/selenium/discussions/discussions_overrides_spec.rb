require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe "discussions overrides" do
  include AssignmentOverridesSeleniumHelper
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @new_section = @course.course_sections.create!(name: 'New Section')
    @assignment = @course.assignments.create!(name: 'assignment', assignment_group: @assignment_group)
    @discussion_topic = @course.discussion_topics.create!(user: @teacher,
                                                         title: 'Discussion 1',
                                                         message: 'Discussion with multiple due dates',
                                                         assignment: @assignment)
  end

  it "should add multiple due dates", priority: "2", test_id: 58763 do
    get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}"
    expect_new_page_load{f('.edit-btn').click}
    expect(f('.ic-token-label')).to include_text('Everyone')
    assign_dates_for_first_override_section
    f('#add_due_date').click
    wait_for_ajaximations
    select_last_override_section(@new_section.name)
    assign_dates_for_last_override_section
    expect_new_page_load { f('.form-actions button[type=submit]').click }
    expect(f('.discussion-title').text).to include('This is a graded discussion: 0 points possible')
  end

  describe "set overrides" do
    before do
      default_due_at = Time.zone.now.advance(days:1).round
      override_due_at = Time.zone.now.advance(days:2).round
      @assignment.due_at = default_due_at
      add_user_specific_due_date_override(@assignment, due_at: override_due_at, section: @new_section)
      @discussion_topic.save!
      @default_due_at_time = default_due_at.strftime('%b %-d at %-l:%M') << default_due_at.strftime('%p').downcase
      @override_due_at_time = override_due_at.strftime('%b %-d at %-l:%M') << override_due_at.strftime('%p').downcase
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}"
    end

    it "should toggle between due dates", priority: "2", test_id: 114317 do
      f(' .toggle_due_dates').click
      wait_for_ajaximations
      expect(f('.discussion-topic-due-dates')).to be_present
      expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(1)').text).to include(@default_due_at_time)
      expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(2)').text).to include('Everyone else')
      expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(1)').text).
                                                                                     to include(@override_due_at_time)
      expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(2)').text).to include('New Section')
      f('.toggle_due_dates').click
      wait_for_ajaximations
      expect(f('.discussion-topic-due-dates')).to be_present
    end

    it "should not show the add due date button after the last available section is selected", priority: "2", test_id: 114319 do
      skip('Example skipped due to an issue in the assignment add button for due dates')
      @new_section_1 = @course.course_sections.create!(name: 'Additional Section')
      expect_new_page_load{f('.edit-btn').click}
      f('#add_due_date').click
      wait_for_ajaximations
      select_last_override_section(@new_section_1.name)
      assign_dates_for_last_override_section
      expect(f('#add_due_date')).not_to be_present
    end

    it "should allow to not set due dates for everyone", priority: "2", test_id: 114320 do
      expect_new_page_load{f('.edit-btn').click}
      f('#bordered-wrapper .Container__DueDateRow-item:nth-of-type(2) button[title = "Remove These Dates"]').click
      f('.form-actions button[type=submit]').click
      wait_for_ajaximations
      expect(f('.ui-dialog')).to be_present
      expect(f('#ui-id-7').text).to include('Do you want to go back and select a due date?')
      f('.ui-dialog .ui-dialog-buttonset .btn-primary').click
      wait_for_ajaximations
      f('.toggle_due_dates').click
      wait_for_ajaximations
      # The toggle dates does not show the due date for everyone else
      expect(f('.discussion-topic-due-dates')).to be_present
      expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(1)').text).to include(@override_due_at_time)
      expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(2)').text).to include('New Section')
      expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(1)').text).
                                                                                    not_to include(@default_due_at_time)
      expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(2)').text).
                                                                                             to include('Everyone else')
    end

    context "outside discussions page" do
      before do
        @default_due = Time.zone.now.advance(days:1).strftime('%b %-d')
        @override_due = Time.zone.now.advance(days:2).strftime('%b %-d')
      end

      it "should show due dates in mouse hover in the assignments index page", priority: "2", test_id: 114318 do
        get "/courses/#{@course.id}/assignments"
        hover_text = "Everyone else\n#{@default_due}\nNew Section\n#{@override_due}"
        driver.mouse.move_to f('.assignment-date-due .vdd_tooltip_link')
        wait_for_ajaximations
        keep_trying_until do
          expect(f('.ui-tooltip-content').text).to eq(hover_text)
        end
      end

      it "should list discussions in the syllabus", priority: "2", test_id: 114321 do
        get "/courses/#{@course.id}/assignments/syllabus"
        expect(f('#syllabus tbody tr th').text).to include(@default_due)
        expect(f('#syllabus tbody tr td').text).to include(@discussion_topic.title)
        expect(f('#syllabus tbody tr:nth-of-type(2) th').text).to include(@override_due)
        expect(f('#syllabus tbody tr:nth-of-type(2) td').text).to include(@discussion_topic.title)
        expect(f('.detail_list tbody tr td .special_date_title').text).to include(@new_section.name)
      end

      it "should list the discussions in course and main dashboard page", priority: "2", test_id: 114322 do
        get "/courses/#{@course.id}"
        expect(f('.events_list .event .icon-grading-gray').text).to eq("#{@discussion_topic.title}\nMultiple Due Dates")
        course_with_admin_logged_in(course: @course)
        get ""
        expect(f('.events_list .event .icon-grading-gray').text).to eq("#{@discussion_topic.title}\nMultiple Due Dates")
      end
    end
  end
end