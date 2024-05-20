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

describe ContentMigration do
  context "course copy" do
    include_context "course copy"

    it "shows correct progress" do
      ce = @course.content_exports.build
      ce.export_type = ContentExport::COMMON_CARTRIDGE
      ce.content_migration = @cm
      @cm.content_export = ce
      ce.save!

      expect(@cm.progress).to be_nil
      @cm.workflow_state = "exporting"

      ce.progress = 10
      expect(@cm.progress).to eq 4
      ce.progress = 50
      expect(@cm.progress).to eq 20
      ce.progress = 75
      expect(@cm.progress).to eq 30
      ce.progress = 100
      expect(@cm.progress).to eq 40

      @cm.progress = 10
      expect(@cm.progress).to eq 46
      @cm.progress = 50
      expect(@cm.progress).to eq 70
      @cm.progress = 80
      expect(@cm.progress).to eq 88
      @cm.progress = 100
      expect(@cm.progress).to eq 100
    end

    it "sets started_at and finished_at" do
      time = 5.minutes.ago
      Timecop.freeze(time) do
        run_course_copy
      end
      @cm.reload
      expect(@cm.started_at.to_i).to eq time.to_i
      expect(@cm.finished_at.to_i).to eq time.to_i
    end

    it "records the job id" do
      allow(Delayed::Worker).to receive(:current_job).and_return(double("Delayed::Job", id: 123))
      run_course_copy
      expect(@cm.reload.migration_settings[:job_ids]).to eq([123])
    end

    it "migrates course home links in rich content on copy" do
      course_model

      page = @copy_from.wiki_pages.create!(title: "page 1", body: %(<p><a title="Home" href="/courses/#{@copy_from.id}?wrap=1">Home</a></p><p><a title="Home" href="/courses/#{@copy_from.id}">Home 2</a></p>))

      run_course_copy

      new_page = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(new_page).not_to be_nil
      expect(new_page.body).to match(%r{<p><a title="Home" href="/courses/#{@copy_to.id}/?\?wrap=1">Home</a></p><p><a title="Home" href="/courses/#{@copy_to.id}/?">Home 2</a></p>})
    end

    context "with precise_link_replacements FF ON" do
      before { Account.site_admin.enable_feature! :precise_link_replacements }

      it "leaves non-href/non-src 'links' untouched" do
        course_model
        @copy_from.wiki_pages.create!(
          title: "page 1",
          body: <<~HTML)
            /courses/#{@copy_from.id}/pages/1
            <a href="/courses/#{@copy_from.id}/pages/1">http://fake.dom/courses/#{@copy_from.id}/pages/1</a>
            <a href="/courses/#{@copy_from.id}/pages/1">/courses/#{@copy_from.id}/pages/1</a>
          HTML

        run_course_copy
        expected_resulting_body = <<~HTML
          /courses/#{@copy_from.id}/pages/1
          <a href="/courses/#{@copy_to.id}/pages/1">/courses/#{@copy_to.id}/pages/1</a>
          <a href="/courses/#{@copy_to.id}/pages/1">/courses/#{@copy_to.id}/pages/1</a>
        HTML
        dest_page = @copy_to.wiki_pages.where(migration_id: mig_id(@copy_from.wiki_pages.last)).first.body
        expect(dest_page.delete("\n")).to eq(expected_resulting_body.delete("\n"))
      end
    end

    it "migrates syllabus links on copy" do
      course_model

      topic = @copy_from.discussion_topics.create!(title: "some topic", message: "<p>some text</p>")
      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/discussion_topics/#{topic.id}'>link</a>"
      @copy_from.save!

      @cm.copy_options = {
        everything: false,
        all_syllabus_body: true,
        all_discussion_topics: true
      }
      @cm.save!
      run_course_copy

      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(new_topic).not_to be_nil
      expect(new_topic.message).to eq topic.message
      expect(@copy_to.syllabus_body).to match(%r{/courses/#{@copy_to.id}/discussion_topics/#{new_topic.id}})
    end

    it "copies course syllabus when the everything option is selected" do
      course_model

      @copy_from.syllabus_body = "What up"
      @copy_from.save!

      run_course_copy

      expect(@copy_to.syllabus_body).to match(/#{@copy_from.syllabus_body}/)
    end

    it "does not migrate a blank syllabus" do
      body = "woo"
      @copy_to.update_attribute(:syllabus_body, body)

      run_course_copy

      expect(@copy_to.syllabus_body).to eq body
    end

    it "does not migrate syllabus when not selected" do
      course_model
      @copy_from.syllabus_body = "<p>wassup</p>"

      @cm.copy_options = {
        course: { "all_syllabus_body" => false }
      }
      @cm.save!

      run_course_copy

      expect(@copy_to.syllabus_body).to be_nil
    end

    it "merges locked files and retain correct html links" do
      att = Attachment.create!(filename: "test.txt", display_name: "testing.txt", uploaded_data: StringIO.new("file"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att.update_attribute(:hidden, true)
      expect(att.reload).to be_hidden
      topic = @copy_from.discussion_topics.create!(title: "some topic", message: "<img src='/courses/#{@copy_from.id}/files/#{att.id}/preview'>")

      run_course_copy

      new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(new_att).not_to be_nil

      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(new_topic).not_to be_nil
      expect(new_topic.message).to match(Regexp.new("/courses/#{@copy_to.id}/files/#{new_att.id}/preview"))
    end

    it "preserves links to files in poorly named folders" do
      rf = Folder.root_folders(@copy_from).first
      folder = rf.sub_folders.create!(name: "course files", context: @copy_from)
      att = Attachment.create!(filename: "test.txt", display_name: "testing.txt", uploaded_data: StringIO.new("file"), folder:, context: @copy_from)
      topic = @copy_from.discussion_topics.create!(title: "some topic", message: "<img src='/courses/#{@copy_from.id}/files/#{att.id}/preview'>")

      run_course_copy

      new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(new_att).not_to be_nil

      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(new_topic).not_to be_nil

      expect(new_topic.message).to match(Regexp.new("/courses/#{@copy_to.id}/files/#{new_att.id}/preview"))
    end

    it "keeps date-locked files locked" do
      student = user_factory
      @copy_from.enroll_student(student)
      att = Attachment.create!(filename: "test.txt", display_name: "testing.txt", uploaded_data: StringIO.new("file"), folder: Folder.root_folders(@copy_from).first, context: @copy_from, lock_at: 1.month.ago, unlock_at: 1.month.from_now)
      expect(att.grants_right?(student, :download)).to be_falsey

      run_course_copy

      @copy_to.enroll_student(student)
      new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(new_att).to be_present

      expect(new_att.grants_right?(student, :download)).to be_falsey
    end

    it "translates links to module items in html content" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      asmnt1 = @copy_from.assignments.create!(title: "some assignment")
      tag = mod1.add_item({ id: asmnt1.id, type: "assignment", indent: 1 })
      body = %(<p>Link to module item: <a href="/courses/%s/modules/items/%s">some assignment</a></p>)
      page = @copy_from.wiki_pages.create!(title: "some page", body: body % [@copy_from.id, tag.id])

      run_course_copy

      mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      tag_to = mod1_to.content_tags.first
      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page_to.body).to eq body % [@copy_to.id, tag_to.id]
    end

    it "translates links to assignments with module item id" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      asmnt1 = @copy_from.assignments.create!(title: "some assignment")
      tag = mod1.add_item({ id: asmnt1.id, type: "assignment", indent: 1 })
      body = %(<p>Link to module item: <a href="/courses/%s/assignments/%s?module_item_id=%s">some assignment</a></p>)
      page = @copy_from.wiki_pages.create!(title: "some page", body: body % [@copy_from.id, asmnt1.id, tag.id])

      run_course_copy

      mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      asmnt_to = @copy_to.assignments.where(migration_id: mig_id(asmnt1)).first
      tag_to = mod1_to.content_tags.first
      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page_to.body).to eq body % [@copy_to.id, asmnt_to.id, tag_to.id]
    end

    it "translates links to modules in quiz content" do
      skip unless Qti.qti_enabled?

      mod1 = @copy_from.context_modules.create!(name: "some module")
      body = %(<p>Link to module: <a href="/courses/%s/modules/%s">some module</a></p>)
      quiz = @copy_from.quizzes.create!(title: "some page", description: body % [@copy_from.id, mod1.id])

      run_course_copy

      mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      expect(quiz_to.description).to eq body % [@copy_to.id, mod1_to.id]
    end

    it "does not interweave module order" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      mod2 = @copy_from.context_modules.create!(name: "some module 2")

      run_course_copy

      [mod1, mod2].each(&:destroy)
      mod3 = @copy_from.context_modules.create!(name: "some module 3")
      expect(mod3.position).to eq 1

      run_course_copy

      mod3_to = @copy_to.context_modules.where(migration_id: mig_id(mod3)).first
      expect(mod3_to.position).to eq 3 # put at end
    end

    it "shan't interweave module order when restoring deleting modules in the destination course neither" do
      ["A", "B"].map { |name| @copy_to.context_modules.create!(name:) }
      ["C", "D"].map { |name| @copy_from.context_modules.create!(name:) }
      run_course_copy
      expect(@copy_to.context_modules.ordered.pluck(:name)).to eq(%w[A B C D])

      @copy_to.context_modules.where(name: ["C", "D"]).map(&:destroy)
      run_course_copy
      expect(@copy_to.context_modules.ordered.pluck(:name)).to eq(%w[A B C D])
    end

    it "is able to copy links to files in folders with html entities and unicode in path" do
      root_folder = Folder.root_folders(@copy_from).first
      folder1 = root_folder.sub_folders.create!(context: @copy_from, name: "mol&eacute; ? i'm silly")
      att1 = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: folder1, context: @copy_from)
      img = Attachment.create!(filename: "img.png", uploaded_data: stub_png_data, folder: folder1, context: @copy_from)
      folder2 = root_folder.sub_folders.create!(context: @copy_from, name: "olé")
      att2 = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: folder2, context: @copy_from)

      body = "<a class='instructure_file_link' href='/courses/#{@copy_from.id}/files/#{att1.id}/download'>link</a>"
      body += "<a class='instructure_file_link' href='/courses/#{@copy_from.id}/files/#{att2.id}/download'>link</a>"
      body += "<img src='/courses/#{@copy_from.id}/files/#{img.id}/preview'>"
      dt = @copy_from.discussion_topics.create!(message: body, title: "discussion title")
      page = @copy_from.wiki_pages.create!(title: "some page", body:)

      run_course_copy

      att_to1 = @copy_to.attachments.where(migration_id: mig_id(att1)).first
      att_to2 = @copy_to.attachments.where(migration_id: mig_id(att2)).first
      img_to = @copy_to.attachments.where(migration_id: mig_id(img)).first

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page_to.body).to include "/courses/#{@copy_to.id}/files/#{att_to1.id}/download"
      expect(page_to.body).to include "/courses/#{@copy_to.id}/files/#{att_to2.id}/download"
      expect(page_to.body).to include "/courses/#{@copy_to.id}/files/#{img_to.id}/preview"

      dt_to = @copy_to.discussion_topics.where(migration_id: mig_id(dt)).first
      expect(dt_to.message).to include "/courses/#{@copy_to.id}/files/#{att_to1.id}/download"
      expect(dt_to.message).to include "/courses/#{@copy_to.id}/files/#{att_to2.id}/download"
      expect(dt_to.message).to include "/courses/#{@copy_to.id}/files/#{img_to.id}/preview"
    end

    it "selectively copies items" do
      dt1 = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
      dt2 = @copy_from.discussion_topics.create!(message: "hey", title: "discussion title 2")
      dt3 = @copy_from.announcements.create!(message: "howdy", title: "announcement title")
      cm = @copy_from.context_modules.create!(name: "some module")
      cm2 = @copy_from.context_modules.create!(name: "another module")
      att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
      att2 = Attachment.create!(filename: "second.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
      wiki = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
      wiki2 = @copy_from.wiki_pages.create!(title: "wiki2", body: "ohais")
      data = [{ points: 3, description: "Outcome row", id: 1, ratings: [{ points: 3, description: "Rockin'", criterion_id: 1, id: 2 }] }]
      rub1 = @copy_from.rubrics.build(title: "rub1")
      rub1.data = data
      rub1.save!
      rub1.associate_with(@copy_from, @copy_from)
      rub2 = @copy_from.rubrics.build(title: "rub2")
      rub2.data = data
      rub2.save!
      rub2.associate_with(@copy_from, @copy_from)
      ef1 = @copy_from.external_feeds.create! url: "https://feed1.example.org", verbosity: "full"
      ef2 = @copy_from.external_feeds.create! url: "https://feed2.example.org", verbosity: "full"
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
      lo.workflow_state = "active"
      lo.data = { rubric_criterion: { mastery_points: 2, ratings: [{ description: "e", points: 50 }, { description: "me", points: 2 }, { description: "Does Not Meet Expectations", points: 0.5 }], description: "First outcome", points_possible: 5 } }
      lo.save!

      log.add_outcome(lo)

      # only select one of each type
      @cm.copy_options = {
        discussion_topics: { mig_id(dt1) => "1" },
        announcements: { mig_id(dt3) => "1" },
        context_modules: { mig_id(cm) => "1", mig_id(cm2) => "0" },
        attachments: { mig_id(att) => "1", mig_id(att2) => "0" },
        wiki_pages: { mig_id(wiki) => "1", mig_id(wiki2) => "0" },
        rubrics: { mig_id(rub1) => "1", mig_id(rub2) => "0" },
        external_feeds: { mig_id(ef1) => "1", mig_id(ef2) => "0" }
      }
      @cm.save!

      run_course_copy

      expect(@copy_to.discussion_topics.where(migration_id: mig_id(dt1)).first).not_to be_nil
      expect(@copy_to.discussion_topics.where(migration_id: mig_id(dt2)).first).to be_nil
      expect(@copy_to.discussion_topics.where(migration_id: mig_id(dt3)).first).not_to be_nil

      expect(@copy_to.context_modules.where(migration_id: mig_id(cm)).first).not_to be_nil
      expect(@copy_to.context_modules.where(migration_id: mig_id(cm2)).first).to be_nil

      expect(@copy_to.attachments.where(migration_id: mig_id(att)).first).not_to be_nil
      expect(@copy_to.attachments.where(migration_id: mig_id(att2)).first).to be_nil

      expect(@copy_to.wiki_pages.where(migration_id: mig_id(wiki)).first).not_to be_nil
      expect(@copy_to.wiki_pages.where(migration_id: mig_id(wiki2)).first).to be_nil

      expect(@copy_to.rubrics.where(migration_id: mig_id(rub1)).first).not_to be_nil
      expect(@copy_to.rubrics.where(migration_id: mig_id(rub2)).first).to be_nil

      expect(@copy_to.created_learning_outcomes.where(migration_id: mig_id(lo)).first).to be_nil
      expect(@copy_to.learning_outcome_groups.where(migration_id: mig_id(log)).first).to be_nil

      expect(@copy_to.external_feeds.where(migration_id: mig_id(ef1)).first).not_to be_nil
      expect(@copy_to.external_feeds.where(migration_id: mig_id(ef2)).first).to be_nil
    end

    it "re-copies deleted items" do
      dt1 = @copy_from.discussion_topics.create!(message: "hi", title: "discussion title")
      cm = @copy_from.context_modules.create!(name: "some module")
      att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@copy_from), context: @copy_from)
      wiki = @copy_from.wiki_pages.create!(title: "wiki", body: "ohai")
      quiz = @copy_from.quizzes.create! if Qti.qti_enabled?
      ag = @copy_from.assignment_groups.create!(name: "empty group")
      asmnt = @copy_from.assignments.create!(title: "some assignment")
      cal = @copy_from.calendar_events.create!(title: "haha", description: "oi")
      tool = @copy_from.context_external_tools.create!(name: "new tool", consumer_key: "key", shared_secret: "secret", domain: "example.com", custom_fields: { "a" => "1", "b" => "2" })
      tool.workflow_state = "public"
      tool.save
      data = [{ points: 3, description: "Outcome row", id: 1, ratings: [{ points: 3, description: "Rockin'", criterion_id: 1, id: 2 }] }]
      rub1 = @copy_from.rubrics.build(title: "rub1")
      rub1.data = data
      rub1.save!
      rub1.associate_with(@copy_from, @copy_from)
      default = @copy_from.root_outcome_group
      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = "active"
      lo.data = { rubric_criterion: { mastery_points: 2, ratings: [{ description: "e", points: 50 }, { description: "me", points: 2 }, { description: "Does Not Meet Expectations", points: 0.5 }], description: "First outcome", points_possible: 5 } }
      lo.save!
      default.add_outcome(lo)
      gs = @copy_from.grading_standards.new
      gs.title = "Standard eh"
      gs.data = [["A", 0.93], ["A-", 0.89], ["B+", 0.85], ["B", 0.83], ["B!-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]]
      gs.save!

      run_course_copy

      @copy_to.discussion_topics.where(migration_id: mig_id(dt1)).first.destroy
      @copy_to.context_modules.where(migration_id: mig_id(cm)).first.destroy
      @copy_to.attachments.where(migration_id: mig_id(att)).first.destroy
      @copy_to.wiki_pages.where(migration_id: mig_id(wiki)).first.destroy
      @copy_to.rubrics.where(migration_id: mig_id(rub1)).first.destroy
      @copy_to.created_learning_outcomes.where(migration_id: mig_id(lo)).first.destroy
      @copy_to.quizzes.where(migration_id: mig_id(quiz)).first.destroy if Qti.qti_enabled?
      @copy_to.context_external_tools.where(migration_id: mig_id(tool)).first.destroy
      @copy_to.assignment_groups.where(migration_id: mig_id(ag)).first.destroy
      @copy_to.assignments.where(migration_id: mig_id(asmnt)).first.destroy
      @copy_to.grading_standards.where(migration_id: mig_id(gs)).first.destroy
      @copy_to.calendar_events.where(migration_id: mig_id(cal)).first.destroy

      @cm = ContentMigration.create!(
        context: @copy_to,
        user: @user,
        source_course: @copy_from,
        migration_type: "course_copy_importer",
        copy_options: { everything: "1" }
      )

      run_course_copy

      expect(@copy_to.discussion_topics.where(migration_id: mig_id(dt1)).first.workflow_state).to eq "active"
      expect(@copy_to.context_modules.where(migration_id: mig_id(cm)).first.workflow_state).to eq "active"
      expect(@copy_to.attachments.count).to eq 1
      expect(@copy_to.attachments.where(migration_id: mig_id(att)).first.file_state).to eq "available"
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

    it "copies course attributes" do
      Account.default.allow_self_enrollment!
      account_admin_user(user: @cm.user, account: @copy_to.account)
      # set all the possible values to non-default values
      @copy_from.start_at = 5.minutes.ago
      @copy_from.conclude_at = 1.month.from_now
      @copy_from.restrict_enrollments_to_course_dates = true
      @copy_from.is_public = false
      @copy_from.name = "haha copy from test &amp;"
      @copy_from.course_code = "something funny"
      @copy_from.allow_student_wiki_edits = true
      @copy_from.show_public_context_messages = false
      @copy_from.allow_student_forum_attachments = false
      @copy_from.default_wiki_editing_roles = "teachers"
      @copy_from.allow_student_organized_groups = false
      @copy_from.show_announcements_on_home_page = false
      @copy_from.home_page_announcement_limit = 3
      @copy_from.default_view = "modules"
      @copy_from.open_enrollment = true
      @copy_from.storage_quota = 444
      @copy_from.allow_wiki_comments = true
      @copy_from.turnitin_comments = "Don't plagiarize"
      @copy_from.self_enrollment = true
      @copy_from.license = "cc_by_nc_nd"
      @copy_from.locale = "es"
      @copy_from.tab_configuration = [{ "id" => 0 }, { "id" => 14 }, { "id" => 8 }, { "id" => 5 }, { "id" => 6 }, { "id" => 2 }, { "id" => 3, "hidden" => true }]
      @copy_from.hide_final_grades = true
      gs = make_grading_standard(@copy_from)
      @copy_from.grading_standard = gs
      @copy_from.grading_standard_enabled = true
      @copy_from.is_public = true
      @copy_from.public_syllabus = true
      @copy_from.public_syllabus_to_auth = true
      @copy_from.lock_all_announcements = true
      @copy_from.usage_rights_required = true
      @copy_from.allow_student_discussion_editing = false
      @copy_from.restrict_student_future_view = true
      @copy_from.restrict_student_past_view = true
      @copy_from.restrict_quantitative_data = true
      @copy_from.show_total_grade_as_points = true
      @copy_from.organize_epub_by_content_type = true
      @copy_from.enable_offline_web_export = true
      @copy_from.is_public_to_auth_users = true
      @copy_from.syllabus_course_summary = false
      @copy_from.homeroom_course = true
      @copy_from.course_color = "#123456"
      @copy_from.alt_name = "drama"
      @copy_from.time_zone = "Alaska"
      @copy_from.save!
      @copy_from.allow_student_discussion_reporting = true
      @copy_from.allow_student_anonymous_discussion_topics = true

      tool = external_tool_1_3_model(context: @copy_from)

      @copy_from.lti_resource_links.create!(
        context_external_tool: tool,
        custom: nil,
        lookup_uuid: "1b302c1e-c0a2-42dc-88b6-c029699a7c7a",
        url: "http://example.com/resource-link-url"
      )
      @copy_from.lti_resource_links.create!(
        context_external_tool: tool,
        custom: nil,
        lookup_uuid: "1b302c1e-c0a2-42dc-88b6-c029699a7c7b",
        url: nil
      )

      run_course_copy

      # compare settings
      expect(@copy_to.conclude_at).to be_nil
      expect(@copy_to.start_at).to be_nil
      expect(@copy_to.restrict_enrollments_to_course_dates).to be true
      expect(@copy_to.storage_quota).to eq 444
      expect(@copy_to.hide_final_grades).to be true
      expect(@copy_to.grading_standard_enabled).to be true
      gs_2 = @copy_to.grading_standards.where(migration_id: mig_id(gs)).first
      expect(gs_2.data).to eq gs.data
      expect(@copy_to.grading_standard).to eq gs_2
      expect(@copy_to.name).to eq "tocourse"
      expect(@copy_to.course_code).to eq "tocourse"
      expect(@copy_to.syllabus_course_summary).to be false
      expect(@copy_to.homeroom_course).to be true
      expect(@copy_to.course_color).to eq "#123456"
      expect(@copy_to.alt_name).to eq "drama"
      expect(@copy_to.time_zone.name).to eq "Alaska"
      # other attributes changed from defaults are compared in clonable_attributes below
      atts = Course.clonable_attributes
      atts -= Canvas::Migration::MigratorHelper::COURSE_NO_COPY_ATTS
      atts.each do |att|
        expect(@copy_to.send(att)).to eq(@copy_from.send(att)), "@copy_to.#{att}: expected #{@copy_from.send(att)}, got #{@copy_to.send(att)}"
      end
      expect(@copy_to.tab_configuration).to eq @copy_from.tab_configuration

      expect(@copy_to.lti_resource_links.size).to eq 2
      rla = @copy_to.lti_resource_links.find { |rl| rl.lookup_uuid == "1b302c1e-c0a2-42dc-88b6-c029699a7c7a" }
      expect(rla.url).to eq "http://example.com/resource-link-url"

      rlb = @copy_to.lti_resource_links.find { |rl| rl.lookup_uuid == "1b302c1e-c0a2-42dc-88b6-c029699a7c7b" }
      expect(rlb.url).to be_nil
      expect(@copy_to.allow_student_discussion_reporting).to be_truthy
      expect(@copy_to.allow_student_anonymous_discussion_topics).to be_truthy
    end

    context "with prevent_course_availability_editing_by_teachers on" do
      it "does not copy restrict_enrollments_to_course_dates for teachers" do
        @copy_from.root_account.settings[:prevent_course_availability_editing_by_teachers] = true
        @copy_from.root_account.save!

        @copy_to.restrict_enrollments_to_course_dates = false
        @copy_to.save!

        @copy_from.restrict_enrollments_to_course_dates = true
        @copy_from.save!

        run_course_copy

        expect(@copy_to.restrict_enrollments_to_course_dates).to be false
      end

      it "does copy restrict_enrollments_to_course_dates for admins" do
        account_admin_user(user: @cm.user, account: @copy_to.account)

        @copy_from.root_account.settings[:prevent_course_availability_editing_by_teachers] = true
        @copy_from.root_account.save!

        @copy_to.restrict_enrollments_to_course_dates = false
        @copy_to.save!

        @copy_from.restrict_enrollments_to_course_dates = true
        @copy_from.save!

        run_course_copy

        expect(@copy_to.restrict_enrollments_to_course_dates).to be true
      end
    end

    it "copies the overridable course visibility setting" do
      visibility_type = "superfunvisibility"
      allow_any_instantiation_of(@copy_from.root_account).to receive(:available_course_visibility_override_options)
        .and_return({ visibility_type => { setting: "Some label" } })
      @copy_from.apply_visibility_configuration(visibility_type)
      @copy_from.save!
      run_course_copy
      expect(@copy_to.reload.overridden_course_visibility).to eq visibility_type

      @copy_from.apply_visibility_configuration("public")
      @copy_from.save!
      run_course_copy
      expect(@copy_to.reload.overridden_course_visibility).to be_blank
    end

    it "does not overwrite visibility when skipped" do
      @copy_from.is_public = true
      @copy_from.is_public_to_auth_users = true
      @copy_from.save!

      @cm.copy_options = { everything: true }
      @cm.migration_settings = { importer_skips: ["visibility_settings"] }
      @cm.save!

      run_course_copy

      expect(@copy_to.is_public).to be false
      expect(@copy_to.is_public_to_auth_users).to be false
    end

    it "copies dashboard images" do
      att = attachment_model(context: @copy_from, uploaded_data: stub_png_data, filename: "homework.png")
      @copy_from.image_id = att.id
      @copy_from.save!

      run_course_copy

      @copy_to.reload
      new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(@copy_to.image_id.to_i).to eq new_att.id

      example_url = "example.com"
      @copy_from.image_url = example_url
      @copy_from.image_id = nil
      @copy_from.save!

      run_course_copy

      @copy_to.reload
      expect(@copy_to.image_url).to eq example_url
    end

    it "copies banner images" do
      att = attachment_model(context: @copy_from, uploaded_data: stub_png_data, filename: "homework.png")
      @copy_from.banner_image_id = att.id
      @copy_from.save!

      run_course_copy

      @copy_to.reload
      new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(@copy_to.banner_image_id.to_i).to eq new_att.id

      example_url = "example.com"
      @copy_from.banner_image_url = example_url
      @copy_from.banner_image_id = nil
      @copy_from.save!

      run_course_copy

      @copy_to.reload
      expect(@copy_to.banner_image_url).to eq example_url
    end

    it "converts domains in imported urls if specified in account settings" do
      account = @copy_to.root_account
      account.settings[:default_migration_settings] = { domain_substitution_map: { "http://derp.derp" => "https://derp.derp" } }
      account.save!

      mod = @copy_from.context_modules.create!(name: "some module")
      tag1 = mod.add_item({ title: "Example 1", type: "external_url", url: "http://derp.derp/something" })
      tool = @copy_from.context_external_tools.create!(name: "b", url: "http://derp.derp/somethingelse", consumer_key: "12345", shared_secret: "secret")
      tag2 = mod.add_item type: "context_external_tool", id: tool.id, url: "#{tool.url}?queryyyyy=something"

      @copy_from.syllabus_body = "<p><a href=\"http://derp.derp/stuff\">this is a link to an insecure domain that could cause problems</a></p>"

      run_course_copy

      tool_to = @copy_to.context_external_tools.where(migration_id: mig_id(tool)).first
      expect(tool_to.url).to eq tool.url.sub("http://derp.derp", "https://derp.derp")
      tag1_to = @copy_to.context_module_tags.where(migration_id: mig_id(tag1)).first
      expect(tag1_to.url).to eq tag1.url.sub("http://derp.derp", "https://derp.derp")
      tag2_to = @copy_to.context_module_tags.where(migration_id: mig_id(tag2)).first
      expect(tag2_to.url).to eq tag2.url.sub("http://derp.derp", "https://derp.derp")

      expect(@copy_to.syllabus_body).to eq @copy_from.syllabus_body.sub("http://derp.derp", "https://derp.derp")
    end

    it "copies module settings" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      tag = mod1.add_item({ title: "Example 1", type: "external_url", url: "http://derp.derp/something" })
      mod1.completion_requirements = { tag.id => { type: "must_view" } }
      mod1.require_sequential_progress = true
      mod1.requirement_count = 1
      mod1.save!

      mod2 = @copy_from.context_modules.create!(name: "some module 2")
      mod2.prerequisites = "module_#{mod1.id}"
      mod2.save!

      run_course_copy

      mod1_to = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      tag_to = mod1_to.content_tags.first
      expect(mod1_to.completion_requirements).to eq [{ id: tag_to.id, type: "must_view" }]
      expect(mod1_to.require_sequential_progress).to be_truthy
      expect(mod1_to.requirement_count).to eq 1
      mod2_to = @copy_to.context_modules.where(migration_id: mig_id(mod2)).first

      expect(mod2_to.prerequisites.count).to eq 1
      expect(mod2_to.prerequisites.first[:id]).to eq mod1_to.id

      mod1.update_attribute(:require_sequential_progress, false)
      mod1.update_attribute(:requirement_count, nil)
      run_course_copy
      expect(mod1_to.reload.require_sequential_progress).to be_falsey
      expect(mod1_to.requirement_count).to be_nil
    end

    it "syncs module items (even when removed) on re-copy" do
      mod = @copy_from.context_modules.create!(name: "some module")
      page = @copy_from.wiki_pages.create(title: "some page")
      tag1 = mod.add_item({ id: page.id, type: "wiki_page" })
      asmnt = @copy_from.assignments.create!(title: "some assignment")
      tag2 = mod.add_item({ id: asmnt.id, type: "assignment", indent: 1 })

      run_course_copy

      mod_to = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      tag1_to = mod_to.content_tags.where(migration_id: mig_id(tag1)).first
      tag2_to = mod_to.content_tags.where(migration_id: mig_id(tag2)).first

      tag2.destroy

      run_course_copy

      tag1_to.reload
      tag2_to.reload

      expect(tag1_to).to_not be_deleted
      expect(tag2_to).to be_deleted
    end

    it "copies weird object links" do
      att = Attachment.create!(filename: "test.txt",
                               uploaded_data: StringIO.new("pixels and frames and stuff"),
                               folder: Folder.root_folders(@copy_from).first,
                               context: @copy_from)
      @copy_from.syllabus_body = "<object><param value=\"/courses/#{@copy_from.id}/files/#{att.id}/download\"></object>"
      @copy_from.save!

      run_course_copy

      att2 = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(@copy_to.reload.syllabus_body).to include "/courses/#{@copy_to.id}/files/#{att2.id}/download"
    end

    it "copies weird longdesc things" do
      page = @copy_from.wiki_pages.create!(title: "page")
      @copy_from.syllabus_body = "<img longdesc=\"/courses/#{@copy_from.id}/pages/#{page.url}/\">"
      @copy_from.save!

      run_course_copy

      page2 = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(@copy_to.reload.syllabus_body).to include "/courses/#{@copy_to.id}/pages/#{page2.url}"
    end

    context "kaltura media objects" do
      before do
        Account.site_admin.enable_feature!(:media_links_use_attachment_id)
        kaltura_double = double("kaltura")
        allow(kaltura_double).to receive(:startSession)
        # rubocop:disable RSpec/ReceiveMessages
        allow(kaltura_double).to receive(:flavorAssetGetByEntryId).and_return([
                                                                                {
                                                                                  isOriginal: 1,
                                                                                  containerFormat: "mp4",
                                                                                  fileExt: "mp4",
                                                                                  id: "one",
                                                                                  size: 15,
                                                                                }
                                                                              ])
        allow(kaltura_double).to receive(:flavorAssetGetOriginalAsset).and_return(kaltura_double.flavorAssetGetByEntryId.first)
        # rubocop:enable RSpec/ReceiveMessages
        allow(CanvasKaltura::ClientV3).to receive_messages(config: true, new: kaltura_double)
      end

      it "updates media comment links to be media attachment links" do
        attachment_model(display_name: "test.mp4", context: @copy_from, media_entry_id: "0_l4l5n0wt")
        attachment_model(display_name: "test2.mp4", context: @copy_from, media_entry_id: "0_12345678")
        attachment_model(display_name: "test3.mp4", context: @copy_from, media_entry_id: "0_bq09qam2")
        @copy_from.syllabus_body = <<~HTML.strip
          <p>
            Hello, students.<br>
            With associated media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
            Without associated media object: <a id="media_comment_0_12345678" class="instructure_inline_media_comment video_comment" href="/media_objects/0_12345678">this is a media comment</a>
            another type: <a id="media_comment_0_bq09qam2" class="instructure_inline_media_comment video_comment" href="/courses/#{@copy_from.id}/file_contents/course%20files/media_objects/0_bq09qam2">this is a media comment</a>
          </p>
        HTML

        run_course_copy

        file1 = @copy_to.attachments.find_by(media_entry_id: "0_l4l5n0wt")
        file2 = @copy_to.attachments.find_by(media_entry_id: "0_12345678")
        file3 = @copy_to.attachments.find_by(media_entry_id: "0_bq09qam2")

        translated_body = <<~HTML.strip
          <p>
            Hello, students.<br>
            With associated media object: <iframe id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file1.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>
            Without associated media object: <iframe id="media_comment_0_12345678" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file2.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_12345678"></iframe>
            another type: <iframe id="media_comment_0_bq09qam2" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file3.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_bq09qam2"></iframe>
          </p>
        HTML
        expect(@copy_to.syllabus_body).to eq translated_body
      end

      it "updates media comment and media object links without crashing when there isn't an attachment associated with the media object" do
        (0..1).each do |index|
          mo = @copy_from.media_objects.create!(media_id: "m-index#{index}")
          mo.attachment.update(workflow_state: "deleted", file_state: "deleted", media_entry_id: nil)
          mo.update(attachment_id: nil)
        end

        @copy_from.syllabus_body = <<~HTML.strip
          with media comment: <a id="media_comment_m-index0" class="instructure_inline_media_comment video_comment" href="/media_objects/m-index0" data-media_comment_type="video" data-alt="">this is a media comment</a>
          with media objects iframe url: <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" data-media-id="m-index1" allowfullscreen="allowfullscreen" allow="fullscreen" src="/media_objects_iframe/m-index1?type=video&amp;embedded=true"></iframe>
        HTML

        run_course_copy

        file0, file1 = @copy_to.attachments.order(:id)

        translated_body = <<~HTML.strip
          with media comment: <iframe id="media_comment_m-index0" class="instructure_inline_media_comment video_comment" data-media_comment_type="video" data-alt="" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file0.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-index0"></iframe>
          with media objects iframe url: <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" data-media-id="m-index1" allowfullscreen="allowfullscreen" allow="fullscreen" src="/media_attachments_iframe/#{file1.id}?embedded=true&amp;type=video"></iframe>
        HTML
        expect(@copy_to.syllabus_body).to eq translated_body
      end

      it "updates media attachment links" do
        media_id = "0_deadbeef"
        @copy_from.media_objects.create!(media_id:)
        att = @copy_from.attachments.find_by(media_entry_id: media_id)
        @copy_from.syllabus_body = %(<p><iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" data-media-id="#{media_id}" allowfullscreen="allowfullscreen" allow="fullscreen" src="/media_attachments_iframe/#{att.id}?embedded=true&amp;type=video"></iframe></p>)
        run_course_copy
        new_att = @copy_to.attachments.find_by(migration_id: mig_id(att))
        expect(@copy_to.syllabus_body).to eq @copy_from.syllabus_body.sub("/media_attachments_iframe/#{att.id}", "/media_attachments_iframe/#{new_att.id}")
      end

      it "does not update media attachment links from a different course" do
        media_id = "0_deadbeef"
        course_with_teacher(course_name: "from course", active_all: true)
        @course.media_objects.create!(media_id:)
        att = @course.attachments.find_by(media_entry_id: media_id)
        @copy_from.syllabus_body = %(<p><iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" data-media-id="#{media_id}" allowfullscreen="allowfullscreen" allow="fullscreen" src="/media_attachments_iframe/#{att.id}?type=video&"></iframe></p>)
        run_course_copy
        expect(@copy_to.attachments.count).to eq 0
        expect(@copy_to.media_objects.count).to eq 0
        expect(@copy_to.syllabus_body.gsub("&amp;", "&")).to eq @copy_from.syllabus_body
      end

      it "does not update media attachment links from user media" do
        media_id = "0_deadbeef"
        att = attachment_model(display_name: "lolcats.mp4", context: @user, media_entry_id: media_id)
        @copy_from.syllabus_body = %(<p><iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" data-media-id="#{media_id}" allowfullscreen="allowfullscreen" allow="fullscreen" src="/media_attachments_iframe/#{att.id}?type=video&amp;embedded=true"></iframe></p>)
        run_course_copy
        expect(@copy_to.attachments.count).to eq 0
        expect(@copy_to.media_objects.count).to eq 0
        expect(@copy_to.syllabus_body).to eq @copy_from.syllabus_body
      end

      it "copies media attachments linked in HTML for an object copied selectively" do
        media_id = "0_deadbeef"
        media_id2 = "0_livecrab"
        att = attachment_model(display_name: "lolcats.mp4", context: @copy_from, media_entry_id: media_id)
        att2 = attachment_model(display_name: "yodawg.mp4", context: @copy_from, media_entry_id: media_id2)
        wiki = @copy_from.wiki_pages.create!(title: "lolcat", body: %(<p><iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" data-media-id="#{media_id}" allowfullscreen="allowfullscreen" allow="fullscreen" src="/media_attachments_iframe/#{att.id}?type=video"></iframe></p>))
        wiki2 = @copy_from.wiki_pages.create!(title: "yodawg", body: %(<p><iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" data-media-id="#{media_id2}" allowfullscreen="allowfullscreen" allow="fullscreen" src="/media_attachments_iframe/#{att2.id}?type=video"></iframe></p>))
        @cm = ContentMigration.create!(
          context: @copy_to,
          user: @user,
          source_course: @copy_from,
          migration_type: "course_copy_importer",
          copy_options: { wiki_pages: { mig_id(wiki) => "1", mig_id(wiki2) => "0" } }
        )

        run_course_copy
        expect(@copy_to.attachments.where(media_entry_id: media_id)).to be_exist
        expect(@copy_to.attachments.where(media_entry_id: media_id2)).not_to be_exist
      end

      it "re-uses kaltura media objects" do
        media_id = "0_deadbeef"
        @copy_from.media_objects.create!(media_id:)
        att = Attachment.create!(filename: "video.mp4", uploaded_data: StringIO.new("pixels and frames and stuff"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
        att.media_entry_id = media_id
        att.content_type = "video/mp4"
        att.save!

        expect do
          run_course_copy

          expect(@copy_to.attachments.where(migration_id: mig_id(att)).first.media_entry_id).to eq media_id
        end.to change { Delayed::Job.jobs_count(:tag, "MediaObject.add_media_files") }.by(0)
      end

      it "copies media tracks without creating new media objects" do
        media_id = "0_deadbeef"
        media_object = @copy_from.media_objects.create!(media_id:)
        copy_from_track = media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs")

        expect do
          run_course_copy

          copy_to_attach = @copy_to.attachments.where(migration_id: mig_id(media_object.attachment)).first
          expect(copy_to_attach.media_entry_id).to eq media_id
          copy_to_track = copy_to_attach.media_tracks.first
          expect(copy_to_track.slice(:media_object_id, :locale).values).to eq [media_object.id, "en"]
          expect(copy_to_track.id).not_to eq(copy_from_track.id)
        end.to change { MediaTrack.count }.by(1)
      end

      it "copies media tracks from non-default media object attachments" do
        media_id = "0_deadbeef"
        media_object = course_factory.media_objects.create!(media_id:)
        att = Attachment.create!(filename: "video.mp4", uploaded_data: StringIO.new("pixels and frames and stuff"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
        att.media_entry_id = media_id
        att.content_type = "video/mp4"
        att.save!
        media_track = att.media_tracks.create!(content: "en subs", media_object_id: media_object, kind: "subtitles", locale: "en", user_id: att.user_id)

        expect do
          run_course_copy

          copy_to_media_track = @copy_to.attachments.where(migration_id: mig_id(att)).first.media_tracks.first
          expect(copy_to_media_track.id).not_to eq media_track.id
          expect(copy_to_media_track.content).to eq "en subs"
          expect(copy_to_media_track.media_object_id).to eq media_track.media_object_id
          expect(MediaObject.where(media_id:).count).to eq 1
        end.to change { MediaTrack.count }.by(1)
      end

      it "doesn't crash when another type of file is linked in HTML" do
        img_att = attachment_model(context: @copy_from, uploaded_data: stub_png_data, filename: "homework.png")
        media_id = "0_deadbeef"
        media_object = course_factory.media_objects.create!(media_id:)
        att = Attachment.create!(filename: "video.mp4", uploaded_data: StringIO.new("pixels and frames and stuff"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
        att.media_entry_id = media_id
        att.content_type = "video/mp4"
        att.save!
        att.media_tracks.create!(content: "en subs", media_object_id: media_object, kind: "subtitles", locale: "en", user_id: att.user_id)

        @copy_from.announcements.create!(title: "links", message: <<~HTML)
          <p><img src="/courses/#{@copy_from.id}/files/#{img_att.id}/preview" alt="assoc_1.png" /></p>
          <p><iframe data-media-type="video" src="/media_attachments_iframe/#{att}?type=video" data-media-id="#{media_id}"></iframe></p>
        HTML
        run_course_copy

        expect(@copy_to.attachments.find_by(filename: "video.mp4").media_tracks.length).to eq 1
      end
    end

    it "imports calendar events" do
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
      cal3 = @copy_from.calendar_events.create!(title: "deleted event")
      cal3.destroy

      series_uuid = "8233ffdc-9067-4eaf-a726-19c3718dab29"
      rrule = "FREQ=DAILY;INTERVAL=1;UNTIL=20241001T055959Z"
      cal4 = @copy_from.calendar_events.create!(series_uuid:, rrule:, series_head: true)
      cal5 = @copy_from.calendar_events.create!(series_uuid:, rrule:)

      run_course_copy

      expect(@copy_to.calendar_events.count).to eq 4
      cal_2 = @copy_to.calendar_events.where(migration_id: mig_id(cal)).first
      expect(cal_2.title).to eq cal.title
      expect(cal_2.start_at.to_i).to eq cal.start_at.to_i
      expect(cal_2.end_at.to_i).to eq cal.end_at.to_i
      expect(cal_2.all_day).to be true
      expect(cal_2.all_day_date).to eq cal.all_day_date
      cal_2.description = body_with_link % @copy_to.id

      cal2_2 = @copy_to.calendar_events.where(migration_id: mig_id(cal2)).first
      expect(cal2_2.title).to eq cal2.title
      expect(cal2_2.start_at.to_i).to eq cal2.start_at.to_i
      expect(cal2_2.end_at.to_i).to eq cal2.end_at.to_i
      expect(cal2_2.description).to eq ""

      cal_4 = @copy_to.calendar_events.where(migration_id: mig_id(cal4)).first
      expect(cal_4.series_head).to be_truthy

      cal_5 = @copy_to.calendar_events.where(migration_id: mig_id(cal5)).first
      expect(cal_5.rrule).to eq rrule
      expect(cal_5.series_head).to be_nil
      expect(cal_5.series_uuid).to be_truthy
      expect(cal_5.series_uuid).to eq cal_4.series_uuid
    end

    it "does not leave link placeholders on catastrophic failure" do
      att = Attachment.create!(filename: "test.txt",
                               display_name: "testing.txt",
                               uploaded_data: StringIO.new("file"),
                               folder: Folder.root_folders(@copy_from).first,
                               context: @copy_from)
      topic = @copy_from.discussion_topics.create!(title: "some topic", message: "<img src='/courses/#{@copy_from.id}/files/#{att.id}/preview'>")

      allow(Importers::WikiPageImporter).to receive(:process_migration).and_raise(ArgumentError)

      expect do
        run_course_copy
      end.to raise_error(ArgumentError)

      new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(new_att).not_to be_nil

      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(new_topic).not_to be_nil
      expect(new_topic.message).to match(Regexp.new("/courses/#{@copy_to.id}/files/#{new_att.id}/preview"))
    end

    it "is able to copy links to folders" do
      folder = Folder.root_folders(@copy_from).first.sub_folders.create!(context: @copy_from, name: "folder_1")
      Attachment.create!(filename: "test.txt",
                         display_name: "testing.txt",
                         uploaded_data: StringIO.new("file"),
                         folder:,
                         context: @copy_from)

      topic = @copy_from.discussion_topics.create!(title: "some topic",
                                                   message: "<a href='/courses/#{@copy_from.id}/files/folder/#{folder.name}'>an ill-advised link</a>")

      run_course_copy

      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(new_topic.message).to match(Regexp.new("/courses/#{@copy_to.id}/files/folder/#{folder.name}"))
    end

    it "does not desync imported module item published status with existing content" do
      asmnt = @copy_from.assignments.create!(title: "some assignment")
      page = @copy_from.wiki_pages.create!(title: "some page")

      run_course_copy

      new_asmnt = @copy_to.assignments.where(migration_id: mig_id(asmnt)).first
      new_asmnt.unpublish!

      new_page = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      new_page.unpublish!

      mod1 = @copy_from.context_modules.create!(name: "some module")
      tag = mod1.add_item({ id: asmnt.id, type: "assignment", indent: 1 })
      tag2 = mod1.add_item({ id: page.id, type: "wiki_page", indent: 1 })

      @cm.copy_options = { all_context_modules: "1" }
      @cm.save!
      run_course_copy

      new_tag = @copy_to.context_module_tags.where(migration_id: mig_id(tag)).first
      expect(new_tag).to be_unpublished

      new_tag2 = @copy_to.context_module_tags.where(migration_id: mig_id(tag2)).first
      expect(new_tag2).to be_unpublished
    end

    it "restores deleted module items on re-import" do
      page = @copy_from.wiki_pages.create!(title: "some page")

      mod = @copy_from.context_modules.create!(name: "some module")
      mod.add_item({ title: "Example 1", type: "external_url", url: "http://derp.derp/something" })
      mod.add_item({ id: page.id, type: "wiki_page", indent: 1 })

      run_course_copy

      new_mod = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      new_mod.destroy!

      run_course_copy

      new_mod.reload
      expect(new_mod).to_not be_deleted
      new_mod.content_tags.each do |new_tag|
        expect(new_tag).to_not be_deleted
      end
    end

    it "copies over published tableless module items" do
      mod = @copy_from.context_modules.create!(name: "some module")
      tag1 = mod.add_item({ title: "Example 1", type: "external_url", url: "http://derp.derp/something" })
      tag1.publish!
      tag2 = mod.add_item({ title: "Example 2", type: "external_url", url: "http://derp.derp/something2" })

      run_course_copy

      new_tag1 = @copy_to.context_module_tags.where(migration_id: mig_id(tag1)).first
      new_tag2 = @copy_to.context_module_tags.where(migration_id: mig_id(tag2)).first
      expect(new_tag1).to be_published
      expect(new_tag2).to be_unpublished
    end

    it "copies over link_settings of external tool items" do
      link_settings = { selection_width: 456, selection_height: 789 }
      tool = @copy_from.context_external_tools.create!(name: "b", url: "http://derp.derp/somethingelse", consumer_key: "12345", shared_secret: "secret")
      mod = @copy_from.context_modules.create!(name: "some module")
      tag = mod.add_item({ id: tool.id, type: "context_external_tool", url: tool.url, link_settings: })

      run_course_copy

      new_tag = @copy_to.context_module_tags.where(migration_id: mig_id(tag)).first
      expect(new_tag.link_settings).to eq link_settings.stringify_keys
    end

    it "preserves publish state of external tool items" do
      tool = @copy_from.context_external_tools.create!(name: "b", url: "http://derp.derp/somethingelse", consumer_key: "12345", shared_secret: "secret")
      mod = @copy_from.context_modules.create!(name: "some module")
      tag1 = mod.add_item type: "context_external_tool", id: tool.id, url: "#{tool.url}?queryyyyy=something"
      tag1.publish!
      tag2 = mod.add_item type: "context_external_tool", id: tool.id, url: "#{tool.url}?queryyyyy=something"

      run_course_copy

      new_tag1 = @copy_to.context_module_tags.where(migration_id: mig_id(tag1)).first
      new_tag2 = @copy_to.context_module_tags.where(migration_id: mig_id(tag2)).first
      expect(new_tag1).to be_published
      expect(new_tag2).to be_unpublished
    end

    it "does not try to translate links to similarishly looking urls" do
      body = %(<p>link to external thing <a href="https://someotherexampledomain.com/users/what">sad</a></p>
        <p>another link to external thing <a href="https://someotherexampledomain2.com/files">so sad</a></p>)
      page = @copy_from.wiki_pages.create!(title: "some page", body:)

      run_course_copy

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page_to.body).to eq body
    end

    it "still translates links to /course/X/files" do
      body = %(<p>link to course files <a href="/courses/%s/files">files</a></p>)
      page = @copy_from.wiki_pages.create!(title: "some page", body: body % @copy_from.id.to_s)
      run_course_copy

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page_to.body).to eq(body % @copy_to.id.to_s)
    end

    context "with late policy" do
      it "copies if no selection is made" do
        @copy_from.create_late_policy!(missing_submission_deduction_enabled: true, late_submission_deduction: 15.0, late_submission_interval: "day")
        run_course_copy

        new_late_policy = @copy_to.late_policy
        expect(new_late_policy.missing_submission_deduction_enabled).to be_truthy
      end

      # This is for faulty direct shares that were exported with late policy in their cartridges
      # when they shouldn't have, or for commons course packages where settings shouldn't be imported
      it "does not copy if settings are skipped" do
        @copy_from.create_late_policy!(missing_submission_deduction_enabled: true, late_submission_deduction: 15.0, late_submission_interval: "day")
        @copy_to.create_late_policy!(missing_submission_deduction_enabled: true, late_submission_deduction: 10.0, late_submission_interval: "day")

        @cm.copy_options = { everything: true }
        @cm.migration_settings = { importer_skips: ["all_course_settings"] }
        @cm.save!

        run_course_copy

        expect(@copy_to.reload.late_policy.late_submission_deduction).to eq 10.0
      end
    end
  end
end
