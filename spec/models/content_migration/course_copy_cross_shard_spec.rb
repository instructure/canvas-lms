# frozen_string_literal: true

require_relative "course_copy_helper"

describe ContentMigration do
  context "course copy across shards" do
    specs_require_sharding
    include_context "course copy"

    before :once do
      @shard1.activate do
        @other_account = Account.create
        @copy_from = @other_account.courses.create!
        @copy_from.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
      end
      @cm.update_attribute(:source_course, @copy_from)
    end

    it "copies everything" do
      dt1 = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
      cm = @copy_from.context_modules.create!(name: "some module")
      att = @copy_from.attachments.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from))
      wiki = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
      quiz = @copy_from.quizzes.create! if Qti.qti_enabled?
      ag = @copy_from.assignment_groups.create!(name: "empty group")
      asmnt = @copy_from.assignments.create!(title: "some assignment")
      cal = @copy_from.calendar_events.create!(title: "haha", description: "oi")
      tool = @copy_from.context_external_tools.create!(name: "new tool",
                                                       consumer_key: "key",
                                                       shared_secret: "secret",
                                                       domain: "example.com",
                                                       custom_fields: { "a" => "1", "b" => "2" },
                                                       workflow_state: "public")
      data = [{ points: 3, description: "Outcome row", id: 1, ratings: [{ points: 3, description: "Rockin'", criterion_id: 1, id: 2 }] }]
      rub1 = @copy_from.rubrics.create!(title: "rub1", data:)
      rub1.associate_with(@copy_from, @copy_from)
      default = @copy_from.root_outcome_group
      lo = @copy_from.created_learning_outcomes.create!(context: @copy_from,
                                                        short_description: "outcome1",
                                                        workflow_state: "active",
                                                        data: { rubric_criterion: { mastery_points: 2,
                                                                                    ratings: [{ description: "e", points: 50 },
                                                                                              { description: "me", points: 2 },
                                                                                              { description: "Does Not Meet Expectations", points: 0.5 }],
                                                                                    description: "First outcome",
                                                                                    points_possible: 5 } })
      default.add_outcome(lo)
      gs = @copy_from.grading_standards.create!(title: "Standard eh", data: [["A", 0.93], ["A-", 0.89], ["F", 0]])

      run_course_copy

      dt1_to = @copy_to.discussion_topics.first
      expect(dt1_to.migration_id).to eq CC::CCHelper.create_key("discussion_topic_#{dt1.global_id}", global: true) # use global identifier
      expect(dt1_to.workflow_state).to eq "active"
      expect(@copy_to.context_modules.where(migration_id: mig_id(cm)).first.workflow_state).to eq "active"
      expect(@copy_to.attachments.count).to eq 1
      att_to = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(att_to.file_state).to eq "available"
      expect(att_to.root_attachment_id).to be_nil # should be root
      expect(att_to.open.read).to eq "ohai" # should have copied content over
      expect(att_to.namespace).to eq "account_#{@copy_to.root_account.id}"
      expect(@copy_to.wiki_pages.where(migration_id: mig_id(wiki)).first.workflow_state).to eq "active"
      rub2 = @copy_to.rubrics.where(migration_id: mig_id(rub1)).first
      expect(rub2.workflow_state).to eq "active"
      expect(rub2.rubric_associations.first.bookmarked).to be true
      expect(@copy_to.created_learning_outcomes.where(migration_id: mig_id(lo)).first.workflow_state).to eq "active"
      expect(@copy_to.quizzes.where(migration_id: mig_id(quiz)).first.workflow_state).to eq "unpublished" if Qti.qti_enabled?
      expect(@copy_to.context_external_tools.where(migration_id: mig_id(tool)).first.workflow_state).to eq "public"
      expect(@copy_to.assignment_groups.where(migration_id: mig_id(ag)).first.workflow_state).to eq "available"
      expect(@copy_to.assignments.where(migration_id: mig_id(asmnt)).first.workflow_state).to eq asmnt.workflow_state
      expect(@copy_to.grading_standards.where(migration_id: mig_id(gs)).first.workflow_state).to eq "active"
      expect(@copy_to.calendar_events.where(migration_id: mig_id(cal)).first.workflow_state).to eq "active"
    end

    it "uses local ids if we're possibly re-importing a previously copied course" do
      prev_export = @copy_from.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      prev_export.update_attribute(:global_identifiers, false)

      dt = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")

      run_course_copy

      expect(@copy_from.content_exports.last).to eq @cm.content_export
      expect(@cm.content_export.global_identifiers?).to be false

      dt_to = @copy_to.discussion_topics.first
      expect(dt_to.migration_id).to eq CC::CCHelper.create_key("discussion_topic_#{dt.local_id}", global: false)
    end

    it "tries to find existing root attachments on destination account" do
      att = @copy_from.attachments.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from))
      dest_root = @copy_to.attachments.create!(filename: "totallydifferentname.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_to))

      run_course_copy

      att_to = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(att_to.root_attachment).to eq dest_root
    end

    it "does not blow up with usage rights" do
      ur = @copy_from.usage_rights.create! use_justification: "used_by_permission", legal_copyright: "(C) 2015 Wyndham Systems"
      att = @copy_from.attachments.create!(filename: "first.txt",
                                           uploaded_data: StringIO.new("ohai"),
                                           folder: Folder.unfiled_folder(@copy_from),
                                           usage_rights: ur)

      run_course_copy

      att_to = @copy_to.attachments.where(migration_id: mig_id(att)).first
      ur_to = att_to.usage_rights
      expect(ur_to.context).to eq @copy_to
      %i[use_justification legal_copyright license].each do |k|
        expect(ur_to.send(k)).to eq ur.send(k)
      end
    end
  end
end
