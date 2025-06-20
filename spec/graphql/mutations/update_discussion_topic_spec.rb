# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
#

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateDiscussionTopic do
  before(:once) do
    course_with_teacher(active_all: true)
    @attachment = attachment_with_context(@teacher)
    discussion_topic_model({ context: @course, attachment: @attachment })
  end

  def mutation_str(
    id: nil,
    published: nil,
    locked: nil,
    title: nil,
    message: nil,
    require_initial_post: nil,
    specific_sections: nil,
    delayed_post_at: nil,
    lock_at: nil,
    file_id: nil,
    remove_attachment: nil,
    assignment: nil,
    checkpoints: nil,
    set_checkpoints: nil,
    group_category_id: nil,
    ungraded_discussion_overrides: nil,
    anonymous_state: nil,
    sort_order: nil,
    sort_order_locked: nil,
    expanded: nil,
    expanded_locked: nil
  )
    <<~GQL
      mutation {
        updateDiscussionTopic(input: {
          discussionTopicId: #{id}
          #{"published: #{published}" unless published.nil?}
          #{"locked: #{locked}" unless locked.nil?}
          #{"title: \"#{title}\"" unless title.nil?}
          #{"message: \"#{message}\"" unless message.nil?}
          #{"requireInitialPost: #{require_initial_post}" unless require_initial_post.nil?}
          #{"specificSections: \"#{specific_sections}\"" unless specific_sections.nil?}
          #{"delayedPostAt: \"#{delayed_post_at}\"" unless delayed_post_at.nil?}
          #{"lockAt: \"#{lock_at}\"" unless lock_at.nil?}
          #{"removeAttachment: #{remove_attachment}" unless remove_attachment.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
          #{"groupCategoryId: #{group_category_id}" unless group_category_id.nil?}
          #{assignment_str(assignment)}
          #{checkpoints_str(checkpoints)}
          #{"setCheckpoints: #{set_checkpoints}" unless set_checkpoints.nil?}
          #{"ungradedDiscussionOverrides: #{ungraded_discussion_overrides_str(ungraded_discussion_overrides)}" unless ungraded_discussion_overrides.nil?}
          #{"anonymousState: #{anonymous_state}" unless anonymous_state.nil?}
          #{"sortOrder: #{sort_order}" unless sort_order.nil?}
          #{"sortOrderLocked: #{sort_order_locked}" unless sort_order_locked.nil?}
          #{"expanded: #{expanded}" unless expanded.nil?}
          #{"expandedLocked: #{expanded_locked}" unless expanded_locked.nil?}
        }) {
          discussionTopic {
            _id
            published
            locked
            replyToEntryRequiredCount
            expanded
            expandedLocked
            sortOrder
            sortOrderLocked
            ungradedDiscussionOverrides {
              nodes {
                _id
                createdAt
                dueAt
                id
                lockAt
                title
                unlockAt
                updatedAt
              }
            }
            anonymousState
            assignment {
              _id
              pointsPossible
              postToSis
              dueAt
              state
              gradingType
              importantDates
              peerReviews {
                anonymousReviews
                automaticReviews
                count
                dueAt
                enabled
                intraReviews
              }
              assignmentOverrides {
                nodes {
                  _id
                  createdAt
                  dueAt
                  id
                  lockAt
                  title
                  unlockAt
                  updatedAt
                }
              }
              checkpoints {
                dueAt
                name
                onlyVisibleToOverrides
                pointsPossible
                tag
              }
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  new_peer_reviews = {
    enabled: true,
    count: 2,
    dueAt: "2023-01-01T01:00:00Z",
    intraReviews: true,
    anonymousReviews: true,
    automaticReviews: true
  }

  def assignment_str(assignment)
    return "" unless assignment

    args = []
    args << "abGuid: #{assignment[:abGuid]}" if assignment[:abGuid]
    args << "pointsPossible: #{assignment[:pointsPossible]}" if assignment[:pointsPossible]
    args << "postToSis: #{assignment[:postToSis]}" if assignment.key?(:postToSis)
    args << "assignmentGroupId: \"#{assignment[:assignmentGroupId]}\"" if assignment[:assignmentGroupId]
    args << "groupCategoryId: #{assignment[:groupCategoryId]}" if assignment[:groupCategoryId]
    args << "dueAt: \"#{assignment[:dueAt]}\"" if assignment[:dueAt]
    args << "state: #{assignment[:state]}" if assignment[:state]
    args << "onlyVisibleToOverrides: #{assignment[:onlyVisibleToOverrides]}" if assignment.key?(:onlyVisibleToOverrides)
    args << "setAssignment: #{assignment[:setAssignment]}" if assignment.key?(:setAssignment)
    args << "gradingType: #{assignment[:gradingType]}" if assignment[:gradingType]
    args << "importantDates: #{assignment[:importantDates]}" if assignment[:importantDates]
    args << peer_reviews_str(assignment[:peerReviews]) if assignment[:peerReviews]
    args << assignment_overrides_str(assignment[:assignmentOverrides]) if assignment[:assignmentOverrides]
    args << "forCheckpoints: #{assignment[:forCheckpoints]}" if assignment[:forCheckpoints]
    args << "lockAt: \"#{assignment[:lockAt]}\"" if assignment[:lockAt]
    args << "unlockAt: \"#{assignment[:unlockAt]}\"" if assignment[:unlockAt]

    "assignment: { #{args.join(", ")} }"
  end

  def checkpoints_str(checkpoints)
    return "" unless checkpoints

    checkpoints_out = []
    checkpoints.each do |checkpoint|
      args = []
      args << "checkpointLabel: #{checkpoint[:checkpointLabel]}"
      args << "pointsPossible: #{checkpoint[:pointsPossible]}"
      args << "repliesRequired: #{checkpoint[:repliesRequired]}" if checkpoint[:repliesRequired]
      args << checkpoints_dates_str(checkpoint[:dates])

      checkpoints_out << "{ #{args.join(", ")} }"
    end

    "checkpoints: [ #{checkpoints_out.join(", ")} ]"
  end

  def checkpoints_dates_str(dates)
    return "" unless dates

    dates_out = []
    dates.each do |date|
      args = []
      args << "type: #{date[:type]}"
      args << "dueAt: \"#{date[:dueAt]}\""
      args << "lockAt: \"#{date[:lockAt]}\"" if date[:lockAt]
      args << "unlockAt: \"#{date[:unlockAt]}\"" if date[:unlockAt]
      args << "studentIds: [#{date[:studentIds].map { |id| "\"#{id}\"" }.join(", ")}]" if date[:studentIds]
      args << "setType: #{date[:setType]}" if date[:setType]
      args << "setId: #{date[:setId]}" if date[:setId]
      args << "id: #{date[:id]}" if date[:id]

      dates_out << "{ #{args.join(", ")} }"
    end

    "dates: [ #{dates_out.join(", ")} ]"
  end

  def peer_reviews_str(peer_reviews)
    return "" unless peer_reviews

    args = []
    args << "enabled: #{peer_reviews[:enabled]}" if peer_reviews.key?(:enabled)
    args << "count: #{peer_reviews[:count]}" if peer_reviews[:count]
    args << "dueAt: \"#{peer_reviews[:dueAt]}\"" if peer_reviews[:dueAt]
    args << "intraReviews: #{peer_reviews[:intraReviews]}" if peer_reviews.key?(:intraReviews)
    args << "anonymousReviews: #{peer_reviews[:anonymousReviews]}" if peer_reviews.key?(:anonymousReviews)
    args << "automaticReviews: #{peer_reviews[:automaticReviews]}" if peer_reviews.key?(:automaticReviews)

    "peerReviews: { #{args.join(", ")} }"
  end

  def assignment_overrides_str(overrides)
    return "" unless overrides

    args = []
    args << "sectionId: \"#{overrides[:sectionId]}\"" if overrides[:sectionId]
    args << "studentIds: [\"#{overrides[:studentIds].join('", "')}\"]" if overrides[:studentIds]
    # Add other override input fields if you want to test them

    "assignmentOverrides: { #{args.join(", ")} }"
  end

  def ungraded_discussion_overrides_str(overrides)
    return "" unless overrides

    args = []
    args << "sectionId: \"#{overrides[:sectionId]}\"" if overrides[:sectionId]
    args << "studentIds: [\"#{overrides[:studentIds].join('", "')}\"]" if overrides[:studentIds]
    # Add other override input fields if you want to test them

    "{ #{args.join(", ")} }"
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  def expect_error(result, message)
    errors = result["errors"] || result.dig("data", "updateDiscussionTopic", "errors")
    expect(errors).not_to be_nil
    expect(errors[0]["message"]).to match(/#{message}/)
  end

  it "updates the discussion topic" do
    delayed_post_at = 5.days.from_now.iso8601
    lock_at = 10.days.from_now.iso8601

    updated_params = {
      id: @topic.id,
      title: "Updated Title",
      message: "Updated Message",
      require_initial_post: true,
      specific_sections: "all",
      delayed_post_at: delayed_post_at.to_s,
      lock_at: lock_at.to_s
    }
    result = run_mutation(updated_params)

    expect(result["errors"]).to be_nil
    @topic.reload
    expect(@topic.title).to eq "Updated Title"
    expect(@topic.message).to eq "Updated Message"
    expect(@topic.require_initial_post).to be true
    expect(@topic.is_section_specific).to be false
    expect(@topic.delayed_post_at).to eq delayed_post_at
    expect(@topic.lock_at).to eq lock_at
    expect(@topic.editor).to eq @teacher
  end

  context "attachments" do
    it "removes a discussion topic attachment" do
      expect(@topic.attachment).to eq(@attachment)
      result = run_mutation({ id: @topic.id, remove_attachment: true })

      expect(result["errors"]).to be_nil
      expect(@topic.reload.attachment).to be_nil
    end

    it "replaces a discussion topic attachment" do
      attachment = attachment_with_context(@teacher)
      attachment.update!(user: @teacher)
      result = run_mutation({ id: @topic.id, file_id: attachment.id })

      expect(result["errors"]).to be_nil
      expect(@topic.reload.attachment_id).to eq attachment.id
    end

    it "allows update by a different teacher, even if there is an attachment" do
      teacher2 = teacher_in_course.user

      # The frontend sends the file_id always, as a string
      result = run_mutation({ id: @topic.id, title: "Updated Title", file_id: @attachment.id.to_s }, teacher2)

      expect(result["errors"]).to be_nil
      expect(@topic.reload.title).to eq "Updated Title"
    end
  end

  context "anonymous state" do
    it "allow to update the anonymous state if there is no reply" do
      @topic.anonymous_state = nil
      @topic.save!
      result = run_mutation({ id: @topic.id, anonymous_state: "full_anonymity" })
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "anonymousState")).to eq "full_anonymity"
      @topic.reload
      expect(@topic.anonymous_state).to eq "full_anonymity"
    end

    it "should save the anonymous state as NULL when the input value is 'off'" do
      @topic.anonymous_state = "full_anonymity"
      @topic.save!
      result = run_mutation({ id: @topic.id, anonymous_state: "off" })
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "anonymousState")).to be_nil
      @topic.reload
      expect(@topic.anonymous_state).to be_nil
    end

    it "should keep the previous anonymous state if the input value is nil" do
      @topic.anonymous_state = "full_anonymity"
      @topic.save!
      result = run_mutation({ id: @topic.id, anonymous_state: nil })
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "anonymousState")).to eq "full_anonymity"
      @topic.reload
      expect(@topic.anonymous_state).to eq "full_anonymity"
    end

    it "does not allow to update the anonymous state if there is a reply" do
      create_valid_discussion_entry
      @topic.anonymous_state = nil
      @topic.save!
      result = run_mutation({ id: @topic.id, anonymous_state: "full_anonymity" })
      expect(result.dig("data", "updateDiscussionTopic", "discussionTopic")).to be_nil
      expect(@topic.anonymous_state).to be_nil
    end

    context "group discussion" do
      it "does not allow to set the anonymous state to 'full_anonymity' if the discussion is changed to group" do
        gc = @course.group_categories.create!(name: "My Group Category")
        result = run_mutation({ id: @topic.id, anonymous_state: "full_anonymity", group_category_id: gc.id })[:data][:updateDiscussionTopic]
        expect(result["discussionTopic"]).to be_nil
        expect(result["errors"][0]["message"]).to eq "Anonymity settings are locked for group and/or graded discussions"
      end

      it "allows to set the anonymous state to 'full_anonymity' if the discussion is changed to ungrouped" do
        gc = @course.group_categories.create!(name: "My Group Category")
        @topic.update!(group_category: gc)
        result = run_mutation({ id: @topic.id, anonymous_state: "full_anonymity", group_category_id: nil })[:data][:updateDiscussionTopic]
        expect(result["errors"]).to be_nil
        expect(result.dig("discussionTopic", "anonymousState")).to eq "full_anonymity"
        @topic.reload
        expect(@topic.anonymous_state).to eq "full_anonymity"
      end
    end

    context "graded discussion" do
      it "does not allow to set the anonymous state to 'full_anonymity' if the discussion is graded" do
        result = run_mutation({
                                id: @topic.id,
                                anonymous_state: "full_anonymity",
                                assignment: {
                                  title: "Graded Topic 1",
                                  setAssignment: true,
                                }
                              })[:data][:updateDiscussionTopic]
        expect(result["discussionTopic"]).to be_nil
        expect(result["errors"][0]["message"]).to eq "Anonymity settings are locked for group and/or graded discussions"
      end

      it "allows to set the anonymous state to 'full_anonymity' if the discussion is changed to ungraded" do
        @discussion_assignment = @course.assignments.create!(
          title: "Graded Topic 1",
          submission_types: "discussion_topic"
        )
        @topic = @discussion_assignment.discussion_topic

        result = run_mutation({ id: @topic.id, anonymous_state: "full_anonymity", assignment: { setAssignment: false } })[:data][:updateDiscussionTopic]
        expect(result["errors"]).to be_nil
        expect(result.dig("discussionTopic", "anonymousState")).to eq "full_anonymity"
        @topic.reload
        expect(@topic.anonymous_state).to eq "full_anonymity"
      end
    end
  end

  it "publishes the discussion topic" do
    @topic.unpublish!
    expect(@topic.published?).to be false
    expected_title = @topic.title

    result = run_mutation({ id: @topic.id, published: true })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be true
    @topic.reload
    expect(@topic.published?).to be true
    expect(@topic.title).to eq expected_title
  end

  it "unpublishes the discussion topic" do
    @topic.publish!
    expect(@topic.published?).to be true

    result = run_mutation({ id: @topic.id, published: false })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be false
    @topic.reload
    expect(@topic.published?).to be false
  end

  it "handles the published state change from false to true and sets posted_at and last_reply_at correctly" do
    @topic.unpublish!
    expect(@topic.published?).to be false

    result = run_mutation({ id: @topic.id, published: true })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be true
    @topic.reload
    expect(@topic.published?).to be true
    expect(@topic.posted_at).to be_within(1.second).of(Time.zone.now)
    expect(@topic.last_reply_at).to be_within(1.second).of(Time.zone.now)
  end

  it "does not change posted_at but updates last_reply_at when published is already true" do
    @topic.publish!
    expect(@topic.published?).to be true
    original_posted_at = @topic.posted_at

    sleep 2 # Ensure there is a noticeable time difference
    result = run_mutation({ id: @topic.id, published: true })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be true
    @topic.reload
    expect(@topic.published?).to be true
    expect(@topic.posted_at).to eq original_posted_at
    expect(@topic.last_reply_at).to be_within(1.second).of(Time.zone.now)
  end

  it "locks the discussion topic" do
    expect(@topic.locked).to be false

    result = run_mutation(id: @topic.id, locked: true)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "locked")).to be true
    expect(@topic.reload.locked).to be true
  end

  it "unlocks the discussion topic" do
    @topic.lock!
    expect(@topic.locked).to be true

    result = run_mutation(id: @topic.id, locked: false)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "locked")).to be false
    expect(@topic.reload.locked).to be false
  end

  context "message handling" do
    it "does not update discussion message if in db its nil, and in request its empty string" do
      @topic.update!(message: nil)
      result = run_mutation(id: @topic.id, message: "")
      expect(result["errors"]).to be_nil
      expect(@topic.reload.message).to be_nil
    end

    it "does not update update discussion message if in db its empty string, and in request its nil" do
      @topic.update!(message: "")
      result = run_mutation(id: @topic.id, message: nil)
      expect(result["errors"]).to be_nil
      expect(@topic.reload.message).to eq ""
    end

    it "does update discussion message if in db its some value, and in request its empty string" do
      @topic.update!(message: "Old Message")
      result = run_mutation(id: @topic.id, message: "")
      expect(result["errors"]).to be_nil
      expect(@topic.reload.message).to eq ""
    end

    it "does update discussion message if in db its nil, and in request its some value" do
      @topic.update!(message: nil)
      result = run_mutation(id: @topic.id, message: "New Message")
      expect(result["errors"]).to be_nil
      expect(@topic.reload.message).to eq "New Message"
    end
  end

  context "discussion assignment" do
    before do
      @discussion_assignment = @course.assignments.create!(
        title: "Graded Topic 1",
        submission_types: "discussion_topic",
        post_to_sis: false,
        grading_type: "points",
        points_possible: 5,
        due_at: 3.months.from_now,
        peer_reviews: false,
        ab_guid: ["1E20776E-7053-11DF-8EBF-BE719DFF4B22"]
      )
      @topic = @discussion_assignment.discussion_topic
    end

    it "can set all new inputs at once" do
      new_points_possible = 100
      new_post_to_sis = true
      new_grading_type = "pass_fail"
      new_due_date = Time.now.utc.iso8601

      assignment_group = @course.assignment_groups.create!(name: "Test Group")
      new_assignment_group_id = assignment_group.id

      new_peer_reviews = {
        enabled: true,
        count: 2,
        dueAt: "2023-01-01T01:00:00Z",
        intraReviews: true,
        anonymousReviews: true,
        automaticReviews: true
      }

      result = run_mutation(id: @topic.id, assignment: { pointsPossible: new_points_possible,
                                                         postToSis: new_post_to_sis,
                                                         assignmentGroupId: new_assignment_group_id,
                                                         gradingType: new_grading_type,
                                                         peerReviews: new_peer_reviews,
                                                         dueAt: new_due_date, })

      expect(result["errors"]).to be_nil

      # Check response from graphql
      new_assignment = result["data"]["updateDiscussionTopic"]["discussionTopic"]["assignment"]

      expect(new_assignment["pointsPossible"]).to eq(new_points_possible)
      expect(new_assignment["postToSis"]).to eq(new_post_to_sis)
      expect(new_assignment["gradingType"]).to eq(new_grading_type)
      expect(new_assignment["state"]).to eq(@discussion_assignment.state.to_s)
      expect(new_assignment["dueAt"]).to eq(new_due_date)

      expect(new_assignment["peerReviews"]["enabled"]).to eq(new_peer_reviews[:enabled])
      expect(new_assignment["peerReviews"]["count"]).to eq(new_peer_reviews[:count])
      expect(new_assignment["peerReviews"]["dueAt"]).to eq(new_peer_reviews[:dueAt])
      expect(new_assignment["peerReviews"]["intraReviews"]).to eq(new_peer_reviews[:intraReviews])
      expect(new_assignment["peerReviews"]["anonymousReviews"]).to eq(new_peer_reviews[:anonymousReviews])
      expect(new_assignment["peerReviews"]["automaticReviews"]).to eq(new_peer_reviews[:automaticReviews])

      # Check updated object
      new_assignment = Assignment.find(@discussion_assignment.id)
      expect(new_assignment.points_possible).to eq(new_points_possible)
      expect(new_assignment.post_to_sis).to eq(new_post_to_sis)
      expect(new_assignment.grading_type).to eq(new_grading_type)
      expect(new_assignment.state).to eq(@discussion_assignment.state)

      expect(new_assignment.peer_reviews).to eq(new_peer_reviews[:enabled])
      expect(new_assignment.peer_review_count).to eq(new_peer_reviews[:count])
      expect(new_assignment.peer_reviews_due_at.utc.strftime("%FT%TZ")).to eq(new_peer_reviews[:dueAt])
      expect(new_assignment.automatic_peer_reviews).to eq(new_peer_reviews[:automaticReviews])
      expect(new_assignment.anonymous_peer_reviews).to eq(new_peer_reviews[:anonymousReviews])
      expect(new_assignment.intra_group_peer_reviews).to eq(new_peer_reviews[:intraReviews])
    end

    it "can update intraReviews" do
      @discussion_assignment.peer_reviews = true
      @discussion_assignment.save!
      @topic.reload

      new_peer_reviews = {
        intraReviews: false,
      }

      result = run_mutation(id: @topic.id, assignment: { peerReviews: new_peer_reviews })

      expect(result["errors"]).to be_nil

      # Check response from graphql
      new_assignment = result["data"]["updateDiscussionTopic"]["discussionTopic"]["assignment"]
      expect(new_assignment["peerReviews"]["intraReviews"]).to be false

      # Check updated object
      new_assignment = Assignment.find(@discussion_assignment.id)
      expect(new_assignment.intra_group_peer_reviews).to be false
    end

    it "sets the important dates field on the assignment" do
      result = run_mutation(id: @topic.id, assignment: { importantDates: true })
      expect(result["errors"]).to be_nil
      expect(Assignment.last.important_dates).to be(true)
    end

    it "sets just the due date" do
      new_due_date = Time.now.utc.iso8601
      result = run_mutation(id: @topic.id, assignment: { dueAt: new_due_date })
      expect(result["errors"]).to be_nil

      updated_assignment = Assignment.find(@discussion_assignment.id)
      expect(updated_assignment.due_at.iso8601).to eq(new_due_date)
      expect(updated_assignment.points_possible).to eq(@discussion_assignment.points_possible)
    end

    it "sets due date overrides" do
      student1 = @course.enroll_student(User.create!, enrollment_state: "active").user
      student2 = @course.enroll_student(User.create!, enrollment_state: "active").user
      @course.enroll_student(User.create!, enrollment_state: "active").user

      overrides = {
        studentIds: [student1.id, student2.id]
      }

      result = run_mutation(id: @topic.id, assignment: { assignmentOverrides: overrides, onlyVisibleToOverrides: true })
      expect(result["errors"]).to be_nil

      updated_assignment = Assignment.find(@discussion_assignment.id)

      new_override = updated_assignment.assignment_overrides.first
      expect(updated_assignment.only_visible_to_overrides).to be(true)

      expect(new_override.set_type).to eq("ADHOC")
      expect(new_override.set_id).to be_nil
      expect(new_override.set.map(&:id)).to match_array([student1.id, student2.id])
    end

    it "doesn't make a new assignment if set_assignment is false" do
      topic = @course.discussion_topics.create!(title: "Discussion Topic Title", user: @teacher)
      result = run_mutation(id: topic.id, assignment: { setAssignment: false })
      expect(result["errors"]).to be_nil
      expect(topic.reload.assignment).to be_nil
    end

    it "can create a new assignment if one didn't exist before" do
      topic = @course.discussion_topics.create!(title: "Discussion Topic Title", user: @teacher)
      new_points_possible = 100
      new_post_to_sis = true
      new_grading_type = "pass_fail"
      lock_at = 20.days.from_now.iso8601
      unlock_at = 10.days.from_now.iso8601

      result = run_mutation(id: topic.id, assignment: { pointsPossible: new_points_possible, postToSis: new_post_to_sis, gradingType: new_grading_type, lockAt: lock_at, unlockAt: unlock_at })
      expect(result["errors"]).to be_nil

      # Verify that the response from graphql is correct
      new_assignment = result["data"]["updateDiscussionTopic"]["discussionTopic"]["assignment"]
      expect(new_assignment["pointsPossible"]).to eq(new_points_possible)
      expect(new_assignment["postToSis"]).to eq(new_post_to_sis)
      expect(new_assignment["gradingType"]).to eq(new_grading_type)

      # Verify that the saved object is correct
      topic.reload
      expect(topic.assignment).to be_present
      expect(topic.lock_at).to eq(lock_at)
      expect(topic.unlock_at).to eq(unlock_at)
      updated_assignment = Assignment.find(topic.assignment.id)

      expect(updated_assignment.points_possible).to eq(new_points_possible)
      expect(updated_assignment.post_to_sis).to eq(new_post_to_sis)
      expect(updated_assignment.grading_type.to_s).to eq(new_grading_type)
      expect(updated_assignment.lock_at).to eq(lock_at)
      expect(updated_assignment.unlock_at).to eq(unlock_at)

      # Verify that a new DiscussionTopic wasn't created
      expect(DiscussionTopic.last.id).to eq(topic.id)
    end

    it "can delete and then restore" do
      result = run_mutation(id: @topic.id, assignment: { setAssignment: false })
      expect(result["errors"]).to be_nil

      expect(Assignment.find(@discussion_assignment.id).workflow_state).to eq "deleted"
      expect(@topic.reload.assignment).to be_nil

      result = run_mutation(id: @topic.id, assignment: { setAssignment: true })
      expect(result["errors"]).to be_nil

      expect(Assignment.find(@discussion_assignment.id).workflow_state).to eq "published"
      expect(@topic.reload.assignment).to eq @discussion_assignment.reload

      # Verify that a new DiscussionTopic wasn't created
      expect(DiscussionTopic.last.id).to eq(@topic.id)
    end

    it "updates the group category id" do
      group_category_old = @course.group_categories.create!(name: "Old Group Category")
      group_category_new = @course.group_categories.create!(name: "New Group Category")
      @topic.update!(group_category: group_category_old)
      result = run_mutation(id: @topic.id, group_category_id: group_category_new.id, assignment: { groupCategoryId: group_category_new.id })
      @topic.reload
      expect(result["errors"]).to be_nil
      expect(@topic.group_category_id).to eq group_category_new.id
    end

    it "can turn a graded non-group discussion into a graded group discussion" do
      gc = @course.group_categories.create!(name: "My Group Category")
      result = run_mutation(id: @topic.id, group_category_id: gc.id, assignment: { groupCategoryId: gc.id })
      @topic.reload
      expect(result["errors"]).to be_nil
      expect(@topic.group_category_id).to eq gc.id
    end

    it "returns error when the discussion group category id does not match the assignment" do
      group_category_old = @course.group_categories.create!(name: "Old Group Category")
      group_category_new = @course.group_categories.create!(name: "New Group Category")
      @topic.update!(group_category: group_category_old)
      result = run_mutation(id: @topic.id, group_category_id: group_category_new.id, assignment: { groupCategoryId: group_category_old.id })
      expect(result["errors"][0]["message"]).to eq "Assignment group category id and discussion topic group category id do not match"
    end

    it "updates the ab_guid on the assignment" do
      result = run_mutation(id: @topic.id, assignment: { abGuid: ["1E20776E-7053-11DF-8EBF-BE719DFF4B22", "1e20776e-7053-11df-8eBf-Be719dff4b22"] })
      expect(result["errors"]).to be_nil
      expect(Assignment.last.ab_guid).to eq(["1E20776E-7053-11DF-8EBF-BE719DFF4B22", "1e20776e-7053-11df-8eBf-Be719dff4b22"])
    end

    it "preserves the current ab_guid value on the assignment if abGuid is not passed in from the mutation" do
      result = run_mutation(id: @topic.id, assignment: {})
      expect(result["errors"]).to be_nil
      expect(Assignment.last.ab_guid).to eq(["1E20776E-7053-11DF-8EBF-BE719DFF4B22"])
    end

    it "allows to update the discussion assignment by a user with custom role without :delete assignment permission" do
      special_role = @course.account.roles.create!(name: "teacher without assignment delete", base_role_type: "TeacherEnrollment")
      special_role.role_overrides.create!(permission: "manage_assignments_delete", context: @course.account, enabled: false)
      @teacher.enrollments.first.update!(role: special_role)

      result = run_mutation(id: @topic.id, published: false, assignment: { pointsPossible: 10 }) # assignment is needed to trigger the if

      expect(result["errors"]).to be_nil
    end

    it "syncs the discussion and assignment lock_at and unlock_at fields when the assignment date changes" do
      lock_at = 6.months.from_now.iso8601
      unlock_at = 3.months.from_now.iso8601
      expect(@topic.lock_at).to be_nil
      result = run_mutation(id: @topic.id, assignment: { lockAt: lock_at.to_s, unlockAt: unlock_at.to_s })
      expect(result["errors"]).to be_nil
      expect(@topic.reload.lock_at).to eq lock_at.to_s
      expect(@topic.reload.unlock_at).to eq unlock_at.to_s
    end

    it "clears discussion topic lock_at if assignment lock_at is cleared" do
      @topic.update!(lock_at: 5.days.from_now)
      result = run_mutation(id: @topic.id, assignment: { lockAt: nil })
      expect(result["errors"]).to be_nil
      expect(@topic.reload.lock_at).to be_nil
    end

    it "overrides discussion_topic's lock at" do
      @topic.update!(lock_at: 5.days.from_now)
      new_lock_at = 10.days.from_now.iso8601
      result = run_mutation(id: @topic.id, lock_at: new_lock_at, assignment: { lockAt: nil })
      expect(result["errors"]).to be_nil
      expect(@topic.reload.lock_at).to be_nil
    end

    it "switch back to discussion's lock_at if assignment in unset" do
      new_lock_at = 5.days.from_now.iso8601
      @topic.update!(lock_at: 2.days.from_now)
      result = run_mutation(id: @topic.id, lock_at: new_lock_at, assignment: { lockAt: @topic.assignment.lock_at, setAssignment: false })
      expect(result["errors"]).to be_nil
      expect(@topic.reload.lock_at).to eq new_lock_at
    end
  end

  context "discussion checkpoints" do
    let(:creator_service) { Checkpoints::DiscussionCheckpointCreatorService }

    before do
      @course.account.enable_feature!(:discussion_checkpoints)
      @graded_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic")

      @due_at1 = 2.days.from_now
      @due_at2 = 5.days.from_now

      @checkpoint1 = creator_service.call(
        discussion_topic: @graded_topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: @due_at1 }],
        points_possible: 5
      )

      @checkpoint2 = creator_service.call(
        discussion_topic: @graded_topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: @due_at2 }],
        points_possible: 10,
        replies_required: 2
      )
    end

    it "converts an ungraded discussion into a graded discussion with checkpoints" do
      ungraded_discussion = discussion_topic_model({ context: @course })
      result = run_mutation(id: ungraded_discussion.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      discussion_topic = result.dig("data", "updateDiscussionTopic", "discussionTopic")

      reply_to_topic_checkpoint = discussion_topic["assignment"]["checkpoints"].find { |checkpoint| checkpoint["tag"] == CheckpointLabels::REPLY_TO_TOPIC }
      reply_to_entry_checkpoint = discussion_topic["assignment"]["checkpoints"].find { |checkpoint| checkpoint["tag"] == CheckpointLabels::REPLY_TO_ENTRY }

      aggregate_failures do
        expect(result["errors"]).to be_nil
        expect(reply_to_topic_checkpoint).to be_truthy
        expect(reply_to_entry_checkpoint).to be_truthy
        expect(reply_to_topic_checkpoint["pointsPossible"]).to eq 6
        expect(reply_to_entry_checkpoint["pointsPossible"]).to eq 8
        expect(discussion_topic["replyToEntryRequiredCount"]).to eq 5
      end
    end

    it "successfully updates a discussion topic with checkpoints" do
      new_lock_at = 12.days.from_now
      new_unlock_at = 1.day.from_now
      new_grading_type = "pass_fail"

      result = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true, gradingType: new_grading_type }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601, lockAt: new_lock_at.iso8601, unlockAt: new_unlock_at.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601, lockAt: new_lock_at.iso8601, unlockAt: new_unlock_at.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      discussion_topic = result.dig("data", "updateDiscussionTopic", "discussionTopic")

      reply_to_topic_checkpoint = discussion_topic["assignment"]["checkpoints"].find { |checkpoint| checkpoint["tag"] == CheckpointLabels::REPLY_TO_TOPIC }
      reply_to_entry_checkpoint = discussion_topic["assignment"]["checkpoints"].find { |checkpoint| checkpoint["tag"] == CheckpointLabels::REPLY_TO_ENTRY }

      expect(Assignment.last.unlock_at).to be_within(1.second).of(new_unlock_at)
      expect(Assignment.last.lock_at).to be_within(1.second).of(new_lock_at)
      expect(Assignment.last.grading_type).to eq(new_grading_type)
      expect(Assignment.last.sub_assignments.first.unlock_at).to be_within(1.second).of(new_unlock_at)
      expect(Assignment.last.sub_assignments.first.lock_at).to be_within(1.second).of(new_lock_at)
      expect(Assignment.last.sub_assignments.first.grading_type).to eq(new_grading_type)
      expect(Assignment.last.sub_assignments.last.unlock_at).to be_within(1.second).of(new_unlock_at)
      expect(Assignment.last.sub_assignments.last.lock_at).to be_within(1.second).of(new_lock_at)
      expect(Assignment.last.sub_assignments.last.grading_type).to eq(new_grading_type)

      aggregate_failures do
        expect(result["errors"]).to be_nil
        expect(reply_to_topic_checkpoint).to be_truthy
        expect(reply_to_entry_checkpoint).to be_truthy
        expect(reply_to_topic_checkpoint["pointsPossible"]).to eq 6
        expect(reply_to_entry_checkpoint["pointsPossible"]).to eq 8
        expect(discussion_topic["replyToEntryRequiredCount"]).to eq 5
      end
    end

    it "successfully updates a discussion topic with checkpoints, part two" do
      missing_submission_deduction = 10.0
      @course.create_late_policy(
        missing_submission_deduction_enabled: true,
        missing_submission_deduction:
      )

      @student_for_missing = student_in_course.user

      @graded_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic")

      @reply_to_topic_points = 5
      @reply_to_entry_points = 15

      discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
      @reply_to_topic = creator_service.call(
        discussion_topic: discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "override", set_type: "ADHOC", student_ids: [@student_for_missing.id] }],
        points_possible: @reply_to_topic_points
      )

      @reply_to_entry = creator_service.call(
        discussion_topic: discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "override", set_type: "ADHOC", student_ids: [@student_for_missing.id] }],
        points_possible: @reply_to_entry_points,
        replies_required: 3
      )

      c1_assignment_override = @reply_to_topic.assignment_overrides.active.first
      c2_assignment_override = @reply_to_entry.assignment_overrides.active.first

      result = run_mutation(id: discussion.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ id: c1_assignment_override.id, type: "override", setType: "ADHOC", studentIds: [@student_for_missing.id], dueAt: 14.days.ago.iso8601 }], pointsPossible: @reply_to_topic_points },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ id: c2_assignment_override.id, type: "override", setType: "ADHOC", studentIds: [@student_for_missing.id], dueAt: 7.days.ago.iso8601 }], pointsPossible: @reply_to_entry_points, repliesRequired: 3 }
                            ])

      expect(result["errors"]).to be_nil

      parent_assignment = discussion.assignment
      student2_parent_submission = parent_assignment.submission_for_student(@student_for_missing)
      student2_reply_to_topic_submission = @reply_to_topic.submission_for_student(@student_for_missing)
      student2_reply_to_entry_submission = @reply_to_entry.submission_for_student(@student_for_missing)

      expect(student2_reply_to_topic_submission.missing?).to be true
      expect(student2_reply_to_entry_submission.missing?).to be true
      expect(student2_parent_submission.missing?).to be true

      expected_reply_to_topic_score = @reply_to_topic_points.to_f * ((100 - missing_submission_deduction.to_f) / 100)
      expected_reply_to_entry_score = @reply_to_entry_points.to_f * ((100 - missing_submission_deduction.to_f) / 100)
      expected_parent_score = expected_reply_to_topic_score + expected_reply_to_entry_score

      expect(student2_reply_to_topic_submission.score).to eq expected_reply_to_topic_score
      expect(student2_reply_to_entry_submission.score).to eq expected_reply_to_entry_score

      expect(student2_parent_submission.score).to eq expected_parent_score
    end

    it "updates the reply to topic checkpoint due at date" do
      new_due_at = 3.days.from_now
      result = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: new_due_at.iso8601 }], pointsPossible: 5 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 10, repliesRequired: 2 }
                            ])

      expect(result["errors"]).to be_nil

      @checkpoint1.reload
      expect(@checkpoint1.due_at).to be_within(1.second).of(new_due_at)
    end

    it "can handle updating all due dates at once" do
      # starting dates
      unlock_at = 1.day.from_now
      reply_to_topic_due_at = 2.days.from_now
      reply_to_entry_due_at = 3.days.from_now
      lock_at = 4.days.from_now

      @graded_topic.update!(unlock_at:, lock_at:)

      reply_to_topic_checkpoint = @graded_topic.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      reply_to_entry_checkpoint = @graded_topic.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)
      reply_to_topic_checkpoint.update!(due_at: reply_to_topic_due_at)
      reply_to_entry_checkpoint.update!(due_at: reply_to_entry_due_at)

      # new dates
      unlock_at += 30.days
      reply_to_topic_due_at += 30.days
      reply_to_entry_due_at += 30.days
      lock_at += 30.days

      result = run_mutation(
        id: @graded_topic.id,
        delayed_post_at: unlock_at.iso8601,
        lock_at: lock_at.iso8601,
        assignment: { forCheckpoints: true },
        checkpoints: [
          { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC,
            dates: [{
              type: "everyone",
              dueAt: reply_to_topic_due_at.iso8601,
              unlockAt: unlock_at.iso8601,
              lockAt: lock_at.iso8601,
            }],
            pointsPossible: 5 },
          { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY,
            dates: [{
              type: "everyone",
              dueAt: reply_to_entry_due_at.iso8601,
              unlockAt: unlock_at.iso8601,
              lockAt: lock_at.iso8601,
            }],
            pointsPossible: 10,
            repliesRequired: 2 }
        ]
      )
      aggregate_failures do
        expect(result["errors"]).to be_nil
        expect(reply_to_topic_checkpoint.reload.due_at).to be_within(1.second).of(reply_to_topic_due_at)
        expect(reply_to_entry_checkpoint.reload.due_at).to be_within(1.second).of(reply_to_entry_due_at)
        expect(reply_to_topic_checkpoint.reload.unlock_at).to be_within(1.second).of(unlock_at)
        expect(reply_to_entry_checkpoint.reload.unlock_at).to be_within(1.second).of(unlock_at)
        expect(reply_to_topic_checkpoint.reload.lock_at).to be_within(1.second).of(lock_at)
        expect(reply_to_entry_checkpoint.reload.lock_at).to be_within(1.second).of(lock_at)
      end
    end

    it "updates checkpoints with overrides due dates" do
      section = add_section("M03")
      result1 = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                               { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC,
                                 dates: [
                                   { type: "override", dueAt: @due_at1.iso8601, setType: "CourseSection", setId: section.id }
                                 ],
                                 pointsPossible: 5 },
                               { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY,
                                 dates: [
                                   { type: "override", dueAt: @due_at1.iso8601, setType: "CourseSection", setId: section.id }
                                 ],
                                 pointsPossible: 10,
                                 repliesRequired: 2 }
                             ])

      expect(result1["errors"]).to be_nil
      @checkpoint1.reload
      @checkpoint2.reload

      c1_assignment_override = @checkpoint1.assignment_overrides.active.first
      c2_assignment_override = @checkpoint2.assignment_overrides.active.first

      expect(c1_assignment_override.due_at).to be_within(1.second).of(@due_at1)
      expect(c2_assignment_override.due_at).to be_within(1.second).of(@due_at1)

      result2 = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                               { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC,
                                 dates: [
                                   { type: "override", id: c1_assignment_override.id, dueAt: @due_at2.iso8601, setType: "CourseSection", setId: section.id }
                                 ],
                                 pointsPossible: 5 },
                               { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY,
                                 dates: [
                                   { type: "override", id: c2_assignment_override.id, dueAt: @due_at2.iso8601, setType: "CourseSection", setId: section.id }
                                 ],
                                 pointsPossible: 10,
                                 repliesRequired: 2 }
                             ])

      expect(result2["errors"]).to be_nil

      @checkpoint1.reload
      @checkpoint2.reload

      c1_assignment_override = @checkpoint1.assignment_overrides.active.first
      c2_assignment_override = @checkpoint2.assignment_overrides.active.first

      expect(c1_assignment_override.due_at).to be_within(1.second).of(@due_at2)
      expect(c2_assignment_override.due_at).to be_within(1.second).of(@due_at2)
    end

    it "updates assignments and checkpoints on topic published status" do
      # check unpublished
      total_sub_assignments = SubAssignment.count
      @graded_topic.unpublish!
      @graded_topic.assignment.unpublish!

      expect(@graded_topic.published?).to be false
      expect(@graded_topic.assignment.published?).to be false
      expect(@checkpoint1.reload.published?).to be false
      expect(@checkpoint2.reload.published?).to be false

      # check publish topic,
      result = run_mutation({ id: @graded_topic.id, published: true })
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be true
      @graded_topic.reload
      @checkpoint1.reload
      @checkpoint2.reload
      expect(@graded_topic.published?).to be true
      expect(@graded_topic.assignment.published?).to be true
      expect(@checkpoint1.published?).to be true
      expect(@checkpoint2.published?).to be true

      # check unpublish topic
      result = run_mutation({ id: @graded_topic.id, published: false })

      @graded_topic.reload
      @checkpoint1.reload
      @checkpoint2.reload
      expect(@graded_topic.published?).to be false
      expect(@graded_topic.assignment.published?).to be false
      expect(@checkpoint1.published?).to be false
      expect(@checkpoint2.published?).to be false

      # confirm no extra sub assignments are created
      expect(total_sub_assignments).to eq(SubAssignment.count)
      expect(result["errors"]).to be_nil
    end

    it "updates the reply to topic overrides to add a section override and then, remove it" do
      section = add_section("M03")

      result1 = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                               { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC,
                                 dates: [
                                   { type: "everyone", dueAt: @due_at1.iso8601 },
                                   { type: "override", dueAt: @due_at2.iso8601, setType: "CourseSection", setId: section.id }
                                 ],
                                 pointsPossible: 5 },
                               { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY,
                                 dates: [
                                   { type: "everyone", dueAt: @due_at2.iso8601 }
                                 ],
                                 pointsPossible: 10,
                                 repliesRequired: 2 }
                             ])

      expect(result1["errors"]).to be_nil

      @checkpoint1.reload
      @checkpoint2.reload

      c1_assignment_overrides = @checkpoint1.assignment_overrides.active
      c2_assignment_overrides = @checkpoint2.assignment_overrides.active

      expect(c1_assignment_overrides.count).to eq(1)
      expect(c2_assignment_overrides.count).to eq(0)

      c1_section_override = c1_assignment_overrides.find_by(set_type: "CourseSection", set_id: section.id)

      expect(c1_section_override).to be_present
      expect(c1_section_override.due_at).to be_within(1.second).of(@due_at2)

      result2 = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                               { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC,
                                 dates: [
                                   { type: "everyone", dueAt: @due_at1.iso8601 }
                                 ],
                                 pointsPossible: 5 },
                               { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY,
                                 dates: [
                                   { type: "everyone", dueAt: @due_at2.iso8601 }
                                 ],
                                 pointsPossible: 10,
                                 repliesRequired: 2 }
                             ])

      expect(result2["errors"]).to be_nil

      @checkpoint1.reload
      @checkpoint2.reload

      c1_assignment_overrides2 = @checkpoint1.assignment_overrides.active
      c2_assignment_overrides2 = @checkpoint2.assignment_overrides.active

      expect(c1_assignment_overrides2.count).to eq(0)
      expect(c2_assignment_overrides2.count).to eq(0)
    end

    it "delete checkpoints when set_checkpoints is false" do
      result = run_mutation(id: @graded_topic.id, set_checkpoints: false)
      expect(result["errors"]).to be_nil

      @graded_topic.reload
      assignment = @graded_topic.assignment
      active_checkpoints = assignment.sub_assignments.active

      expect(active_checkpoints.count).to eq(0)
    end

    it "can edit a non-checkpointed discussion to a checkpointed discussion" do
      @course.enroll_student(User.create!, enrollment_state: "active")
      @discussion_assignment = @course.assignments.create!(
        title: "Graded Topic 1",
        submission_types: "discussion_topic",
        post_to_sis: false,
        grading_type: "points",
        points_possible: 5,
        due_at: 3.months.from_now,
        peer_reviews: false
      )

      @non_checkpoint_topic = @discussion_assignment.discussion_topic
      assignment = Assignment.last

      expect(assignment.due_at).to be_within(1.minute).of(3.months.from_now)
      expect(assignment.submissions.first.cached_due_date).to be_within(1.minute).of(3.months.from_now)

      run_mutation(id: @non_checkpoint_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                     { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                     { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                   ])

      assignment.reload
      expect(assignment.has_sub_assignments?).to be true
      expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 5

      sub_assignments = SubAssignment.where(parent_assignment_id: assignment.id)
      sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      expect(sub_assignment1.sub_assignment_tag).to eq "reply_to_topic"
      expect(sub_assignment1.points_possible).to eq 6
      expect(sub_assignment2.sub_assignment_tag).to eq "reply_to_entry"
      expect(sub_assignment2.points_possible).to eq 8
      expect(assignment.points_possible).to eq 14
      expect(assignment.due_at).to be_nil
      expect(assignment.submissions.first.cached_due_date).to be_nil
    end

    it "can turn a graded checkpointed discussion into a non-graded discussion" do
      result = run_mutation(id: @graded_topic.id, assignment: { setAssignment: false })
      expect(result["errors"]).to be_nil

      assignment = Assignment.last

      expect(assignment.has_sub_assignments?).to be false
      expect(assignment.sub_assignments.count).to eq 0
      expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 0
      expect(@graded_topic.reload.assignment).to be_nil
    end

    it "returns an error if the sum of points possible for the checkpoints exceeds the max for the assignment" do
      result = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC,
                                dates: [],
                                pointsPossible: 999_999_999 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY,
                                dates: [],
                                pointsPossible: 1,
                                repliesRequired: 2 }
                            ])
      expect_error(result, "The value of possible points for this assignment cannot exceed 999999999.")
    end

    it "returns an error when attempting add a group category to a discussion with checkpoints" do
      @course.account.disable_feature!(:checkpoints_group_discussions)
      group_category = @course.group_categories.create!(name: "My Group Category")
      # even though @graded_topic has checkpoints, we still need to pass in the actual checkpoints so they are not cleared out
      result = run_mutation(id: @graded_topic.id, group_category_id: group_category.id, assignment: { forCheckpoints: true, groupCategoryId: group_category.id }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      expect_error(result, "Group discussions cannot have checkpoints.")
    end

    it "can turn a checkpointed discussion into a group discussion as well" do
      group_category = @course.group_categories.create!(name: "My Group Category")
      @course.groups.create!(name: "g1", group_category:)
      @course.groups.create!(name: "g2", group_category:)

      result = run_mutation(id: @graded_topic.id, group_category_id: group_category.id, assignment: { forCheckpoints: true, groupCategoryId: group_category.id }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      expect(result["errors"]).to be_nil
      expect(@graded_topic.child_topics.count).to eq 2
    end

    it "returns an error when attempting to add checkpoints to a graded group discussion" do
      @course.account.disable_feature!(:checkpoints_group_discussions)
      group_category = @course.group_categories.create!(name: "My Group Category")
      topic = group_discussion_assignment

      result = run_mutation(id: topic.id, group_category_id: group_category.id, assignment: { forCheckpoints: true, groupCategoryId: group_category.id }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      expect_error(result, "Group discussions cannot have checkpoints.")
    end

    it "group discussions can still become checkpointed if checkpoints_group_discussions feature is enabled" do
      group_category = @course.group_categories.create!(name: "My Group Category")
      topic = group_discussion_assignment

      result = run_mutation(id: topic.id, group_category_id: group_category.id, assignment: { forCheckpoints: true, groupCategoryId: group_category.id }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      expect(result["errors"]).to be_nil

      assignment = Assignment.last
      expect(assignment.has_sub_assignments?).to be true
      topic.reload
      expect(topic.reply_to_entry_required_count).to eq 5
      expect(topic.sub_assignments.count).to eq 2
    end

    it "returns an error when attempting to add checkpoints to a graded discussion with student submissions" do
      discussion_assignment = @course.assignments.create!(
        title: "Topic 1",
        submission_types: "discussion_topic"
      )
      student = student_in_course.user
      topic = discussion_assignment.discussion_topic
      topic.ensure_particular_submission(discussion_assignment, student, Time.zone.now)
      result = run_mutation(id: topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      expect_error(result, "If there are replies, checkpoints cannot be enabled.")
    end

    it "returns an error when attemting to add checkpoints to an ungraded discussion with replies" do
      my_topic = discussion_topic_model({ context: @course, attachment: @attachment })
      my_topic.discussion_entries.create!(message: "first message", user: @teacher)

      result = run_mutation(id: my_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])
      expect(my_topic.assignment).to be_nil
      expect(my_topic.reply_to_entry_required_count).to eq 0
      expect_error(result, "If there are replies, checkpoints cannot be enabled.")
    end

    it "graded discussions with only deleted replies can still become checkpointed" do
      student = student_in_course.user
      graded_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic")
      entry = graded_topic.discussion_entries.create!(message: "delete me", user: student)
      entry.destroy
      expect(graded_topic.discussion_entries.active).to be_empty

      result = run_mutation(id: graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      expect(result["errors"]).to be_nil

      assignment = Assignment.last
      expect(assignment.has_sub_assignments?).to be true
      expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 5
    end

    it "ungraded discussions with only deleted replies can still become checkpointed" do
      my_topic = discussion_topic_model({ context: @course, attachment: @attachment })
      entry = my_topic.discussion_entries.create!(message: "first message", user: @teacher)
      entry.destroy
      expect(my_topic.discussion_entries.active).to be_empty
      result = run_mutation(id: my_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                              { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC, dates: [{ type: "everyone", dueAt: @due_at1.iso8601 }], pointsPossible: 6 },
                              { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY, dates: [{ type: "everyone", dueAt: @due_at2.iso8601 }], pointsPossible: 8, repliesRequired: 5 }
                            ])

      expect(result["errors"]).to be_nil

      assignment = Assignment.last
      expect(assignment.has_sub_assignments?).to be true
      expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 5
    end

    context "with differentiation tag overrides" do
      before do
        @course.account.enable_feature!(:assign_to_differentiation_tags)
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: true }
          a.save!
        end

        @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
        @diff_tag1 = @course.groups.create!(name: "Diff Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
      end

      it "allows differentiation tag overrides on checkpointed discussions" do
        result = run_mutation(id: @graded_topic.id, assignment: { forCheckpoints: true }, checkpoints: [
                                { checkpointLabel: CheckpointLabels::REPLY_TO_TOPIC,
                                  dates: [
                                    { type: "everyone", dueAt: @due_at1.iso8601 },
                                    { type: "override", setType: "Group", setId: @diff_tag1.id, dueAt: @due_at1.iso8601 }
                                  ],
                                  pointsPossible: 6 },
                                { checkpointLabel: CheckpointLabels::REPLY_TO_ENTRY,
                                  dates: [
                                    { type: "everyone", dueAt: @due_at2.iso8601 },
                                    { type: "override", setType: "Group", setId: @diff_tag1.id, dueAt: @due_at2.iso8601 }
                                  ],
                                  pointsPossible: 8,
                                  repliesRequired: 5 }
                              ])

        expect(result["errors"]).to be_nil

        @checkpoint1.reload
        @checkpoint2.reload

        c1_assignment_overrides = @checkpoint1.assignment_overrides.active
        c2_assignment_overrides = @checkpoint2.assignment_overrides.active

        expect(c1_assignment_overrides.count).to eq(1)
        expect(c2_assignment_overrides.count).to eq(1)

        c1_diff_tag_override = c1_assignment_overrides.find_by(set_type: "Group", set_id: @diff_tag1.id)

        expect(c1_diff_tag_override).to be_present
        expect(c1_diff_tag_override.due_at).to be_within(1.second).of(@due_at1)
      end
    end
  end

  context "with selective release" do
    it "updates ungraded assignment overrides" do
      student1 = @course.enroll_student(User.create!, enrollment_state: "active").user
      student2 = @course.enroll_student(User.create!, enrollment_state: "active").user
      @course.enroll_student(User.create!, enrollment_state: "active").user

      ungraded_discussion_overrides = {
        studentIds: [student1.id, student2.id]
      }
      result = run_mutation(id: @topic.id, ungraded_discussion_overrides:)
      expect(result["errors"]).to be_nil

      new_override = DiscussionTopic.last.active_assignment_overrides.first

      expect(new_override.set_type).to eq("ADHOC")
      expect(new_override.set_id).to be_nil
      expect(new_override.set.map(&:id)).to match_array([student1.id, student2.id])
    end

    it "updates an announcement to be section specific" do
      announcement1 = @course.announcements.create!(title: "Announcement Title", message: "Announcement Message", user: @teacher)
      section1 = @course.course_sections.create!(name: "Section 1")

      result = run_mutation(id: announcement1.id, specific_sections: section1.id)
      expect(result["errors"]).to be_nil
      expect(Announcement.last.is_section_specific).to be_truthy
      expect(Announcement.last.course_sections.pluck(:id)).to eq([section1.id])
    end

    it "updates a section specific announcement to be unspecific" do
      section1 = @course.course_sections.create!(name: "Section 1")
      announcement1 = @course.announcements.create!(title: "Announcement Title", message: "Announcement Message", user: @teacher, course_sections: [section1], is_section_specific: true)
      result = run_mutation(id: announcement1.id, specific_sections: "all")
      expect(result["errors"]).to be_nil
      expect(Announcement.last.is_section_specific).to be_falsy
      expect(Announcement.last.course_sections.pluck(:id)).to eq([])
    end

    it "delete the section of section specific announcement" do
      section1 = @course.course_sections.create!(name: "Section 1")
      announcement1 = @course.announcements.create!(title: "Announcement Title", message: "Announcement Message", user: @teacher, course_sections: [section1], is_section_specific: true)
      section1.destroy!
      expect(Announcement.last.is_section_specific).to be_truthy
      expect(Announcement.last.course_sections.pluck(:id)).to eq([])
      result = run_mutation(id: announcement1.id, specific_sections: "all")
      expect(result["errors"]).to be_nil
      expect(Announcement.last.is_section_specific).to be_falsy
    end
  end

  context "discussion_default_expand and discussion_default_sort" do
    it "updates the default sort order" do
      result = run_mutation({ id: @topic.id, sort_order: :asc })[:data][:updateDiscussionTopic]
      expect(result["errors"]).to be_nil
      expect(result[:discussionTopic][:sortOrder]).to eq("asc")
      result = run_mutation({ id: @topic.id, sort_order_locked: true })[:data][:updateDiscussionTopic]
      expect(result["errors"]).to be_nil
      expect(result[:discussionTopic][:sortOrderLocked]).to be true
    end

    it "updates the default expand fields" do
      result = run_mutation({ id: @topic.id, expanded: true })[:data][:updateDiscussionTopic]
      expect(result["errors"]).to be_nil
      expect(@topic.reload.expanded).to be true
      result = run_mutation({ id: @topic.id, expanded_locked: true })[:data][:updateDiscussionTopic]
      expect(result["errors"]).to be_nil
      expect(@topic.reload.expanded_locked).to be true
    end

    it "fails to update, if default_expand = false and default_expand_locked = true" do
      result = run_mutation({ id: @topic.id, expanded: false, expanded_locked: true })[:data][:updateDiscussionTopic]
      expect(result["errors"][0]["message"]).to match(/Cannot set default thread state locked, when threads are collapsed/)
    end
  end
end
