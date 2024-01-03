# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "course_copy_helper"
require_relative "../../lti2_spec_helper"

describe ContentMigration do
  context "course copy assignments" do
    include_context "course copy"

    it "links assignments to account rubrics and outcomes" do
      account = @copy_from.account
      lo = create_outcome(account)

      rub = Rubric.new(context: account)
      rub.data = [
        {
          points: 3,
          description: "Outcome row",
          id: 1,
          ratings: [{ points: 3, description: "Rockin'", criterion_id: 1, id: 2 }],
          learning_outcome_id: lo.id
        }
      ]
      rub.save!

      from_assign = @copy_from.assignments.create!(title: "some assignment")
      rub.associate_with(from_assign, @copy_from, purpose: "grading")

      run_course_copy

      to_assign = @copy_to.assignments.first
      expect(to_assign.rubric).to eq rub

      expect(to_assign.learning_outcome_alignments.map(&:learning_outcome_id)).to eq [lo.id].sort
    end

    it "does not overwrite assignment points possible on import" do
      @course = @copy_from
      outcome_with_rubric
      from_assign = @copy_from.assignments.create! title: "some assignment"
      @rubric.associate_with(from_assign, @copy_from, purpose: "grading", use_for_grading: true)
      from_assign.update_attribute(:points_possible, 1)

      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.points_possible).to eq 1
      expect(to_assign.rubric.rubric_associations.for_grading.first.use_for_grading).to be_truthy

      run_course_copy
      expect(to_assign.reload.points_possible).to eq 1
    end

    it "copies rubric outcomes in selective copy" do
      @course = @copy_from
      outcome_with_rubric
      from_assign = @copy_from.assignments.create! title: "some assignment"
      @rubric.associate_with(from_assign, @copy_from, purpose: "grading")
      @cm.copy_options = { assignments: { mig_id(from_assign) => true } }
      run_course_copy
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_outcomes = to_assign.rubric.learning_outcome_alignments.map { |a| a.learning_outcome.migration_id }
      expect(to_outcomes).to eql [mig_id(@outcome)]
    end

    it "copies rubric outcomes (even if in a group) in selective copy" do
      @course = @copy_from
      outcome_group_model(context: @copy_from)
      outcome_with_rubric
      from_assign = @copy_from.assignments.create! title: "some assignment"
      @rubric.associate_with(from_assign, @copy_from, purpose: "grading")

      @cm.copy_options = { assignments: { mig_id(from_assign) => true } }

      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_outcomes = to_assign.rubric.learning_outcome_alignments.map { |a| a.learning_outcome.migration_id }
      expect(to_outcomes).to eql [mig_id(@outcome)]
    end

    it "links account rubric outcomes (even if in a group) in selective copy" do
      @course = @copy_from
      outcome_group_model(context: @copy_from)
      outcome_with_rubric(outcome_context: @copy_from.account)
      from_assign = @copy_from.assignments.create! title: "some assignment"
      @rubric.associate_with(from_assign, @copy_from, purpose: "grading")

      @cm.copy_options = { assignments: { mig_id(from_assign) => true } }

      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_outcomes = to_assign.rubric.learning_outcome_alignments.map(&:learning_outcome)
      expect(to_outcomes).to eql [@outcome]
    end

    it "links assignments to assignment groups when copying all assignments" do
      g = @copy_from.assignment_groups.create!(name: "group")
      from_assign = @copy_from.assignments.create!(title: "some assignment", assignment_group_id: g.id)

      @cm.copy_options = { all_assignments: true }
      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).to eq @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "links assignments to assignment groups when copying entire assignment group" do
      g = @copy_from.assignment_groups.create!(name: "group")
      from_assign = @copy_from.assignments.create!(title: "some assignment", assignment_group_id: g.id)

      @cm.copy_options = { assignment_groups: { mig_id(g) => true }, assignments: { mig_id(from_assign) => true } }
      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).to eq @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "does not link assignments to assignment groups when copying single assignment" do
      g = @copy_from.assignment_groups.create!(name: "group")
      from_assign = @copy_from.assignments.create!(title: "some assignment", assignment_group_id: g.id)

      @cm.copy_options = { assignments: { mig_id(from_assign) => true } }
      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(@copy_to.assignment_groups.where(migration_id: mig_id(g)).first).to be_nil
      expect(to_assign.assignment_group.migration_id).to be_nil
    end

    it "links assignments to assignment groups on complete export" do
      g = @copy_from.assignment_groups.create!(name: "group")
      from_assign = @copy_from.assignments.create!(title: "some assignment", assignment_group_id: g.id)
      run_export_and_import
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).to eq @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "does not link assignments to assignment groups on selective export" do
      g = @copy_from.assignment_groups.create!(name: "group")
      from_assign = @copy_from.assignments.create!(title: "some assignment", assignment_group_id: g.id)
      # test that we neither export nor reference the assignment group
      unrelated_group = @copy_to.assignment_groups.create! name: "unrelated group with coincidentally matching migration id"
      unrelated_group.update_attribute :migration_id, mig_id(g)
      run_export_and_import do |export|
        export.selected_content = { "assignments" => { mig_id(from_assign) => "1" } }
      end
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).not_to eq unrelated_group
      expect(unrelated_group.reload.name).not_to eql g.name
    end

    it "copies assignment attributes" do
      assignment_model(course: @copy_from, points_possible: 0, submission_types: "file_upload", grading_type: "points")
      @assignment.turnitin_enabled = true
      @assignment.vericite_enabled = true
      @assignment.vericite_settings = {
        originality_report_visibility: "after_grading",
        exclude_quoted: "1",
        exclude_self_plag: "0",
        store_in_index: "1"
      }
      @assignment.peer_reviews = true
      @assignment.peer_review_count = 2
      @assignment.automatic_peer_reviews = true
      @assignment.anonymous_peer_reviews = true
      @assignment.allowed_extensions = ["doc", "xls"]
      @assignment.position = 2
      @assignment.muted = true
      @assignment.hide_in_gradebook = true
      @assignment.omit_from_final_grade = true
      @assignment.only_visible_to_overrides = true
      @assignment.post_to_sis = true
      @assignment.allowed_attempts = 10

      @assignment.save!

      expect_any_instantiation_of(@copy_to).to receive(:turnitin_enabled?).at_least(1).and_return(true)
      expect_any_instantiation_of(@copy_to).to receive(:vericite_enabled?).at_least(1).and_return(true)

      attrs = %i[turnitin_enabled
                 vericite_enabled
                 turnitin_settings
                 peer_reviews
                 automatic_peer_reviews
                 anonymous_peer_reviews
                 grade_group_students_individually
                 allowed_extensions
                 position
                 peer_review_count
                 hide_in_gradebook
                 omit_from_final_grade
                 post_to_sis
                 allowed_attempts]

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      attrs.each do |attr|
        if @assignment[attr].instance_of?(Hash)
          expect(@assignment[attr].stringify_keys).to eq new_assignment[attr].stringify_keys
        else
          expect(@assignment[attr]).to eq new_assignment[attr]
        end
      end
      expect(new_assignment.muted).to be true
      expect(new_assignment.only_visible_to_overrides).to be_falsey
    end

    it "copies an assignment's post policy along with the assignment" do
      assignment_model(course: @copy_from, points_possible: 40)
      @assignment.post_policy.update!(post_manually: true)

      run_course_copy

      new_assignment = @copy_to.assignments.find_by(migration_id: mig_id(@assignment))
      expect(new_assignment.post_policy).to be_post_manually
    end

    it "always sets a moderated assignment to post manually" do
      @copy_to.enable_feature!(:moderated_grading)
      assignment_model(course: @copy_from, points_possible: 40, moderated_grading: true, grader_count: 2)
      @assignment.post_policy.update!(post_manually: false)

      run_course_copy

      new_assignment = @copy_to.assignments.find_by(migration_id: mig_id(@assignment))
      expect(new_assignment.post_policy).to be_post_manually
    end

    it "unsets allowed extensions" do
      assignment_model(course: @copy_from,
                       points_possible: 40,
                       submission_types: "file_upload",
                       grading_type: "points",
                       allowed_extensions: ["txt", "doc"])

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(new_assignment.allowed_extensions).to eq ["txt", "doc"]
      @assignment.update_attribute(:allowed_extensions, [])

      run_course_copy

      expect(new_assignment.reload.allowed_extensions).to eq []
    end

    it "only auto-imports into an active assignment group" do
      assign = @copy_from.assignments.create!
      run_export_and_import do |export|
        export.selected_content = { "assignments" => { mig_id(assign) => "1" } }
      end
      group = @copy_to.assignments.first.assignment_group
      expect(group.name).to eq "Imported Assignments" # hi
      group.destroy # bye

      assign2 = @copy_from.assignments.create!
      run_export_and_import do |export|
        export.selected_content = { "assignments" => { mig_id(assign2) => "1" } }
      end
      new_group = @copy_to.assignments.where(migration_id: mig_id(assign2)).first.assignment_group
      expect(new_group).to_not eq group
      expect(new_group).to be_available
      expect(new_group.name).to eq "Imported Assignments"
    end

    describe "allowed_attempts copying" do
      it "copies nil over properly" do
        assignment_model(course: @copy_from, points_possible: 40, submission_types: "file_upload", grading_type: "points")
        @assignment.allowed_attempts = nil
        @assignment.save!

        run_course_copy
        new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).last
        expect(new_assignment.allowed_attempts).to be_nil
      end

      it "copies -1 over properly" do
        assignment_model(course: @copy_from, points_possible: 40, submission_types: "file_upload", grading_type: "points")
        @assignment.allowed_attempts = -1
        @assignment.save!

        run_course_copy
        new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).last
        expect(new_assignment.allowed_attempts).to eq(-1)
      end

      it "copies values > 0 over properly" do
        assignment_model(course: @copy_from, points_possible: 40, submission_types: "file_upload", grading_type: "points")
        @assignment.allowed_attempts = 3
        @assignment.save!

        run_course_copy
        new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).last
        expect(new_assignment.allowed_attempts).to eq(3)
      end
    end

    it "copies other feature-dependent assignment attributes (if enabled downstream)" do
      assignment_model(course: @copy_from)
      @assignment.moderated_grading = true
      @assignment.grader_count = 2
      @assignment.grader_comments_visible_to_graders = true
      @assignment.anonymous_grading = true
      @assignment.graders_anonymous_to_graders = true
      @assignment.grader_names_visible_to_final_grader = true
      @assignment.anonymous_instructor_annotations = true
      @assignment.save!

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      [:moderated_grading, :anonymous_grading].each do |attr|
        expect(new_assignment.send(attr)).to be false
      end

      @copy_to.enable_feature!(:moderated_grading)
      @copy_to.enable_feature!(:anonymous_marking)

      run_course_copy

      new_assignment.reload
      %i[moderated_grading
         grader_count
         grader_comments_visible_to_graders
         anonymous_grading
         graders_anonymous_to_graders
         grader_names_visible_to_final_grader
         anonymous_instructor_annotations].each do |attr|
        expect(new_assignment.send(attr)).to eq @assignment.send(attr)
      end
    end

    describe "student annotation assignments" do
      let(:source_attachment) do
        attachment_model(course: @copy_from, filename: "some_attachment")
      end

      let!(:source_assignment) do
        assignment_model(
          course: @copy_from,
          annotatable_attachment: source_attachment,
          submission_types: "online_text_entry,student_annotation"
        )
      end

      let(:copied_assignment) { @copy_to.assignments.find_by!(migration_id: mig_id(source_assignment)) }
      let(:copied_attachment) { copied_assignment.annotatable_attachment }

      let(:copied_annotation_attachments) do
        @copy_to.student_annotation_documents_folder.attachments.where(migration_id: mig_id(source_attachment))
      end

      context "when copying the whole course" do
        it "also copies annotatable attachments" do
          run_course_copy

          aggregate_failures do
            expect(copied_attachment).to be_present
            expect(copied_assignment.annotatable_attachment).to eq copied_attachment
          end
        end

        it "adds the copied attachment to the destination course's annotated documents folder" do
          run_course_copy
          expect(copied_attachment.folder).to eq @copy_to.student_annotation_documents_folder
        end
      end

      context "when copying a single assignment" do
        let(:content_migration) { @cm }

        before do
          content_migration.copy_options = { assignments: { mig_id(source_assignment) => true } }
        end

        it "also copies the assignment's annotatable attachment" do
          run_course_copy

          aggregate_failures do
            expect(copied_attachment).to be_present
            expect(copied_assignment.annotatable_attachment).to eq copied_attachment
          end
        end

        it "adds the copied attachment to the destination course's annotated documents folder" do
          run_course_copy
          expect(copied_attachment.folder).to eq @copy_to.student_annotation_documents_folder
        end
      end

      context "when copying multiple assignments" do
        let(:content_migration) { @cm }
        let(:other_assignment) do
          assignment_model(
            annotatable_attachment: source_attachment,
            course: @copy_from,
            submission_types: "online_upload,student_annotation"
          )
        end

        before do
          content_migration.copy_options = {
            assignments: {
              mig_id(source_assignment) => true,
              mig_id(other_assignment) => true
            }
          }
        end

        it "creates at most one copy of each attachment" do
          run_course_copy

          aggregate_failures do
            annotation_attachments = @copy_to.student_annotation_documents_folder.attachments
            expect(annotation_attachments.count).to eq 1
            expect(@copy_to.assignments.pluck(:annotatable_attachment_id).uniq).to eq [annotation_attachments.first.id]
          end
        end
      end

      it "does not copy the attachment if it has been deleted" do
        source_attachment.destroy!
        run_course_copy

        aggregate_failures do
          expect(copied_assignment.annotatable_attachment).to be_nil
          expect(Attachment.where(root_attachment: source_attachment)).to be_empty
        end
      end

      it "does not copy the attachment if the assignment does not allow annotations" do
        source_assignment.update!(submission_types: "online_text_entry")

        expect do
          run_course_copy
        end.not_to change {
          copied_annotation_attachments.count
        }
      end
    end

    it "does not copy turnitin/vericite_enabled if it's not enabled on the copyee's account" do
      assignment_model(course: @copy_from, points_possible: 40, submission_types: "file_upload", grading_type: "points")
      @assignment.turnitin_enabled = true
      @assignment.vericite_enabled = true
      @assignment.save!

      expect_any_instantiation_of(@copy_to).to receive(:turnitin_enabled?).at_least(1).and_return(false)
      expect_any_instantiation_of(@copy_to).to receive(:vericite_enabled?).at_least(1).and_return(false)

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(new_assignment[:turnitin_enabled]).to be_falsey
      expect(new_assignment[:vericite_enabled]).to be_falsey
    end

    it "copies group assignment setting" do
      assignment_model(course: @copy_from,
                       points_possible: 40,
                       submission_types: "file_upload",
                       grading_type: "points")

      group_category = @copy_from.group_categories.create!(name: "category")
      @assignment.group_category = group_category
      @assignment.save!

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(new_assignment).to be_has_group_category
      expect(new_assignment.group_category.name).to eq "Project Groups"
    end

    it "does not copy peer_reviews_assigned" do
      assignment_model(course: @copy_from, points_possible: 40, submission_types: "file_upload", grading_type: "points")
      @assignment.peer_reviews_assigned = true

      @assignment.save!

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(new_assignment.peer_reviews_assigned).to be_falsey
    end

    it "includes implied objects for context modules" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      asmnt1 = @copy_from.assignments.create!(title: "some assignment")
      mod1.add_item({ id: asmnt1.id, type: "assignment", indent: 1 })
      page = @copy_from.wiki_pages.create!(title: "some page")
      page2 = @copy_from.wiki_pages.create!(title: "some page 2")
      mod1.add_item({ id: page.id, type: "wiki_page" })
      att = Attachment.create!(filename: "first.png", uploaded_data: StringIO.new("ohai"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att2 = Attachment.create!(filename: "first.png", uploaded_data: StringIO.new("ohai"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      mod1.add_item({ id: att.id, type: "attachment" })
      mod1.add_item({ title: "Example 1", type: "external_url", url: "http://a.example.com/" })
      mod1.add_item type: "context_module_sub_header", title: "Sub Header"
      tool = @copy_from.context_external_tools.create!(name: "b", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      tool2 = @copy_from.context_external_tools.create!(name: "b", url: "http://www.instructure.com", consumer_key: "12345", shared_secret: "secret")
      mod1.add_item type: "context_external_tool", id: tool.id, url: tool.url
      topic = @copy_from.discussion_topics.create!(title: "topic")
      topic2 = @copy_from.discussion_topics.create!(title: "topic2")
      mod1.add_item type: "discussion_topic", id: topic.id
      quiz = @copy_from.quizzes.create!(title: "quiz")
      quiz2 = @copy_from.quizzes.create!(title: "quiz2")
      mod1.add_item type: "quiz", id: quiz.id
      mod1.save!

      mod2 = @copy_from.context_modules.create!(name: "not copied")
      asmnt2 = @copy_from.assignments.create!(title: "some assignment again")
      mod2.add_item({ id: asmnt2.id, type: "assignment", indent: 1 })
      mod2.save!

      @cm.copy_options = {
        context_modules: { mig_id(mod1) => "1", mig_id(mod2) => "0" },
      }
      @cm.save!

      run_course_copy

      mod1_copy = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      expect(mod1_copy).not_to be_nil
      if Qti.qti_enabled?
        expect(mod1_copy.content_tags.count).to eq 8
      else
        expect(mod1_copy.content_tags.count).to eq 7
      end

      expect(@copy_to.assignments.where(migration_id: mig_id(asmnt1)).first).not_to be_nil
      expect(@copy_to.wiki_pages.where(migration_id: mig_id(page)).first).not_to be_nil
      expect(@copy_to.attachments.where(migration_id: mig_id(att)).first).not_to be_nil
      expect(@copy_to.context_external_tools.where(migration_id: mig_id(tool)).first).not_to be_nil
      expect(@copy_to.discussion_topics.where(migration_id: mig_id(topic)).first).not_to be_nil
      expect(@copy_to.quizzes.where(migration_id: mig_id(quiz)).first).not_to be_nil if Qti.qti_enabled?

      expect(@copy_to.context_modules.where(migration_id: mig_id(mod2)).first).to be_nil
      expect(@copy_to.assignments.where(migration_id: mig_id(asmnt2)).first).to be_nil
      expect(@copy_to.attachments.where(migration_id: mig_id(att2)).first).to be_nil
      expect(@copy_to.wiki_pages.where(migration_id: mig_id(page2)).first).to be_nil
      expect(@copy_to.context_external_tools.where(migration_id: mig_id(tool2)).first).to be_nil
      expect(@copy_to.discussion_topics.where(migration_id: mig_id(topic2)).first).to be_nil
      expect(@copy_to.quizzes.where(migration_id: mig_id(quiz2)).first).to be_nil
    end

    it "copies module prerequisites" do
      enable_cache do
        mod = @copy_from.context_modules.create!(name: "first module")
        mod2 = @copy_from.context_modules.create(name: "next module")
        mod2.position = 2
        mod2.prerequisites = "module_#{mod.id}"
        mod2.save!

        run_course_copy

        to_mod = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
        to_mod2 = @copy_to.context_modules.where(migration_id: mig_id(mod2)).first
        expect(to_mod2.prerequisites).not_to eq []
        expect(to_mod2.prerequisites[0][:id]).to eql(to_mod.id)
      end
    end

    it "does not try to restore deleted assignments to an unpublished state if unable to" do
      a_from = assignment_model(course: @copy_from, points_possible: 40, submission_types: "online_text_entry", grading_type: "points")
      a_from.unpublish!

      run_course_copy

      @copy_to.offer!
      student_in_course(course: @copy_to, active_user: true)

      a_to = @copy_to.assignments.where(migration_id: mig_id(a_from)).first
      a_to.publish!
      a_to.submit_homework(@student, submission_type: "online_text_entry")
      a_to.destroy

      run_course_copy
      a_to.reload
      expect(a_to).to be_published
    end

    context "copying frozen assignments" do
      before :once do
        @setting = PluginSetting.create!(name: "assignment_freezer", settings: { "no_copying" => "yes" })

        @asmnt = @copy_from.assignments.create!(title: "lock locky")
        @asmnt.copied = true
        @asmnt.freeze_on_copy = true
        @asmnt.save!
        @quiz = @copy_from.quizzes.create(title: "quiz", quiz_type: "assignment")
        @quiz.workflow_state = "available"
        @quiz.save!
        @quiz.assignment.copied = true
        @quiz.assignment.freeze_on_copy = true
        @quiz.save!
        @topic = @copy_from.discussion_topics.build(title: "topic")
        assignment = @copy_from.assignments.build(submission_types: "discussion_topic", title: @topic.title)
        assignment.infer_times
        assignment.saved_by = :discussion_topic
        assignment.copied = true
        assignment.freeze_on_copy = true
        @topic.assignment = assignment
        @topic.save

        @admin = account_admin_user
      end

      it "copies for admin" do
        @cm.user = @admin
        @cm.save!

        run_course_copy

        expect(@copy_to.assignments.count).to eq(Qti.qti_enabled? ? 3 : 2)
        expect(@copy_to.quizzes.count).to eq 1 if Qti.qti_enabled?
        expect(@copy_to.discussion_topics.count).to eq 1
        expect(@cm.content_export.error_messages).to eq []
      end

      it "copies for teacher if flag not set" do
        @setting.settings = {}
        @setting.save!

        run_course_copy

        expect(@copy_to.assignments.count).to eq(Qti.qti_enabled? ? 3 : 2)
        expect(@copy_to.quizzes.count).to eq 1 if Qti.qti_enabled?
        expect(@copy_to.discussion_topics.count).to eq 1
        expect(@cm.content_export.error_messages).to eq []
      end

      it "does not copy for teacher" do
        warnings = [
          "The assignment \"lock locky\" could not be copied because it is locked.",
          "The topic \"topic\" could not be copied because it is locked.",
          "The quiz \"quiz\" could not be copied because it is locked."
        ]

        run_course_copy(warnings)

        expect(@copy_to.assignments.count).to eq 0
        expect(@copy_to.quizzes.count).to eq 0
        expect(@copy_to.discussion_topics.count).to eq 0
        expect(@cm.content_export.error_messages.sort).to eq(warnings.sort.map { |w| [w, nil] })
      end

      it "does not mark assignment as copied if not set to be frozen" do
        @asmnt.freeze_on_copy = false
        @asmnt.copied = false
        @asmnt.save!

        warnings = ["The topic \"topic\" could not be copied because it is locked.",
                    "The quiz \"quiz\" could not be copied because it is locked."]

        run_course_copy(warnings)

        asmnt_2 = @copy_to.assignments.where(migration_id: mig_id(@asmnt)).first
        expect(asmnt_2.freeze_on_copy).to be false
        expect(asmnt_2.copied).to be false
      end
    end

    describe "grading standards" do
      it "retains reference to account grading standard" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        expect(@copy_to.grading_standard).to eq gs
      end

      it "retains reference to points based account grading standard" do
        gs = make_grading_standard(@copy_from.root_account, { points_based: true, scaling_factor: 4.0 })
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        expect(@copy_to.grading_standard).to eq gs
      end

      it "copies a course grading standard not owned by the copy_from course" do
        @other_course = course_model
        gs = make_grading_standard(@other_course)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        expect(@copy_to.grading_standard_enabled).to be_truthy
        expect(@copy_to.grading_standard.data).to eq gs.data
      end

      it "creates a warning if an account grading standard can't be found" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.delete

        run_course_copy(["Couldn't find account grading standard for the course."])

        expect(@copy_to.grading_standard).to be_nil
      end

      it "does not copy deleted grading standards" do
        gs = make_grading_standard(@copy_from)
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.destroy
        @copy_from.reload

        run_course_copy

        expect(@copy_to.grading_standards).to be_empty
      end

      it "does not copy grading standards if nothing is selected" do
        gs = make_grading_standard(@copy_from)
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { "everything" => "0" }
        @cm.save!
        run_course_copy
        expect(@copy_to.grading_standards).to be_empty
      end

      it "copies the course's grading standard (once) if course_settings are selected" do
        gs = make_grading_standard(@copy_from, title: "What")
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { "everything" => "0", "all_course_settings" => "1" }
        @cm.save!
        run_course_copy
        expect(@copy_to.grading_standards.count).to be 1 # no dupes
        expect(@copy_to.grading_standard.title).to eql gs.title
      end

      it "does not copy grading standards if nothing is selected (export/import)" do
        gs = make_grading_standard(@copy_from, title: "What")
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { "everything" => "0" }
        @cm.migration_ids_to_import = { "copy" => { "everything" => "0" } }
        @cm.save!
        run_export_and_import
        expect(@cm.warnings).to be_empty
        expect(@copy_to.grading_standards).to be_empty
      end

      it "copies the course's grading standard (once) if course_settings are selected (export/import)" do
        gs = make_grading_standard(@copy_from, title: "What")
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { "everything" => "0", "all_course_settings" => "1" }
        @cm.migration_ids_to_import = { "copy" => { "all_course_settings" => "1" } }
        @cm.save!
        run_export_and_import
        expect(@cm.warnings).to be_empty
        expect(@copy_to.grading_standards.count).to be 1 # no dupes
        expect(@copy_to.grading_standard.title).to eql gs.title
      end

      it "copies grading standards referenced by exported assignments" do
        _gs1, gs2 = make_grading_standard(@copy_from, title: "One"), make_grading_standard(@copy_from, title: "Two")
        assign = @copy_from.assignments.build
        assign.grading_standard = gs2
        assign.save!
        @cm.copy_options = { "everything" => "0", "assignments" => { mig_id(assign) => "1" } }
        run_course_copy
        expect(@copy_to.grading_standards.map(&:title)).to eql %w[Two]
        expect(@copy_to.assignments.first.grading_standard.title).to eql "Two"
      end

      it "copies referenced grading standards in complete export" do
        gs = make_grading_standard(@copy_from, title: "GS")
        assign = @copy_from.assignments.build
        assign.grading_standard = gs
        assign.save!
        run_export_and_import
        expect(@copy_to.assignments.first.grading_standard.title).to eql gs.title
      end

      it "does not copy referenced grading standards in selective export" do
        gs = make_grading_standard(@copy_from, title: "One")
        assign = @copy_from.assignments.build
        assign.grading_standard = gs
        assign.save!
        # test that we neither export nor reference the grading standard
        unrelated_grading_standard = make_grading_standard(@copy_to, title: "unrelated grading standard with coincidentally matching migration id")
        unrelated_grading_standard.update_attribute :migration_id, mig_id(gs)
        run_export_and_import do |export|
          export.selected_content = { "assignments" => { mig_id(assign) => "1" } }
        end
        expect(@copy_to.assignments.count).to be 1
        expect(@copy_to.assignments.first.grading_standard).to be_nil
        expect(unrelated_grading_standard.reload.title).not_to eql gs.title
      end
    end

    describe "assignment overrides" do
      before :once do
        @assignment = @copy_from.assignments.create!(title: "ovrdn")
      end

      it "copies only noop overrides" do
        account = Account.default
        account.settings[:conditional_release] = { value: true }
        account.save!
        assignment_override_model(assignment: @assignment, set_type: "ADHOC")
        assignment_override_model(assignment: @assignment,
                                  set_type: AssignmentOverride::SET_TYPE_NOOP,
                                  set_id: AssignmentOverride::NOOP_MASTERY_PATHS,
                                  title: "Tag 1")
        assignment_override_model(assignment: @assignment,
                                  set_type: AssignmentOverride::SET_TYPE_NOOP,
                                  set_id: nil,
                                  title: "Tag 2")
        @assignment.only_visible_to_overrides = true
        @assignment.save!
        run_course_copy
        to_assignment = @copy_to.assignments.first
        expect(to_assignment.only_visible_to_overrides).to be_truthy
        expect(to_assignment.assignment_overrides.length).to eq 2
        expect(to_assignment.assignment_overrides.detect { |o| o.set_id == 1 }.title).to eq "Tag 1"
        expect(to_assignment.assignment_overrides.detect { |o| o.set_id.nil? }.title).to eq "Tag 2"
      end

      it "ignores conditional release noop overrides if feature is not enabled in destination" do
        assignment_override_model(assignment: @assignment,
                                  set_type: AssignmentOverride::SET_TYPE_NOOP,
                                  set_id: AssignmentOverride::NOOP_MASTERY_PATHS)
        @assignment.only_visible_to_overrides = true
        @assignment.save!

        run_course_copy
        to_assignment = @copy_to.assignments.first
        expect(to_assignment.only_visible_to_overrides).to be_falsey
        expect(to_assignment.assignment_overrides.length).to eq 0
      end

      it "copies dates" do
        account = Account.default
        account.settings[:conditional_release] = { value: true }
        account.save!
        due_at = 1.hour.from_now.round
        assignment_override_model(assignment: @assignment,
                                  set_type: "Noop",
                                  set_id: 1,
                                  title: "Tag 1",
                                  due_at:)
        run_course_copy
        to_override = @copy_to.assignments.first.assignment_overrides.first
        expect(to_override.title).to eq "Tag 1"
        expect(to_override.due_at).to eq due_at
        expect(to_override.due_at_overridden).to be true
        expect(to_override.unlock_at_overridden).to be false
      end

      it "preserves only_visible_to_overrides for page assignments" do
        account = Account.default
        account.settings[:conditional_release] = { value: true }
        account.save!
        a1 = assignment_model(context: @copy_from, title: "a1", submission_types: "wiki_page", only_visible_to_overrides: true)
        a1.build_wiki_page(title: a1.title, context: a1.context).save!
        a2 = assignment_model(context: @copy_from, title: "a2", submission_types: "wiki_page", only_visible_to_overrides: false)
        a2.build_wiki_page(title: a2.title, context: a2.context).save!
        run_course_copy
        a1_to = @copy_to.assignments.where(migration_id: mig_id(a1)).take
        expect(a1_to.only_visible_to_overrides).to be true
        a2_to = @copy_to.assignments.where(migration_id: mig_id(a2)).take
        expect(a2_to.only_visible_to_overrides).to be false
      end

      it "ignores page assignments if mastery paths is not enabled in destination" do
        a1 = assignment_model(context: @copy_from, title: "a1", submission_types: "wiki_page", only_visible_to_overrides: true)
        a1.build_wiki_page(title: a1.title, context: a1.context).save!
        run_course_copy
        page_to = @copy_to.wiki_pages.where(migration_id: mig_id(a1.wiki_page)).take
        expect(page_to.assignment).to be_nil
        expect(@copy_to.assignments.where(migration_id: mig_id(a1)).exists?).to be false
      end
    end

    context "lti 2 external tools" do
      include_context "lti2_spec_helper"

      let(:assignment) { @copy_from.assignments.create!(name: "test assignment") }
      let(:resource_link_id) { assignment.lti_context_id }
      let(:custom_data) { { "setting_one" => "value one" } }
      let(:custom_parameters) { { "param_one" => "param value one" } }
      let(:tool_settings) do
        Lti::ToolSetting.create!(
          tool_proxy:,
          resource_link_id:,
          context: assignment.course,
          custom: custom_data,
          custom_parameters:,
          product_code: tool_proxy.product_family.product_code,
          vendor_code: tool_proxy.product_family.vendor_code
        )
      end

      before do
        allow(Lti::ToolProxy).to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) do
          Lti::ToolProxy.where(id: tool_proxy.id)
        end
        product_family.update!(
          product_code: "product_code",
          vendor_code: "vendor_code"
        )
        tool_proxy.update!(
          resources: [resource_handler],
          context: @copy_to
        )
        tool_settings
        AssignmentConfigurationToolLookup.create!(
          assignment:,
          tool_id: message_handler.id,
          tool_type: "Lti::MessageHandler",
          tool_product_code: product_family.product_code,
          tool_vendor_code: product_family.vendor_code
        )
      end

      it "creates tool settings for associated plagiarism tools" do
        expect { run_course_copy }.to change { Lti::ToolSetting.count }.from(1).to(2)
      end

      it "sets the context of the tool setting to the new course" do
        run_course_copy
        expect(Lti::ToolSetting.last.context).to eq @copy_to
      end

      it "sets the custom field of the new tool setting" do
        run_course_copy
        expect(Lti::ToolSetting.last.custom).to eq custom_data
      end

      it "sets the custom parameters of the new tool setting" do
        run_course_copy
        expect(Lti::ToolSetting.last.custom_parameters).to eq custom_parameters
      end
    end

    context "lti 1.3 line items" do
      let(:developer_key) { DeveloperKey.create!(account: @course.root_account) }

      context "with one coupled and one coupled line item" do
        let(:tool) { external_tool_model(context: @course.root_account, opts: { use_1_3: true, developer_key: }) }
        let(:tag) { ContentTag.new(content: tool, url: tool.url, context: assignment) }
        let(:assignment) do
          @copy_from.assignments.create!(
            name: "test assignment",
            submission_types: "external_tool",
            points_possible: 10
          )
        end

        before do
          assignment.update!(external_tool_tag: tag)
          Lti::LineItem.create_line_item! assignment, nil, tool, {
            tag: "tag2",
            resource_id: "resource_id2",
            extensions: { foo: "bar" },
            label: "abc",
            score_maximum: 123,
          }
        end

        it "copies both coupled and uncoupled line items" do
          run_course_copy
          line_items = @copy_to.assignments.last.line_items
          expect(line_items.where(coupled: true).pluck(
                   :tag, :resource_id, :extensions, :label, :score_maximum
                 )).to eq([
                            [nil, nil, {}, "test assignment", 10],
                          ])
          expect(line_items.where(coupled: false).pluck(
                   :tag, :resource_id, :extensions, :label, :score_maximum
                 )).to eq([
                            ["tag2", "resource_id2", { "foo" => "bar" }, "abc", 123],
                          ])
        end

        context "when content tag has external_data" do
          let(:ext_data) { { "key" => "https://canvas.instructure.com/lti/mastery_connect_assessment" } }
          let(:tag) do
            super().tap do |t|
              t.external_data = ext_data
              t.save!
            end
          end

          it "copies external_data" do
            run_course_copy
            a_to = @copy_to.assignments.where(migration_id: mig_id(assignment)).first
            expect(a_to.external_tool_tag.external_data).to eq ext_data
          end
        end

        context "when content tag has link_settings" do
          let(:link_settings) { { selection_height: 456, selection_width: 789 } }
          let(:tag) do
            super().tap do |t|
              t.link_settings = link_settings
              t.save!
            end
          end

          it "copies link_settings" do
            run_course_copy
            a_to = @copy_to.assignments.where(migration_id: mig_id(assignment)).first
            expect(a_to.external_tool_tag.link_settings).to eq link_settings.stringify_keys
          end
        end
      end

      context "with one uncoupled line item (submission_types=none)" do
        let(:developer_key) { DeveloperKey.create!(account: @course.root_account) }
        let(:assignment) do
          @course.assignments.create!(
            name: "test assignment",
            submission_types: "none"
          )
        end

        before do
          Lti::LineItem.create_line_item! assignment, nil, nil, {
            tag: "tag2",
            resource_id: "resource_id2",
            extensions: { foo: "bar" },
            label: "abc",
            score_maximum: 123,
            client_id: developer_key.global_id,
          }
        end

        it "copies the line item" do
          run_course_copy
          line_items = @copy_to.assignments.last.line_items
          expect(line_items.pluck(
                   :tag, :resource_id, :extensions, :label, :score_maximum
                 )).to eq([
                            ["tag2", "resource_id2", { "foo" => "bar" }, "abc", 123],
                          ])
        end
      end
    end

    context "post_to_sis" do
      before do
        @course.root_account.enable_feature!(:new_sis_integrations)
        @course.root_account.settings[:sis_syncing] = true
        @course.root_account.settings[:sis_require_assignment_due_date] = true
        @course.root_account.save!
      end

      it "does not break trying to copy over an assignment with required due dates but only specified via overrides" do
        assignment_model(course: @copy_from, points_possible: 40, submission_types: "file_upload", grading_type: "points")
        assignment_override_model(assignment: @assignment, set_type: "CourseSection", set_id: @copy_from.default_section.id, due_at: 1.day.from_now)
        @assignment.only_visible_to_overrides = true
        @assignment.post_to_sis = true
        @assignment.due_at = nil
        @assignment.save!

        run_course_copy(["The Sync to SIS setting could not be enabled for the assignment \"#{@assignment.title}\" without a due date."])

        a_to = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
        expect(a_to.post_to_sis).to be false
        expect(a_to).to be_valid
      end

      it "does not break trying to copy over a graded discussion assignment with required due dates but only specified via overrides" do
        graded_discussion_topic(context: @copy_from)
        assignment_override_model(assignment: @assignment, set_type: "CourseSection", set_id: @copy_from.default_section.id, due_at: 1.day.from_now)
        @assignment.only_visible_to_overrides = true
        @assignment.post_to_sis = true
        @assignment.due_at = nil
        @assignment.save!

        run_course_copy(["The Sync to SIS setting could not be enabled for the assignment \"#{@assignment.title}\" without a due date."])

        topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(@topic)).first
        expect(topic_to).to be_valid
        expect(topic_to.assignment.post_to_sis).to be false
      end

      it "is able to copy post_to_sis" do
        assignment_model(course: @copy_from, points_possible: 40, submission_types: "file_upload", grading_type: "points")
        @assignment.post_to_sis = true
        @assignment.due_at = 1.day.from_now
        @assignment.save!

        run_course_copy

        a_to = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
        expect(a_to.post_to_sis).to be true
        expect(a_to).to be_valid
      end
    end
  end
end
