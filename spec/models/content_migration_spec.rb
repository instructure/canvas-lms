#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ContentMigration do

  context "course copy" do
    before do
      course_with_teacher(:course_name => "from course", :active_all => true)
      @copy_from = @course

      course_with_teacher(:user => @user, :course_name => "to course")
      @copy_to = @course

      @cm = ContentMigration.new(:context => @copy_to, :user => @user, :source_course => @copy_from, :copy_options => {:everything => "1"})
      @cm.user = @user
      @cm.save!
    end

    it "should show correct progress" do
      ce = ContentExport.new
      ce.export_type = ContentExport::COMMON_CARTRIDGE
      ce.content_migration = @cm
      @cm.content_export = ce
      ce.save!

      @cm.progress.should == nil
      @cm.workflow_state = 'exporting'

      ce.progress = 10
      @cm.progress.should == 4
      ce.progress = 50
      @cm.progress.should == 20
      ce.progress = 75
      @cm.progress.should == 30
      ce.progress = 100
      @cm.progress.should == 40

      @cm.progress = 10
      @cm.progress.should == 46
      @cm.progress = 50
      @cm.progress.should == 70
      @cm.progress = 80
      @cm.progress.should == 88
      @cm.progress = 100
      @cm.progress.should == 100
    end

    def run_course_copy(warnings=[])
      @cm.copy_course_without_send_later
      @cm.reload
      @cm.warnings.should == warnings
      if @cm.migration_settings[:last_error]
        er = ErrorReport.last
        "#{er.message} - #{er.backtrace}".should == ""
      end
      @cm.workflow_state.should == 'imported'
      @copy_to.reload
    end

    it "should migrate syllabus links on copy" do
      course_model
      topic = @copy_from.discussion_topics.create!(:title => "some topic", :message => "<p>some text</p>")
      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/discussion_topics/#{topic.id}'>link</a>"
      @copy_from.save!

      run_course_copy

      new_topic = @copy_to.discussion_topics.find_by_migration_id(CC::CCHelper.create_key(topic))
      new_topic.should_not be_nil
      new_topic.message.should == topic.message
      @copy_to.syllabus_body.should match(/\/courses\/#{@copy_to.id}\/discussion_topics\/#{new_topic.id}/)
    end

    it "should copy course attributes" do
      @copy_from.tab_configuration = [{"id"=>0}, {"id"=>14}, {"id"=>8}, {"id"=>5}, {"id"=>6}, {"id"=>2}, {"id"=>3, "hidden"=>true}]
      @copy_from.locale = "es"
      @copy_from.save

      run_course_copy

      @copy_to.locale.should == 'es'
      @copy_to.tab_configuration.should == @copy_from.tab_configuration
    end

    it "should copy external tools" do
      tool_from = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      tool_from.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool_from.save

      run_course_copy

      @copy_to.context_external_tools.count.should == 1

      tool_to = @copy_to.context_external_tools.first
      tool_to.name.should == tool_from.name
      tool_to.custom_fields.should == tool_from.custom_fields
      tool_to.has_course_navigation.should == true
      tool_to.consumer_key.should == tool_from.consumer_key
      tool_to.shared_secret.should == tool_from.shared_secret
    end

    it "should not duplicate external tools used in modules" do
      tool_from = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      tool_from.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool_from.save

      mod1 = @copy_from.context_modules.create!(:name => "some module")
      tag = mod1.add_item({:type => 'context_external_tool',
                           :title => 'Example URL',
                           :url => "http://www.example.com",
                           :new_tab => true})
      tag.save

      run_course_copy

      @copy_to.context_external_tools.count.should == 1

      tool_to = @copy_to.context_external_tools.first
      tool_to.name.should == tool_from.name
      tool_to.consumer_key.should == tool_from.consumer_key
      tool_to.has_course_navigation.should == true
    end

    it "should copy external tool assignments" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points')
      tag_from = @assignment.build_external_tool_tag(:url => "http://example.com/one", :new_tab => true)
      tag_from.content_type = 'ContextExternalTool'
      tag_from.save!

      run_course_copy

      asmnt_2 = @copy_to.assignments.first
      asmnt_2.submission_types.should == "external_tool"
      asmnt_2.external_tool_tag.should_not be_nil
      tag_to = asmnt_2.external_tool_tag
      tag_to.content_type.should == tag_from.content_type
      tag_to.url.should == tag_from.url
      tag_to.new_tab.should == tag_from.new_tab
    end

    def mig_id(obj)
      CC::CCHelper.create_key(obj)
    end


    it "should merge locked files and retain correct html links" do
      att = Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att.update_attribute(:hidden, true)
      att.reload.should be_hidden
      topic = @copy_from.discussion_topics.create!(:title => "some topic", :message => "<img src='/courses/#{@copy_from.id}/files/#{att.id}/preview'>")

      run_course_copy

      new_att = @copy_to.attachments.find_by_migration_id(CC::CCHelper.create_key(att))
      new_att.should_not be_nil

      new_topic = @copy_to.discussion_topics.find_by_migration_id(CC::CCHelper.create_key(topic))
      new_topic.should_not be_nil
      new_topic.message.should match(Regexp.new("/courses/#{@copy_to.id}/files/#{new_att.id}/preview"))
    end

    it "should selectively copy items" do
      dt1 = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      dt2 = @copy_from.discussion_topics.create!(:message => "hey", :title => "discussion title 2")
      dt3 = @copy_from.announcements.create!(:message => "howdy", :title => "announcement title")
      cm = @copy_from.context_modules.create!(:name => "some module")
      cm2 = @copy_from.context_modules.create!(:name => "another module")
      att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      att2 = Attachment.create!(:filename => 'second.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      wiki = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      wiki2 = @copy_from.wiki.wiki_pages.create!(:title => "wiki2", :body => "ohais")
      data = [{:points => 3,:description => "Outcome row",:id => 1,:ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}]}]
      rub1 = @copy_from.rubrics.build(:title => "rub1")
      rub1.data = data
      rub1.save!
      rub1.associate_with(@copy_from, @copy_from)
      rub2 = @copy_from.rubrics.build(:title => "rub2")
      rub2.data = data
      rub2.save!
      rub2.associate_with(@copy_from, @copy_from)
      default = LearningOutcomeGroup.default_for(@copy_from)
      lo = @copy_from.learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      lo2 = @copy_from.learning_outcomes.new
      lo2.context = @copy_from
      lo2.short_description = "outcome1"
      lo2.workflow_state = 'active'
      lo2.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo2.save!

      default.add_item(lo)
      default.add_item(lo2)

      # only select one of each type
      @cm.copy_options = {
              :discussion_topics => {mig_id(dt1) => "1", mig_id(dt3) => "1"},
              :context_modules => {mig_id(cm) => "1", mig_id(cm2) => "0"},
              :attachments => {mig_id(att) => "1", mig_id(att2) => "0"},
              :wiki_pages => {mig_id(wiki) => "1", mig_id(wiki2) => "0"},
              :rubrics => {mig_id(rub1) => "1", mig_id(rub2) => "0"},
              :learning_outcomes => {mig_id(lo) => "1", mig_id(lo2) => "0"},
      }
      @cm.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1)).should_not be_nil
      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt2)).should be_nil
      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt3)).should_not be_nil

      @copy_to.context_modules.find_by_migration_id(mig_id(cm)).should_not be_nil
      @copy_to.context_modules.find_by_migration_id(mig_id(cm2)).should be_nil

      @copy_to.attachments.find_by_migration_id(mig_id(att)).should_not be_nil
      @copy_to.attachments.find_by_migration_id(mig_id(att2)).should be_nil

      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki)).should_not be_nil
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki2)).should be_nil

      @copy_to.rubrics.find_by_migration_id(mig_id(rub1)).should_not be_nil
      @copy_to.rubrics.find_by_migration_id(mig_id(rub2)).should be_nil

      @copy_to.learning_outcomes.find_by_migration_id(mig_id(lo)).should_not be_nil
      @copy_to.learning_outcomes.find_by_migration_id(mig_id(lo2)).should be_nil
    end

    it "should re-copy deleted items" do
      dt1 = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      cm = @copy_from.context_modules.create!(:name => "some module")
      att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      wiki = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      quiz = @copy_from.quizzes.create! if Qti.qti_enabled?
      ag = @copy_from.assignment_groups.create!(:name => 'empty group')
      asmnt = @copy_from.assignments.create!(:title => "some assignment")
      cal = @copy_from.calendar_events.create!(:title => "haha", :description => "oi")
      tool = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      tool.workflow_state = 'public'
      tool.save
      data = [{:points => 3,:description => "Outcome row",:id => 1,:ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}]}]
      rub1 = @copy_from.rubrics.build(:title => "rub1")
      rub1.data = data
      rub1.save!
      rub1.associate_with(@copy_from, @copy_from)
      default = LearningOutcomeGroup.default_for(@copy_from)
      lo = @copy_from.learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      default.add_item(lo)
      gs = @copy_from.grading_standards.new
      gs.title = "Standard eh"
      gs.data = [["A", 0.93], ["A-", 0.89], ["B+", 0.85], ["B", 0.83], ["B!-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]]
      gs.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1)).destroy
      @copy_to.context_modules.find_by_migration_id(mig_id(cm)).destroy
      @copy_to.attachments.find_by_migration_id(mig_id(att)).destroy
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki)).destroy
      @copy_to.rubrics.find_by_migration_id(mig_id(rub1)).destroy
      @copy_to.learning_outcomes.find_by_migration_id(mig_id(lo)).destroy
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).destroy if Qti.qti_enabled?
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool)).destroy
      @copy_to.assignment_groups.find_by_migration_id(mig_id(ag)).destroy
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).destroy
      @copy_to.grading_standards.find_by_migration_id(mig_id(gs)).destroy
      @copy_to.calendar_events.find_by_migration_id(mig_id(cal)).destroy

      @cm = ContentMigration.new(:context => @copy_to, :user => @user, :source_course => @copy_from, :copy_options => {:everything => "1"})
      @cm.user = @user
      @cm.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1)).workflow_state.should == 'active'
      @copy_to.context_modules.find_by_migration_id(mig_id(cm)).workflow_state.should == 'active'
      @copy_to.attachments.find_by_migration_id(mig_id(att)).file_state.should == 'available'
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki)).workflow_state.should == 'active'
      @copy_to.rubrics.find_by_migration_id(mig_id(rub1)).workflow_state.should == 'active'
      @copy_to.learning_outcomes.find_by_migration_id(mig_id(lo)).workflow_state.should == 'active'
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).workflow_state.should == 'created' if Qti.qti_enabled?
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool)).workflow_state.should == 'public'
      @copy_to.assignment_groups.find_by_migration_id(mig_id(ag)).workflow_state.should == 'available'
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).workflow_state.should == 'available'
      @copy_to.grading_standards.find_by_migration_id(mig_id(gs)).workflow_state.should == 'active'
      @copy_to.calendar_events.find_by_migration_id(mig_id(cal)).workflow_state.should == 'active'
    end

    it "should copy learning outcomes into the new course" do
      lo = @copy_from.learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "Lone outcome"
      lo.description = "<p>Descriptions are boring</p>"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
      lo.save!

      old_root = LearningOutcomeGroup.default_for(@copy_from)
      old_root.add_item(lo)

      lo_g = @copy_from.learning_outcome_groups.new
      lo_g.context = @copy_from
      lo_g.title = "Lone outcome group"
      lo_g.description = "<p>Groupage</p>"
      lo_g.save!
      old_root.add_item(lo_g)

      lo2 = @copy_from.learning_outcomes.new
      lo2.context = @copy_from
      lo2.short_description = "outcome in group"
      lo2.workflow_state = 'active'
      lo2.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo2.save!
      lo_g.add_item(lo2)
      old_root.reload

      # copy outcomes into new course
      new_root = LearningOutcomeGroup.default_for(@copy_to)

      run_course_copy

      @copy_to.learning_outcomes.count.should == @copy_from.learning_outcomes.count
      @copy_to.learning_outcome_groups.count.should == @copy_from.learning_outcome_groups.count
      new_root.sorted_content.count.should == old_root.sorted_content.count

      lo_2 = new_root.sorted_content.first
      lo_2.short_description.should == lo.short_description
      lo_2.description.should == lo.description
      lo_2.data.should == lo.data

      lo_g_2 = new_root.sorted_content.last
      lo_g_2.title.should == lo_g.title
      lo_g_2.description.should == lo_g.description
      lo_g_2.sorted_content.length.should == 1
      lo_g_2.root_learning_outcome_group_id.should == new_root.id
      lo_g_2.learning_outcome_group_id.should == new_root.id

      lo_2 = lo_g_2.sorted_content.first
      lo_2.short_description.should == lo2.short_description
      lo_2.description.should == lo2.description
      lo_2.data.should == lo2.data
    end

    it "should copy a quiz when assignment is selected" do
      pending unless Qti.qti_enabled?
      @quiz = @copy_from.quizzes.create!
      @quiz.did_edit
      @quiz.offer!
      @quiz.assignment.should_not be_nil

      @cm.copy_options = {
              :assignments => {mig_id(@quiz.assignment) => "1"},
              :quizzes => {mig_id(@quiz) => "0"},
      }
      @cm.save!

      run_course_copy

      @copy_to.quizzes.find_by_migration_id(mig_id(@quiz)).should_not be_nil
    end

    it "should export quizzes with groups that point to external banks" do
      pending unless Qti.qti_enabled?
      course_with_teacher(:user => @user)
      different_course = @course
      different_account = Account.create!

      q1 = @copy_from.quizzes.create!(:title => 'quiz1')
      bank = different_course.assessment_question_banks.create!(:title => 'bank')
      bank2 = @copy_from.account.assessment_question_banks.create!(:title => 'bank2')
      bank2.assessment_question_bank_users.create!(:user => @user)
      bank3 = different_account.assessment_question_banks.create!(:title => 'bank3')
      group = q1.quiz_groups.create!(:name => "group", :pick_count => 3, :question_points => 5.0)
      group.assessment_question_bank = bank
      group.save
      group2 = q1.quiz_groups.create!(:name => "group2", :pick_count => 5, :question_points => 2.0)
      group2.assessment_question_bank = bank2
      group2.save
      group3 = q1.quiz_groups.create!(:name => "group3", :pick_count => 5, :question_points => 2.0)
      group3.assessment_question_bank = bank3
      group3.save

      run_course_copy(["User didn't have permission to reference question bank in quiz group Question Group"])

      q = @copy_to.quizzes.find_by_migration_id(mig_id(q1))
      q.should_not be_nil
      q.quiz_groups.count.should == 3
      g = q.quiz_groups[0]
      g.assessment_question_bank_id.should == bank.id
      g = q.quiz_groups[1]
      g.assessment_question_bank_id.should == bank2.id
      g = q.quiz_groups[2]
      g.assessment_question_bank_id.should == nil

    end

    it "should copy a discussion topic when assignment is selected" do
      topic = @copy_from.discussion_topics.build(:title => "topic")
      assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => topic.title)
      assignment.infer_due_at
      assignment.saved_by = :discussion_topic
      topic.assignment = assignment
      topic.save

      @cm.copy_options = {
              :assignments => {mig_id(assignment) => "1"},
              :discussion_topics => {mig_id(topic) => "0"},
      }
      @cm.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(topic)).should_not be_nil
    end

    it "should still associate rubrics and assignments" do
      rubric = @copy_from.rubrics.new
      rubric.title = "Rubric"
      rubric.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}, {:criterion_id=>"309_6312", :points=>0, :description=>"No Marks", :id=>"blank_2", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}]
      rubric.save!

      assignment = @copy_from.assignments.create!(:title => "some assignment", :assignment_group => @group, :points_possible => 12)
      rubric.associate_with(assignment, @copy_from, :purpose => 'grading', :use_for_grading => true)

      run_course_copy

      rub = @copy_to.rubrics.find_by_migration_id(mig_id(rubric))
      rub.should_not be_nil
      asmnt2 = @copy_to.assignments.find_by_migration_id(mig_id(assignment))
      asmnt2.rubric.id.should == rub.id
    end

    it "should assign the correct parent folder when the parent folder has already been created" do
      folder = Folder.root_folders(@copy_from).first
      folder = folder.sub_folders.create!(:context => @copy_from, :name => 'folder_1')
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => folder, :context => @copy_from)
      folder = folder.sub_folders.create!(:context => @copy_from, :name => 'folder_2')
      folder = folder.sub_folders.create!(:context => @copy_from, :name => 'folder_3')
      old_attachment = Attachment.create!(:filename => 'merge.test', :uploaded_data => StringIO.new('ohey'), :folder => folder, :context => @copy_from)

      run_course_copy

      new_attachment = @copy_to.attachments.find_by_migration_id(mig_id(old_attachment))
      new_attachment.should_not be_nil
      new_attachment.full_path.should == "course files/folder_1/folder_2/folder_3/merge.test"
      folder.reload
    end

    it "items in the root folder should be in the root in the new course" do
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>"
      @copy_from.save!

      run_course_copy

      to_root = Folder.root_folders(@copy_to).first
      new_attachment = @copy_to.attachments.find_by_migration_id(mig_id(att))
      new_attachment.should_not be_nil
      new_attachment.full_path.should == "course files/dummy.txt"
      new_attachment.folder.should == to_root
      @copy_to.syllabus_body.should == %{<a href="/courses/#{@copy_to.id}/files/#{new_attachment.id}/download?wrap=1">link</a>}
    end

    it "should preserve media comment links" do
      pending unless Qti.qti_enabled?
      @copy_from.media_objects.create!(:media_id => '0_12345678')
      @copy_from.syllabus_body = <<-HTML.strip
      <p>
        Hello, students.<br>
        With associated media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
        Without associated media object: <a id="media_comment_0_12345678" class="instructure_inline_media_comment video_comment" href="/media_objects/0_12345678">this is a media comment</a>
        another type: <a id="media_comment_0_bq09qam2" class="instructure_inline_media_comment video_comment" href="/courses/#{@copy_from.id}/file_contents/course%20files/media_objects/0_bq09qam2">this is a media comment</a>
      </p>
      HTML

      run_course_copy

      @copy_to.syllabus_body.should == @copy_from.syllabus_body.gsub("/courses/#{@copy_from.id}/file_contents/course%20files",'')
    end

    it "should included implied files for course exports" do
      att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'second.jpg', :uploaded_data => StringIO.new('ohais'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att3 = Attachment.create!(:filename => 'third.jpg', :uploaded_data => StringIO.new('3333'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)

      asmnt_des = %{<a href="/courses/%s/files/%s/preview">First file</a>}
      wiki_body = %{<img src="/courses/%s/files/%s/preview">}
      asmnt = @copy_from.assignments.create!(:points_possible => 40, :grading_type => 'points', :description=>(asmnt_des % [@copy_from.id, att.id]), :title => "assignment")
      wiki = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => (wiki_body % [@copy_from.id, att2.id]))

      # don't mark the attachments
      @cm.copy_options = {
              :wiki_pages => {mig_id(wiki) => "1"},
              :assignments => {mig_id(asmnt) => "1"},
      }
      @cm.save!
      run_course_copy

      @copy_to.attachments.count.should == 2
      att_2 = @copy_to.attachments.find_by_migration_id(mig_id(att))
      att_2.should_not be_nil
      att2_2 = @copy_to.attachments.find_by_migration_id(mig_id(att2))
      att2_2.should_not be_nil

      @copy_to.assignments.first.description.should == asmnt_des % [@copy_to.id, att_2.id]
      @copy_to.wiki.wiki_pages.first.body.should == wiki_body % [@copy_to.id, att2_2.id]
    end

    it "should include implied objects for context modules" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
      mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})
      page = @copy_from.wiki.wiki_pages.create!(:title => "some page")
      page2 = @copy_from.wiki.wiki_pages.create!(:title => "some page 2")
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

      mod1_copy = @copy_to.context_modules.find_by_migration_id(mig_id(mod1))
      mod1_copy.should_not be_nil
      if Qti.qti_enabled?
        mod1_copy.content_tags.count.should == 8
      else
        mod1_copy.content_tags.count.should == 7
      end


      @copy_to.assignments.find_by_migration_id(mig_id(asmnt1)).should_not be_nil
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page)).should_not be_nil
      @copy_to.attachments.find_by_migration_id(mig_id(att)).should_not be_nil
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool)).should_not be_nil
      @copy_to.discussion_topics.find_by_migration_id(mig_id(topic)).should_not be_nil
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).should_not be_nil if Qti.qti_enabled?

      @copy_to.context_modules.find_by_migration_id(mig_id(mod2)).should be_nil
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt2)).should be_nil
      @copy_to.attachments.find_by_migration_id(mig_id(att2)).should be_nil
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page2)).should be_nil
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool2)).should be_nil
      @copy_to.discussion_topics.find_by_migration_id(mig_id(topic2)).should be_nil
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz2)).should be_nil
    end

    it "should perform day substitutions" do
      pending unless Qti.qti_enabled?
      @copy_from.assert_assignment_group
      today = Time.now.utc
      asmnt = @copy_from.assignments.build
      asmnt.due_at = today
      asmnt.workflow_state = 'published'
      asmnt.save!
      @copy_from.reload

      @cm.migration_settings[:migration_ids_to_import] = {
              :copy => {
                      :shift_dates => true,
                      :day_substitutions => {today.wday.to_s => (today.wday + 1).to_s}
              }
      }
      @cm.save!

      run_course_copy

      new_assignment = @copy_to.assignments.first
      # new_assignment.due_at.should == today + 1.day does not work
      new_assignment.due_at.to_i.should_not == asmnt.due_at.to_i
      (new_assignment.due_at.to_i - (today + 1.day).to_i).abs.should < 60
    end

    it "should shift dates" do
      pending unless Qti.qti_enabled?
      options = {
              :everything => true,
              :shift_dates => true,
              :old_start_date => 'Jul 1, 2012',
              :old_end_date => 'Jul 11, 2012',
              :new_start_date => 'Aug 5, 2012',
              :new_end_date => 'Aug 15, 2012'
      }

      old_start = DateTime.parse("01 Jul 2012 06:00:00 UTC +00:00")
      new_start = DateTime.parse("05 Aug 2012 06:00:00 UTC +00:00")

      @copy_from.assert_assignment_group
      @copy_from.assignments.create!(:due_at => old_start + 1.day,
                                     :unlock_at => old_start + 2.days,
                                     :lock_at => old_start + 3.days,
                                     :peer_reviews_due_at => old_start + 4.days
      )
      @copy_from.quizzes.create!(:due_at => "05 Jul 2012 06:00:00 UTC +00:00",
                                 :unlock_at => old_start + 1.days,
                                 :lock_at => old_start + 5.days
      )
      @copy_from.discussion_topics.create!(:title => "some topic",
                                           :message => "<p>some text</p>",
                                           :delayed_post_at => old_start + 3.days)
      cm = @copy_from.context_modules.build(:name => "some module", :unlock_at => old_start + 1.days)
      cm.start_at = old_start + 2.day
      cm.end_at = old_start + 3.days
      cm.save!

      @cm.migration_settings[:migration_ids_to_import] = {
              :copy => options
      }
      @cm.save!

      run_course_copy

      new_asmnt = @copy_to.assignments.first
      new_asmnt.due_at.to_i.should  == (new_start + 1.day).to_i
      new_asmnt.unlock_at.to_i.should == (new_start + 2.day).to_i
      new_asmnt.lock_at.to_i.should == (new_start + 3.day).to_i
      new_asmnt.peer_reviews_due_at.to_i.should == (new_start + 4.day).to_i

      new_quiz = @copy_to.quizzes.first
      new_quiz.due_at.to_i.should  == (new_start + 4.day).to_i
      new_quiz.unlock_at.to_i.should == (new_start + 1.day).to_i
      new_quiz.lock_at.to_i.should == (new_start + 5.day).to_i

      new_disc = @copy_to.discussion_topics.first
      new_disc.delayed_post_at.to_i.should == (new_start + 3.day).to_i

      new_mod = @copy_to.context_modules.first
      new_mod.unlock_at.to_i.should  == (new_start + 1.day).to_i
      new_mod.start_at.to_i.should == (new_start + 2.day).to_i
      new_mod.end_at.to_i.should == (new_start + 3.day).to_i
    end

    it "should copy time correctly across daylight savings shift MST to MDT" do
      Time.use_zone('America/Denver') do
        asmnt = @copy_from.assignments.new
        asmnt.title = "Nothing Assignment"
        asmnt.description = 'oi'
        asmnt.due_at = Time.zone.at(1325876400) # Fri, 06 Jan 2012 12:00:00 MST -07:00
        asmnt.save!

        @cm.migration_settings[:migration_ids_to_import] = {
                :copy => {
                        :everything => true,
                        :shift_dates => true,
                        :old_start_date => 'Jan 1, 2012',
                        :old_end_date => 'Jan 15, 2012',
                        :new_start_date => 'Jun 2, 2012',
                        :new_end_date => 'Jun 16, 2012'
                }
        }
        @cm.save!

        run_course_copy

        asmnt_2 = @copy_to.assignments.find_by_migration_id(mig_id(asmnt))
        asmnt_2.due_at.to_i.should == Time.zone.at(1339178400).to_i # Fri, 08 Jun 2012 12:00:00 MDT -06:00
      end
    end

    it "should copy time correctly across daylight savings shift MDT to MST" do
      Time.use_zone('America/Denver') do
        asmnt = @copy_from.assignments.new
        asmnt.title = "Nothing Assignment"
        asmnt.description = 'oi'
        asmnt.due_at = Time.zone.at(1339178400) # Fri, 08 Jun 2012 12:00:00 MDT -06:00
        asmnt.save!

        @cm.migration_settings[:migration_ids_to_import] = {
                :copy => {
                        :everything => true,
                        :shift_dates => true,
                        :old_start_date => 'Jun 2, 2012',
                        :old_end_date => 'Jun 16, 2012',
                        :new_start_date => 'Jan 4, 2013',
                        :new_end_date => 'Jan 18, 2013'
                }
        }
        @cm.save!

        run_course_copy

        asmnt_2 = @copy_to.assignments.find_by_migration_id(mig_id(asmnt))
        asmnt_2.due_at.to_i.should == Time.zone.at(1357326000).to_i # Fri, 04 Jan 2013 12:00:00 MST -07:00
      end
    end

    it "should leave file references in AQ context as-is on copy" do
      pending unless Qti.qti_enabled?
      @bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      @attachment = attachment_with_context(@copy_from)
      @attachment2 = @attachment = Attachment.create!(:filename => 'test.jpg', :display_name => "test.jpg", :uploaded_data => StringIO.new('psych!'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      data = {"name" => "Hi", "question_text" => <<-HTML.strip, "answers" => [{"id" => 1}, {"id" => 2}]}
      File ref:<img src="/courses/#{@copy_from.id}/files/#{@attachment.id}/download">
      different file ref: <img src="/courses/#{@copy_from.id}/file_contents/course%20files/unfiled/test.jpg">
      media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
      equation: <img class="equation_image" title="Log_216" src="/equation_images/Log_216" alt="Log_216">
      link to some other course: <a href="/courses/#{@copy_from.id + @copy_to.id}">Cool Course</a>
      canvas image: <img style="max-width: 723px;" src="/images/preview.png" alt="">
      HTML
      @question = @bank.assessment_questions.create!(:question_data => data)
      @question.reload.question_data['question_text'].should =~ %r{/assessment_questions/}

      run_course_copy

      bank = @copy_to.assessment_question_banks.first
      bank.assessment_questions.count.should == 1
      aq = bank.assessment_questions.first

      aq.question_data['question_text'].should == @question.question_data['question_text']
    end

    it "should correctly copy quiz question html file references" do
      pending unless Qti.qti_enabled?
      att = Attachment.create!(:filename => 'first.jpg', :display_name => "first.jpg", :uploaded_data => StringIO.new('first'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'test.jpg', :display_name => "test.jpg", :uploaded_data => StringIO.new('second'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att3 = Attachment.create!(:filename => 'testing.jpg', :display_name => "testing.jpg", :uploaded_data => StringIO.new('test this'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      qtext = <<-HTML.strip
File ref:<img src="/courses/%s/files/%s/download">
different file ref: <img src="/courses/%s/%s">
media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
equation: <img class="equation_image" title="Log_216" src="/equation_images/Log_216" alt="Log_216">
        HTML

      data = {:correct_comments_html => "<strong>correct</strong>",
                    :question_type => "multiple_choice_question",
                    :question_name => "test fun",
                    :name => "test fun",
                    :points_possible => 10,
                    :question_text => qtext % [@copy_from.id, att.id, @copy_from.id, "file_contents/course%20files/test.jpg"],
                    :answers =>
                            [{:migration_id => "QUE_1016_A1", :html => %{File ref:<img src="/courses/#{@copy_from.id}/files/#{att3.id}/download">}, :comments_html =>'<i>comment</i>', :text => "", :weight => 100, :id => 8080},
                             {:migration_id => "QUE_1017_A2", :html => "<strong>html answer 2</strong>", :comments_html =>'<i>comment</i>', :text => "", :weight => 0, :id => 2279}]}.with_indifferent_access

      q1 = @copy_from.quizzes.create!(:title => 'quiz1')
      qq = q1.quiz_questions.create!
      qq.write_attribute(:question_data, data)
      qq.save!

      run_course_copy

      @copy_to.attachments.count.should == 3
      att_2 = @copy_to.attachments.find_by_migration_id(mig_id(att))
      att2_2 = @copy_to.attachments.find_by_migration_id(mig_id(att2))
      att3_2 = @copy_to.attachments.find_by_migration_id(mig_id(att3))

      q_to = @copy_to.quizzes.first
      qq_to = q_to.quiz_questions.first
      qq_to.question_data[:question_text].should == qtext % [@copy_to.id, att_2.id, @copy_to.id, "files/#{att2_2.id}/preview"]
      qq_to.question_data[:answers][0][:html].should == %{File ref:<img src="/courses/#{@copy_to.id}/files/#{att3_2.id}/download">}
    end

    it "should copy all html fields in assessment questions" do
      pending unless Qti.qti_enabled?
      @bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      data = {:correct_comments_html => "<strong>correct</strong>",
                          :question_type => "multiple_choice_question",
                          :incorrect_comments_html => "<strong>incorrect</strong>",
                          :neutral_comments_html => "<strong>meh</strong>",
                          :question_name => "test fun",
                          :name => "test fun",
                          :points_possible => 10,
                          :question_text => "<strong>html for fun</strong>",
                          :answers =>
                                  [{:migration_id => "QUE_1016_A1", :html => "<strong>html answer 1</strong>", :comments_html =>'<i>comment</i>', :text => "", :weight => 100, :id => 8080},
                                   {:migration_id => "QUE_1017_A2", :html => "<strong>html answer 2</strong>", :comments_html =>'<i>comment</i>', :text => "", :weight => 0, :id => 2279}]}.with_indifferent_access
      aq_from1 = @bank.assessment_questions.create!(:question_data => data)
      data2 = data.clone
      data2[:question_text] = "<i>matching yo</i>"
      data2[:question_type] = 'matching_question'
      data2[:matches] = [{:match_id=>4835, :text=>"a", :html => '<i>a</i>'},
                        {:match_id=>6247, :text=>"b", :html => '<i>a</i>'}]
      data2[:answers][0][:match_id] = 4835
      data2[:answers][0][:left_html] = data2[:answers][0][:html]
      data2[:answers][0][:right] = "a"
      data2[:answers][1][:match_id] = 6247
      data2[:answers][1][:right] = "b"
      data2[:answers][1][:left_html] = data2[:answers][1][:html]
      aq_from2 = @bank.assessment_questions.create!(:question_data => data2)

      run_course_copy

      aq = @copy_to.assessment_questions.find_by_migration_id(mig_id(aq_from1))

      aq.question_data[:question_text].should == data[:question_text]
      aq.question_data[:answers][0][:html].should == data[:answers][0][:html]
      aq.question_data[:answers][0][:comments_html].should == data[:answers][0][:comments_html]
      aq.question_data[:answers][1][:html].should == data[:answers][1][:html]
      aq.question_data[:answers][1][:comments_html].should == data[:answers][1][:comments_html]
      aq.question_data[:correct_comments_html].should == data[:correct_comments_html]
      aq.question_data[:incorrect_comments_html].should == data[:incorrect_comments_html]
      aq.question_data[:neutral_comments_html].should == data[:neutral_comments_html]

      # and the matching question
      aq = @copy_to.assessment_questions.find_by_migration_id(mig_id(aq_from2))
      aq.question_data[:answers][0][:html].should == data2[:answers][0][:html]
      aq.question_data[:answers][0][:left_html].should == data2[:answers][0][:left_html]
      aq.question_data[:answers][1][:html].should == data2[:answers][1][:html]
      aq.question_data[:answers][1][:left_html].should == data2[:answers][1][:left_html]
    end

    it "should send the correct emails" do
      Notification.create!(:name => 'Migration Export Ready')
      Notification.create!(:name => 'Migration Import Failed')
      Notification.create!(:name => 'Migration Import Finished')

      run_course_copy

      @cm.messages_sent['Migration Export Ready'].should be_blank
      @cm.messages_sent['Migration Import Finished'].should be_blank
      @cm.messages_sent['Migration Import Failed'].should be_blank
    end

  end

  context "import_object?" do
    before do
      @cm = ContentMigration.new
    end

    it "should return true for everything if there are no copy options" do
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == true
    end

    it "should return true for everything if 'everything' is selected" do
      @cm.migration_ids_to_import = {:copy => {:everything => "1"}}
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == true
    end

    it "should return true if there are no copy options" do
      @cm.migration_ids_to_import = {:copy => {}}
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == true
    end

    it "should return false for nil objects" do
      @cm.import_object?("content_migrations", nil).should == false
    end

    it "should return true for all object types if the all_ option is true" do
      @cm.migration_ids_to_import = {:copy => {:all_content_migrations => "1"}}
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == true
    end

    it "should return false for objects not selected" do
      @cm.save!
      @cm.migration_ids_to_import = {:copy => {:all_content_migrations => "0"}}
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == false
      @cm.migration_ids_to_import = {:copy => {:content_migrations => {}}}
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == false
      @cm.migration_ids_to_import = {:copy => {:content_migrations => {CC::CCHelper.create_key(@cm) => "0"}}}
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == false
    end

    it "should return true for selected objects" do
      @cm.save!
      @cm.migration_ids_to_import = {:copy => {:content_migrations => {CC::CCHelper.create_key(@cm) => "1"}}}
      @cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm)).should == true
    end

  end

end
