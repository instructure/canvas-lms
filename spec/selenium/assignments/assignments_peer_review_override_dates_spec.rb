# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../common"

describe "peer review override dates", :ignore_js_errors do
  include_context "in-process server selenium tests"

  before(:once) do
    @pr_course = course_factory(name: "Peer Review Course", active_course: true)
    @pr_course.enable_feature!(:peer_review_allocation_and_grading)
    @pr_teacher = teacher_in_course(name: "PR Teacher", course: @pr_course, enrollment_state: :active).user
    @section = @pr_course.course_sections.create!(name: "Test Section")
    @student1 = student_in_course(course: @pr_course, active_all: true, name: "Student 1").user
    @pr_course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    @pr_course.account.save!
    @diff_tag_category = @pr_course.group_categories.create!(name: "Test Tag Category", non_collaborative: true)
    @diff_tag_group = @pr_course.groups.create!(name: "Test Tag", group_category: @diff_tag_category)
    @diff_tag_group.add_user(@student1)
  end

  before do
    user_session(@pr_teacher)
  end

  def set_date_field(comboboxes, index, value)
    return unless value

    comboboxes[index].click
    comboboxes[index].send_keys(value)
    comboboxes[index].send_keys(:tab)
    wait_for_ajaximations
  end

  def set_override_dates(
    assignment_due: "03/01/2026",
    assignment_unlock: nil,
    assignment_lock: nil,
    peer_review_due: nil
  )
    comboboxes = ff("input[role='combobox']")

    # Set assignment due date first (required for peer review fields to enable)
    set_date_field(comboboxes, 1, assignment_due)
    wait_for_ajaximations

    # Refresh comboboxes after assignment due date is set
    # New order: due(1) → peer_review_due(3) → unlock(5) → lock(7)
    comboboxes = ff("input[role='combobox']")

    set_date_field(comboboxes, 3, peer_review_due)
    set_date_field(comboboxes, 5, assignment_unlock)
    set_date_field(comboboxes, 7, assignment_lock)
  end

  def verify_assignment_created_and_dates_persisted(
    assignment_name:,
    assignment_due:,
    assignment_unlock: nil,
    assignment_lock: nil,
    peer_review_due: nil
  )
    # Verify assignment was created
    assignment = @pr_course.assignments.last
    expect(assignment.name).to eq(assignment_name)
    expect(assignment.peer_reviews).to be true

    # Reopen assignment to verify dates persisted
    edit_assignment(assignment.id)

    # Verify dates persisted
    # New order: due(1) → peer_review_due(3) → unlock(5) → lock(7)
    comboboxes_after = ff("input[role='combobox']")

    expect(comboboxes_after[1].attribute("value")).to include(assignment_due)
    expect(comboboxes_after[3].attribute("value")).to include(peer_review_due) if peer_review_due
    expect(comboboxes_after[5].attribute("value")).to include(assignment_unlock) if assignment_unlock
    expect(comboboxes_after[7].attribute("value")).to include(assignment_lock) if assignment_lock
  end

  def change_override_assignee(assignee_name)
    fj("button:contains('Everyone')").click
    wait_for_ajaximations
    assign_to_input = f("input[role='combobox'][placeholder='Start typing to search...']")
    assign_to_input.send_keys(assignee_name)
    wait_for_ajaximations
    assign_to_input.send_keys(:enter)
    wait_for_ajaximations
  end

  def update_date_field(comboboxes, index, value)
    return unless value

    comboboxes[index].click
    comboboxes[index].send_keys([:control, "a"], :backspace)
    comboboxes[index].send_keys(value)
    comboboxes[index].send_keys(:tab)
    wait_for_ajaximations
  end

  def update_override_dates(
    assignment_due: nil,
    assignment_unlock: nil,
    assignment_lock: nil,
    peer_review_due: nil
  )
    # New order: due(1) → peer_review_due(3) → unlock(5) → lock(7)
    comboboxes = ff("input[role='combobox']")

    update_date_field(comboboxes, 1, assignment_due)
    update_date_field(comboboxes, 3, peer_review_due)
    update_date_field(comboboxes, 5, assignment_unlock)
    update_date_field(comboboxes, 7, assignment_lock)
  end

  def enter_assignment_name(name)
    f("#assignment_name").send_keys(name)
    f("#assignment_text_entry").click
  end

  def enable_peer_reviews
    f("[data-testid='peer-review-checkbox'] + label").click
    wait_for_ajaximations
  end

  def save_assignment(with_modal: false)
    if with_modal
      f(".btn-primary[type=submit]").click
      wait_for_ajaximations
      force_click("button:contains('Continue')")
    else
      expect_new_page_load { f(".btn-primary[type=submit]").click }
    end
    wait_for_ajaximations
  end

  def create_new_assignment
    get "/courses/#{@pr_course.id}/assignments/new"
    wait_for_ajaximations
  end

  def edit_assignment(assignment_id)
    get "/courses/#{@pr_course.id}/assignments/#{assignment_id}/edit"
    wait_for_ajaximations
  end

  context "as instructor creating assignment with peer reviews and setting default dates" do
    it "can create assignment with peer reviews and Everyone override" do
      create_new_assignment

      enter_assignment_name("Assignment with Peer Reviews and Everyone Override")

      enable_peer_reviews

      set_override_dates(
        assignment_due: "03/01/2026",
        assignment_unlock: "02/01/2026",
        assignment_lock: "03/20/2026",
        peer_review_due: "03/15/2026"
      )

      save_assignment

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment with Peer Reviews and Everyone Override",
        assignment_due: "Mar 1",
        assignment_unlock: "Feb 1",
        assignment_lock: "Mar 20",
        peer_review_due: "Mar 15"
      )
    end

    it "can update peer review dates on assignment with peer reviews and Everyone override" do
      create_new_assignment

      enter_assignment_name("Assignment for Peer Reviews and Everyone Override Update")

      enable_peer_reviews

      set_override_dates(
        assignment_due: "03/06/2026",
        assignment_unlock: "02/06/2026",
        assignment_lock: "03/25/2026",
        peer_review_due: "03/20/2026"
      )

      save_assignment

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Everyone Override Update",
        assignment_due: "Mar 6",
        assignment_unlock: "Feb 6",
        assignment_lock: "Mar 25",
        peer_review_due: "Mar 20"
      )

      update_override_dates(
        assignment_due: "03/11/2026",
        assignment_unlock: "02/11/2026",
        assignment_lock: "03/30/2026",
        peer_review_due: "03/25/2026"
      )

      save_assignment

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Everyone Override Update",
        assignment_due: "Mar 11",
        assignment_unlock: "Feb 11",
        assignment_lock: "Mar 30",
        peer_review_due: "Mar 25"
      )
    end

    it "can create assignment with peer reviews and Section override" do
      create_new_assignment

      enter_assignment_name("Assignment with Peer Reviews and Section Override")

      enable_peer_reviews

      change_override_assignee("Test Section")

      set_override_dates(
        assignment_due: "03/16/2026",
        assignment_unlock: "02/16/2026",
        assignment_lock: "04/04/2026",
        peer_review_due: "03/30/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment with Peer Reviews and Section Override",
        assignment_due: "Mar 16",
        assignment_unlock: "Feb 16",
        assignment_lock: "Apr 4",
        peer_review_due: "Mar 30"
      )
    end

    it "can update peer review dates on assignment with peer reviews and Section override" do
      create_new_assignment

      enter_assignment_name("Assignment for Peer Reviews and Section Override Update")

      enable_peer_reviews

      change_override_assignee("Test Section")

      set_override_dates(
        assignment_due: "03/21/2026",
        assignment_unlock: "02/21/2026",
        assignment_lock: "04/09/2026",
        peer_review_due: "04/04/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Section Override Update",
        assignment_due: "Mar 21",
        assignment_unlock: "Feb 21",
        assignment_lock: "Apr 9",
        peer_review_due: "Apr 4"
      )

      update_override_dates(
        assignment_due: "03/26/2026",
        assignment_unlock: "02/26/2026",
        assignment_lock: "04/14/2026",
        peer_review_due: "04/09/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Section Override Update",
        assignment_due: "Mar 26",
        assignment_unlock: "Feb 26",
        assignment_lock: "Apr 14",
        peer_review_due: "Apr 9"
      )
    end

    it "can create assignment with peer reviews and Student override" do
      create_new_assignment

      enter_assignment_name("Assignment with Peer Reviews and Student Override")

      enable_peer_reviews

      change_override_assignee("Student 1")

      set_override_dates(
        assignment_due: "03/31/2026",
        assignment_unlock: "03/03/2026",
        assignment_lock: "04/19/2026",
        peer_review_due: "04/14/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment with Peer Reviews and Student Override",
        assignment_due: "Mar 31",
        assignment_unlock: "Mar 3",
        assignment_lock: "Apr 19",
        peer_review_due: "Apr 14"
      )
    end

    it "can update peer review dates on assignment with peer reviews and Student override" do
      create_new_assignment

      enter_assignment_name("Assignment for Peer Reviews and Student Override Update")

      enable_peer_reviews

      change_override_assignee("Student 1")

      set_override_dates(
        assignment_due: "04/05/2026",
        assignment_unlock: "03/08/2026",
        assignment_lock: "04/24/2026",
        peer_review_due: "04/19/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Student Override Update",
        assignment_due: "Apr 5",
        assignment_unlock: "Mar 8",
        assignment_lock: "Apr 24",
        peer_review_due: "Apr 19"
      )

      update_override_dates(
        assignment_due: "04/10/2026",
        assignment_unlock: "03/13/2026",
        assignment_lock: "04/29/2026",
        peer_review_due: "04/24/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Student Override Update",
        assignment_due: "Apr 10",
        assignment_unlock: "Mar 13",
        assignment_lock: "Apr 29",
        peer_review_due: "Apr 24"
      )
    end

    it "can create assignment with peer reviews and Differentiation Tag override" do
      create_new_assignment

      enter_assignment_name("Assignment with Peer Reviews and Tag Override")

      enable_peer_reviews

      change_override_assignee("Test Tag")

      set_override_dates(
        assignment_due: "04/15/2026",
        assignment_unlock: "03/18/2026",
        assignment_lock: "05/04/2026",
        peer_review_due: "04/29/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment with Peer Reviews and Tag Override",
        assignment_due: "Apr 15",
        assignment_unlock: "Mar 18",
        assignment_lock: "May 4",
        peer_review_due: "Apr 29"
      )
    end

    it "can update peer review dates on assignment with peer reviews and Differentiation Tag override" do
      create_new_assignment

      enter_assignment_name("Assignment for Peer Reviews and Tag Override Update")

      enable_peer_reviews

      change_override_assignee("Test Tag")

      set_override_dates(
        assignment_due: "04/20/2026",
        assignment_unlock: "03/23/2026",
        assignment_lock: "05/09/2026",
        peer_review_due: "05/04/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Tag Override Update",
        assignment_due: "Apr 20",
        assignment_unlock: "Mar 23",
        assignment_lock: "May 9",
        peer_review_due: "May 4"
      )

      update_override_dates(
        assignment_due: "04/25/2026",
        assignment_unlock: "03/28/2026",
        assignment_lock: "05/14/2026",
        peer_review_due: "05/09/2026"
      )

      save_assignment(with_modal: true)

      verify_assignment_created_and_dates_persisted(
        assignment_name: "Assignment for Peer Reviews and Tag Override Update",
        assignment_due: "Apr 25",
        assignment_unlock: "Mar 28",
        assignment_lock: "May 14",
        peer_review_due: "May 9"
      )
    end
  end

  context "as instructor clearing peer review dates" do
    it "clears peer review due date when assignment due date is cleared" do
      create_new_assignment

      enter_assignment_name("Assignment for Clearing Due Date Test")

      enable_peer_reviews

      set_override_dates(
        assignment_due: "03/01/2026",
        assignment_unlock: "02/01/2026",
        assignment_lock: "03/20/2026",
        peer_review_due: "03/15/2026"
      )

      save_assignment

      assignment = @pr_course.assignments.last
      peer_review_sub = assignment.peer_review_sub_assignment
      expect(peer_review_sub.due_at).not_to be_nil

      # Reopen and clear the assignment due date
      edit_assignment(assignment.id)

      comboboxes = ff("input[role='combobox']")
      comboboxes[1].click
      comboboxes[1].send_keys([:control, "a"], :backspace)
      comboboxes[1].send_keys(:tab)
      wait_for_ajaximations

      save_assignment

      # Verify peer review due date was cleared
      assignment.reload
      peer_review_sub.reload
      expect(assignment.due_at).to be_nil
      expect(peer_review_sub.due_at).to be_nil
      expect(peer_review_sub.unlock_at).to be_nil
    end

    it "clears peer review due date independently" do
      create_new_assignment

      enter_assignment_name("Assignment for Clearing PR Due Date Test")

      enable_peer_reviews

      set_override_dates(
        assignment_due: "03/01/2026",
        assignment_unlock: "02/01/2026",
        assignment_lock: "03/20/2026",
        peer_review_due: "03/15/2026"
      )

      save_assignment

      assignment = @pr_course.assignments.last
      peer_review_sub = assignment.peer_review_sub_assignment
      expect(peer_review_sub.due_at).not_to be_nil

      # Reopen and clear only the peer review due date
      edit_assignment(assignment.id)

      comboboxes = ff("input[role='combobox']")
      comboboxes[3].click
      comboboxes[3].send_keys([:control, "a"], :backspace)
      comboboxes[3].send_keys(:tab)
      wait_for_ajaximations

      save_assignment

      # Assignment due date should still be set
      assignment.reload
      peer_review_sub.reload
      expect(assignment.due_at).not_to be_nil
      # Peer review due date should be cleared
      expect(peer_review_sub.due_at).to be_nil
      # Peer review unlock/lock should still match assignment dates
      expect(peer_review_sub.unlock_at).not_to be_nil
      expect(peer_review_sub.lock_at).not_to be_nil
    end
  end
end
