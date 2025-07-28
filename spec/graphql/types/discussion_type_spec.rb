# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

RSpec.shared_context "DiscussionTypeContext" do
  let(:discussion_type) { GraphQLTypeTester.new(discussion, current_user: @teacher) }
  let(:default_permissions) do
    [
      {
        value: "attach",
        allowed: ->(user) { discussion.grants_right?(user, nil, :attach) }
      },
      {
        value: "create",
        allowed: ->(user) { discussion.grants_right?(user, nil, :create) }
      },
      {
        value: "delete",
        allowed: ->(user) { discussion.grants_right?(user, nil, :delete) && !discussion.editing_restricted?(:any) }
      },
      {
        value: "duplicate",
        allowed: ->(user) { discussion.grants_right?(user, nil, :duplicate) }
      },
      {
        value: "moderateForum",
        allowed: ->(user) { discussion.grants_right?(user, nil, :moderate_forum) }
      },
      {
        value: "rate",
        allowed: ->(user) { discussion.grants_right?(user, nil, :rate) }
      },
      {
        value: "read",
        allowed: ->(user) { discussion.grants_right?(user, nil, :read) }
      },
      {
        value: "readAsAdmin",
        allowed: ->(user) { discussion.grants_right?(user, nil, :read_as_admin) }
      },
      {
        value: "studentReporting",
        allowed: ->(_user) { discussion.course.student_reporting? }
      },
      {
        value: "readReplies",
        allowed: ->(user) { discussion.grants_right?(user, nil, :read_replies) }
      },
      {
        value: "reply",
        allowed: ->(user) { discussion.grants_right?(user, nil, :reply) }
      },
      {
        value: "update",
        allowed: ->(user) { discussion.grants_right?(user, nil, :update) }
      },
      {
        value: "speedGrader",
        allowed: lambda do |user|
          permission = !discussion.assignment.context.large_roster? && discussion.assignment_id && discussion.assignment.published?
          if discussion.assignment.context.concluded?
            permission && discussion.assignment.context.grants_right?(user, :read_as_admin)
          else
            permission && discussion.assignment.context.grants_any_right?(user, :manage_grades, :view_all_grades)
          end
        end
      },
      {
        value: "peerReview",
        allowed: lambda do |user|
          discussion.assignment_id &&
            discussion.assignment.published? &&
            discussion.assignment.has_peer_reviews? &&
            discussion.assignment.grants_right?(user, :grade)
        end
      },
      {
        value: "showRubric",
        allowed: ->(_user) { !discussion.assignment_id.nil? && !discussion.assignment.rubric.nil? }
      },
      {
        value: "addRubric",
        allowed: lambda do |user|
          !discussion.assignment_id.nil? &&
            discussion.assignment.rubric.nil? &&
            discussion.assignment.grants_right?(user, :update)
        end
      },
      {
        value: "openForComments",
        allowed: lambda do |user|
          !discussion.comments_disabled? &&
            discussion.locked &&
            discussion.grants_right?(user, :moderate_forum)
        end
      },
      {
        value: "closeForComments",
        allowed: lambda do |user|
          discussion.can_lock? &&
            !discussion.comments_disabled? &&
            !discussion.locked &&
            discussion.grants_right?(user, :moderate_forum)
        end
      },
      {
        value: "copyAndSendTo",
        allowed: ->(user) { discussion.context.grants_right?(user, :read_as_admin) }
      }
    ]
  end
  let(:manage_course_content_permissions) do
    [
      {
        value: "manageCourseContentAdd",
        allowed: ->(user) { discussion.context.grants_right?(user, :manage_course_content_add) }
      },
      {
        value: "manageCourseContentEdit",
        allowed: ->(user) { discussion.context.grants_right?(user, :manage_course_content_edit) }
      },
      {
        value: "manageCourseContentDelete",
        allowed: ->(user) { discussion.context.grants_right?(user, :manage_course_content_delete) }
      }
    ]
  end
  let(:permissions) do
    default_permissions.concat(manage_course_content_permissions)
  end
end

