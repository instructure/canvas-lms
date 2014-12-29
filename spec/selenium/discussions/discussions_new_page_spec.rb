require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_examples "in-process server selenium tests"

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:default_section) { course.default_section }
  let(:new_section) { course.course_sections.create!(name: "section 2") }
  let(:group) do
    course.groups.create!(name: 'group',
                          group_category: group_category).tap do |g|
      g.add_user(student, 'accepted', nil)
    end
  end
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:assignment_group) { course.assignment_groups.create!(name: 'assignment group') }
  let(:group_category) { course.group_categories.create!(name: 'group category') }
  let(:assignment) { course.assignments.create!(
      name: 'assignment',
      #submission_types: 'discussion_topic',
      assignment_group: assignment_group
  ) }

  context "on the new page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/new" }

    context "as a teacher" do
      before(:each) do
        user_session(teacher)
      end

      it "should add an attachment to a new topic" do
        topic_title = 'new topic with file'
        get url
        replace_content(f('input[name=title]'), topic_title)
        add_attachment_and_validate
        expect(DiscussionTopic.where(title: topic_title).first.attachment_id).to be_present
      end

      it "should create a podcast enabled topic" do
        get url
        replace_content(f('input[name=title]'), "This is my test title")
        type_in_tiny('textarea[name=message]', 'This is the discussion description.')

        f('input[type=checkbox][name=podcast_enabled]').click
        expect_new_page_load { submit_form('.form-actions') }
        #get "/courses/#{course.id}/discussion_topics"
        # TODO: talk to UI, figure out what to display here
        # f('.discussion-topic .icon-rss').should be_displayed
        expect(DiscussionTopic.last.podcast_enabled).to be_truthy
      end

      context "graded" do
        it "should allow creating multiple due dates" do
          assignment_group
          group_category
          new_section
          get url
          wait_for_ajaximations

          f('input[type=checkbox][name="assignment[set_assignment]"]').click

          due_at1 = Time.zone.now + 3.days
          due_at2 = Time.zone.now + 4.days

          click_option('.due-date-row:first select', default_section.name)
          fj('.due-date-overrides:first [name="due_at"]').send_keys(due_at1.strftime('%b %-d, %y'))

          f('#add_due_date').click
          wait_for_ajaximations

          click_option('.due-date-row:last select', new_section.name)
          ff('.due-date-overrides [name="due_at"]')[1].send_keys(due_at2.strftime('%b %-d, %y'))

          expect_new_page_load { f('.form-actions button[type=submit]').click }
          topic = DiscussionTopic.last

          overrides = topic.assignment.assignment_overrides
          expect(overrides.count).to eq 2
          default_override = overrides.detect { |o| o.set_id == default_section.id }
          expect(default_override.due_at.strftime('%b %-d, %y')).to eq due_at1.to_date.strftime('%b %-d, %y')
          other_override = overrides.detect { |o| o.set_id == new_section.id }
          expect(other_override.due_at.strftime('%b %-d, %y')).to eq due_at2.to_date.strftime('%b %-d, %y')
        end

        it "should validate that a group category is selected" do
          assignment_group
          get url
          wait_for_ajaximations

          f('input[type=checkbox][name="assignment[set_assignment]"]').click
          f('#has_group_category').click
          close_visible_dialog
          f('.btn-primary[type=submit]').click
          wait_for_ajaximations

          errorBoxes = driver.execute_script("return $('.errorBox').filter('[id!=error_box_template]').toArray();")
          visBoxes, hidBoxes = errorBoxes.partition { |eb| eb.displayed? }
          expect(visBoxes.first.text).to eq "Please select a group set for this assignment"
        end
      end
    end

    context "as a student" do
      before(:each) do
        user_session(student)
      end

      it "should not show file attachment if allow_student_forum_attachments is not true" do
        # given
        get url
        expect(f('#disussion_attachment_uploaded_data')).to be_nil
        # when
        course.allow_student_forum_attachments = true
        course.save!
        # expect
        get url
        expect(f('#discussion_attachment_uploaded_data')).not_to be_nil
      end

      context "in a group" do
        let(:url) { "/groups/#{group.id}/discussion_topics/new" }

        it "should not show file attachment if allow_student_forum_attachments is not true" do
          # given
          get url
          expect(f('label[for=discussion_attachment_uploaded_data]')).to be_nil
          # when
          course.allow_student_forum_attachments = true
          course.save!
          # expect
          get url
          expect(f('label[for=discussion_attachment_uploaded_data]')).to be_displayed
        end
      end
    end
  end
end
