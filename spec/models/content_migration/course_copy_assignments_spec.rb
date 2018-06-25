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

require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')

describe ContentMigration do
  context "course copy assignments" do
    include_examples "course copy"

    it "should link assignments to account rubrics and outcomes" do
      account = @copy_from.account
      lo = create_outcome(account)

      rub = Rubric.new(:context => account)
      rub.data = [
          {
              :points => 3,
              :description => "Outcome row",
              :id => 1,
              :ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}],
              :learning_outcome_id => lo.id
          }
      ]
      rub.save!

      from_assign = @copy_from.assignments.create!(:title => "some assignment")
      rub.associate_with(from_assign, @copy_from, :purpose => "grading")

      run_course_copy

      to_assign = @copy_to.assignments.first
      expect(to_assign.rubric).to eq rub

      expect(to_assign.learning_outcome_alignments.map(&:learning_outcome_id)).to eq [lo.id].sort
    end

    it "should not overwrite assignment points possible on import" do
      @course = @copy_from
      outcome_with_rubric
      from_assign = @copy_from.assignments.create! title: 'some assignment'
      @rubric.associate_with(from_assign, @copy_from, purpose: 'grading', use_for_grading: true)
      from_assign.update_attribute(:points_possible, 1)

      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.points_possible).to eq 1
      expect(to_assign.rubric.rubric_associations.for_grading.first.use_for_grading).to be_truthy

      run_course_copy
      expect(to_assign.reload.points_possible).to eq 1
    end

    it "should copy rubric outcomes in selective copy" do
      @course = @copy_from
      outcome_with_rubric
      from_assign = @copy_from.assignments.create! title: 'some assignment'
      @rubric.associate_with(from_assign, @copy_from, purpose: 'grading')
      @cm.copy_options = {:assignments => {mig_id(from_assign) => true}}
      run_course_copy
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_outcomes = to_assign.rubric.learning_outcome_alignments.map(&:learning_outcome).map(&:migration_id)
      expect(to_outcomes).to eql [mig_id(@outcome)]
    end

    it "should copy rubric outcomes (even if in a group) in selective copy" do
      @course = @copy_from
      outcome_group_model(:context => @copy_from)
      outcome_with_rubric
      from_assign = @copy_from.assignments.create! title: 'some assignment'
      @rubric.associate_with(from_assign, @copy_from, purpose: 'grading')

      @cm.copy_options = {:assignments => {mig_id(from_assign) => true}}

      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_outcomes = to_assign.rubric.learning_outcome_alignments.map(&:learning_outcome).map(&:migration_id)
      expect(to_outcomes).to eql [mig_id(@outcome)]
    end

    it "should link account rubric outcomes (even if in a group) in selective copy" do
      @course = @copy_from
      outcome_group_model(:context => @copy_from)
      outcome_with_rubric(:outcome_context => @copy_from.account)
      from_assign = @copy_from.assignments.create! title: 'some assignment'
      @rubric.associate_with(from_assign, @copy_from, purpose: 'grading')

      @cm.copy_options = {:assignments => {mig_id(from_assign) => true}}

      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      to_outcomes = to_assign.rubric.learning_outcome_alignments.map(&:learning_outcome)
      expect(to_outcomes).to eql [@outcome]
    end

    it "should link assignments to assignment groups when copying all assignments" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)

      @cm.copy_options = {:all_assignments => true}
      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).to eq @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "should link assignments to assignment groups when copying entire assignment group" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)

      @cm.copy_options = {:assignment_groups => {mig_id(g) => true}, :assignments => {mig_id(from_assign) => true}}
      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).to eq @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "should not link assignments to assignment groups when copying single assignment" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)

      @cm.copy_options = {:assignments => {mig_id(from_assign) => true}}
      run_course_copy

      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(@copy_to.assignment_groups.where(migration_id: mig_id(g)).first).to be_nil
      expect(to_assign.assignment_group.migration_id).to be_nil
    end

    it "should link assignments to assignment groups on complete export" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)
      run_export_and_import
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).to eq @copy_to.assignment_groups.where(migration_id: mig_id(g)).first
    end

    it "should not link assignments to assignment groups on selective export" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)
      # test that we neither export nor reference the assignment group
      unrelated_group = @copy_to.assignment_groups.create! name: 'unrelated group with coincidentally matching migration id'
      unrelated_group.update_attribute :migration_id, mig_id(g)
      run_export_and_import do |export|
        export.selected_content = { 'assignments' => { mig_id(from_assign) => "1" } }
      end
      to_assign = @copy_to.assignments.where(migration_id: mig_id(from_assign)).first!
      expect(to_assign.assignment_group).not_to eq unrelated_group
      expect(unrelated_group.reload.name).not_to eql g.name
    end


    it "should copy assignment attributes" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'file_upload', :grading_type => 'points')
      @assignment.turnitin_enabled = true
      @assignment.vericite_enabled = true
      @assignment.vericite_settings = {
          :originality_report_visibility => "after_grading",
          :exclude_quoted => '1',
          :exclude_self_plag => '0',
          :store_in_index => '1'
      }
      @assignment.peer_reviews = true
      @assignment.peer_review_count = 2
      @assignment.automatic_peer_reviews = true
      @assignment.anonymous_peer_reviews = true
      @assignment.allowed_extensions = ["doc", "xls"]
      @assignment.position = 2
      @assignment.muted = true
      @assignment.omit_from_final_grade = true
      @assignment.only_visible_to_overrides = true
      @assignment.post_to_sis = true

      @assignment.save!

      expect_any_instantiation_of(@copy_to).to receive(:turnitin_enabled?).at_least(1).and_return(true)
      expect_any_instantiation_of(@copy_to).to receive(:vericite_enabled?).at_least(1).and_return(true)

      attrs = [:turnitin_enabled, :vericite_enabled, :turnitin_settings, :peer_reviews,
          :automatic_peer_reviews, :anonymous_peer_reviews,
          :grade_group_students_individually, :allowed_extensions,
          :position, :peer_review_count, :omit_from_final_grade, :post_to_sis]

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      attrs.each do |attr|
        if @assignment[attr].class == Hash
          expect(@assignment[attr].stringify_keys).to eq new_assignment[attr].stringify_keys
        else
          expect(@assignment[attr]).to eq new_assignment[attr]
        end
      end
      expect(new_assignment.muted).to be_falsey
      expect(new_assignment.only_visible_to_overrides).to be_falsey
    end

    it "shouldn't copy turnitin/vericite_enabled if it's not enabled on the copyee's account" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'file_upload', :grading_type => 'points')
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

    it "should copy group assignment setting" do
      assignment_model(:course => @copy_from, :points_possible => 40,
        :submission_types => 'file_upload', :grading_type => 'points')

      group_category = @copy_from.group_categories.create!(:name => "category")
      @assignment.group_category = group_category
      @assignment.save!

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(new_assignment).to be_has_group_category
      expect(new_assignment.group_category.name).to eq "Project Groups"
    end

    it "should not copy peer_reviews_assigned" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'file_upload', :grading_type => 'points')
      @assignment.peer_reviews_assigned = true

      @assignment.save!

      run_course_copy

      new_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(new_assignment.peer_reviews_assigned).to be_falsey
    end

    it "should include implied objects for context modules" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
      mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})
      page = @copy_from.wiki_pages.create!(:title => "some page")
      page2 = @copy_from.wiki_pages.create!(:title => "some page 2")
      mod1.add_item({:id => page.id, :type => 'wiki_page'})
      att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      mod1.add_item({:id => att.id, :type => 'attachment'})
      mod1.add_item({ :title => 'Example 1', :type => 'external_url', :url => 'http://a.example.com/' })
      mod1.add_item :type => 'context_module_sub_header', :title => "Sub Header"
      tool = @copy_from.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      tool2 = @copy_from.context_external_tools.create!(:name => "b", :url => "http://www.instructure.com", :consumer_key => '12345', :shared_secret => 'secret')
      mod1.add_item :type => 'context_external_tool', :id => tool.id, :url => tool.url
      topic = @copy_from.discussion_topics.create!(:title => "topic")
      topic2 = @copy_from.discussion_topics.create!(:title => "topic2")
      mod1.add_item :type => 'discussion_topic', :id => topic.id
      quiz = @copy_from.quizzes.create!(:title => 'quiz')
      quiz2 = @copy_from.quizzes.create!(:title => 'quiz2')
      mod1.add_item :type => 'quiz', :id => quiz.id
      mod1.save!

      mod2 = @copy_from.context_modules.create!(:name => "not copied")
      asmnt2 = @copy_from.assignments.create!(:title => "some assignment again")
      mod2.add_item({:id => asmnt2.id, :type => 'assignment', :indent => 1})
      mod2.save!

      @cm.copy_options = {
                      :context_modules => {mig_id(mod1) => "1", mig_id(mod2) => "0"},
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

    it "should copy module prerequisites" do
      enable_cache do
        mod = @copy_from.context_modules.create!(:name => "first module")
        mod2 = @copy_from.context_modules.create(:name => "next module")
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

    it "should not try to restore deleted assignments to an unpublished state if unable to" do
      a_from = assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'online_text_entry', :grading_type => 'points')
      a_from.unpublish!

      run_course_copy

      @copy_to.offer!
      student_in_course(:course => @copy_to, :active_user => true)

      a_to = @copy_to.assignments.where(:migration_id => mig_id(a_from)).first
      a_to.publish!
      a_to.submit_homework(@student, :submission_type => "online_text_entry")
      a_to.destroy

      run_course_copy
      a_to.reload
      expect(a_to).to be_published
    end

    context "copying frozen assignments" do
      before :once do
        @setting = PluginSetting.create!(:name => "assignment_freezer", :settings => {"no_copying" => "yes"})

        @asmnt = @copy_from.assignments.create!(:title => 'lock locky')
        @asmnt.copied = true
        @asmnt.freeze_on_copy = true
        @asmnt.save!
        @quiz = @copy_from.quizzes.create(:title => "quiz", :quiz_type => "assignment")
        @quiz.workflow_state = 'available'
        @quiz.save!
        @quiz.assignment.copied = true
        @quiz.assignment.freeze_on_copy = true
        @quiz.save!
        @topic = @copy_from.discussion_topics.build(:title => "topic")
        assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
        assignment.infer_times
        assignment.saved_by = :discussion_topic
        assignment.copied = true
        assignment.freeze_on_copy = true
        @topic.assignment = assignment
        @topic.save

        @admin = account_admin_user(opts={})
      end

      it "should copy for admin" do
        @cm.user = @admin
        @cm.save!

        run_course_copy

        expect(@copy_to.assignments.count).to eq(Qti.qti_enabled? ? 3 : 2)
        expect(@copy_to.quizzes.count).to eq 1 if Qti.qti_enabled?
        expect(@copy_to.discussion_topics.count).to eq 1
        expect(@cm.content_export.error_messages).to eq []
      end

      it "should copy for teacher if flag not set" do
        @setting.settings = {}
        @setting.save!

        run_course_copy

        expect(@copy_to.assignments.count).to eq(Qti.qti_enabled? ? 3 : 2)
        expect(@copy_to.quizzes.count).to eq 1 if Qti.qti_enabled?
        expect(@copy_to.discussion_topics.count).to eq 1
        expect(@cm.content_export.error_messages).to eq []
      end

      it "should not copy for teacher" do
        warnings = [
            "The assignment \"lock locky\" could not be copied because it is locked.",
            "The topic \"topic\" could not be copied because it is locked.",
            "The quiz \"quiz\" could not be copied because it is locked."]

        run_course_copy(warnings)

        expect(@copy_to.assignments.count).to eq 0
        expect(@copy_to.quizzes.count).to eq 0
        expect(@copy_to.discussion_topics.count).to eq 0
        expect(@cm.content_export.error_messages.sort).to eq warnings.sort.map{|w| [w, nil]}
      end

      it "should not mark assignment as copied if not set to be frozen" do
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
      it "should retain reference to account grading standard" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        expect(@copy_to.grading_standard).to eq gs
      end

      it "should copy a course grading standard not owned by the copy_from course" do
        @other_course = course_model
        gs = make_grading_standard(@other_course)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        expect(@copy_to.grading_standard_enabled).to be_truthy
        expect(@copy_to.grading_standard.data).to eq gs.data
      end

      it "should create a warning if an account grading standard can't be found" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.delete

        run_course_copy(["Couldn't find account grading standard for the course."])

        expect(@copy_to.grading_standard).to eq nil
      end

      it "should not copy deleted grading standards" do
        gs = make_grading_standard(@copy_from)
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.destroy
        @copy_from.reload

        run_course_copy

        expect(@copy_to.grading_standards).to be_empty
      end

      it "should not copy grading standards if nothing is selected" do
        gs = make_grading_standard(@copy_from)
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0' }
        @cm.save!
        run_course_copy
        expect(@copy_to.grading_standards).to be_empty
      end

      it "should copy the course's grading standard (once) if course_settings are selected" do
        gs = make_grading_standard(@copy_from, title: 'What')
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0', 'all_course_settings' => '1' }
        @cm.save!
        run_course_copy
        expect(@copy_to.grading_standards.count).to eql 1 # no dupes
        expect(@copy_to.grading_standard.title).to eql gs.title
      end

      it "should not copy grading standards if nothing is selected (export/import)" do
        gs = make_grading_standard(@copy_from, title: 'What')
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0' }
        @cm.migration_ids_to_import = { 'copy' => { 'everything' => '0' } }
        @cm.save!
        run_export_and_import
        expect(@cm.warnings).to be_empty
        expect(@copy_to.grading_standards).to be_empty
      end

      it "should copy the course's grading standard (once) if course_settings are selected (export/import)" do
        gs = make_grading_standard(@copy_from, title: 'What')
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0', 'all_course_settings' => '1' }
        @cm.migration_ids_to_import = { 'copy' => { 'all_course_settings' => '1' } }
        @cm.save!
        run_export_and_import
        expect(@cm.warnings).to be_empty
        expect(@copy_to.grading_standards.count).to eql 1 # no dupes
        expect(@copy_to.grading_standard.title).to eql gs.title
      end

      it "should copy grading standards referenced by exported assignments" do
        gs1, gs2 = make_grading_standard(@copy_from, title: 'One'), make_grading_standard(@copy_from, title: 'Two')
        assign = @copy_from.assignments.build
        assign.grading_standard = gs2
        assign.save!
        @cm.copy_options = { 'everything' => '0', 'assignments' => { mig_id(assign) => "1" } }
        run_course_copy
        expect(@copy_to.grading_standards.map(&:title)).to eql %w(Two)
        expect(@copy_to.assignments.first.grading_standard.title).to eql 'Two'
      end

      it "should copy referenced grading standards in complete export" do
        gs = make_grading_standard(@copy_from, title: 'GS')
        assign = @copy_from.assignments.build
        assign.grading_standard = gs
        assign.save!
        run_export_and_import
        expect(@copy_to.assignments.first.grading_standard.title).to eql gs.title
      end

      it "should not copy referenced grading standards in selective export" do
        gs = make_grading_standard(@copy_from, title: 'One')
        assign = @copy_from.assignments.build
        assign.grading_standard = gs
        assign.save!
        # test that we neither export nor reference the grading standard
        unrelated_grading_standard = make_grading_standard(@copy_to, title: 'unrelated grading standard with coincidentally matching migration id')
        unrelated_grading_standard.update_attribute :migration_id, mig_id(gs)
        run_export_and_import do |export|
          export.selected_content = { 'assignments' => { mig_id(assign) => "1" } }
        end
        expect(@copy_to.assignments.count).to eql 1
        expect(@copy_to.assignments.first.grading_standard).to be_nil
        expect(unrelated_grading_standard.reload.title).not_to eql gs.title
      end
    end

    describe "assignment overrides" do
      before :once do
        @assignment = @copy_from.assignments.create!(title: 'ovrdn')
      end

      it "should copy only noop overrides" do
        assignment_override_model(assignment: @assignment, set_type: 'ADHOC')
        assignment_override_model(assignment: @assignment, set_type: 'Noop',
          set_id: 1, title: 'Tag 1')
        assignment_override_model(assignment: @assignment, set_type: 'Noop',
          set_id: nil, title: 'Tag 2')
        @assignment.only_visible_to_overrides = true
        @assignment.save!
        run_course_copy
        to_assignment = @copy_to.assignments.first
        expect(to_assignment.only_visible_to_overrides).to be_truthy
        expect(to_assignment.assignment_overrides.length).to eq 2
        expect(to_assignment.assignment_overrides.detect{ |o| o.set_id == 1 }.title).to eq 'Tag 1'
        expect(to_assignment.assignment_overrides.detect{ |o| o.set_id.nil? }.title).to eq 'Tag 2'
      end

      it "should copy dates" do
        due_at = 1.hour.from_now.round
        assignment_override_model(assignment: @assignment, set_type: 'Noop',
          set_id: 1, title: 'Tag 1', due_at: due_at)
        run_course_copy
        to_override = @copy_to.assignments.first.assignment_overrides.first
        expect(to_override.title).to eq 'Tag 1'
        expect(to_override.due_at).to eq due_at
        expect(to_override.due_at_overridden).to eq true
        expect(to_override.unlock_at_overridden).to eq false
      end
    end

    context 'external tools' do
      include_context 'lti2_spec_helper'

      let(:assignment) { @copy_from.assignments.create!(name: 'test assignment') }
      let(:resource_link_id) { assignment.lti_context_id }
      let(:custom_data) { {'setting_one' => 'value one'} }
      let(:custom_parameters) { {'param_one' => 'param value one'} }
      let(:tool_settings) do
        Lti::ToolSetting.create!(
          tool_proxy: tool_proxy,
          resource_link_id: resource_link_id,
          context: assignment.course,
          custom: custom_data,
          custom_parameters: custom_parameters,
          product_code: tool_proxy.product_family.product_code,
          vendor_code: tool_proxy.product_family.vendor_code
        )
      end

      before do
        allow_any_instance_of(Lti::AssignmentSubscriptionsHelper).to receive(:create_subscription) { SecureRandom.uuid }
        allow(Lti::ToolProxy).to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) do
          Lti::ToolProxy.where(id: tool_proxy.id)
        end
        product_family.update_attributes!(
          product_code: 'product_code',
          vendor_code: 'vendor_code'
        )
        tool_proxy.update_attributes!(
          resources: [resource_handler],
          context: @copy_to
        )
        tool_settings
        AssignmentConfigurationToolLookup.create!(
          assignment: assignment,
          tool_id: message_handler.id,
          tool_type: 'Lti::MessageHandler',
          tool_product_code: product_family.product_code,
          tool_vendor_code: product_family.vendor_code
        )
      end

      it 'creates tool settings for associated plagiarism tools' do
        expect{run_course_copy}.to change{Lti::ToolSetting.count}.from(1).to(2)
      end

      it 'sets the context of the tool setting to the new course' do
        run_course_copy
        expect(Lti::ToolSetting.last.context).to eq @copy_to
      end

      it 'sets the custom field of the new tool setting' do
        run_course_copy
        expect(Lti::ToolSetting.last.custom).to eq custom_data
      end

      it 'sets the custom parameters of the new tool setting' do
        run_course_copy
        expect(Lti::ToolSetting.last.custom_parameters).to eq custom_parameters
      end
    end
  end
end
