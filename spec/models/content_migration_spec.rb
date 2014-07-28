# coding: utf-8
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
    before :once do
      course_with_teacher(:course_name => "from course", :active_all => true)
      @copy_from = @course

      course_with_teacher(:user => @user, :course_name => "tocourse", :course_code => "tocourse")
      @copy_to = @course

      @cm = ContentMigration.new(
        :context => @copy_to,
        :user => @user,
        :source_course => @copy_from,
        :migration_type => 'course_copy_importer',
        :copy_options => {:everything => "1"}
      )
      @cm.migration_settings[:import_immediately] = true
      @cm.save!
    end

    it "should show correct progress" do
      ce = @course.content_exports.build
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
      @cm.set_default_settings
      worker = Canvas::Migration::Worker::CourseCopyWorker.new
      worker.perform(@cm)
      @cm.reload
      if @cm.migration_settings[:last_error]
        er = ErrorReport.last
        "#{er.message} - #{er.backtrace}".should == ""
      end
      @cm.warnings.should == warnings
      @cm.workflow_state.should == 'imported'
      @copy_to.reload
    end

    it "should migrate syllabus links on copy" do
      course_model

      topic = @copy_from.discussion_topics.create!(:title => "some topic", :message => "<p>some text</p>")
      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/discussion_topics/#{topic.id}'>link</a>"
      @copy_from.save!

      @cm.copy_options = {
        everything: false,
        all_syllabus_body: true,
        all_discussion_topics: true
      }
      @cm.save!
      run_course_copy

      new_topic = @copy_to.discussion_topics.find_by_migration_id(CC::CCHelper.create_key(topic))
      new_topic.should_not be_nil
      new_topic.message.should == topic.message
      @copy_to.syllabus_body.should match(/\/courses\/#{@copy_to.id}\/discussion_topics\/#{new_topic.id}/)
    end

    it "should copy course syllabus when the everything option is selected" do
      course_model

      @copy_from.syllabus_body = "What up"
      @copy_from.save!

      run_course_copy

      @copy_to.syllabus_body.should =~ /#{@copy_from.syllabus_body}/
    end

    it "should not migrate syllabus when not selected" do
      course_model
      @copy_from.syllabus_body = "<p>wassup</p>"

      @cm.copy_options = {
        :course => {'all_syllabus_body' => false}
      }
      @cm.save!

      run_course_copy

      @copy_to.syllabus_body.should == nil
    end

    def make_grading_standard(context, opts = {})
      gs = context.grading_standards.new
      gs.title = opts[:title] || "Standard eh"
      gs.data = [["A", 0.93], ["A-", 0.89], ["B+", 0.85], ["B", 0.83], ["B!-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]]
      gs.save!
      gs
    end

    it "should copy course attributes" do
      #set all the possible values to non-default values
      @copy_from.start_at = 5.minutes.ago
      @copy_from.conclude_at = 1.month.from_now
      @copy_from.is_public = false
      @copy_from.name = "haha copy from test &amp;"
      @copy_from.course_code = 'something funny'
      @copy_from.allow_student_wiki_edits = true
      @copy_from.show_public_context_messages = false
      @copy_from.allow_student_forum_attachments = false
      @copy_from.default_wiki_editing_roles = 'teachers'
      @copy_from.allow_student_organized_groups = false
      @copy_from.default_view = 'modules'
      @copy_from.show_all_discussion_entries = false
      @copy_from.open_enrollment = true
      @copy_from.storage_quota = 444
      @copy_from.allow_wiki_comments = true
      @copy_from.turnitin_comments = "Don't plagiarize"
      @copy_from.self_enrollment = true
      @copy_from.license = "cc_by_nc_nd"
      @copy_from.locale = "es"
      @copy_from.tab_configuration = [{"id"=>0}, {"id"=>14}, {"id"=>8}, {"id"=>5}, {"id"=>6}, {"id"=>2}, {"id"=>3, "hidden"=>true}]
      @copy_from.hide_final_grades = true
      gs = make_grading_standard(@copy_from)
      @copy_from.grading_standard = gs
      @copy_from.grading_standard_enabled = true
      @copy_from.save!

      run_course_copy

      #compare settings
      @copy_to.conclude_at.should == nil
      @copy_to.start_at.should == nil
      @copy_to.storage_quota.should == 444
      @copy_to.hide_final_grades.should == true
      @copy_to.grading_standard_enabled.should == true
      gs_2 = @copy_to.grading_standards.find_by_migration_id(mig_id(gs))
      gs_2.data.should == gs.data
      @copy_to.grading_standard.should == gs_2
      @copy_to.name.should == "tocourse"
      @copy_to.course_code.should == "tocourse"
      atts = Course.clonable_attributes
      atts -= Canvas::Migration::MigratorHelper::COURSE_NO_COPY_ATTS
      atts.each do |att|
        @copy_to.send(att).should == @copy_from.send(att)
      end
      @copy_to.tab_configuration.should == @copy_from.tab_configuration
     end

    describe "grading standards" do
      it "should retain reference to account grading standard" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        @copy_to.grading_standard.should == gs
      end

      it "should copy a course grading standard not owned by the copy_from course" do
        @other_course = course_model
        gs = make_grading_standard(@other_course)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        run_course_copy

        @copy_to.grading_standard_enabled.should be_true
        @copy_to.grading_standard.data.should == gs.data
      end

      it "should create a warning if an account grading standard can't be found" do
        gs = make_grading_standard(@copy_from.root_account)
        @copy_from.grading_standard = gs
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.delete

        run_course_copy(["Couldn't find account grading standard for the course."])

        @copy_to.grading_standard.should == nil
      end

      it "should not copy deleted grading standards" do
        gs = make_grading_standard(@copy_from)
        @copy_from.grading_standard_enabled = true
        @copy_from.save!

        gs.destroy
        @copy_from.reload

        run_course_copy

        @copy_to.grading_standards.should be_empty
      end

      it "should not copy grading standards if nothing is selected" do
        gs = make_grading_standard(@copy_from)
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0' }
        @cm.save!
        run_course_copy
        @copy_to.grading_standards.should be_empty
      end

      it "should copy the course's grading standard (once) if course_settings are selected" do
        gs = make_grading_standard(@copy_from, title: 'What')
        @copy_from.update_attribute(:grading_standard, gs)
        @cm.copy_options = { 'everything' => '0', 'all_course_settings' => '1' }
        @cm.save!
        run_course_copy
        @copy_to.grading_standards.count.should eql 1 # no dupes
        @copy_to.grading_standard.title.should eql gs.title
      end

      it "should copy grading standards referenced by exported assignments" do
        gs1, gs2 = make_grading_standard(@copy_from, title: 'One'), make_grading_standard(@copy_from, title: 'Two')
        assign = @copy_from.assignments.build
        assign.grading_standard = gs2
        assign.save!
        @cm.copy_options = { 'everything' => '0', 'assignments' => { mig_id(assign) => "1" } }
        run_course_copy
        @copy_to.grading_standards.map(&:title).should eql %w(Two)
        @copy_to.assignments.first.grading_standard.title.should eql 'Two'
      end
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

    it "should keep date-locked files locked" do
      student = user
      @copy_from.enroll_student(student)
      att = Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from, :lock_at => 1.month.ago, :unlock_at => 1.month.from_now)
      att.grants_right?(student, :download).should be_false

      run_course_copy

      @copy_to.enroll_student(student)
      new_att = @copy_to.attachments.find_by_migration_id(CC::CCHelper.create_key(att))
      new_att.should be_present

      new_att.grants_right?(student, :download).should be_false
    end

    it "should translate links to module items in html content" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
      tag = mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})
      body = %{<p>Link to module item: <a href="/courses/%s/modules/items/%s">some assignment</a></p>}
      page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body % [@copy_from.id, tag.id])

      run_course_copy

      mod1_to = @copy_to.context_modules.find_by_migration_id(mig_id(mod1))
      tag_to = mod1_to.content_tags.first
      page_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
      page_to.body.should == body % [@copy_to.id, tag_to.id]
    end

    it "should be able to copy links to files in folders with html entities and unicode in path" do
      root_folder = Folder.root_folders(@copy_from).first
      folder1 = root_folder.sub_folders.create!(:context => @copy_from, :name => "mol&eacute;")
      att1 = Attachment.create!(:filename => "first.txt", :uploaded_data => StringIO.new('ohai'), :folder => folder1, :context => @copy_from)
      folder2 = root_folder.sub_folders.create!(:context => @copy_from, :name => "olé")
      att2 = Attachment.create!(:filename => "first.txt", :uploaded_data => StringIO.new('ohai'), :folder => folder2, :context => @copy_from)

      body = "<a class='instructure_file_link' href='/courses/#{@copy_from.id}/files/#{att1.id}/download'>link</a>"
      body += "<a class='instructure_file_link' href='/courses/#{@copy_from.id}/files/#{att2.id}/download'>link</a>"
      dt = @copy_from.discussion_topics.create!(:message => body, :title => "discussion title")
      page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body)

      run_course_copy

      att_to1 = @copy_to.attachments.find_by_migration_id(mig_id(att1))
      att_to2 = @copy_to.attachments.find_by_migration_id(mig_id(att2))

      page_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
      page_to.body.include?("/courses/#{@copy_to.id}/files/#{att_to1.id}/download").should be_true
      page_to.body.include?("/courses/#{@copy_to.id}/files/#{att_to2.id}/download").should be_true

      dt_to = @copy_to.discussion_topics.find_by_migration_id(mig_id(dt))
      dt_to.message.include?("/courses/#{@copy_to.id}/files/#{att_to1.id}/download").should be_true
      dt_to.message.include?("/courses/#{@copy_to.id}/files/#{att_to2.id}/download").should be_true
    end

    it "should not escape links to wiki urls" do
      page1 = @copy_from.wiki.wiki_pages.create!(:title => "keepthese%20percent signs", :body => "blah")

      body = %{<p>Link to module item: <a href="/courses/%s/#{@copy_from.feature_enabled?(:draft_state) ? 'pages' : 'wiki'}/%s#header">some assignment</a></p>}
      page2 = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body % [@copy_from.id, page1.url])

      run_course_copy

      page1_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page1))
      page2_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page2))
      page2_to.body.should == body % [@copy_to.id, page1_to.url]
    end

    context "unpublished items" do
      before :each do
        Account.default.enable_feature!(:draft_state)
      end

      it "should copy unpublished modules" do
        cm = @copy_from.context_modules.create!(:name => "some module")
        cm.publish
        cm2 = @copy_from.context_modules.create!(:name => "another module")
        cm2.unpublish

        run_course_copy

        @copy_to.context_modules.count.should == 2
        cm_2 = @copy_to.context_modules.find_by_migration_id(mig_id(cm))
        cm_2.workflow_state.should == 'active'
        cm2_2 = @copy_to.context_modules.find_by_migration_id(mig_id(cm2))
        cm2_2.workflow_state.should == 'unpublished'
      end

      it "should copy links to unpublished items in modules" do
        mod1 = @copy_from.context_modules.create!(:name => "some module")
        page = @copy_from.wiki.wiki_pages.create(:title => "some page")
        page.workflow_state = :unpublished
        page.save!
        mod1.add_item({:id => page.id, :type => 'wiki_page'})

        asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
        asmnt1.workflow_state = :unpublished
        asmnt1.save!
        mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})

        run_course_copy

        mod1_copy = @copy_to.context_modules.find_by_migration_id(mig_id(mod1))
        mod1_copy.content_tags.count.should == 2

        mod1_copy.content_tags.each do |tag_copy|
          tag_copy.unpublished?.should == true
          tag_copy.content.unpublished?.should == true
        end
      end

      it "should copy unpublished discussion topics" do
        dt1 = @copy_from.discussion_topics.create!(:message => "hideeho", :title => "Blah")
        dt1.workflow_state = :unpublished
        dt1.save!
        dt2 = @copy_from.discussion_topics.create!(:message => "asdf", :title => "qwert")
        dt2.workflow_state = :active
        dt2.save!

        run_course_copy

        dt1_copy = @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1))
        dt1_copy.workflow_state.should == 'unpublished'
        dt2_copy = @copy_to.discussion_topics.find_by_migration_id(mig_id(dt2))
        dt2_copy.workflow_state.should == 'active'
      end

      it "should copy unpublished wiki pages" do
        wiki = @copy_from.wiki.wiki_pages.create(:title => "wiki", :body => "ohai")
        wiki.workflow_state = :unpublished
        wiki.save!

        run_course_copy

        wiki2 = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki))
        wiki2.workflow_state.should == 'unpublished'
      end

      it "should copy unpublished quiz assignments" do
        pending unless Qti.qti_enabled?
        @quiz = @copy_from.quizzes.create!
        @quiz.did_edit
        @quiz.offer!
        @quiz.unpublish!
        @quiz.assignment.should be_unpublished

        @cm.copy_options = {
            :assignments => {mig_id(@quiz.assignment) => "0"},
            :quizzes => {mig_id(@quiz) => "1"},
        }
        @cm.save!

        run_course_copy

        quiz_to = @copy_to.quizzes.find_by_migration_id(mig_id(@quiz))
        quiz_to.should_not be_nil
        quiz_to.assignment.should_not be_nil
        quiz_to.assignment.should be_unpublished
        quiz_to.assignment.migration_id.should == mig_id(@quiz.assignment)
      end
    end

    it "should find and fix wiki links by title or id" do
      # simulating what happens when the user clicks "link to new page" and enters a title that isn't
      # urlified the same way by the client vs. the server.  this doesn't break navigation because
      # ApplicationController#get_wiki_page can match by urlified title, but it broke import (see #9945)
      main_page = @copy_from.wiki.front_page
      main_page.body = %{<a href="/courses/#{@copy_from.id}/wiki/online:-unit-pages">wut</a>}
      main_page.save!
      @copy_from.wiki.wiki_pages.create!(:title => "Online: Unit Pages", :body => %{<a href="/courses/#{@copy_from.id}/wiki/#{main_page.id}">whoa</a>})
      run_course_copy
      @copy_to.wiki.front_page.body.should == %{<a href="/courses/#{@copy_to.id}/wiki/online-unit-pages">wut</a>}
      @copy_to.wiki.wiki_pages.find_by_url!("online-unit-pages").body.should == %{<a href="/courses/#{@copy_to.id}/wiki/#{main_page.url}">whoa</a>}
    end

    context "wiki front page" do
      it "should copy wiki front page setting if there is no front page" do
        page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(page.url)

        @copy_to.wiki.unset_front_page!
        run_course_copy

        new_page = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
        @copy_to.wiki.front_page.should == new_page
      end

      it "should not overwrite current front page" do
        @copy_to.root_account.enable_feature!(:draft_state)

        copy_from_front_page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(copy_from_front_page.url)

        copy_to_front_page = @copy_to.wiki.wiki_pages.create!(:title => "stuff and stuff and even more stuf")
        @copy_to.wiki.set_front_page_url!(copy_to_front_page.url)

        run_course_copy

        @copy_to.wiki.front_page.should == copy_to_front_page
      end

      it "should remain with no front page if other front page is not selected for copy" do
        @copy_to.root_account.enable_feature!(:draft_state)

        front_page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(front_page.url)

        other_page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and other stuff")

        @copy_to.wiki.unset_front_page!

        # only select one of each type
        @cm.copy_options = {
            :wiki_pages => {mig_id(other_page) => "1", mig_id(front_page) => "0"}
        }
        @cm.save!

        run_course_copy

        @copy_to.wiki.has_no_front_page.should == true
      end

      it "should set retain default behavior if front page is missing and draft state is not enabled" do
        @copy_to.wiki.front_page.save!

        @copy_from.default_view = 'wiki'
        @copy_from.save!
        @copy_from.wiki.set_front_page_url!('haha not here')

        run_course_copy

        @copy_to.wiki.has_front_page?.should == true
        @copy_to.wiki.get_front_page_url.should == 'front-page'
      end

      it "should set default view to feed if wiki front page is missing and draft state is enabled" do
        @copy_from.root_account.enable_feature!(:draft_state)

        @copy_from.default_view = 'wiki'
        @copy_from.save!
        @copy_from.wiki.set_front_page_url!('haha not here')

        run_course_copy

        @copy_to.default_view.should == 'feed'
        @copy_to.wiki.has_front_page?.should == false
      end
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
      default = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      default.adopt_outcome_group(log)

      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!

      log.add_outcome(lo)

      # only select one of each type
      @cm.copy_options = {
              :discussion_topics => {mig_id(dt1) => "1"},
              :announcements => {mig_id(dt3) => "1"},
              :context_modules => {mig_id(cm) => "1", mig_id(cm2) => "0"},
              :attachments => {mig_id(att) => "1", mig_id(att2) => "0"},
              :wiki_pages => {mig_id(wiki) => "1", mig_id(wiki2) => "0"},
              :rubrics => {mig_id(rub1) => "1", mig_id(rub2) => "0"},
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

      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).should be_nil
      @copy_to.learning_outcome_groups.find_by_migration_id(mig_id(log)).should be_nil
    end

    it "should copy all learning outcomes and their groups if selected" do
      default = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      default.adopt_outcome_group(log)

      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!

      log.add_outcome(lo)

      @cm.copy_options = {
          :all_learning_outcomes => "1"
      }
      @cm.save!

      run_course_copy

      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).should_not be_nil
      @copy_to.learning_outcome_groups.find_by_migration_id(mig_id(log)).should_not be_nil
    end

    it "should copy learning outcome alignments with question banks" do
      pending unless Qti.qti_enabled?
      default = @copy_from.root_outcome_group
      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      default.add_outcome(lo)

      bank = @copy_from.assessment_question_banks.create!(:title => 'bank')
      bank.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})

      lo.align(bank, @copy_from, {:mastery_type => 'points', :mastery_score => 50.0})

      run_course_copy

      new_lo = @copy_to.learning_outcomes.find_by_migration_id(mig_id(lo))
      new_bank = @copy_to.assessment_question_banks.find_by_migration_id(mig_id(bank))

      new_lo.alignments.count.should == 1
      new_alignment = new_lo.alignments.first

      new_alignment.content.should == new_bank
      new_alignment.context.should == @copy_to

      new_alignment.tag.should == 'points_mastery'
      new_alignment.mastery_score.should == 50.0
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
      default = @copy_from.root_outcome_group
      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      default.add_outcome(lo)
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
      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).destroy
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).destroy if Qti.qti_enabled?
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool)).destroy
      @copy_to.assignment_groups.find_by_migration_id(mig_id(ag)).destroy
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).destroy
      @copy_to.grading_standards.find_by_migration_id(mig_id(gs)).destroy
      @copy_to.calendar_events.find_by_migration_id(mig_id(cal)).destroy

      @cm = ContentMigration.create!(
        :context => @copy_to,
        :user => @user,
        :source_course => @copy_from,
        :migration_type => 'course_copy_importer',
        :copy_options => {:everything => "1"}
      )

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1)).workflow_state.should == 'active'
      @copy_to.context_modules.find_by_migration_id(mig_id(cm)).workflow_state.should == 'active'
      @copy_to.attachments.count.should == 1
      @copy_to.attachments.find_by_migration_id(mig_id(att)).file_state.should == 'available'
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki)).workflow_state.should == 'active'
      rub2 = @copy_to.rubrics.find_by_migration_id(mig_id(rub1))
      rub2.workflow_state.should == 'active'
      rub2.rubric_associations.first.bookmarked.should == true
      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).workflow_state.should == 'active'
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).workflow_state.should == 'created' if Qti.qti_enabled?
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool)).workflow_state.should == 'public'
      @copy_to.assignment_groups.find_by_migration_id(mig_id(ag)).workflow_state.should == 'available'
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).workflow_state.should == asmnt.workflow_state
      @copy_to.grading_standards.find_by_migration_id(mig_id(gs)).workflow_state.should == 'active'
      @copy_to.calendar_events.find_by_migration_id(mig_id(cal)).workflow_state.should == 'active'
    end

    def create_outcome(context, group=nil)
      lo = LearningOutcome.new
      lo.context = context
      lo.short_description = "haha_#{rand(10_000)}"
      lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      if group
        group.add_outcome(lo)
      elsif context
        context.root_outcome_group.add_outcome(lo)
      end

      lo
    end

    it "should copy learning outcomes into the new course" do
      old_root = @copy_from.root_outcome_group

      lo = create_outcome(@copy_from, old_root)

      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "An outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      old_root.adopt_outcome_group(log)

      lo2 = create_outcome(@copy_from, log)

      log_sub = @copy_from.learning_outcome_groups.new
      log_sub.context = @copy_from
      log_sub.title = "Sub group"
      log_sub.description = "<p>SubGroupage</p>"
      log_sub.save!
      log.adopt_outcome_group(log_sub)

      log_sub2 = @copy_from.learning_outcome_groups.new
      log_sub2.context = @copy_from
      log_sub2.title = "Sub group2"
      log_sub2.description = "<p>SubGroupage2</p>"
      log_sub2.save!
      log_sub.adopt_outcome_group(log_sub2)

      lo3 = create_outcome(@copy_from, log_sub2)

      # copy outcomes into new course
      new_root = @copy_to.root_outcome_group

      run_course_copy

      @copy_to.created_learning_outcomes.count.should == @copy_from.created_learning_outcomes.count
      @copy_to.learning_outcome_groups.count.should == @copy_from.learning_outcome_groups.count
      new_root.child_outcome_links.count.should == old_root.child_outcome_links.count
      new_root.child_outcome_groups.count.should == old_root.child_outcome_groups.count

      lo_new = new_root.child_outcome_links.first.content
      lo_new.short_description.should == lo.short_description
      lo_new.description.should == lo.description
      lo_new.data.should == lo.data

      log_new = new_root.child_outcome_groups.first
      log_new.title.should == log.title
      log_new.description.should == log.description
      log_new.child_outcome_links.length.should == 1

      lo_new = log_new.child_outcome_links.first.content
      lo_new.short_description.should == lo2.short_description
      lo_new.description.should == lo2.description
      lo_new.data.should == lo2.data

      log_sub_new = log_new.child_outcome_groups.first
      log_sub_new.title.should == log_sub.title
      log_sub_new.description.should == log_sub.description

      log_sub2_new = log_sub_new.child_outcome_groups.first
      log_sub2_new.title.should == log_sub2.title
      log_sub2_new.description.should == log_sub2.description

      lo3_new = log_sub2_new.child_outcome_links.first.content
      lo3_new.short_description.should == lo3.short_description
      lo3_new.description.should == lo3.description
      lo3_new.data.should == lo3.data
    end

    it "should not copy deleted learning outcomes into the new course" do
      old_root = @copy_from.root_outcome_group

      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "An outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      old_root.adopt_outcome_group(log)

      lo = create_outcome(@copy_from, log)
      lo2 = create_outcome(@copy_from, log)
      lo2.destroy

      run_course_copy

      @copy_to.created_learning_outcomes.count.should == 1
      @copy_to.created_learning_outcomes.first.migration_id.should == mig_id(lo)
    end

    it "should relink to external outcomes" do
      account = @copy_from.account
      a_group = account.root_outcome_group

      root_group = LearningOutcomeGroup.create!(:title => "contextless group")

      lo = create_outcome(nil, root_group)

      lo2 = create_outcome(account, a_group)

      from_root = @copy_from.root_outcome_group
      from_root.add_outcome(lo)
      from_root.add_outcome(lo2)

      run_course_copy

      to_root = @copy_to.root_outcome_group
      to_root.child_outcome_links.count.should == 2
      to_root.child_outcome_links.find_by_content_id(lo.id).should_not be_nil
      to_root.child_outcome_links.find_by_content_id(lo2.id).should_not be_nil
    end

    it "should create outcomes in new course if external context not found" do
      hash = {"is_global_outcome"=>true,
               "points_possible"=>nil,
               "type"=>"learning_outcome",
               "ratings"=>[],
               "description"=>nil,
               "mastery_points"=>nil,
               "external_identifier"=>"0",
               "title"=>"root outcome",
               "migration_id"=>"id1072dcf40e801c6468d9eaa5774e56d"}

      @cm.outcome_to_id_map = {}
      Importers::LearningOutcomeImporter.import_from_migration(hash, @cm)

      @cm.warnings.should == ["The external Learning Outcome couldn't be found for \"root outcome\", creating a copy."]

      to_root = @copy_to.root_outcome_group
      to_root.child_outcome_links.count.should == 1
      new_lo = to_root.child_outcome_links.first.content
      new_lo.id.should_not == 0
      new_lo.short_description.should == hash["title"]
    end

    it "should create rubrics in new course if external context not found" do
      hash = {
              "reusable"=>false,
              "public"=>false,
              "hide_score_total"=>nil,
              "free_form_criterion_comments"=>nil,
              "points_possible"=>nil,
              "data"=>[{"id"=>"1",
                        "description"=>"Outcome row",
                        "long_description"=>nil,
                        "points"=>3,
                        "mastery_points"=>nil,
                        "title"=>"Outcome row",
                        "ratings"=>[{"description"=>"Rockin'",
                                     "id"=>"2",
                                     "criterion_id"=>"1", "points"=>3}]}],
              "read_only"=>false,
              "description"=>nil,
              "external_identifier"=>"0",
              "title"=>"root rubric",
              "migration_id"=>"id1072dcf40e801c6468d9eaa5774e56d"}

      @cm.outcome_to_id_map = {}
      Importers::RubricImporter.import_from_migration(hash, @cm)

      @cm.warnings.should == ["The external Rubric couldn't be found for \"root rubric\", creating a copy."]

      new_rubric = @copy_to.rubrics.first
      new_rubric.id.should_not == 0
      new_rubric.title.should == hash["title"]
    end

    it "should link rubric (and assignments) to outcomes" do
      root_group = LearningOutcomeGroup.create!(:title => "contextless group")

      lo = create_outcome(nil, root_group)
      lo2 = create_outcome(@copy_from)

      from_root = @copy_from.root_outcome_group
      from_root.add_outcome(lo)
      from_root.add_outcome(lo2)

      rub = Rubric.new(:context => @copy_from)
      rub.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}],
          :learning_outcome_id => lo.id
        },
        {
          :points => 3,
          :description => "Outcome row 2",
          :id => 2,
          :ratings => [{:points => 3,:description => "lame'",:criterion_id => 2,:id => 3}],
          :ignore_for_scoring => true,
          :learning_outcome_id => lo2.id
        }
      ]
      rub.save!
      rub.associate_with(@copy_from, @copy_from)

      from_assign = @copy_from.assignments.create!(:title => "some assignment")
      rub.associate_with(from_assign, @copy_from, :purpose => "grading")

      run_course_copy

      new_lo2 = @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo2))
      to_rub = @copy_to.rubrics.first
      to_assign = @copy_to.assignments.first

      to_rub.data[1]["learning_outcome_id"].should == new_lo2.id
      to_rub.data[1]["ignore_for_scoring"].should == true
      to_rub.data[0]["learning_outcome_id"].should == lo.id
      to_rub.learning_outcome_alignments.map(&:learning_outcome_id).sort.should == [lo.id, new_lo2.id].sort
      to_assign.learning_outcome_alignments.map(&:learning_outcome_id).sort.should == [lo.id, new_lo2.id].sort
    end

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
      to_assign.rubric.should == rub

      to_assign.learning_outcome_alignments.map(&:learning_outcome_id).should == [lo.id].sort
    end

    it "should link assignments to assignment groups on selective copy" do
      g = @copy_from.assignment_groups.create!(:name => "group")
      from_assign = @copy_from.assignments.create!(:title => "some assignment", :assignment_group_id => g.id)

      @cm.copy_options = {:all_assignments => true}
      run_course_copy

      to_assign = @copy_to.assignments.find_by_migration_id(mig_id(from_assign))
      to_assign.assignment_group.should == @copy_to.assignment_groups.find_by_migration_id(mig_id(g))
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

    it "should create a new assignment and module item if copying a new quiz (even if the assignment migration_id matches)" do
      pending unless Qti.qti_enabled?
      quiz = @copy_from.quizzes.create!(:title => "new quiz")
      quiz2 = @copy_to.quizzes.create!(:title => "already existing quiz")

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag = mod.add_item({:id => quiz.id, :type => 'quiz'})

      [quiz, quiz2].each do |q|
        q.did_edit
        q.offer!
      end

      a = quiz2.assignment
      a.migration_id = mig_id(quiz.assignment)
      a.save!

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["already existing quiz", "new quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["already existing quiz", "new quiz"]
      @copy_to.context_module_tags.map(&:title).should == ["new quiz"]
    end

    it "should not duplicate quizzes and associated items if overwrite_quizzes is true" do
      pending unless Qti.qti_enabled?
      # overwrite_quizzes should now default to true for course copy and canvas import

      quiz = @copy_from.quizzes.create!(:title => "published quiz")
      quiz2 = @copy_from.quizzes.create!(:title => "unpublished quiz")
      quiz.did_edit
      quiz.offer!
      quiz2.unpublish!

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag = mod.add_item({:id => quiz.id, :type => 'quiz'})
      tag2 = mod.add_item({:id => quiz2.id, :type => 'quiz'})

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["published quiz", "unpublished quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["published quiz"]
      @copy_to.context_module_tags.map(&:title).sort.should == ["published quiz", "unpublished quiz"]

      @copy_to.quizzes.find_by_title("published quiz").should_not be_unpublished
      @copy_to.quizzes.find_by_title("unpublished quiz").should be_unpublished

      quiz.title = "edited published quiz"
      quiz.save!
      quiz2.title = "edited unpublished quiz"
      quiz2.save!

      # run again
      @cm = ContentMigration.new(
        :context => @copy_to,
        :user => @user,
        :source_course => @copy_from,
        :migration_type => 'course_copy_importer',
        :copy_options => {:everything => "1"}
      )
      @cm.user = @user
      @cm.migration_settings[:import_immediately] = true
      @cm.save!

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["edited published quiz", "edited unpublished quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["edited published quiz"]
      @copy_to.context_module_tags.map(&:title).sort.should == ["edited published quiz", "edited unpublished quiz"]

      @copy_to.quizzes.find_by_title("edited published quiz").should_not be_unpublished
      @copy_to.quizzes.find_by_title("edited unpublished quiz").should be_unpublished
    end

    it "should duplicate quizzes and associated items if overwrite_quizzes is false" do
      pending unless Qti.qti_enabled?
      quiz = @copy_from.quizzes.create!(:title => "published quiz")
      quiz2 = @copy_from.quizzes.create!(:title => "unpublished quiz")
      quiz.did_edit
      quiz2.did_edit
      quiz.offer!

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag = mod.add_item({:id => quiz.id, :type => 'quiz'})
      tag2 = mod.add_item({:id => quiz2.id, :type => 'quiz'})

      run_course_copy

      # run again
      @cm = ContentMigration.new(
        :context => @copy_to,
        :user => @user,
        :source_course => @copy_from,
        :migration_type => 'course_copy_importer',
        :copy_options => {:everything => "1"}
      )
      @cm.user = @user
      @cm.migration_settings[:import_immediately] = true
      @cm.migration_settings[:overwrite_quizzes] = false
      @cm.save!

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["published quiz", "published quiz", "unpublished quiz", "unpublished quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["published quiz", "published quiz"]
      @copy_to.context_module_tags.map(&:title).sort.should == ["published quiz", "published quiz", "unpublished quiz", "unpublished quiz"]
    end

    it "should have correct question count on copied surveys and practive quizzes" do
      pending unless Qti.qti_enabled?
      sp = @copy_from.quizzes.create!(:title => "survey pub", :quiz_type => "survey")
      data = {
                          :question_type => "multiple_choice_question",
                          :question_name => "test fun",
                          :name => "test fun",
                          :points_possible => 10,
                          :question_text => "<strong>html for fun</strong>",
                          :answers =>
                                  [{:migration_id => "QUE_1016_A1", :text => "<br />", :weight => 100, :id => 8080},
                                   {:migration_id => "QUE_1017_A2", :text => "<pre>", :weight => 0, :id => 2279}]}.with_indifferent_access
      qq = sp.quiz_questions.create!
      qq.write_attribute(:question_data, data)
      qq.save!
      sp.generate_quiz_data
      sp.published_at = Time.now
      sp.workflow_state = 'available'
      sp.save!

      sp.question_count.should == 1

      run_course_copy

      q = @copy_to.quizzes.find_by_migration_id(mig_id(sp))
      q.should_not be_nil
      q.question_count.should == 1
    end

    it "should not mix up quiz questions and assessment questions with the same ids" do
      pending unless Qti.qti_enabled?
      quiz1 = @copy_from.quizzes.create!(:title => "quiz 1")
      quiz2 = @copy_from.quizzes.create!(:title => "quiz 1")

      qq1 = quiz1.quiz_questions.create!(:question_data => {'question_name' => 'test question 1', 'answers' => [{'id' => 1}, {'id' => 2}]})
      qq2 = quiz2.quiz_questions.create!(:question_data => {'question_name' => 'test question 2', 'answers' => [{'id' => 1}, {'id' => 2}]})
      Quizzes::QuizQuestion.where(:id => qq1).update_all(:assessment_question_id => qq2.id)

      run_course_copy

      newquiz2 = @copy_to.quizzes.find_by_migration_id(mig_id(quiz2))
      newquiz2.quiz_questions.first.question_data['question_name'].should == 'test question 2'
    end

    it "should generate numeric ids for answers" do
      pending unless Qti.qti_enabled?

      q = @copy_from.quizzes.create!(:title => "test quiz")
      mc = q.quiz_questions.create!
      mc.write_attribute(:question_data, {
          points_possible: 1,
          question_type: "multiple_choice_question",
          question_name: "mc",
          name: "mc",
          question_text: "what is your favorite color?",
          answers: [{ text: 'blue', weight: 0, id: 123 },
                    { text: 'yellow', weight: 100, id: 456 }]
      }.with_indifferent_access)
      mc.save!
      tf = q.quiz_questions.create!
      tf.write_attribute(:question_data, {
          points_possible: 1,
          question_type: "true_false_question",
          question_name: "tf",
          name: "tf",
          question_text: "this statement is false.",
          answers: [{ text: "True", weight: 100, id: 9608 },
                    { text: "False", weight: 0, id: 9093 }]
      }.with_indifferent_access)
      tf.save!
      q.generate_quiz_data
      q.workflow_state = 'available'
      q.save!

      run_course_copy

      q2 = @copy_to.quizzes.find_by_migration_id(mig_id(q))
      q2.quiz_data.size.should eql(2)
      ans_count = 0
      q2.quiz_data.each do |qd|
        qd["answers"].each do |ans|
          ans["id"].should be_a(Integer)
          ans_count += 1
        end
      end
      ans_count.should eql(4)
    end

    it "should copy quizzes as published if they were published before" do
      pending unless Qti.qti_enabled?
      g = @copy_from.assignment_groups.create!(:name => "new group")
      asmnt_unpub = @copy_from.quizzes.create!(:title => "asmnt unpub", :quiz_type => "assignment", :assignment_group_id => g.id)
      asmnt_pub = @copy_from.quizzes.create(:title => "asmnt", :quiz_type => "assignment", :assignment_group_id => g.id)
      asmnt_pub.workflow_state = 'available'
      asmnt_pub.save!
      graded_survey_unpub = @copy_from.quizzes.create!(:title => "graded survey unpub", :quiz_type => "graded_survey", :assignment_group_id => g.id)
      graded_survey_pub = @copy_from.quizzes.create(:title => "grade survey pub", :quiz_type => "graded_survey", :assignment_group_id => g.id)
      graded_survey_pub.workflow_state = 'available'
      graded_survey_pub.save!
      survey_unpub = @copy_from.quizzes.create!(:title => "survey unpub", :quiz_type => "survey")
      survey_pub = @copy_from.quizzes.create(:title => "survey pub", :quiz_type => "survey")
      survey_pub.workflow_state = 'available'
      survey_pub.save!
      practice_unpub = @copy_from.quizzes.create!(:title => "practice unpub", :quiz_type => "practice_quiz")
      practice_pub = @copy_from.quizzes.create(:title => "practice pub", :quiz_type => "practice_quiz")
      practice_pub.workflow_state = 'available'
      practice_pub.save!

      run_course_copy

      [asmnt_unpub, asmnt_pub, graded_survey_unpub, graded_survey_pub, survey_pub, survey_unpub, practice_unpub, practice_pub].each do |orig|
        q = @copy_to.quizzes.find_by_migration_id(mig_id(orig))
        "#{q.title} - #{q.workflow_state}".should == "#{orig.title} - #{orig.workflow_state}" # titles in there to help identify what type failed
        q.quiz_type.should == orig.quiz_type
      end
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

    it "should omit deleted questions in banks" do
      pending unless Qti.qti_enabled?
      bank1 = @copy_from.assessment_question_banks.create!(:title => 'bank')
      q1 = bank1.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
      q2 = bank1.assessment_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}]})
      q3 = bank1.assessment_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 5}, {'id' => 6}]})
      q2.destroy

      run_course_copy

      bank2 = @copy_to.assessment_question_banks.first
      bank2.should be_present
      # we don't copy over deleted questions at all, not even marked as deleted
      bank2.assessment_questions.active.size.should == 2
      bank2.assessment_questions.size.should == 2
    end

    it "should not copy plain text question comments as html" do
      pending unless Qti.qti_enabled?
      bank1 = @copy_from.assessment_question_banks.create!(:title => 'bank')
      q = bank1.assessment_questions.create!(:question_data => {
          "question_type" => "multiple_choice_question", 'name' => 'test question',
          'answers' => [{'id' => 1, "text" => "Correct", "weight" => 100, "comments" => "another comment"},
                        {'id' => 2, "text" => "inorrect", "weight" => 0}],
          "correct_comments" => "Correct answer comment", "incorrect_comments" => "Incorrect answer comment",
          "neutral_comments" => "General Comment", "more_comments" => "even more comments"
      })

      run_course_copy

      q2 = @copy_to.assessment_questions.first
      ["correct_comments_html", "incorrect_comments_html", "neutral_comments_html", "more_comments_html"].each do |k|
        q2.question_data.keys.should_not include(k)
      end
      q2.question_data["answers"].each do |a|
        a.keys.should_not include("comments_html")
      end
    end

    it "should copy assignment attributes" do
      assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'file_upload', :grading_type => 'points')
      @assignment.turnitin_enabled = true
      @assignment.peer_reviews_assigned = true
      @assignment.peer_reviews = true
      @assignment.peer_review_count = 2
      @assignment.automatic_peer_reviews = true
      @assignment.anonymous_peer_reviews = true
      @assignment.allowed_extensions = ["doc", "xls"]
      @assignment.position = 2
      @assignment.muted = true

      @assignment.save!

      attrs = [:turnitin_enabled, :peer_reviews_assigned, :peer_reviews,
          :automatic_peer_reviews, :anonymous_peer_reviews,
          :grade_group_students_individually, :allowed_extensions,
          :position, :peer_review_count, :muted]

      run_course_copy

      new_assignment = @copy_to.assignments.find_by_migration_id(mig_id(@assignment))
      attrs.each do |attr|
        @assignment[attr].should == new_assignment[attr]
      end
    end

    it "should copy discussion topic attributes" do
      topic = @copy_from.discussion_topics.create!(:title => "topic", :message => "<p>bloop</p>",
                                                   :pinned => true, :discussion_type => "threaded",
                                                   :require_initial_post => true)
      topic.posted_at = 2.days.ago
      topic.position = 2
      topic.save!

      run_course_copy

      @copy_to.discussion_topics.count.should == 1
      new_topic = @copy_to.discussion_topics.first

      attrs = ["title", "message", "discussion_type", "type", "pinned", "position", "require_initial_post"]
      topic.attributes.slice(*attrs).should == new_topic.attributes.slice(*attrs)

      new_topic.last_reply_at.to_i.should == new_topic.posted_at.to_i
      topic.posted_at.to_i.should == new_topic.posted_at.to_i
    end

    it "should copy a discussion topic when assignment is selected" do
      topic = @copy_from.discussion_topics.build(:title => "topic")
      assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => topic.title)
      assignment.infer_times
      assignment.saved_by = :discussion_topic
      topic.assignment = assignment
      topic.save

      # Should not fail if the destination has a group
      @copy_to.groups.create!(:name => 'some random group of people')

      @cm.copy_options = {
              :assignments => {mig_id(assignment) => "1"},
              :discussion_topics => {mig_id(topic) => "0"},
      }
      @cm.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(topic)).should_not be_nil
    end

    it "should properly copy selected delayed announcements" do
      from_ann = @copy_from.announcements.create!(:message => "goodbye", :title => "goodbye announcement", delayed_post_at: 1.hour.from_now)
      from_ann.workflow_state = "post_delayed"
      from_ann.save!

      @cm.copy_options = { :announcements => {mig_id(from_ann) => "1"}}
      @cm.save!

      run_course_copy

      to_ann = @copy_to.announcements.find_by_migration_id(mig_id(from_ann))
      to_ann.workflow_state.should == "post_delayed"
    end

    it "should not copy announcements if not selected" do
      ann = @copy_from.announcements.create!(:message => "howdy", :title => "announcement title")

      @cm.copy_options = {
          :all_discussion_topics => "1", :all_announcements => "0"
      }
      @cm.save!

      run_course_copy

      @copy_to.announcements.find_by_migration_id(mig_id(ann)).should be_nil
    end

    it "should not copy deleted assignment attached to topic" do
      topic = @copy_from.discussion_topics.build(:title => "topic")
      assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => topic.title)
      assignment.infer_times
      assignment.saved_by = :discussion_topic
      topic.assignment = assignment
      topic.save!
      assignment.workflow_state = 'deleted'
      assignment.save!

      topic.reload
      topic.active?.should == true

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(topic)).should_not be_nil
      @copy_to.assignments.find_by_migration_id(mig_id(assignment)).should be_nil
    end

    it "should not copy deleted assignment attached to quizzes" do
      pending unless Qti.qti_enabled?
      g = @copy_from.assignment_groups.create!(:name => "new group")
      quiz = @copy_from.quizzes.create(:title => "asmnt", :quiz_type => "assignment", :assignment_group_id => g.id)
      quiz.workflow_state = 'available'
      quiz.save!

      asmnt = quiz.assignment

      quiz.quiz_type = 'practice_quiz'
      quiz.save!

      asmnt.workflow_state = 'deleted'
      asmnt.save!

      run_course_copy

      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).should_not be_nil
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).should be_nil
    end

    def create_rubric_asmnt
      @rubric = @copy_from.rubrics.new
      @rubric.title = "Rubric"
      @rubric.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5.5, :description=>"Full Marks", :id=>"blank", :long_description=>""}, {:criterion_id=>"309_6312", :points=>0, :description=>"No Marks", :id=>"blank_2", :long_description=>""}], :points=>5.5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}]
      @rubric.save!

      @assignment = @copy_from.assignments.create!(:title => "some assignment", :points_possible => 12)
      @assoc = @rubric.associate_with(@assignment, @copy_from, :purpose => 'grading', :use_for_grading => true)
      @assoc.hide_score_total = true
      @assoc.use_for_grading = true
      @assoc.save!
    end

    it "should still associate rubrics and assignments and copy rubric association properties" do
      create_rubric_asmnt
      @assoc.summary_data = {:saved_comments=>{"309_6312"=>["what the comment", "hey"]}}
      @assoc.save!

      run_course_copy

      rub = @copy_to.rubrics.find_by_migration_id(mig_id(@rubric))
      rub.should_not be_nil

      [:description, :id, :points].each do |k|
        rub.data.first[k].should == @rubric.data.first[k]
      end
      [:criterion_id, :description, :id, :points].each do |k|
        rub.data.first[:ratings].each_with_index do |criterion, i|
          criterion[k].should == @rubric.data.first[:ratings][i][k]
        end
      end

      asmnt2 = @copy_to.assignments.find_by_migration_id(mig_id(@assignment))
      asmnt2.rubric.id.should == rub.id
      asmnt2.rubric_association.use_for_grading.should == true
      asmnt2.rubric_association.hide_score_total.should == true
      asmnt2.rubric_association.summary_data.should == @assoc.summary_data
    end

    it "should copy rubrics associated with assignments when rubric isn't selected" do
      create_rubric_asmnt
      @cm.copy_options = {
              :assignments => {mig_id(@assignment) => "1"},
      }
      @cm.save!
      run_course_copy

      rub = @copy_to.rubrics.find_by_migration_id(mig_id(@rubric))
      rub.should_not be_nil
      asmnt2 = @copy_to.assignments.find_by_migration_id(mig_id(@assignment))
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

    it "should copy files into the correct folders when the folders share the same name" do
      root = Folder.root_folders(@copy_from).first
      f1 = root.sub_folders.create!(:name => "folder", :context => @copy_from)
      f2 = f1.sub_folders.create!(:name => "folder", :context => @copy_from)

      atts = []
      atts << Attachment.create!(:filename => 'dummy1.txt', :uploaded_data => StringIO.new('fakety'), :folder => f2, :context => @copy_from)
      atts << Attachment.create!(:filename => 'dummy2.txt', :uploaded_data => StringIO.new('fakety'), :folder => f1, :context => @copy_from)

      run_course_copy

      atts.each do |att|
        new_att = @copy_to.attachments.find_by_migration_id(mig_id(att))
        new_att.full_path.should == att.full_path
      end
    end

    it "should add a warning instead of failing when trying to copy an invalid file" do
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      Attachment.where(:id => att).update_all(:filename => nil)

      att.reload
      att.should_not be_valid

      run_course_copy(["Couldn't copy file \"dummy.txt\""])
    end

    it "should convert domains in imported urls if specified in account settings" do
      account = @copy_to.root_account
      account.settings[:default_migration_settings] = {:domain_substitution_map => {"http://derp.derp" => "https://derp.derp"}}
      account.save!

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag1 = mod.add_item({ :title => 'Example 1', :type => 'external_url', :url => 'http://derp.derp/something' })
      tool = @copy_from.context_external_tools.create!(:name => "b", :url => "http://derp.derp/somethingelse", :consumer_key => '12345', :shared_secret => 'secret')
      tag2 = mod.add_item :type => 'context_external_tool', :id => tool.id, :url => "#{tool.url}?queryyyyy=something"

      @copy_from.syllabus_body = "<p><a href=\"http://derp.derp/stuff\">this is a link to an insecure domain that could cause problems</a></p>"

      run_course_copy

      tool_to = @copy_to.context_external_tools.find_by_migration_id(mig_id(tool))
      tool_to.url.should == tool.url.sub("http://derp.derp", "https://derp.derp")
      tag1_to = @copy_to.context_module_tags.find_by_migration_id(mig_id(tag1))
      tag1_to.url.should == tag1.url.sub("http://derp.derp", "https://derp.derp")
      tag2_to = @copy_to.context_module_tags.find_by_migration_id(mig_id(tag2))
      tag2_to.url.should == tag2.url.sub("http://derp.derp", "https://derp.derp")

      @copy_to.syllabus_body.should == @copy_from.syllabus_body.sub("http://derp.derp", "https://derp.derp")
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

    it "should re-use kaltura media objects" do
      expect {
        media_id = '0_deadbeef'
        @copy_from.media_objects.create!(:media_id => media_id)
        att = Attachment.create!(:filename => 'video.mp4', :uploaded_data => StringIO.new('pixels and frames and stuff'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
        att.media_entry_id = media_id
        att.content_type = "video/mp4"
        att.save!

        run_course_copy

        @copy_to.attachments.find_by_migration_id(mig_id(att)).media_entry_id.should == media_id
      }.to change { Delayed::Job.jobs_count(:tag, 'MediaObject.add_media_files') }.by(0)
    end

    it "should include implied files for course exports" do
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

    it "should copy module prerequisites" do
      enable_cache do
        mod = @copy_from.context_modules.create!(:name => "first module")
        mod2 = @copy_from.context_modules.create(:name => "next module")
        mod2.position = 2
        mod2.prerequisites = "module_#{mod.id}"
        mod2.save!

        run_course_copy

        to_mod = @copy_to.context_modules.find_by_migration_id(mig_id(mod))
        to_mod2 = @copy_to.context_modules.find_by_migration_id(mig_id(mod2))
        to_mod2.prerequisites.should_not == []
        to_mod2.prerequisites[0][:id].should eql(to_mod.id)
      end
    end

    it "should preserve links to re-uploaded attachments" do
      att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att.destroy
      new_att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      @copy_from.attachments.find(att.id).should == new_att

      page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>")

      @cm.copy_options = { :wiki_pages => {mig_id(page) => "1"}}
      @cm.save!

      run_course_copy

      att2 = @copy_to.attachments.find_by_filename('first.png')
      page2 = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
      page2.body.should include("<a href=\"/courses/#{@copy_to.id}/files/#{att2.id}/download?wrap=1\">link</a>")
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

      @cm.copy_options = @cm.copy_options.merge(
              :shift_dates => true,
              :day_substitutions => {today.wday.to_s => (today.wday + 1).to_s}
      )
      @cm.save!

      run_course_copy

      new_assignment = @copy_to.assignments.first
      # new_assignment.due_at.should == today + 1.day does not work
      new_assignment.due_at.to_i.should_not == asmnt.due_at.to_i
      (new_assignment.due_at.to_i - (today + 1.day).to_i).abs.should < 60
    end

    describe "date shifting" do
      before do
        @old_start = DateTime.parse("01 Jul 2012 06:00:00 UTC +00:00")
        @new_start = DateTime.parse("05 Aug 2012 06:00:00 UTC +00:00")

        @copy_from.assert_assignment_group
        @copy_from.assignments.create!(:due_at => @old_start + 1.day,
                                       :unlock_at => @old_start + 2.days,
                                       :lock_at => @old_start + 3.days,
                                       :peer_reviews_due_at => @old_start + 4.days
        )
        @copy_from.quizzes.create!(:due_at => "05 Jul 2012 06:00:00 UTC +00:00",
                                   :unlock_at => @old_start + 1.days,
                                   :lock_at => @old_start + 5.days,
                                   :show_correct_answers_at => @old_start + 6.days,
                                   :hide_correct_answers_at => @old_start + 7.days
        )
        @copy_from.discussion_topics.create!(:title => "some topic",
                                             :message => "<p>some text</p>",
                                             :delayed_post_at => @old_start + 3.days)
        @copy_from.announcements.create!(:title => "hear ye",
                                         :message => "<p>grades will henceforth be in Cyrillic letters</p>",
                                         :delayed_post_at => @old_start + 10.days)
        @copy_from.calendar_events.create!(:title => "an event",
                                           :start_at => @old_start + 4.days,
                                           :end_at => @old_start + 4.days + 1.hour)
        cm = @copy_from.context_modules.build(:name => "some module", :unlock_at => @old_start + 1.days)
        cm.start_at = @old_start + 2.day
        cm.end_at = @old_start + 3.days
        cm.save!
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
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        new_asmnt.due_at.to_i.should  == (@new_start + 1.day).to_i
        new_asmnt.unlock_at.to_i.should == (@new_start + 2.day).to_i
        new_asmnt.lock_at.to_i.should == (@new_start + 3.day).to_i
        new_asmnt.peer_reviews_due_at.to_i.should == (@new_start + 4.day).to_i

        new_quiz = @copy_to.quizzes.first
        new_quiz.due_at.to_i.should  == (@new_start + 4.day).to_i
        new_quiz.unlock_at.to_i.should == (@new_start + 1.day).to_i
        new_quiz.lock_at.to_i.should == (@new_start + 5.day).to_i
        new_quiz.show_correct_answers_at.to_i.should == (@new_start + 6.day).to_i
        new_quiz.hide_correct_answers_at.to_i.should == (@new_start + 7.day).to_i

        new_disc = @copy_to.discussion_topics.first
        new_disc.delayed_post_at.to_i.should == (@new_start + 3.day).to_i

        new_ann = @copy_to.announcements.first
        new_ann.delayed_post_at.to_i.should == (@new_start + 10.day).to_i

        new_event = @copy_to.calendar_events.first
        new_event.start_at.to_i.should == (@new_start + 4.day).to_i
        new_event.end_at.to_i.should == (@new_start + 4.day + 1.hour).to_i

        new_mod = @copy_to.context_modules.first
        new_mod.unlock_at.to_i.should  == (@new_start + 1.day).to_i
        new_mod.start_at.to_i.should == (@new_start + 2.day).to_i
        new_mod.end_at.to_i.should == (@new_start + 3.day).to_i
      end

      it "should remove dates" do
        pending unless Qti.qti_enabled?
        options = {
            :everything => true,
            :remove_dates => true,
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        new_asmnt.due_at.should be_nil
        new_asmnt.unlock_at.should be_nil
        new_asmnt.lock_at.should be_nil
        new_asmnt.peer_reviews_due_at.should be_nil

        new_quiz = @copy_to.quizzes.first
        new_quiz.due_at.should be_nil
        new_quiz.unlock_at.should be_nil
        new_quiz.lock_at.should be_nil
        new_quiz.show_correct_answers_at.should be_nil
        new_quiz.hide_correct_answers_at.should be_nil

        new_disc = @copy_to.discussion_topics.first
        new_disc.delayed_post_at.should be_nil

        new_ann = @copy_to.announcements.first
        new_ann.delayed_post_at.should be_nil

        new_event = @copy_to.calendar_events.first
        new_event.start_at.should be_nil
        new_event.end_at.should be_nil

        new_mod = @copy_to.context_modules.first
        new_mod.unlock_at.should be_nil
        new_mod.start_at.should be_nil
        new_mod.end_at.should be_nil
      end
    end

    it "should copy all quiz attributes" do
      pending unless Qti.qti_enabled?
      q = @copy_from.quizzes.create!(
              :title => 'quiz',
              :description => "<p>description eh</p>",
              :shuffle_answers => true,
              :show_correct_answers => true,
              :time_limit => 20,
              :allowed_attempts => 4,
              :scoring_policy => 'keep_highest',
              :quiz_type => 'survey',
              :access_code => 'code',
              :anonymous_submissions => true,
              :hide_results => 'until_after_last_attempt',
              :ip_filter => '192.168.1.1',
              :require_lockdown_browser => true,
              :require_lockdown_browser_for_results => true,
              :notify_of_update => true,
              :one_question_at_a_time => true,
              :cant_go_back => true,
              :require_lockdown_browser_monitor => true,
              :lockdown_browser_monitor_data => 'VGVzdCBEYXRhCg==',
      )

      run_course_copy

      new_quiz = @copy_to.quizzes.first

      [:title, :description, :points_possible, :shuffle_answers,
       :show_correct_answers, :time_limit, :allowed_attempts, :scoring_policy, :quiz_type,
       :access_code, :anonymous_submissions,
       :hide_results, :ip_filter, :require_lockdown_browser,
       :require_lockdown_browser_for_results, :require_lockdown_browser_monitor,
       :lockdown_browser_monitor_data].each do |prop|
        new_quiz.send(prop).should == q.send(prop)
      end

    end

    context "should copy time correctly across daylight saving shift" do
      let(:local_time_zone) { ActiveSupport::TimeZone.new 'America/Denver' }

      def copy_assignment(options = {})
        account = @copy_to.account

        old_time_zone = account.default_time_zone
        account.default_time_zone = options.include?(:account_time_zone) ? options[:account_time_zone].name : 'UTC'
        account.save!

        Time.use_zone('UTC') do
          assignment = @copy_from.assignments.create! :title => 'Assignment', :due_at => old_date
          assignment.save!

          opts = {
                  :everything => true,
                  :shift_dates => true,
                  :old_start_date => old_start_date,
                  :old_end_date => old_end_date,
                  :new_start_date => new_start_date,
                  :new_end_date => new_end_date
          }
          opts[:time_zone] = options[:time_zone].name if options.include?(:time_zone)
          @cm.copy_options = @cm.copy_options.merge(opts)
          @cm.save!

          run_course_copy

          assignment2 = @copy_to.assignments.find_by_migration_id(mig_id(assignment))
          assignment2.due_at.in_time_zone(local_time_zone)
        end
      ensure
        account.default_time_zone = old_time_zone
        account.save!
      end

      context "from MST to MDT" do
        let(:old_date)       { local_time_zone.local(2012, 1, 6, 12, 0) } # 6 Jan 2012 12:00
        let(:new_date)       { local_time_zone.local(2012, 4, 6, 12, 0) } # 6 Apr 2012 12:00
        let(:old_start_date) { 'Jan 1, 2012' }
        let(:old_end_date)   { 'Jan 15, 2012' }
        let(:new_start_date) { 'Apr 1, 2012' }
        let(:new_end_date)   { 'Apr 15, 2012' }

        it "using an explicit time zone" do
          new_date.should == copy_assignment(:time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-04-01 06:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 06:00:00 UTC')
        end

        it "using the account time zone" do
          new_date.should == copy_assignment(:account_time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-04-01 06:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 06:00:00 UTC')
        end
      end

      context "from MDT to MST" do
        let(:old_date)       { local_time_zone.local(2012, 9, 6, 12, 0) }  # 6 Sep 2012 12:00
        let(:new_date)       { local_time_zone.local(2012, 12, 6, 12, 0) } # 6 Dec 2012 12:00
        let(:old_start_date) { 'Sep 1, 2012' }
        let(:old_end_date)   { 'Sep 15, 2012' }
        let(:new_start_date) { 'Dec 1, 2012' }
        let(:new_end_date)   { 'Dec 15, 2012' }

        it "using an explicit time zone" do
          new_date.should == copy_assignment(:time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-12-01 07:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 07:00:00 UTC')
        end

        it "using the account time zone" do
          new_date.should == copy_assignment(:account_time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-12-01 07:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 07:00:00 UTC')
        end
      end

      context "parsing dates with times" do
        context "from MST to MDT" do
          let(:old_date)       { local_time_zone.local(2012, 1, 6, 12, 0) } # 6 Jan 2012 12:00
          let(:new_date)       { local_time_zone.local(2012, 4, 6, 12, 0) } # 6 Apr 2012 12:00
          let(:old_start_date) { '2012-01-01T01:00:00' }
          let(:old_end_date)   { '2012-01-15T01:00:00' }
          let(:new_start_date) { '2012-04-01T01:00:00' }
          let(:new_end_date)   { '2012-04-15T01:00:00' }

          it "using an explicit time zone" do
            new_date.should == copy_assignment(:time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-04-01 07:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 07:00:00 UTC')
          end

          it "using the account time zone" do
            new_date.should == copy_assignment(:account_time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-04-01 07:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 07:00:00 UTC')
          end
        end

        context "from MDT to MST" do
          let(:old_date)       { local_time_zone.local(2012, 9, 6, 12, 0) }  # 6 Sep 2012 12:00
          let(:new_date)       { local_time_zone.local(2012, 12, 6, 12, 0) } # 6 Dec 2012 12:00
          let(:old_start_date) { '2012-09-01T01:00:00' }
          let(:old_end_date)   { '2012-09-15T01:00:00' }
          let(:new_start_date) { '2012-12-01T01:00:00' }
          let(:new_end_date)   { '2012-12-15T01:00:00' }

          it "using an explicit time zone" do
            new_date.should == copy_assignment(:time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-12-01 08:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 08:00:00 UTC')
          end

          it "using the account time zone" do
            new_date.should == copy_assignment(:account_time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-12-01 08:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 08:00:00 UTC')
          end
        end
      end
    end

    it "should correctly copy all day dates for assignments and events" do
      date = "Jun 21 2012 11:59pm"
      date2 = "Jun 21 2012 00:00am"
      asmnt = @copy_from.assignments.create!(:title => 'all day', :due_at => date)
      asmnt.all_day.should be_true

      cal = nil
      Time.use_zone('America/Denver') do
        cal = @copy_from.calendar_events.create!(:title => "haha", :description => "oi", :start_at => date2, :end_at => date2)
        cal.start_at.strftime("%H:%M").should == "00:00"
      end

      Time.use_zone('UTC') do
        run_course_copy
      end

      asmnt_2 = @copy_to.assignments.find_by_migration_id(mig_id(asmnt))
      asmnt_2.all_day.should be_true
      asmnt_2.due_at.strftime("%H:%M").should == "23:59"
      asmnt_2.all_day_date.should == Date.parse("Jun 21 2012")

      cal_2 = @copy_to.calendar_events.find_by_migration_id(mig_id(cal))
      cal_2.all_day.should be_true
      cal_2.all_day_date.should == Date.parse("Jun 21 2012")
      cal_2.start_at.utc.should == cal.start_at.utc
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

      aq.question_data['question_text'].should match_ignoring_whitespace(@question.question_data['question_text'])
    end

    it "should correctly copy quiz question html file references" do
      pending unless Qti.qti_enabled?
      root = Folder.root_folders(@copy_from).first
      folder = root.sub_folders.create!(:context => @copy_from, :name => 'folder 1')
      att = Attachment.create!(:filename => 'first.jpg', :display_name => "first.jpg", :uploaded_data => StringIO.new('first'), :folder => root, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'test.jpg', :display_name => "test.jpg", :uploaded_data => StringIO.new('second'), :folder => root, :context => @copy_from)
      att3 = Attachment.create!(:filename => 'testing.jpg', :display_name => "testing.jpg", :uploaded_data => StringIO.new('test this'), :folder => root, :context => @copy_from)
      att4 = Attachment.create!(:filename => 'sub_test.jpg', :display_name => "sub_test.jpg", :uploaded_data => StringIO.new('sub_folder'), :folder => folder, :context => @copy_from)
      qtext = <<-HTML.strip
File ref:<img src="/courses/%s/files/%s/download">
different file ref: <img src="/courses/%s/%s">
subfolder file ref: <img src="/courses/%s/%s">
media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
equation: <img class="equation_image" title="Log_216" src="/equation_images/Log_216" alt="Log_216">
        HTML

      data = {:correct_comments_html => "<strong>correct</strong>",
                    :question_type => "multiple_choice_question",
                    :question_name => "test fun",
                    :name => "test fun",
                    :points_possible => 10,
                    :question_text => qtext % [@copy_from.id, att.id, @copy_from.id, "file_contents/course%20files/test.jpg", @copy_from.id, "file_contents/course%20files/folder%201/sub_test.jpg"],
                    :answers =>
                            [{:migration_id => "QUE_1016_A1", :html => %{File ref:<img src="/courses/#{@copy_from.id}/files/#{att3.id}/download">}, :comments_html =>'<i>comment</i>', :text => "", :weight => 100, :id => 8080},
                             {:migration_id => "QUE_1017_A2", :html => "<strong>html answer 2</strong>", :comments_html =>'<i>comment</i>', :text => "", :weight => 0, :id => 2279}]}.with_indifferent_access

      q1 = @copy_from.quizzes.create!(:title => 'quiz1')
      qq = q1.quiz_questions.create!
      qq.write_attribute(:question_data, data)
      qq.save!

      run_course_copy

      @copy_to.attachments.count.should == 4
      att_2 = @copy_to.attachments.find_by_migration_id(mig_id(att))
      att2_2 = @copy_to.attachments.find_by_migration_id(mig_id(att2))
      att3_2 = @copy_to.attachments.find_by_migration_id(mig_id(att3))
      att4_2 = @copy_to.attachments.find_by_migration_id(mig_id(att4))

      q_to = @copy_to.quizzes.first
      qq_to = q_to.active_quiz_questions.first
      qq_to.question_data[:question_text].should match_ignoring_whitespace(qtext % [@copy_to.id, att_2.id, @copy_to.id, "files/#{att2_2.id}/preview", @copy_to.id, "files/#{att4_2.id}/preview"])
      qq_to.question_data[:answers][0][:html].should match_ignoring_whitespace(%{File ref:<img src="/courses/#{@copy_to.id}/files/#{att3_2.id}/download">})
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
                                   {:migration_id => "QUE_1017_A2", :html => "<span style=\"color: #808000;\">html answer 2</span>", :comments_html =>'<i>comment</i>', :text => "", :weight => 0, :id => 2279}]}.with_indifferent_access
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

    it "should copy file_upload_questions" do
      pending unless Qti.qti_enabled?
      bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      data = {:question_type => "file_upload_question",
              :points_possible => 10,
              :question_text => "<strong>html for fun</strong>"
              }.with_indifferent_access
      bank.assessment_questions.create!(:question_data => data)

      q = @copy_from.quizzes.create!(:title => "survey pub", :quiz_type => "survey")
      q.quiz_questions.create!(:question_data => data)
      q.generate_quiz_data
      q.published_at = Time.now
      q.workflow_state = 'available'
      q.save!

      run_course_copy

      @copy_to.assessment_questions.count.should == 2
      @copy_to.assessment_questions.each do |aq|
        aq.question_data['question_type'].should == data[:question_type]
        aq.question_data['question_text'].should == data[:question_text]
      end

      @copy_to.quizzes.count.should == 1
      quiz = @copy_to.quizzes.first
      quiz.active_quiz_questions.size.should == 1

      qq = quiz.active_quiz_questions.first
      qq.question_data['question_type'].should == data[:question_type]
      qq.question_data['question_text'].should == data[:question_text]
    end

    it "should import calendar events" do
      body_with_link = "<p>Watup? <strong>eh?</strong><a href=\"/courses/%s/assignments\">Assignments</a></p>"
      cal = @copy_from.calendar_events.new
      cal.title = "Calendar event"
      cal.description = body_with_link % @copy_from.id
      cal.start_at = 1.week.from_now
      cal.save!
      cal.all_day = true
      cal.save!
      cal2 = @copy_from.calendar_events.new
      cal2.title = "Stupid events"
      cal2.start_at = 5.minutes.from_now
      cal2.end_at = 10.minutes.from_now
      cal2.all_day = false
      cal2.save!
      cal3 = @copy_from.calendar_events.create!(:title => "deleted event")
      cal3.destroy

      run_course_copy

      @copy_to.calendar_events.count.should == 2
      cal_2 = @copy_to.calendar_events.find_by_migration_id(CC::CCHelper.create_key(cal))
      cal_2.title.should == cal.title
      cal_2.start_at.to_i.should == cal.start_at.to_i
      cal_2.end_at.to_i.should == cal.end_at.to_i
      cal_2.all_day.should == true
      cal_2.all_day_date.should == cal.all_day_date
      cal_2.description = body_with_link % @copy_to.id

      cal2_2 = @copy_to.calendar_events.find_by_migration_id(CC::CCHelper.create_key(cal2))
      cal2_2.title.should == cal2.title
      cal2_2.start_at.to_i.should == cal2.start_at.to_i
      cal2_2.end_at.to_i.should == cal2.end_at.to_i
      cal2_2.description.should == ''
    end

    it "should leave text answers as text" do
      pending unless Qti.qti_enabled?
      @bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      data = {
                          :question_type => "multiple_choice_question",
                          :question_name => "test fun",
                          :name => "test fun",
                          :points_possible => 10,
                          :question_text => "<strong>html for fun</strong>",
                          :answers =>
                                  [{:migration_id => "QUE_1016_A1", :text => "<br />", :weight => 100, :id => 8080},
                                   {:migration_id => "QUE_1017_A2", :text => "<pre>", :weight => 0, :id => 2279}]}.with_indifferent_access
      aq_from1 = @bank.assessment_questions.create!(:question_data => data)

      run_course_copy

      aq = @copy_to.assessment_questions.find_by_migration_id(mig_id(aq_from1))

      aq.question_data[:answers][0][:text].should == data[:answers][0][:text]
      aq.question_data[:answers][1][:text].should == data[:answers][1][:text]
      aq.question_data[:answers][0][:html].should be_nil
      aq.question_data[:answers][1][:html].should be_nil
      aq.question_data[:question_text].should == data[:question_text]
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

        @copy_to.assignments.count.should == (Qti.qti_enabled? ? 3 : 2)
        @copy_to.quizzes.count.should == 1 if Qti.qti_enabled?
        @copy_to.discussion_topics.count.should == 1
        @cm.content_export.error_messages.should == []
      end

      it "should copy for teacher if flag not set" do
        @setting.settings = {}
        @setting.save!

        run_course_copy

        @copy_to.assignments.count.should == (Qti.qti_enabled? ? 3 : 2)
        @copy_to.quizzes.count.should == 1 if Qti.qti_enabled?
        @copy_to.discussion_topics.count.should == 1
        @cm.content_export.error_messages.should == []
      end

      it "should not copy for teacher" do
        run_course_copy

        @copy_to.assignments.count.should == 0
        @copy_to.quizzes.count.should == 0
        @copy_to.discussion_topics.count.should == 0
        @cm.content_export.error_messages.should == [
                ["The assignment \"lock locky\" could not be copied because it is locked.", nil],
                ["The topic \"topic\" could not be copied because it is locked.", nil],
                ["The quiz \"quiz\" could not be copied because it is locked.", nil]]
      end

      it "should not mark assignment as copied if not set to be frozen" do
        @asmnt.freeze_on_copy = false
        @asmnt.copied = false
        @asmnt.save!

        run_course_copy

        asmnt_2 = @copy_to.assignments.find_by_migration_id(mig_id(@asmnt))
        asmnt_2.freeze_on_copy.should be_nil
        asmnt_2.copied.should be_nil
      end

    end

    context "external tools" do
      before :once do
        @tool_from = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :custom_fields => {'a' => '1', 'b' => '2'}, :url => "http://www.example.com")
        @tool_from.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
        @tool_from.save!
      end

      it "should copy external tools" do
        @copy_from.tab_configuration = [
          {"id" =>0 }, {"id" => "context_external_tool_#{@tool_from.id}"}, {"id" => 14}
        ]
        @copy_from.save!

        run_course_copy

        @copy_to.context_external_tools.count.should == 1
        tool_to = @copy_to.context_external_tools.first

        @copy_to.tab_configuration.should == [
            {"id" =>0 }, {"id" => "context_external_tool_#{tool_to.id}"}, {"id" => 14}
        ]

        tool_to.name.should == @tool_from.name
        tool_to.custom_fields.should == @tool_from.custom_fields
        tool_to.has_course_navigation.should == true
        tool_to.consumer_key.should == @tool_from.consumer_key
        tool_to.shared_secret.should == @tool_from.shared_secret
      end

      it "should not duplicate external tools used in modules" do
        mod1 = @copy_from.context_modules.create!(:name => "some module")
        tag = mod1.add_item({:type => 'context_external_tool',
                             :title => 'Example URL',
                             :url => "http://www.example.com",
                             :new_tab => true})
        tag.save

        run_course_copy

        @copy_to.context_external_tools.count.should == 1

        tool_to = @copy_to.context_external_tools.first
        tool_to.name.should == @tool_from.name
        tool_to.consumer_key.should == @tool_from.consumer_key
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

      it "should copy vendor extensions" do
        @tool_from.settings[:vendor_extensions] = [{:platform=>"my.lms.com", :custom_fields=>{"key"=>"value"}}]
        @tool_from.save!

        run_course_copy

        tool = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(@tool_from))
        tool.settings[:vendor_extensions].should == [{'platform'=>"my.lms.com", 'custom_fields'=>{"key"=>"value"}}]
      end

      it "should copy canvas extensions" do
        @tool_from.user_navigation = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :extra => 'extra', :custom_fields=>{"key"=>"value"}}
        @tool_from.course_navigation = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :default => 'disabled', :visibility => 'members', :extra => 'extra', :custom_fields=>{"key"=>"value"}}
        @tool_from.account_navigation = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :extra => 'extra', :custom_fields=>{"key"=>"value"}}
        @tool_from.resource_selection = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :selection_width => 100, :selection_height => 50, :extra => 'extra', :custom_fields=>{"key"=>"value"}}
        @tool_from.editor_button = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :selection_width => 100, :selection_height => 50, :icon_url => "http://www.example.com", :extra => 'extra', :custom_fields=>{"key"=>"value"}}
        @tool_from.save!

        run_course_copy

        tool = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(@tool_from))
        tool.course_navigation.should_not be_nil
        tool.course_navigation.should == @tool_from.course_navigation
        tool.editor_button.should_not be_nil
        tool.editor_button.should == @tool_from.editor_button
        tool.resource_selection.should_not be_nil
        tool.resource_selection.should == @tool_from.resource_selection
        tool.account_navigation.should_not be_nil
        tool.account_navigation.should == @tool_from.account_navigation
        tool.user_navigation.should_not be_nil
        tool.user_navigation.should == @tool_from.user_navigation
      end

      it "should keep reference to ContextExternalTool by id for courses" do
        mod1 = @copy_from.context_modules.create!(:name => "some module")
        tag = mod1.add_item :type => 'context_external_tool', :id => @tool_from.id,
                      :url => "https://www.example.com/launch"
        run_course_copy

        tool_copy = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(@tool_from))
        tag = @copy_to.context_modules.first.content_tags.first
        tag.content_type.should == 'ContextExternalTool'
        tag.content_id.should == tool_copy.id
      end

      it "should keep reference to ContextExternalTool by id for accounts" do
        account = @copy_from.root_account
        @tool_from.context = account
        @tool_from.save!
        mod1 = @copy_from.context_modules.create!(:name => "some module")
        mod1.add_item :type => 'context_external_tool', :id => @tool_from.id, :url => "https://www.example.com/launch"

        run_course_copy

        tag = @copy_to.context_modules.first.content_tags.first
        tag.content_type.should == 'ContextExternalTool'
        tag.content_id.should == @tool_from.id
      end

      it "should keep tab configuration for account-level external tools" do
        account = @copy_from.root_account
        @tool_from.context = account
        @tool_from.save!

        @copy_from.tab_configuration = [
            {"id" =>0 }, {"id" => "context_external_tool_#{@tool_from.id}"}, {"id" => 14}
        ]
        @copy_from.save!

        run_course_copy

        @copy_to.tab_configuration.should == [
            {"id" =>0 }, {"id" => "context_external_tool_#{@tool_from.id}"}, {"id" => 14}
        ]
      end
    end
  end

  context "#prepare_data" do
    it "should strip invalid utf8" do
      data = {
        'assessment_questions' => [{
          'question_name' => "hai\xfbabcd"
        }]
      }
      ContentMigration.new.prepare_data(data)[:assessment_questions][0][:question_name].should == "haiabcd"
    end
  end

  context "import_object?" do
    before :once do
      course
      @cm = ContentMigration.new(context: @course)
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

  it "should exclude user-hidden migration plugins" do
    ab = Canvas::Plugin.find(:academic_benchmark_importer)
    ContentMigration.migration_plugins(true).include?(ab).should be_false
  end

  context "zip file import" do
    def test_zip_import(context)
      zip_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/file.zip")
      cm = ContentMigration.new(:context => context, :user => @user,)
      cm.migration_type = 'zip_file_importer'
      cm.migration_settings[:folder_id] = Folder.root_folders(context).first.id
      cm.save!

      attachment = Attachment.new
      attachment.context = cm
      attachment.uploaded_data = File.open(zip_path, 'rb')
      attachment.filename = 'file.zip'
      attachment.save!

      cm.attachment = attachment
      cm.save!

      cm.queue_migration
      run_jobs
      context.reload.attachments.count.should == 1
    end

    it "should import into a course" do
      course_with_teacher
      test_zip_import(@course)
    end

    it "should import into a user" do
      user
      test_zip_import(@user)
    end

    it "should import into a group" do
      group_with_user
      test_zip_import(@group)
    end
  end

  it "should use url for migration file" do
    course_with_teacher
    cm = ContentMigration.new(:context => @course, :user => @user,)
    cm.migration_type = 'zip_file_importer'
    cm.migration_settings[:folder_id] = Folder.root_folders(@course).first.id
    # the mock below should prevent it from actually hitting the url
    cm.migration_settings[:file_url] = "http://localhost:3000/file.zip"
    cm.save!

    Attachment.any_instance.expects(:clone_url).with(cm.migration_settings[:file_url], false, true, :quota_context => cm.context)

    cm.queue_migration
    worker = Canvas::Migration::Worker::CCWorker.new
    worker.perform(cm)
  end

  context "account-level import" do
    it "should import question banks from qti migrations" do
      pending unless Qti.qti_enabled?

      account = Account.create!(:name => 'account')
      @user = user
      account.account_users.create!(user: @user)
      cm = ContentMigration.new(:context => account, :user => @user)
      cm.migration_type = 'qti_converter'
      cm.migration_settings['import_immediately'] = true
      qb_name = 'Import Unfiled Questions Into Me'
      cm.migration_settings['question_bank_name'] = qb_name
      cm.save!

      package_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/cc_default_qb_test.zip")
      attachment = Attachment.new
      attachment.context = cm
      attachment.uploaded_data = File.open(package_path, 'rb')
      attachment.filename = 'file.zip'
      attachment.save!

      cm.attachment = attachment
      cm.save!

      cm.queue_migration
      run_jobs

      cm.migration_issues.should be_empty

      account.assessment_question_banks.count.should == 1
      bank = account.assessment_question_banks.first
      bank.title.should == qb_name

      bank.assessment_questions.count.should == 1
    end

    it "should import questions from quizzes into question banks" do
      pending unless Qti.qti_enabled?

      account = Account.create!(:name => 'account')
      @user = user
      account.account_users.create!(user: @user)
      cm = ContentMigration.new(:context => account, :user => @user)
      cm.migration_type = 'qti_converter'
      cm.migration_settings['import_immediately'] = true
      cm.save!

      package_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/quiz_qti.zip")
      attachment = Attachment.new
      attachment.context = cm
      attachment.uploaded_data = File.open(package_path, 'rb')
      attachment.filename = 'file.zip'
      attachment.save!

      cm.attachment = attachment
      cm.save!

      cm.queue_migration
      run_jobs

      cm.migration_issues.should be_empty

      account.assessment_question_banks.count.should == 1
      bank = account.assessment_question_banks.first
      bank.title.should == "Unnamed Quiz"

      bank.assessment_questions.count.should == 1
    end
  end
end