RSpec.shared_examples "DiscussionType" do
  include_context "DiscussionTypeContext"

  it "works" do
    expect(discussion_type.resolve("_id")).to eq discussion.id.to_s
  end

  context "when file_association_access is enabled" do
    it "tags attachment urls with asset location" do
      attachment = attachment_model(context: @course)
      attachment.root_account.enable_feature!(:file_association_access)
      discussion_topic = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                 message: "<img src='/courses/#{@course.id}/files/#{attachment.id}'>",
                                                 anonymous_state: "partial_anonymity",
                                                 context: @course,
                                                 user: @teacher,
                                                 editor: @teacher,
                                                 attachment:,
                                                 is_anonymous_author: true)
      discussion_type = GraphQLTypeTester.new(discussion_topic, current_user: @teacher, domain_root_account: attachment.root_account)

      result = discussion_type.resolve("message", request: ActionDispatch::TestRequest.create)
      expect(result).to include("location=#{discussion_topic.asset_string}")
    end
  end

  it "returns if the current user requires an initial post" do
    discussion.update!(require_initial_post: true)
    student_in_course(active_all: true)
    discussion.discussion_entries.create!(message: "other student entry", user: @student)

    student_in_course(active_all: true)
    type_with_student = GraphQLTypeTester.new(discussion, current_user: @student)

    expect(type_with_student.resolve("initialPostRequiredForCurrentUser")).to be true
    expect(type_with_student.resolve("discussionEntriesConnection { nodes { message } }").count).to eq 0

    discussion.discussion_entries.create!(message: "Here is my entry", user: @student)
    expect(type_with_student.resolve("initialPostRequiredForCurrentUser")).to be false
    expect(type_with_student.resolve("discussionEntriesConnection { nodes { message } }").count).to eq 2
  end

  it "allows querying for entry counts" do
    3.times { discussion.discussion_entries.create!(message: "sub entry", user: @teacher) }
    discussion.discussion_entries.take.destroy
    expect(discussion_type.resolve("entryCounts { deletedCount }")).to eq 1
    expect(discussion_type.resolve("entryCounts { unreadCount }")).to eq 0
    expect(discussion_type.resolve("entryCounts { repliesCount }")).to eq 2
    DiscussionEntryParticipant.where(user_id: @teacher).update_all(workflow_state: "unread")
    expect(discussion_type.resolve("entryCounts { deletedCount }")).to eq 1
    expect(discussion_type.resolve("entryCounts { unreadCount }")).to eq 2
    expect(discussion_type.resolve("entryCounts { repliesCount }")).to eq 2
  end

  it "queries the attribute" do
    expect(discussion_type.resolve("title")).to eq discussion.title
    expect(discussion_type.resolve("anonymousState")).to eq discussion.anonymous_state
    expect(discussion_type.resolve("podcastEnabled")).to eq discussion.podcast_enabled
    expect(discussion_type.resolve("podcastHasStudentPosts")).to eq discussion.podcast_has_student_posts
    expect(discussion_type.resolve("discussionType")).to eq discussion.discussion_type
    expect(discussion_type.resolve("position")).to eq discussion.position
    expect(discussion_type.resolve("allowRating")).to eq discussion.allow_rating
    expect(discussion_type.resolve("onlyGradersCanRate")).to eq discussion.only_graders_can_rate
    expect(discussion_type.resolve("sortByRating")).to eq discussion.sort_by_rating
    expect(discussion_type.resolve("todoDate")).to eq discussion.todo_date
    expect(discussion_type.resolve("isSectionSpecific")).to eq discussion.is_section_specific

    expect(discussion_type.resolve("rootTopic { _id }")).to eq discussion.root_topic_id&.to_s

    expect(discussion_type.resolve("assignment { _id }")).to eq discussion.assignment_id.to_s
    expect(discussion_type.resolve("delayedPostAt")).to eq discussion.delayed_post_at
    expect(discussion_type.resolve("lockAt")).to eq discussion.lock_at
    expect(discussion_type.resolve("userCount")).to eq discussion.course.users.count
    expect(discussion_type.resolve("replyToEntryRequiredCount")).to eq discussion.reply_to_entry_required_count

    expect(discussion_type.resolve("sortOrder")).to eq discussion.sort_order
    expect(discussion_type.resolve("sortOrderLocked")).to eq discussion.sort_order_locked
    expect(discussion_type.resolve("expanded")).to eq discussion.expanded
    expect(discussion_type.resolve("expandedLocked")).to eq discussion.expanded_locked
  end

  it "orders root_entries by their created_at" do
    de = discussion.discussion_entries.create!(message: "root entry", user: @teacher)
    de2 = discussion.discussion_entries.create!(message: "root entry", user: @teacher)
    de3 = discussion.discussion_entries.create!(message: "root entry", user: @teacher)
    # adding a discussion entry should NOT impact sort order of root entries
    discussion.discussion_entries.create!(message: "sub entry", user: @teacher, parent_id: de2.id)
    discussion.update!(sort_order: "asc", sort_order_locked: true)
    expect(discussion_type.resolve("discussionEntriesConnection(rootEntries: true) { nodes { _id } }")).to eq [de.id, de2.id, de3.id].map(&:to_s)
    discussion.update!(sort_order: "desc")
    expect(discussion_type.resolve("discussionEntriesConnection(rootEntries: true) { nodes { _id } }")).to eq [de3.id, de2.id, de.id].map(&:to_s)
    discussion.discussion_entries.create!(message: "sub entry", user: @teacher, parent_id: de3.id)
    expect(discussion_type.resolve("discussionEntriesConnection(rootEntries: true) { nodes { _id } }")).to eq [de3.id, de2.id, de.id].map(&:to_s)
  end

  it "loads discussion_entry_drafts" do
    de = discussion.discussion_entries.create!(message: "root entry", user: @teacher)
    dr = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: discussion, message: "hey")
    dr2 = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: discussion, message: "hooo", parent: de)
    dr3 = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: discussion, message: "party now", entry: de)
    # not going to be included cause other user
    DiscussionEntryDraft.upsert_draft(user: user_model, topic: discussion, message: "party now", entry: de)
    ids = discussion_type.resolve("discussionEntryDraftsConnection { nodes { _id } }")
    expect(ids).to match_array([dr, dr2, dr3].flatten.map(&:to_s))
    messages = discussion_type.resolve("discussionEntryDraftsConnection { nodes { message } }")
    expect(messages).to match_array(["hey", "hooo", "party now"])
  end

  it "allows querying root discussion entries" do
    de = discussion.discussion_entries.create!(message: "root entry", user: @teacher)
    discussion.discussion_entries.create!(message: "sub entry", user: @teacher, parent_id: de.id)

    result = discussion_type.resolve("discussionEntriesConnection(rootEntries:true) { nodes { message } }")
    expect(result.count).to be 1
    expect(result[0]).to eq de.message
  end

  it "has modules" do
    module1 = discussion.course.context_modules.create!(name: "Module 1")
    module2 = discussion.course.context_modules.create!(name: "Module 2")
    discussion.context_module_tags.create!(context_module: module1, context: discussion.course, tag_type: "context_module")
    discussion.context_module_tags.create!(context_module: module2, context: discussion.course, tag_type: "context_module")
    expect(discussion_type.resolve("modules { _id }").sort).to eq [module1.id.to_s, module2.id.to_s].sort
  end

  it "has an attachment" do
    a = attachment_model
    discussion.attachment = a
    discussion.save!

    expect(discussion_type.resolve("attachment { _id }")).to eq discussion.attachment.id.to_s
    expect(discussion_type.resolve("attachment { displayName }")).to eq discussion.attachment.display_name
  end

  it "has a group_set" do
    expect(discussion_type.resolve("groupSet { name }")).to eq discussion.group_category&.name
  end

  context "graded discussion" do
    it "allows querying the assignment type on a discussion" do
      Assignment::ALLOWED_GRADING_TYPES.each do |grading_type|
        discussion.assignment.update!(grading_type:)
        expect(discussion_type.resolve("assignment { gradingType }")).to eq grading_type
      end
    end
  end

  context "anonymous discussions" do
    before do
      @anon_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                 message: "anonymous discussion",
                                                 anonymous_state: "full_anonymity",
                                                 context: @course,
                                                 user: @teacher,
                                                 editor: @teacher)
      @anon_discussion_type = GraphQLTypeTester.new(
        @anon_discussion,
        current_user: @teacher
      )

      course_with_student(course: @course)
      @anon_student_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                         message: "anonymous discussion",
                                                         anonymous_state: "full_anonymity",
                                                         context: @course,
                                                         user: @student,
                                                         editor: @student)
      @anon_student_discussion_type = GraphQLTypeTester.new(
        @anon_student_discussion,
        current_user: @teacher
      )
      @anon_discussion_as_student_type = GraphQLTypeTester.new(
        @anon_student_discussion,
        current_user: @student
      )

      course_with_designer(course: @course)
      @anon_designer_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                          message: "anonymous discussion",
                                                          anonymous_state: "full_anonymity",
                                                          context: @course,
                                                          user: @designer,
                                                          editor: @designer)
      @anon_designer_discussion_type = GraphQLTypeTester.new(
        @anon_designer_discussion,
        current_user: @teacher
      )

      @anon_teacher_discussion_with_anonymous_author = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                                               message: "anonymous discussion",
                                                                               anonymous_state: "partial_anonymity",
                                                                               context: @course,
                                                                               user: @teacher,
                                                                               editor: @teacher,
                                                                               is_anonymous_author: true)
      @anon_teacher_discussion_with_anonymous_author_type = GraphQLTypeTester.new(
        @anon_teacher_discussion_with_anonymous_author,
        current_user: @teacher
      )

      @anon_teacher_discussion_with_non_anonymous_author = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                                                   message: "anonymous discussion",
                                                                                   anonymous_state: "partial_anonymity",
                                                                                   context: @course,
                                                                                   user: @teacher,
                                                                                   editor: @teacher,
                                                                                   is_anonymous_author: false)
      @anon_teacher_discussion_with_non_anonymous_author_type = GraphQLTypeTester.new(
        @anon_teacher_discussion_with_non_anonymous_author,
        current_user: @teacher
      )

      @anon_student_discussion_with_anonymous_author = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                                               message: "anonymous discussion",
                                                                               anonymous_state: "partial_anonymity",
                                                                               context: @course,
                                                                               user: @student,
                                                                               editor: @student,
                                                                               is_anonymous_author: true)
      @anon_student_discussion_with_anonymous_author_type = GraphQLTypeTester.new(
        @anon_student_discussion_with_anonymous_author,
        current_user: @teacher
      )

      @anon_student_discussion_with_non_anonymous_author = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                                                   message: "anonymous discussion",
                                                                                   anonymous_state: "partial_anonymity",
                                                                                   context: @course,
                                                                                   user: @student,
                                                                                   editor: @student,
                                                                                   is_anonymous_author: false)
      @anon_student_discussion_with_non_anonymous_author_type = GraphQLTypeTester.new(
        @anon_student_discussion_with_non_anonymous_author,
        current_user: @teacher
      )

      @custom_teacher = user_factory(name: "custom teacher")
      teacher_role_custom = custom_teacher_role("CustomTeacherRole", account: @course.account)
      course_with_user("TeacherEnrollment", course: @course, user: @custom_teacher, active_all: true, role: teacher_role_custom)
      @anon_custom_teacher_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                                message: "anonymous discussion",
                                                                anonymous_state: "full_anonymity",
                                                                context: @course,
                                                                user: @custom_teacher,
                                                                editor: @custom_teacher)
      @anon_custom_teacher_discussion_type = GraphQLTypeTester.new(
        @anon_custom_teacher_discussion,
        current_user: @teacher
      )

      @custom_ta = user_factory(name: "custom ta")
      ta_role_custom = custom_ta_role("CustomTARole", account: @course.account)
      course_with_user("TaEnrollment", course: @course, user: @custom_ta, active_all: true, role: ta_role_custom)
      @anon_custom_ta_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                           message: "anonymous discussion",
                                                           anonymous_state: "full_anonymity",
                                                           context: @course,
                                                           user: @custom_ta,
                                                           editor: @custom_ta)
      @anon_custom_ta_discussion_type = GraphQLTypeTester.new(
        @anon_custom_ta_discussion,
        current_user: @teacher
      )

      @custom_designer = user_factory(name: "custom designer")
      designer_role_custom = custom_designer_role("CustomDesignerRole", account: @course.account)
      course_with_user("DesignerEnrollment", course: @course, user: @custom_designer, active_all: true, role: designer_role_custom)
      @anon_custom_designer_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                                 message: "anonymous discussion",
                                                                 anonymous_state: "full_anonymity",
                                                                 context: @course,
                                                                 user: @custom_designer,
                                                                 editor: @custom_designer)
      @anon_custom_designer_discussion_type = GraphQLTypeTester.new(
        @anon_custom_designer_discussion,
        current_user: @teacher
      )
    end

    it "teacher author is not nil" do
      expect(@anon_discussion_type.resolve("author { shortName }")).to eq @teacher.short_name
    end

    it "editor is nil" do
      expect(@anon_discussion_type.resolve("editor { shortName }")).to be_nil
    end

    it "anonymous_author is not nil" do
      expect(@anon_discussion_type.resolve("anonymousAuthor { shortName }")).to eq "current_user"
    end

    it "mentionableUsersConnection is nil" do
      expect(@anon_discussion_type.resolve("mentionableUsersConnection { nodes { _id } }")).to be_nil
    end

    it "returns the teacher author if a course id is provided" do
      expect(@anon_discussion_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @teacher.short_name
    end

    it "returns the author of custom teacher post" do
      expect(@anon_custom_teacher_discussion_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @custom_teacher.short_name
    end

    it "returns the author of custom TA post" do
      expect(@anon_custom_ta_discussion_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @custom_ta.short_name
    end

    it "returns the author of custom designer post" do
      expect(@anon_custom_designer_discussion_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @custom_designer.short_name
    end

    it "returns the teacher editor if a course id is provided" do
      expect(@anon_discussion_type.resolve("editor(courseId: \"#{@course.id}\") { shortName }")).to eq @teacher.short_name
    end

    it "returns the designer author if a course id is provided" do
      expect(@anon_designer_discussion_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @designer.short_name
    end

    it "returns the designer editor if a course id is provided" do
      expect(@anon_designer_discussion_type.resolve("editor(courseId: \"#{@course.id}\") { shortName }")).to eq @designer.short_name
    end

    it "does not return the student author if a course id is provided" do
      expect(@anon_student_discussion_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to be_nil
    end

    it "does not return the student editor if a course id is provided" do
      expect(@anon_student_discussion_type.resolve("editor(courseId: \"#{@course.id}\") { shortName }")).to be_nil
    end

    context "partial anonymity" do
      context "when is_anonymous_author is true" do
        it "returns teacher as author" do
          expect(@anon_teacher_discussion_with_anonymous_author_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @teacher.short_name
        end

        it "does not return as student author" do
          expect(@anon_student_discussion_with_anonymous_author_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to be_nil
        end

        it "does not return as student editor" do
          expect(@anon_student_discussion_with_anonymous_author_type.resolve("editor(courseId: \"#{@course.id}\") { shortName }")).to be_nil
        end

        it "returns student's anonymousAuthor" do
          expect(@anon_student_discussion_with_anonymous_author_type.resolve("anonymousAuthor { shortName }")).to eq @anon_student_discussion_with_anonymous_author.discussion_topic_participants.where(user_id: @student.id).first.id.to_s(36)
        end
      end

      context "when is_anonymous_author is false" do
        it "returns teacher as author" do
          expect(@anon_teacher_discussion_with_non_anonymous_author_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @teacher.short_name
        end

        it "returns student as author" do
          expect(@anon_student_discussion_with_non_anonymous_author_type.resolve("author(courseId: \"#{@course.id}\") { shortName }")).to eq @student.short_name
        end

        it "returns student as editor" do
          expect(@anon_student_discussion_with_non_anonymous_author_type.resolve("editor(courseId: \"#{@course.id}\") { shortName }")).to eq @student.short_name
        end

        it "does not return student's anonymousAuthor" do
          expect(@anon_student_discussion_with_non_anonymous_author_type.resolve("anonymousAuthor { shortName }")).to be_nil
        end
      end
    end

    context "can reply anonymously" do
      it "returns false for teachers" do
        expect(@anon_discussion_type.resolve("canReplyAnonymously")).to be false
      end

      it "returns true for students" do
        expect(@anon_discussion_as_student_type.resolve("canReplyAnonymously")).to be true
      end
    end
  end

  context "allows filtering discussion entries by workflow_state" do
    before do
      @de = discussion.discussion_entries.create!(message: "find me", user: @teacher)
      student_in_course(active_all: true)
      @de2 = discussion.discussion_entries.create!(message: "not me", user: @student)
    end

    it "at message body" do
      result = discussion_type.resolve('discussionEntriesConnection(searchTerm:"find") { nodes { message } }')
      expect(result.count).to be 1
      expect(result[0]).to eq @de.message
    end

    it "at author name" do
      @student.update(name: "Student")

      result = discussion_type.resolve('discussionEntriesConnection(searchTerm:"student") { nodes { message } }')
      expect(result.count).to be 1
      expect(result[0]).to eq @de2.message
    end
  end

  context "search entry count" do
    before do
      @de = discussion.discussion_entries.create!(message: "peekaboo", user: @teacher)
      @de2 = discussion.discussion_entries.create!(message: "find me", user: @teacher)
    end

    it "only counts entries that match the search term" do
      entry_count = discussion_type.resolve('searchEntryCount(filter: all, searchTerm: "boo")')
      result = discussion_type.resolve('discussionEntriesConnection(searchTerm:"boo") { nodes { message } }')
      expect(result.count).to be 1
      expect(entry_count).to be 1
    end
  end

  context "allows filtering discussion entries" do
    before do
      @de = discussion.discussion_entries.create!(message: "peekaboo", user: @teacher)
      @de2 = discussion.discussion_entries.create!(message: "find me", user: @teacher)
      @de2.change_read_state("unread", @teacher)
    end

    it "by any workflow state" do
      result = discussion_type.resolve("discussionEntriesConnection(filter:all) { nodes { message } }")
      expect(result.count).to be 2
    end

    it "by unread workflow state" do
      @de.change_read_state("read", @teacher)
      result = discussion_type.resolve("discussionEntriesConnection(filter:unread) { nodes { message } }")
      expect(result.count).to be 1
      expect(result[0]).to eq @de2.message
    end

    it "by deleted workflow state" do
      @de2.destroy
      result = discussion_type.resolve("discussionEntriesConnection(filter:deleted) { nodes { deleted } }")

      expect(result.count).to be 1
      expect(result[0]).to be true
    end
  end

  it "returns the current user permissions" do
    student_in_course(active_all: true)
    type_with_student = GraphQLTypeTester.new(discussion, current_user: @student)

    permissions.each do |permission|
      expect(discussion_type.resolve("permissions { #{permission[:value]} }")).to eq permission[:allowed].call(@teacher)

      expect(type_with_student.resolve("permissions { #{permission[:value]} }")).to eq permission[:allowed].call(@student)
    end
  end

  it "returns the course sections" do
    section = add_section("Dope Section")
    topic = discussion_topic_model(context: @course, is_section_specific: true, course_section_ids: [section.id])
    type = GraphQLTypeTester.new(topic, current_user: @teacher)

    expect(type.resolve("courseSections { _id }")[0]).to eq section.id.to_s
    expect(type.resolve("courseSections { name }")[0]).to eq section.name
  end

  it "returns the appropriate course sections for students and teachers" do
    section1 = add_section("Dope Section 1")
    section2 = add_section("Dope Section 2")
    student = student_in_course(active_all: true, section: section2)
    topic = discussion_topic_model(context: @course, is_section_specific: true, course_section_ids: [section1.id, section2.id])

    type_student = GraphQLTypeTester.new(topic, current_user: student.user)
    expect(type_student.resolve("courseSections { _id }").length).to eq 1
    expect(type_student.resolve("courseSections { _id }")[0]).to eq section2.id.to_s
    expect(type_student.resolve("courseSections { name }")[0]).to eq section2.name

    type_teacher = GraphQLTypeTester.new(topic, current_user: @teacher)
    expect(type_teacher.resolve("courseSections { _id }").length).to eq 2
  end

  it "returns if the discussion is able to be unpublished" do
    result = discussion_type.resolve("canUnpublish")
    expect(result).to eq discussion.can_unpublish?
  end

  context "pagination" do
    before(:once) do
      # Add 10 root entries
      @total_root_entries = 10
      @total_root_entries.times do |i|
        discussion.discussion_entries.create!(message: "Message #{i}", user: @teacher)
      end
      # Add 10 subentries
      @total_subentries = 10
      subentry = discussion.discussion_entries.first
      @total_subentries.times do |i|
        subentry.discussion_subentries.create!(
          message: "Subentry #{i}",
          user: @teacher,
          discussion_topic_id: discussion.id
        )
      end

      @total_entries = @total_root_entries + @total_subentries
    end

    it "returns total number of root entry pages" do
      (1..@total_root_entries).each do |i|
        expect(discussion_type.resolve("rootEntriesTotalPages(perPage: #{i})")).to eq((@total_root_entries.to_f / i).ceil)
      end
    end

    it "returns total number of root entry pages (via rootEntries param)" do
      (1..@total_root_entries).each do |i|
        expect(discussion_type.resolve("entriesTotalPages(perPage: #{i}, rootEntries: true)")).to eq((@total_root_entries.to_f / i).ceil)
      end
    end

    it "returns total number of entry pages" do
      (1..@total_entries).each do |i|
        expect(discussion_type.resolve("entriesTotalPages(perPage: #{i})")).to eq((@total_entries.to_f / i).ceil)
      end
    end
  end
end

describe Types::DiscussionType do
  context "course discussion" do
    let_once(:discussion) { graded_discussion_topic }
    include_examples "DiscussionType"

    describe "mentionable users connection" do
      it "finds lists the user" do
        expect(discussion_type.resolve("mentionableUsersConnection { nodes { _id } }")).to eq(discussion.context.users.map { |u| u.id.to_s })
      end
    end

    it "available_for_user is set correctly" do
      allow_any_instantiation_of(discussion).to receive(:locked_for?)
        .with(@teacher, check_policies: true)
        .and_return({ unlock_at: "a sample date" })
      expect(GraphQLTypeTester.new(discussion, current_user: @teacher).resolve("availableForUser")).to be false
      allow_any_instantiation_of(discussion).to receive(:locked_for?)
        .with(@teacher, check_policies: true)
        .and_return(false)
      expect(GraphQLTypeTester.new(discussion, current_user: @teacher).resolve("availableForUser")).to be true
    end

    it "returns the correct data for a discussion that is closed for comments" do
      discussion.lock!
      course_with_student(course: discussion.context)
      allow_any_instantiation_of(discussion).to receive(:locked_for?)
        .with(@student, check_policies: true)
        .and_return({ can_view: true })

      expect(GraphQLTypeTester.new(discussion, current_user: @student, request: ActionDispatch::TestRequest.create).resolve("message")).to eq discussion.message
    end

    describe "delayed post" do
      before do
        @delayed_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                      message: "delayed",
                                                      context: @course,
                                                      user: @teacher,
                                                      editor: @teacher,
                                                      delayed_post_at: 10.days.from_now)
        @past_delayed_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                           message: "past delay",
                                                           context: @course,
                                                           user: @teacher,
                                                           editor: @teacher,
                                                           delayed_post_at: 1.day.ago)

        @delayed_discussion.discussion_entries.create!(message: "teacher entry", user: @teacher)
        @past_delayed_discussion.discussion_entries.create!(message: "teacher entry", user: @teacher)
        discussion.discussion_entries.create!(message: "teacher entry", user: @teacher)

        course_with_student(course: @course)

        @delayed_type_with_student = GraphQLTypeTester.new(@delayed_discussion, current_user: @student, request: ActionDispatch::TestRequest.create)
        @delayed_type_with_teacher = GraphQLTypeTester.new(@delayed_discussion, current_user: @teacher, request: ActionDispatch::TestRequest.create)
        @nil_delayed_at_type_with_student = GraphQLTypeTester.new(discussion, current_user: @student, request: ActionDispatch::TestRequest.create)
        @past_delayed_type_with_student = GraphQLTypeTester.new(@past_delayed_discussion, current_user: @student, request: ActionDispatch::TestRequest.create)
      end

      it "exposes title field" do
        expect(@delayed_type_with_student.resolve("title")).to eq @delayed_discussion.title
        expect(@delayed_type_with_teacher.resolve("title")).to eq @delayed_discussion.title
      end

      it "returns lock_reason for message and emtpy entries array for student" do
        expect(@delayed_type_with_student.resolve("message")).not_to eq @delayed_discussion.message
        expect(@delayed_type_with_student.resolve("discussionEntriesConnection { nodes { message } }")).to eq []
      end

      it "returns correct message and entries for teachers" do
        expect(@delayed_type_with_teacher.resolve("message")).to eq @delayed_discussion.message
        expect(@delayed_type_with_teacher.resolve("discussionEntriesConnection { nodes { message } }").count).to eq 1
      end

      it "returns correct message and entries of topics when delayed_post_at is nil" do
        expect(discussion.delayed_post_at).to be_nil
        expect(@nil_delayed_at_type_with_student.resolve("message")).to eq discussion.message
        expect(@nil_delayed_at_type_with_student.resolve("discussionEntriesConnection { nodes { message } }").count).to eq 1
      end

      it "returns correct message and entries of topics when delayed_post_at is past" do
        expect(@past_delayed_type_with_student.resolve("message")).to eq @past_delayed_discussion.message
        expect(@past_delayed_type_with_student.resolve("discussionEntriesConnection { nodes { message } }").count).to eq 1
      end
    end

    describe "discussion user roles" do
      before do
        authored_discussion = DiscussionTopic.create!(title: "Welcome whoever you are",
                                                      message: "authored",
                                                      context: @course,
                                                      user: @teacher,
                                                      editor: @teacher)
        @discusion_teacher_author = GraphQLTypeTester.new(authored_discussion, current_user: @teacher, request: ActionDispatch::TestRequest.create)
      end

      it "finds author course roles without extra variables" do
        expect(@discusion_teacher_author.resolve("author { courseRoles }")).to eq(["TeacherEnrollment"])
      end

      it "finds editor course roles without extra variables" do
        expect(@discusion_teacher_author.resolve("editor { courseRoles }")).to eq(["TeacherEnrollment"])
      end

      it "finds the author htmlUrl without extra variables" do
        expected_url = "http://test.host/courses/#{@course.id}/users/#{@teacher.id}"
        expect(@discusion_teacher_author.resolve("author { htmlUrl }")).to eq(expected_url)
      end

      it "finds the editor htmlUrl without extra variables" do
        expected_url = "http://test.host/courses/#{@course.id}/users/#{@teacher.id}"
        expect(@discusion_teacher_author.resolve("editor { htmlUrl }")).to eq(expected_url)
      end
    end
  end

  context "group discussion" do
    let_once(:discussion) { group_discussion_assignment.child_topics.take }
    include_examples "DiscussionType"

    describe "mentionable users connection" do
      it "finds lists the user" do
        expected = discussion.context.participating_users_in_context
        expected |= discussion.course.teachers
        expect(discussion_type.resolve("mentionableUsersConnection { nodes { _id } }")).to eq(expected.map { |u| u.id.to_s })
      end
    end

    it "returns can_group correctly" do
      student_in_course(active_all: true)
      expect(discussion_type.resolve("canGroup")).to be true

      discussion.discussion_entries.create!(message: "other student entry", user: @student)
      expect(discussion_type.resolve("canGroup")).to be false
    end
  end

  context "group discussion with deleted group" do
    let_once(:discussion) { group_discussion_with_deleted_group }
    include_context "DiscussionTypeContext"

    it "doesn't show child topic associated to a deleted group" do
      expect(discussion_type.resolve("childTopics { contextName }")).to match_array(["group 1", "group 2"])
    end
  end

  context "discussion within modules" do
    before do
      student_in_course(active_all: true)
      @topic = @course.discussion_topics.create!(
        title: "Ya Ya Ding Dong",
        user: @teacher,
        message: "By Will Ferrell and My Marianne",
        workflow_state: "published"
      )
      @context_module = @course.context_modules.create!(name: "some module")
      @context_module.unlock_at = 1.day.from_now
      @context_module.add_item(type: "discussion_topic", id: @topic.id)
      @context_module.save!
    end

    it "returns module lock information" do
      type_with_student = GraphQLTypeTester.new(@topic, current_user: @student, request: ActionDispatch::TestRequest.create)
      resolved_message = type_with_student.resolve("message")

      canvaslms_url = resolved_message.match(/x-canvaslms-trusted-url='([^']+)'/)
      expect(canvaslms_url[1]).to include("/courses/#{@course.id}/modules/#{@context_module.id}/prerequisites/discussion_topic_#{@topic.id}")
      expect(resolved_message).to include("id='module_prerequisites_lookup_link'")
    end

    it "does not return locked module information when you are the teacher" do
      teacher_type = GraphQLTypeTester.new(@topic, current_user: @teacher, request: ActionDispatch::TestRequest.create)
      expect(teacher_type.resolve("message")).to eq @topic.message
    end
  end

  context "editing group category id" do
    it "changing group category id returns only group new group child topics" do
      course = @course || course_factory(active_all: true)

      discussion = course.discussion_topics.build(title: "topic")
      discussion.save!

      group_category_a = course.group_categories.create(name: "category_a", context: course, context_type: "Course", account: course.account)
      group_category_a.groups.create!(name: "group 1a", context: course, context_type: "Course", account: course.account)
      group_category_a.groups.create!(name: "group 2a", context: course, context_type: "Course", account: course.account)

      group_category_b = course.group_categories.create(name: "category_b", context: course, context_type: "Course", account: course.account)
      group_category_b.groups.create!(name: "group 1b", context: course, context_type: "Course", account: course.account)
      group_category_b.groups.create!(name: "group 2b", context: course, context_type: "Course", account: course.account)

      discussion.group_category = group_category_a
      discussion.save!

      discussion_type = GraphQLTypeTester.new(discussion, current_user: @teacher)

      expect(discussion_type.resolve("childTopics { contextName }")).to match_array(["group 1a", "group 2a"])

      discussion.group_category = group_category_b
      discussion.save!

      expect(discussion_type.resolve("childTopics { contextName }")).to match_array(["group 1b", "group 2b"])
    end
  end

  context "group discussion context name sorting" do
    let_once(:discussion) do
      course = @course || course_factory(active_all: true)
      group_category = course.group_categories.create!(name: "category")
      course.groups.create!(name: "group 10", group_category:)
      course.groups.create!(name: "group 2", group_category:)
      course.groups.create!(name: "group 1", group_category:)
      course.groups.create!(name: "group 11", group_category:)

      topic = course.discussion_topics.build(title: "topic")
      topic.group_category = group_category
      topic.save!
      topic
    end
    include_context "DiscussionTypeContext"

    it "sorts child_topics by their context_name" do
      # eq is used instead of match_array to make sure it is ordered properly
      expect(discussion_type.resolve("childTopics { contextName }")).to eq(["group 1", "group 10", "group 11", "group 2"])
    end
  end

  context "announcement" do
    let(:discussion) { announcement_model(delayed_post_at: 1.day.from_now) }
    let(:discussion_type) { GraphQLTypeTester.new(discussion, current_user: @teacher) }

    it "allows querying for is_announcement and delayed_post_at" do
      expect(discussion_type.resolve("isAnnouncement")).to eq discussion.is_announcement
      expect(discussion_type.resolve("delayedPostAt")).to eq discussion.delayed_post_at&.iso8601
    end
  end

  context "selective release" do
    context "ungraded discussions" do
      before do
        course_factory(active_all: true)
        @topic = discussion_topic_model(user: @teacher, context: @course)
        @topic.update!(only_visible_to_overrides: true)
        @course_section = @course.course_sections.create
        @student1 = student_in_course(course: @course, active_enrollment: true).user
        @student2 = student_in_course(course: @course, active_enrollment: true, section: @course_section).user
        @teacher1 = teacher_in_course(course: @course, active_enrollment: true).user

        @student1_type = GraphQLTypeTester.new(@topic, current_user: @student1)
        @student2_type = GraphQLTypeTester.new(@topic, current_user: @student2)
        @teacher1_type = GraphQLTypeTester.new(@topic, current_user: @teacher1)
      end

      context "visibility" do
        it "is visible only to the assigned student" do
          override = @topic.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student1)

          expect(@student1_type.resolve("_id")).to be_truthy
          expect(@student2_type.resolve("_id")).to be_nil
          expect(@teacher1_type.resolve("_id")).to be_truthy
        end

        it "is visible only to users who can access the assigned section" do
          @topic.assignment_overrides.create!(set: @course_section)

          expect(@student1_type.resolve("_id")).to be_nil
          expect(@student2_type.resolve("_id")).to be_truthy
          expect(@teacher1_type.resolve("_id")).to be_truthy
        end

        it "is visible only to students in module override section" do
          context_module = @course.context_modules.create!(name: "module")
          context_module.content_tags.create!(content: @topic, context: @course)

          override2 = @topic.assignment_overrides.create!(unlock_at: "2022-02-01T01:00:00Z",
                                                          unlock_at_overridden: true,
                                                          lock_at: "2022-02-02T01:00:00Z",
                                                          lock_at_overridden: true)
          override2.assignment_override_students.create!(user: @student1)

          expect(@student1_type.resolve("_id")).to be_truthy
          expect(@student2_type.resolve("_id")).to be_nil
          expect(@teacher1_type.resolve("_id")).to be_truthy
        end
      end

      context "overrides" do
        it "returns data" do
          override = @topic.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student1)

          expect(@student1_type.resolve("ungradedDiscussionOverrides { nodes { _id } }")).to match([override.id.to_s])
          expect(@student1_type.resolve("ungradedDiscussionOverrides { nodes { title } }")).to match([override.title])
        end
      end
    end
  end

  context "submissions_connection" do
    before(:once) do
      course_with_teacher(active_all: true)

      @student = student_in_course(active_all: true).user

      @topic = discussion_topic_model(context: @course)
      @assignment = assignment_model(course: @course)
      @topic.assignment = @assignment
      @topic.save!

      @assignment.submissions.where(user_id: @student.id).delete_all
      @submission = @assignment.submissions.create!(
        user: @student,
        submission_type: "online_text_entry",
        body: "This is a test submission",
        workflow_state: "submitted"
      )

      @teacher_type = GraphQLTypeTester.new(@topic, current_user: @teacher)
      @student_type = GraphQLTypeTester.new(@topic, current_user: @student)
    end

    it "returns nil when user is not logged in" do
      guest_type = GraphQLTypeTester.new(@topic, current_user: nil)
      expect(guest_type.resolve("submissionsConnection { nodes { _id } }")).to be_nil
    end

    it "returns nil when topic has no assignment" do
      topic_without_assignment = discussion_topic_model(context: @course)
      student_type = GraphQLTypeTester.new(topic_without_assignment, current_user: @student)
      expect(student_type.resolve("submissionsConnection { nodes { _id } }")).to be_nil
    end

    it "returns submissions for the teacher" do
      submission_in_db = Submission.find_by(id: @submission.id)
      expect(submission_in_db).not_to be_nil
      expect(submission_in_db.user_id).to eq(@student.id)

      submission_ids = @teacher_type.resolve("submissionsConnection { nodes { _id } }")
      expect(submission_ids).to include(@submission.id.to_s)
    end

    it "returns the student's own submission" do
      submission_ids = @student_type.resolve("submissionsConnection { nodes { _id } }")
      expect(submission_ids).to include(@submission.id.to_s)
    end

    it "applies filters correctly" do
      @submission.update!(score: 10, workflow_state: "graded")
      filter_query = "submissionsConnection(filter: {states: [graded]}) { nodes { _id } }"
      submission_ids = @teacher_type.resolve(filter_query)
      expect(submission_ids).to include(@submission.id.to_s)
    end
  end

  context "checkpoints" do
    before do
      course_with_teacher(active_all: true)
      @student = student_in_course(active_all: true).user
    end

    describe "checkpoints field" do
      before(:once) do
        @topic = discussion_topic_model(context: @course)
        @assignment = assignment_model(course: @course)
        @topic.assignment = @assignment
        @topic.save!
        @teacher_type = GraphQLTypeTester.new(@topic, current_user: @teacher)
      end

      it "returns nil when checkpoints are not enabled" do
        allow_any_instance_of(Course).to receive(:discussion_checkpoints_enabled?).and_return(false)
        expect(@teacher_type.resolve("checkpoints { name }")).to be_nil
      end

      it "returns checkpoints when enabled" do
        allow_any_instance_of(Course).to receive(:discussion_checkpoints_enabled?).and_return(true)

        # Set up assignment for sub-assignments
        @assignment.update!(has_sub_assignments: true)

        # Create sub-assignments using the association
        @assignment.sub_assignments.create!(
          context: @course,
          title: "Reply to Topic",
          points_possible: 5,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC
        )

        @assignment.sub_assignments.create!(
          context: @course,
          title: "Reply to Entry",
          points_possible: 10,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY
        )

        # Refresh the topic to ensure associations are loaded
        @topic.reload
        @assignment.reload

        checkpoint_names = @teacher_type.resolve("checkpoints { name }")
        expect(checkpoint_names).to include("Reply to Topic", "Reply to Entry")
      end

      it "returns correct checkpoint data including details" do
        allow_any_instance_of(Course).to receive(:discussion_checkpoints_enabled?).and_return(true)

        # Set up assignment for sub-assignments
        @assignment.update!(has_sub_assignments: true)

        # Create a single sub-assignment for detailed testing
        @assignment.sub_assignments.create!(
          context: @course,
          title: "Reply to Topic",
          points_possible: 5,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC
        )

        # Refresh from database
        @topic.reload
        @assignment.reload

        expect(@teacher_type.resolve("checkpoints { name }")).to include("Reply to Topic")
        expect(@teacher_type.resolve("checkpoints { pointsPossible }")).to include(5)
        expect(@teacher_type.resolve("checkpoints { tag }")).to include("reply_to_topic")
      end
    end

    it "returns the reply to entry required count" do
      cdt = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: cdt,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: Time.zone.now }],
        points_possible: 6
      )
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: cdt,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: Time.zone.now }],
        points_possible: 7,
        replies_required: 3
      )

      discussion_type = GraphQLTypeTester.new(cdt, current_user: @teacher)
      replies_required = discussion_type.resolve("replyToEntryRequiredCount")
      expect(replies_required).to eq cdt.reply_to_entry_required_count
      expect(replies_required).to eq 3
    end

    it "returns the parent's reply to entry required count for child topics" do
      cgdt = group_discussion_assignment
      GroupCategory.last

      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: cgdt,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: Time.zone.now }],
        points_possible: 6
      )
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: cgdt,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: Time.zone.now }],
        points_possible: 7,
        replies_required: 3
      )

      child_topic = cgdt.child_topics.first
      discussion_type = GraphQLTypeTester.new(child_topic, current_user: @teacher)
      replies_required = discussion_type.resolve("replyToEntryRequiredCount")
      expect(replies_required).to eq child_topic.root_topic.reply_to_entry_required_count
      expect(replies_required).to eq 3
    end
  end

  context "admin groups" do
    before do
      @account = Account.create!
      @group = Group.create!(name: "Admin Group", context: @account)
      @group_student, @group_teacher = create_users(2, return_type: :record)
      puts @group_teacher
      puts "Hello"
      group.bulk_add_users_to_group([@group_teacher, @group_student])

      @group_topic = DiscussionTopic.create!(title: "Admin Group Topic", context: group, user: @group_teacher, editor: @group_teacher)
      @group_topic.discussion_entries.create!(message: "Group Entry", user: @group_student)
    end

    it "returns the correct htmlUrl for" do
      puts @group_topic
      discussion_type = GraphQLTypeTester.new(
        @group_topic,
        current_user: @group_teacher,
        request: ActionDispatch::TestRequest.create
      )
      expect(discussion_type.resolve("author { htmlUrl }")).to end_with("/groups/#{@group.id}/users/#{@group_teacher.id}")
      entries_url = discussion_type.resolve("discussionEntriesConnection { nodes { author { htmlUrl }}}")

      entries_url.each do |entry|
        expect(entry).to end_with("/groups/#{@group.id}/users/#{@group_student.id}")
      end
    end
  end
end
