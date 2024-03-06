# frozen_string_literal: true

#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require_relative "../api_spec_helper"
require_relative "../../lti2_spec_helper"

require "nokogiri"

describe ContentExportsApiController, type: :request do
  include_context "lti2_spec_helper"

  let_once(:t_teacher) do
    user_factory(active_all: true)
  end

  let_once(:t_course) do
    course_with_teacher(user: t_teacher, active_all: true)
    @course.wiki_pages.create! title: "something to export"
    @course
  end

  let_once(:t_student) do
    student_in_course(course: t_course, active_all: true).user
  end

  def past_export(context = t_course, user = t_teacher, type = "common_cartridge")
    export = context.content_exports.create
    export.export_type = type
    export.workflow_state = "exported"
    export.user = user
    att = export.attachments.create! filename: "blah", uploaded_data: StringIO.new("blah")
    export.attachment_id = att.id
    export.save
    progress = Progress.new(context: export, completion: 100, tag: "course_export")
    progress.workflow_state = "completed"
    progress.save!
    export
  end

  def pending_export
    export = t_course.content_exports.create
    export.export_type = "qti"
    export.save
    Progress.create!(context: export, tag: "course_export")
    export
  end

  def course_copy_export
    export = t_course.content_exports.create
    export.export_type = "course_copy"
    export.save!
    export
  end

  describe "index" do
    it "checks permissions" do
      random_user = user_factory active_all: true
      api_call_as_user(random_user,
                       :get,
                       "/api/v1/courses/#{t_course.id}/content_exports",
                       { controller: "content_exports_api", action: "index", format: "json", course_id: t_course.to_param },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "returns the correct data" do
      @my_zip_export = past_export(t_course, t_teacher, "zip")
      @other_zip_export = past_export(t_course, t_student, "zip")
      @past = past_export
      @pending = pending_export
      @cc = course_copy_export
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/courses/#{t_course.id}/content_exports",
                              { controller: "content_exports_api", action: "index", format: "json", course_id: t_course.to_param })

      expect(json.size).to be 3
      expect(json[0]["id"]).to eql @pending.id
      expect(json[0]["workflow_state"]).to eql "created"
      expect(json[0]["export_type"]).to eql "qti"
      expect(json[0]["course_id"]).to eql t_course.id
      expect(json[0]["created_at"]).to eql @pending.created_at.as_json
      expect(json[0]["progress_url"]).to include "/progress/#{@pending.job_progress.id}"

      expect(json[1]["id"]).to eql @past.id
      expect(json[1]["workflow_state"]).to eql "exported"
      expect(json[1]["export_type"]).to eql "common_cartridge"
      expect(json[1]["course_id"]).to eql t_course.id
      expect(json[1]["created_at"]).to eql @past.created_at.as_json
      expect(json[1]["user_id"]).to eql t_teacher.id
      expect(json[1]["progress_url"]).to include "/progress/#{@past.job_progress.id}"
      expect(json[1]["attachment"]["url"]).to include "/files/#{@past.attachment.id}/download?download_frd=1&verifier=#{@past.attachment.uuid}"

      expect(json[2]["id"]).to eql @my_zip_export.id
      expect(json[2]["workflow_state"]).to eql "exported"
      expect(json[2]["export_type"]).to eql "zip"
      expect(json[2]["course_id"]).to eql t_course.id
      expect(json[2]["created_at"]).to eql @my_zip_export.created_at.as_json
      expect(json[2]["user_id"]).to eql t_teacher.id
      expect(json[2]["progress_url"]).to include "/progress/#{@my_zip_export.job_progress.id}"
      expect(json[2]["attachment"]["url"]).to include "/files/#{@my_zip_export.attachment.id}/download?download_frd=1&verifier=#{@my_zip_export.attachment.uuid}"
    end

    it "paginates" do
      exports = (1..5).map { pending_export }
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/courses/#{t_course.id}/content_exports?per_page=3",
                              { controller: "content_exports_api", action: "index", format: "json", course_id: t_course.to_param, per_page: "3" })
      expect(json.size).to be 3
      json += api_call_as_user(t_teacher,
                               :get,
                               "/api/v1/courses/#{t_course.id}/content_exports?per_page=3&page=2",
                               { controller: "content_exports_api", action: "index", format: "json", course_id: t_course.to_param, per_page: "3", page: "2" })
      expect(json.size).to be 5
      expect(json.pluck("id")).to eql exports.map(&:id).sort.reverse
    end

    it "does not return attachments for expired exports" do
      @past = past_export
      ContentExport.where(id: @past.id).update_all(created_at: 35.days.ago)

      json = api_call_as_user(
        t_teacher,
        :get,
        "/api/v1/courses/#{t_course.id}/content_exports",
        {
          controller: "content_exports_api",
          action: "index",
          format: "json",
          course_id: t_course.to_param
        }
      )

      expect(json[0]["attachment"]).to be_nil
    end
  end

  describe "update" do
    let(:user) { site_admin_user }

    it "does not find exports other than common cartridges" do
      @cc = course_copy_export
      api_call_as_user(user,
                       :put,
                       "/api/v1/courses/#{t_course.id}/content_exports/#{@cc.id}",
                       { controller: "content_exports_api", action: "update", format: "json", course_id: t_course.to_param, id: @cc.to_param },
                       {},
                       {},
                       { expected_status: 404 })
    end

    it "requires an content_export parameter" do
      @past = past_export
      api_call_as_user(user,
                       :put,
                       "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
                       { controller: "content_exports_api", action: "update", format: "json", course_id: t_course.to_param, id: @past.to_param },
                       { new_quizzes_export_url: "https://some.url", new_quizzes_export_state: "completed" },
                       {},
                       { expected_status: 400 })
    end

    it "returns the correct data" do
      @past = past_export
      json = api_call_as_user(user,
                              :put,
                              "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
                              { controller: "content_exports_api", action: "update", format: "json", course_id: t_course.to_param, id: @past.to_param },
                              { content_export: { new_quizzes_export_url: "https://some.url", new_quizzes_export_state: "completed" } })

      expect(json["id"]).to eql @past.id
      expect(json["export_type"]).to eql "common_cartridge"
      expect(json["course_id"]).to eql t_course.id
      expect(json["new_quizzes_export_url"]).to eql "https://some.url"
      expect(json["new_quizzes_export_state"]).to eql "completed"
    end

    it "returns status 401 if the request is not from a site admin user" do
      @past = past_export
      api_call_as_user(t_teacher,
                       :put,
                       "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
                       { controller: "content_exports_api", action: "update", format: "json", course_id: t_course.to_param, id: @past.to_param },
                       { new_quizzes_export_url: "https://some.url", new_quizzes_export_state: "completed" },
                       {},
                       { expected_status: 401 })
    end

    context "when the new_quizzes_export_state param is set to 'failed'" do
      it "fails the export" do
        @past = past_export
        json = api_call_as_user(user,
                                :put,
                                "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
                                { controller: "content_exports_api", action: "update", format: "json", course_id: t_course.to_param, id: @past.to_param },
                                { content_export: { new_quizzes_export_url: "", new_quizzes_export_state: "failed" } })
        expect(json["id"]).to eql @past.id
        expect(json["export_type"]).to eql "common_cartridge"
        expect(json["course_id"]).to eql t_course.id
        expect(json["new_quizzes_export_state"]).to eql "failed"
        expect(json["workflow_state"]).to eql "failed"
        expect(json["new_quizzes_export_url"]).to eql ""
      end
    end

    context "when the new_quizzes_export succeeds" do
      it "exports the export" do
        @past = past_export
        json = api_call_as_user(user,
                                :put,
                                "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
                                { controller: "content_exports_api", action: "update", format: "json", course_id: t_course.to_param, id: @past.to_param },
                                { content_export: { new_quizzes_export_url: "https://some.url", new_quizzes_export_state: "completed" } })
        expect(json["id"]).to eql @past.id
        expect(json["export_type"]).to eql "common_cartridge"
        expect(json["course_id"]).to eql t_course.id
        expect(json["new_quizzes_export_state"]).to eql "completed"
        expect(json["workflow_state"]).to eql "exported"
        expect(json["new_quizzes_export_url"]).to eql "https://some.url"
      end
    end
  end

  describe "show" do
    it "checks permissions" do
      @past = past_export
      api_call_as_user(t_student,
                       :get,
                       "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
                       { controller: "content_exports_api", action: "show", format: "json", course_id: t_course.to_param, id: @past.to_param },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "returns the correct data" do
      @past = past_export
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
                              { controller: "content_exports_api", action: "show", format: "json", course_id: t_course.to_param, id: @past.to_param })
      expect(json["id"]).to eql @past.id
      expect(json["workflow_state"]).to eql "exported"
      expect(json["export_type"]).to eql "common_cartridge"
      expect(json["course_id"]).to eql t_course.id
      expect(json["created_at"]).to eql @past.created_at.as_json
      expect(json["user_id"]).to eql t_teacher.id
      expect(json["attachment"]["url"]).to include "/files/#{@past.attachment.id}/download?download_frd=1&verifier=#{@past.attachment.uuid}"
    end

    it "does not find course copy exports" do
      @cc = course_copy_export
      api_call_as_user(t_teacher,
                       :get,
                       "/api/v1/courses/#{t_course.id}/content_exports/#{@cc.id}",
                       { controller: "content_exports_api", action: "show", format: "json", course_id: t_course.to_param, id: @cc.to_param },
                       {},
                       {},
                       { expected_status: 404 })
    end

    it "does not read other users' zip exports" do
      @zip_export = past_export(t_course, t_student, "zip")
      api_call_as_user(t_teacher,
                       :get,
                       "/api/v1/courses/#{t_course.id}/content_exports/#{@zip_export.id}",
                       { controller: "content_exports_api", action: "show", format: "json", course_id: t_course.to_param, id: @zip_export.to_param },
                       {},
                       {},
                       { expected_status: 401 })
    end
  end

  describe "create" do
    it "checks permissions" do
      api_call_as_user(t_student,
                       :post,
                       "/api/v1/courses/#{t_course.id}/content_exports?export_type=qti",
                       { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "qti" },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "requires an export_type parameter" do
      api_call_as_user(t_teacher,
                       :post,
                       "/api/v1/courses/#{t_course.id}/content_exports",
                       { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param },
                       {},
                       {},
                       { expected_status: 400 })
    end

    it "requires a sensible export_type parameter" do
      api_call_as_user(t_teacher,
                       :post,
                       "/api/v1/courses/#{t_course.id}/content_exports?export_type=frog",
                       { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "frog" },
                       {},
                       {},
                       { expected_status: 400 })
    end

    it "sets skip notifications flag" do
      json = api_call_as_user(t_teacher,
                              :post,
                              "/api/v1/courses/#{t_course.id}/content_exports",
                              { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge", skip_notifications: true })
      export = t_course.content_exports.where(id: json["id"]).first
      expect(export.send_notification?).to be_falsey
    end

    it "creates a qti export" do
      json = api_call_as_user(t_teacher,
                              :post,
                              "/api/v1/courses/#{t_course.id}/content_exports?export_type=qti",
                              { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "qti" })
      export = t_course.content_exports.where(id: json["id"]).first
      expect(export).not_to be_nil
      expect(export.workflow_state).to eql "created"
      expect(export.export_type).to eql "qti"
      expect(export.user_id).to eql t_teacher.id
      expect(export.settings["selected_content"]["all_quizzes"]).to be_truthy
      expect(export.job_progress).to be_queued
    end

    it "creates a course export and update progress" do
      json = api_call_as_user(t_teacher,
                              :post,
                              "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                              { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" })
      export = t_course.content_exports.where(id: json["id"]).first
      expect(export).not_to be_nil
      expect(export.workflow_state).to eql "created"
      expect(export.export_type).to eql "common_cartridge"
      expect(export.user_id).to eql t_teacher.id
      expect(export.settings["selected_content"]["everything"]).to be_truthy
      expect(export.job_progress).to be_queued

      run_jobs

      export.reload
      expect(export.workflow_state).to eql "exported"
      expect(export.job_progress).to be_completed
      expect(export.attachment).not_to be_nil
    end

    it "creates a 1.3 common cartridge if specified" do
      t_course.assignments.create! name: "teh assignment", description: "<b>what</b>", points_possible: 11, submission_types: "online_text_entry"
      json = api_call_as_user(t_teacher,
                              :post,
                              "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge&version=1.3",
                              { controller: "content_exports_api",
                                action: "create",
                                format: "json",
                                course_id: t_course.to_param,
                                export_type: "common_cartridge",
                                version: "1.3" })
      export = t_course.content_exports.find(json["id"])
      run_jobs
      f = export.reload.attachment.open
      Zip::File.open(f.path) do |zf|
        doc = Nokogiri::XML(zf.read("imsmanifest.xml"))
        expect(doc.at_css("metadata schemaversion").text).to eq "1.3.0"
      end
    end

    context "selective exports" do
      let_once :att_to_copy do
        Attachment.create!(context: t_course,
                           filename: "hi.txt",
                           uploaded_data: StringIO.new("stuff"),
                           folder: Folder.unfiled_folder(t_course))
      end
      let_once :att_to_not_copy do
        Attachment.create!(context: t_course,
                           filename: "derp.txt",
                           uploaded_data: StringIO.new("more stuff"),
                           folder: Folder.unfiled_folder(t_course))
      end
      let_once :page_to_copy do
        page_to_copy = t_course.wiki_pages.create!(title: "other page")
        page_to_copy.body = "<p><a href=\"/courses/#{t_course.id}/files/#{att_to_copy.id}/preview\">hey look a link</a></p>"
        page_to_copy.save!
        page_to_copy
      end
      let_once(:page_to_not_copy) { t_course.wiki_pages.create!(title: "another page") }
      let_once(:mod) do
        # both the wiki page and the referenced attachment should be exported implicitly through the module
        mod = t_course.context_modules.create!(name: "who cares")
        mod.add_item(id: page_to_copy.id, type: "wiki_page")
        mod
      end
      let_once(:quiz_to_copy) do
        t_course.quizzes.create! title: "thaumolinguistics"
      end
      let_once(:announcement) do
        t_course.announcements.create! title: "hear ye!", message: "wat"
      end

      it "creates a selective course export with old migration id format" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { context_modules: { mod.asset_string => "1" } } })
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export).not_to be_nil
        expect(export.workflow_state).to eql "created"
        expect(export.export_type).to eql "common_cartridge"
        expect(export.user_id).to eql t_teacher.id
        expect(export.settings["selected_content"]["context_modules"]).to eq({ export.create_key(mod) => "1" })
        expect(export.job_progress).to be_queued

        run_jobs

        export.reload
        expect(export.workflow_state).to eql "exported"
        expect(export.job_progress).to be_completed
        expect(export.attachment).not_to be_nil

        course_factory
        cm = @course.content_migrations.new
        cm.attachment = export.attachment
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings[:import_immediately] = true
        cm.save!
        cm.queue_migration

        run_jobs

        expect(@course.context_modules.where(migration_id: export.create_key(mod))).to be_exists
        copied_page = @course.wiki_pages.where(migration_id: export.create_key(page_to_copy)).first
        expect(copied_page).not_to be_nil
        expect(@course.wiki_pages.where(migration_id: export.create_key(page_to_not_copy))).not_to be_exists

        copied_att = @course.attachments.where(filename: att_to_copy.filename).first
        expect(copied_att).not_to be_nil
        expect(copied_page.body).to eq "<p><a href=\"/courses/#{@course.id}/files/#{copied_att.id}/preview\">hey look a link</a></p>"
        expect(@course.attachments.where(filename: att_to_not_copy.filename)).not_to be_exists
      end

      it "creates a selective course export with arrays of ids" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { context_modules: [mod.id] } })
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export).not_to be_nil
        expect(export.workflow_state).to eql "created"
        expect(export.export_type).to eql "common_cartridge"
        expect(export.user_id).to eql t_teacher.id
        expect(export.settings["selected_content"]["context_modules"]).to eq({ export.create_key(mod) => "1" })
        expect(export.job_progress).to be_queued

        run_jobs

        export.reload
        expect(export.workflow_state).to eql "exported"
        expect(export.job_progress).to be_completed
        expect(export.attachment).not_to be_nil

        course_factory
        cm = @course.content_migrations.new
        cm.attachment = export.attachment
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings[:import_immediately] = true
        cm.save!
        cm.queue_migration

        run_jobs

        expect(@course.context_modules.where(migration_id: export.create_key(mod))).to be_exists
        copied_page = @course.wiki_pages.where(migration_id: export.create_key(page_to_copy)).first
        expect(copied_page).not_to be_nil
        expect(@course.wiki_pages.where(migration_id: export.create_key(page_to_not_copy))).not_to be_exists

        copied_att = @course.attachments.where(filename: att_to_copy.filename).first
        expect(copied_att).not_to be_nil
        expect(copied_page.body).to eq "<p><a href=\"/courses/#{@course.id}/files/#{copied_att.id}/preview\">hey look a link</a></p>"
        expect(@course.attachments.where(filename: att_to_not_copy.filename)).not_to be_exists
      end

      context "selection with sharding" do
        specs_require_sharding

        it "properly selects content with global ids when asset_strings are used" do
          json = api_call_as_user(t_teacher,
                                  :post,
                                  "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                  { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                  { select: { context_modules: { mod.asset_string => "1" } } })
          export = t_course.content_exports.where(id: json["id"]).first
          expect(export).not_to be_nil
          expect(export.workflow_state).to eql "created"
          expect(export.export_type).to eql "common_cartridge"
          expect(export.user_id).to eql t_teacher.id
          expect(export.settings["selected_content"]["context_modules"]).to eq({ export.create_key(mod) => "1" })
          expect(export.job_progress).to be_queued

          run_jobs

          export.reload
          expect(export.workflow_state).to eql "exported"
          expect(export.job_progress).to be_completed
          expect(export.attachment).not_to be_nil

          course_factory
          cm = @course.content_migrations.new
          cm.attachment = export.attachment
          cm.migration_type = "canvas_cartridge_importer"
          cm.migration_settings[:import_immediately] = true
          cm.save!
          cm.queue_migration

          run_jobs

          expect(@course.context_modules.where(migration_id: export.create_key(mod))).to be_exists
          copied_page = @course.wiki_pages.where(migration_id: export.create_key(page_to_copy)).first
          expect(copied_page).not_to be_nil
          expect(@course.wiki_pages.where(migration_id: export.create_key(page_to_not_copy))).not_to be_exists

          copied_att = @course.attachments.where(filename: att_to_copy.filename).first
          expect(copied_att).not_to be_nil
          expect(copied_page.body).to eq "<p><a href=\"/courses/#{@course.id}/files/#{copied_att.id}/preview\">hey look a link</a></p>"
          expect(@course.attachments.where(filename: att_to_not_copy.filename)).not_to be_exists
        end

        it "properly selects content with global ids when arrays of ids are used" do
          json = api_call_as_user(t_teacher,
                                  :post,
                                  "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                  { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                  { select: { context_modules: [mod.id] } })
          export = t_course.content_exports.where(id: json["id"]).first
          expect(export).not_to be_nil
          expect(export.workflow_state).to eql "created"
          expect(export.export_type).to eql "common_cartridge"
          expect(export.user_id).to eql t_teacher.id
          expect(export.settings["selected_content"]["context_modules"]).to eq({ export.create_key(mod) => "1" })
          expect(export.job_progress).to be_queued

          run_jobs

          export.reload
          expect(export.workflow_state).to eql "exported"
          expect(export.job_progress).to be_completed
          expect(export.attachment).not_to be_nil

          course_factory
          cm = @course.content_migrations.new
          cm.attachment = export.attachment
          cm.migration_type = "canvas_cartridge_importer"
          cm.migration_settings[:import_immediately] = true
          cm.save!
          cm.queue_migration

          run_jobs

          expect(@course.context_modules.where(migration_id: export.create_key(mod))).to be_exists
          copied_page = @course.wiki_pages.where(migration_id: export.create_key(page_to_copy)).first
          expect(copied_page).not_to be_nil
          expect(@course.wiki_pages.where(migration_id: export.create_key(page_to_not_copy))).not_to be_exists

          copied_att = @course.attachments.where(filename: att_to_copy.filename).first
          expect(copied_att).not_to be_nil
          expect(copied_page.body).to eq "<p><a href=\"/courses/#{@course.id}/files/#{copied_att.id}/preview\">hey look a link</a></p>"
          expect(@course.attachments.where(filename: att_to_not_copy.filename)).not_to be_exists
        end
      end

      it "selects quizzes correctly" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { quizzes: [quiz_to_copy.id] } })
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export.settings["selected_content"]["quizzes"]).to eq({ export.create_key(quiz_to_copy) => "1" })
        expect(export.export_object?(quiz_to_copy)).to be_truthy
      end

      it "selects announcements correctly" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { announcements: [announcement.id] } })
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export.settings["selected_content"]["announcements"]).to eq({ export.create_key(announcement) => "1" })
        expect(export.export_object?(announcement)).to be_truthy
      end

      it "selects announcements even when specifically called as a discussion topic" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { discussion_topics: [announcement.id] } })

        export = t_course.content_exports.where(id: json["id"]).first
        expect(export.settings["selected_content"]["discussion_topics"]).to eq({ export.create_key(announcement) => "1" })
        expect(export.export_object?(announcement)).to be_truthy

        run_jobs

        export.reload
        course_factory
        cm = @course.content_migrations.new
        cm.attachment = export.attachment
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings[:import_immediately] = true
        cm.save!
        cm.queue_migration

        run_jobs

        copied_ann = @course.announcements.where(migration_id: export.create_key(announcement)).first
        expect(copied_ann).to be_present
      end

      it "does not select announcements when selecting all discussion topics" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { all_discussion_topics: "1" } })

        export = t_course.content_exports.where(id: json["id"]).first
        expect(export.export_object?(announcement)).to be_falsey
      end

      it "selects using shortened collection names" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { modules: [mod.id] } })
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export.export_object?(mod)).to be_truthy

        tag = mod.content_tags.first
        json2 = api_call_as_user(t_teacher,
                                 :post,
                                 "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                 { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                 { select: { module_items: [tag.id] } })
        export2 = t_course.content_exports.where(id: json2["id"]).first
        expect(export2.export_object?(tag)).to be_truthy

        json3 = api_call_as_user(t_teacher,
                                 :post,
                                 "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                 { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                 { select: { pages: [page_to_copy.id] } })
        export3 = t_course.content_exports.where(id: json3["id"]).first
        expect(export3.export_object?(page_to_copy)).to be_truthy

        file = attachment_model(context: t_course)
        json4 = api_call_as_user(t_teacher,
                                 :post,
                                 "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                 { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                 { select: { files: [file.id] } })
        export4 = t_course.content_exports.where(id: json4["id"]).first
        expect(export4.export_object?(file)).to be_truthy
      end

      it "exports by module item id" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { module_items: [mod.content_tags.first.id] } })
        export = t_course.content_exports.where(id: json["id"]).first
        run_jobs

        export.reload
        course_factory
        cm = @course.content_migrations.new
        cm.attachment = export.attachment
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings[:import_immediately] = true
        cm.save!
        cm.queue_migration

        run_jobs

        copied_page = @course.wiki_pages.where(migration_id: export.create_key(page_to_copy)).first
        expect(copied_page).not_to be_nil
        expect(@course.wiki_pages.where(migration_id: export.create_key(page_to_not_copy))).not_to be_exists
      end

      it "exports rubrics attached to discussions" do
        @course = t_course
        outcome_with_rubric
        assignment_model(course: @course, submission_types: "discussion_topic", title: "graded discussion")
        @rubric.associate_with(@assignment, @course, purpose: "grading")

        topic = @assignment.discussion_topic

        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                                { select: { discussion_topics: [topic.id] } })
        export = t_course.content_exports.where(id: json["id"]).first
        run_jobs

        export.reload
        course_factory
        cm = @course.content_migrations.new
        cm.attachment = export.attachment
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings[:import_immediately] = true
        cm.save!
        cm.queue_migration

        run_jobs

        to_assign = @course.assignments.first
        to_outcomes = to_assign.rubric.learning_outcome_alignments.map { |a| a.learning_outcome.migration_id }
        expect(to_outcomes).to eql [export.create_key(@outcome)]
      end
    end

    context "when :newquizzes_on_quiz_page FF is enabled" do
      let(:course) { t_course }
      let(:quiz) do
        Quizzes::Quiz.create(
          title: "test quiz",
          description: "default quiz description",
          context: course
        )
      end

      before do
        course.root_account.settings[:provision] = { "lti" => "lti url" }
        course.root_account.save!
        course.enable_feature!(:quizzes_next)
        course.root_account.enable_feature!(:newquizzes_on_quiz_page)
      end

      it "output migrated quiz in json" do
        json = api_call_as_user(
          t_teacher,
          :post,
          "/api/v1/courses/#{t_course.id}/content_exports?export_type=quizzes2&include[]=migrated_quiz",
          {
            controller: "content_exports_api",
            action: "create",
            format: "json",
            course_id: t_course.to_param,
            export_type: "quizzes2",
            include: ["migrated_quiz"],
            quiz_id: quiz.id
          }
        )
        expect(json["migrated_quiz"].count).to be 1
        expect(json["migrated_quiz"][0]["quiz_type"]).to eq "quizzes.next"
      end

      it "output migrated assignment in json" do
        json = api_call_as_user(
          t_teacher,
          :post,
          "/api/v1/courses/#{t_course.id}/content_exports?export_type=quizzes2&include[]=migrated_assignment",
          {
            controller: "content_exports_api",
            action: "create",
            format: "json",
            course_id: t_course.to_param,
            export_type: "quizzes2",
            include: ["migrated_assignment"],
            quiz_id: quiz.id
          }
        )
        expect(json["migrated_assignment"].count).to be 1
        expect(json["migrated_assignment"][0]["new_positions"]).not_to be_nil
      end
    end
  end

  describe "#content_list" do
    it "returns a list of exportable content for a course directly" do
      @dt1 = @course.discussion_topics.create!(message: "hi", title: "discussion title")
      @cm = @course.context_modules.create!(name: "some module")
      @att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@course), context: @course)
      @wiki = @course.wiki_pages.create!(title: "wiki", body: "ohai")
      @course.course_paces.create!

      @quiz = @course.quizzes.create!(title: "quizz")
      @quiz.did_edit
      @quiz.offer!
      expect(@quiz.assignment).not_to be_nil

      list_url = "/api/v1/courses/#{@course.id}/content_list"
      params = { controller: "content_exports_api", format: "json", course_id: @course.id.to_param, action: "content_list" }
      json = api_call_as_user(t_teacher, :get, list_url, params)
      expect(json.sort_by { |h| h["type"] }).to eq [
        { "type" => "assignments", "property" => "select[all_assignments]", "title" => "Assignments", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=assignments" },
        { "type" => "attachments", "property" => "select[all_attachments]", "title" => "Files", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=attachments" },
        { "type" => "context_modules", "property" => "select[all_context_modules]", "title" => "Modules", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=context_modules" },
        { "type" => "course_paces", "property" => "select[all_course_paces]", "title" => "Course Pace" },
        { "type" => "course_settings", "property" => "select[all_course_settings]", "title" => "Course Settings" },
        { "type" => "discussion_topics", "property" => "select[all_discussion_topics]", "title" => "Discussion Topics", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=discussion_topics" },
        { "type" => "quizzes", "property" => "select[all_quizzes]", "title" => "Quizzes", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=quizzes" },
        { "type" => "syllabus_body", "property" => "select[all_syllabus_body]", "title" => "Syllabus Body" },
        { "type" => "wiki_pages", "property" => "select[all_wiki_pages]", "title" => "Pages", "count" => 2, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=wiki_pages" }
      ]

      json = api_call_as_user(t_teacher, :get, list_url + "?type=context_modules", params.merge({ type: "context_modules" }))
      expect(json.length).to eq 1
      expect(json.first["type"]).to eq "context_modules"
      expect(json.first["title"]).to eq @cm.name
      expect(json.first["id"]).to eq @cm.asset_string

      json = api_call_as_user(t_teacher, :get, list_url + "?type=quizzes", params.merge({ type: "quizzes" }))
      expect(json.first["type"]).to eq "quizzes"
      expect(json.first["title"]).to eq @quiz.title
      expect(json.first["id"]).to eq @quiz.asset_string
      expect(json.first["linked_resource"]["id"]).to eq @quiz.assignment.asset_string
    end
  end

  describe "quizzes2 exports" do
    before do
      t_course.enable_feature!(:quizzes_next)
    end

    context "quiz_id param" do
      it "requires a quiz_id param" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=quizzes2",
                                {
                                  controller: "content_exports_api",
                                  action: "create",
                                  format: "json",
                                  course_id: t_course.to_param,
                                  export_type: "quizzes2"
                                })
        expect(json["message"]).to eq "quiz_id required and must be a valid ID"
        expect(response).to have_http_status :bad_request
      end

      it "verifies quiz_id param is a number" do
        ce_url = "/api/v1/courses/#{t_course.id}/content_exports"
        params = {
          controller: "content_exports_api",
          format: "json",
          action: "create",
          course_id: t_course.to_param,
          export_type: "quizzes2",
          quiz_id: "lulz"
        }
        json = api_call_as_user(t_teacher, :post, ce_url, params)
        expect(json["message"]).to eq "quiz_id required and must be a valid ID"
        expect(response).to have_http_status :bad_request
      end
    end

    context "with invalid quiz" do
      it "verifies quiz exists in course" do
        ce_url = "/api/v1/courses/#{t_course.id}/content_exports"
        params = {
          controller: "content_exports_api",
          format: "json",
          action: "create",
          course_id: t_course.to_param,
          export_type: "quizzes2",
          quiz_id: "123"
        }
        json = api_call_as_user(t_teacher, :post, ce_url, params)
        expect(json["message"]).to eq "Quiz could not be found"
        expect(response).to have_http_status :bad_request
      end
    end

    context "with valid quiz" do
      before do
        @quiz = t_course.quizzes.create!(title: "valid_quiz")
      end

      it "creates a quizzes2 export" do
        ce_url = "/api/v1/courses/#{t_course.id}/content_exports"
        params = {
          controller: "content_exports_api",
          format: "json",
          action: "create",
          course_id: t_course.to_param,
          export_type: "quizzes2",
          quiz_id: @quiz.id
        }
        json = api_call_as_user(t_teacher, :post, ce_url, params)
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export).not_to be_nil
        expect(export.workflow_state).to eql "created"
        expect(export.export_type).to eql "quizzes2"
        expect(export.user_id).to eql t_teacher.id
        expect(export.settings["selected_content"]).to eql @quiz.id.to_s
        expect(export.job_progress).to be_queued
      end
    end
  end

  describe "zip exports" do
    context "course" do
      before do
        @root_folder = Folder.root_folders(t_course).first
        @file1 = attachment_model context: t_course, display_name: "file1.txt", folder: @root_folder, uploaded_data: stub_file_data("file1.txt", "file1", "text/plain")
        @sub_folder = t_course.folders.create! name: "teh_folder", parent_folder: @root_folder, locked: true
        @file2 = attachment_model context: t_course, display_name: "file2.txt", folder: @sub_folder, uploaded_data: stub_file_data("file2.txt", "file2", "text/plain")
        @empty_folder = t_course.folders.create! name: "empty_folder", parent_folder: @sub_folder
        @hiddenfile = attachment_model context: t_course, display_name: "hidden.txt", folder: @root_folder, uploaded_data: stub_file_data("hidden.txt", "hidden", "text/plain"), hidden: true
      end

      it "applies user time zone to export when present in user settings" do
        target_time_zone = "America/Denver"
        t_teacher.update!(time_zone: target_time_zone)
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "zip" })
        run_jobs
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export).to be_present
        expect(export.settings[:user_time_zone]).to eq(target_time_zone)
      end

      it "downloads course files" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "zip" })
        run_jobs
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export).to be_present
        expect(export.settings["errors"]).to be_blank
        expect(export.attachment).to be_present
        expect(export.attachment.display_name).to eql "course_files_export.zip"
        tf = export.attachment.open
        Zip::File.open(tf) do |zf|
          expect(zf.entries.select { |entry| entry.ftype == :file }.map(&:name)).to match_array %w[file1.txt hidden.txt teh_folder/file2.txt]
          expect(zf.entries.select { |entry| entry.ftype == :directory }.map(&:name)).to match_array %w[teh_folder/ teh_folder/empty_folder/]
        end
      end

      it "supports content selection" do
        file3 = attachment_model context: t_course, display_name: "file3.txt", folder: @root_folder, uploaded_data: stub_file_data("file3.txt", "file3", "text/plain")
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip&select[folders][]=#{@sub_folder.id}&select[attachments][]=#{file3.id}",
                                { controller: "content_exports_api",
                                  action: "create",
                                  format: "json",
                                  course_id: t_course.to_param,
                                  export_type: "zip",
                                  select: { "folders" => [@sub_folder.to_param], "attachments" => [file3.to_param] } })
        run_jobs
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export).to be_present
        expect(export.attachment).to be_present
        expect(export.attachment.display_name).to eql "course_files_export.zip"
        tf = export.attachment.open
        Zip::File.open(tf) do |zf|
          expect(zf.entries.map(&:name)).to match_array %w[teh_folder/ teh_folder/file2.txt teh_folder/empty_folder/ file3.txt]
        end
      end

      it "supports 'files' in addition to 'attachments'" do
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param },
                                { export_type: "zip", select: { "files" => [@file1.id] } })
        ce = ContentExport.find(json["id"])
        expect(ce.export_object?(@file1)).to be true
      end

      it "logs an error report and skip unreadable files" do
        @file1.update_attribute(:filename, "nonexistent_file")
        json = api_call_as_user(t_teacher,
                                :post,
                                "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip",
                                { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "zip" })
        run_jobs
        export = t_course.content_exports.where(id: json["id"]).first
        expect(export.settings["errors"].map(&:first)).to include("Skipped file file1.txt due to error")
        tf = export.attachment.open
        Zip::File.open(tf) do |zf|
          expect(zf.entries.select { |entry| entry.ftype == :file }.map(&:name)).to match_array %w[hidden.txt teh_folder/file2.txt]
        end
      end

      context "as a student" do
        it "excludes non-zip and/or other users' exports from #index" do
          my_zip_export = past_export(t_course, t_student, "zip")
          past_export(t_course, t_student, "common_cartridge")  # disallowed type
          past_export(t_course, t_teacher, "zip")               # other user
          json = api_call_as_user(t_student,
                                  :get,
                                  "/api/v1/courses/#{t_course.id}/content_exports",
                                  { controller: "content_exports_api", action: "index", format: "json", course_id: t_course.to_param })
          expect(json.pluck("id")).to match_array [my_zip_export.id]
        end

        it "denies access to admin exports in #show" do
          cc_export = past_export
          api_call_as_user(t_student,
                           :get,
                           "/api/v1/courses/#{t_course.id}/content_exports/#{cc_export.id}",
                           { controller: "content_exports_api", action: "show", format: "json", course_id: t_course.to_param, id: cc_export.to_param },
                           {},
                           {},
                           { expected_status: 401 })
        end

        it "excludes locked, deleted, and hidden folders and files from archive" do
          attachment_model context: t_course, display_name: "file3.txt", folder: @root_folder, uploaded_data: stub_file_data("file3.txt", "file3", "text/plain"), locked: true
          attachment_model context: t_course, display_name: "del_file0.txt", folder: @root_folder, uploaded_data: stub_file_data("del_file0.txt", "del_file0", "text/plain"), file_state: "deleted"
          del_folder = t_course.folders.create! name: "del_folder", parent_folder: @root_folder
          attachment_model context: t_course, display_name: "del_file1.txt", folder: del_folder, uploaded_data: stub_file_data("del_file1.txt", "del_file1", "text/plain")
          del_folder.destroy
          json = api_call_as_user(t_student,
                                  :post,
                                  "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip",
                                  { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "zip" })
          run_jobs
          export = t_course.content_exports.where(id: json["id"]).first
          expect(export).to be_present
          expect(export.attachment).to be_present
          tf = export.attachment.open
          Zip::File.open(tf) do |zf|
            expect(zf.entries.map(&:name)).to match_array %w[file1.txt]
          end
        end

        it "includes files in public-to-institution courses" do
          t_course.update_attribute(:is_public_to_auth_users, true)
          other_user = user_with_pseudonym(active_all: true)
          json = api_call_as_user(other_user,
                                  :post,
                                  "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip",
                                  { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "zip" })
          run_jobs
          export = t_course.content_exports.where(id: json["id"]).first
          expect(export).to be_present
          expect(export.attachment).to be_present
          tf = export.attachment.open
          Zip::File.open(tf) do |zf|
            expect(zf.entries.map(&:name)).to match_array %w[file1.txt]
          end
        end

        it "rejects common cartridge export due to permissions" do
          api_call_as_user(t_student,
                           :post,
                           "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                           { controller: "content_exports_api", action: "create", format: "json", course_id: t_course.to_param, export_type: "common_cartridge" },
                           {},
                           {},
                           { expected_status: 401 })
        end
      end
    end

    context "group" do
      let(:t_group) do
        group_with_user(active_all: true, context: t_course.account, user: t_teacher)
        @group
      end

      it "requires :read permission" do
        user_model
        api_call_as_user(@user,
                         :post,
                         "/api/v1/groups/#{t_group.id}/content_exports?export_type=zip",
                         { controller: "content_exports_api", action: "create", format: "json", group_id: t_group.to_param, export_type: "zip" },
                         {},
                         {},
                         { expected_status: 401 })
      end

      it "creates a group file export" do
        json = {}
        expect do
          json = api_call_as_user(t_teacher,
                                  :post,
                                  "/api/v1/groups/#{t_group.id}/content_exports?export_type=zip",
                                  { controller: "content_exports_api", action: "create", format: "json", group_id: t_group.to_param, export_type: "zip" })
        end.to change(Delayed::Job, :count).by(1)
        export = t_group.content_exports.find(json["id"])
        expect(export.export_type).to eq "zip"
      end

      it "rejects common cartridge format with bad_request" do
        api_call_as_user(t_teacher,
                         :post,
                         "/api/v1/groups/#{t_group.id}/content_exports?export_type=common_cartridge",
                         { controller: "content_exports_api", action: "create", format: "json", group_id: t_group.to_param, export_type: "common_cartridge" },
                         {},
                         {},
                         { expected_status: 400 })
      end

      it "lists exports" do
        zip_export = past_export(t_group, t_teacher, "zip")
        json = api_call_as_user(t_teacher,
                                :get,
                                "/api/v1/groups/#{t_group.id}/content_exports",
                                { controller: "content_exports_api", action: "index", format: "json", group_id: t_group.to_param })
        expect(json.pluck("id")).to eql [zip_export.id]
      end

      it "shows an export" do
        zip_export = past_export(t_group, t_teacher, "zip")
        json = api_call_as_user(t_teacher,
                                :get,
                                "/api/v1/groups/#{t_group.id}/content_exports/#{zip_export.id}",
                                { controller: "content_exports_api", action: "show", format: "json", group_id: t_group.to_param, id: zip_export.to_param })
        expect(json["id"]).to eql zip_export.id
        expect(json["export_type"]).to eql "zip"
      end
    end

    context "user" do
      it "requires :read permission" do
        api_call_as_user(t_teacher,
                         :post,
                         "/api/v1/users/#{t_student.id}/content_exports?export_type=zip",
                         { controller: "content_exports_api", action: "create", format: "json", user_id: t_student.to_param, export_type: "zip" },
                         {},
                         {},
                         { expected_status: 401 })
      end

      it "creates a user file export" do
        json = {}
        expect do
          json = api_call_as_user(t_student,
                                  :post,
                                  "/api/v1/users/#{t_student.id}/content_exports?export_type=zip",
                                  { controller: "content_exports_api", action: "create", format: "json", user_id: t_student.to_param, export_type: "zip" })
        end.to change(Delayed::Job, :count).by(1)
        export = t_student.content_exports.find(json["id"])
        expect(export.export_type).to eq "zip"
      end

      it "rejects qti format with bad_request" do
        api_call_as_user(t_student,
                         :post,
                         "/api/v1/users/#{t_student.id}/content_exports?export_type=qti",
                         { controller: "content_exports_api", action: "create", format: "json", user_id: t_student.to_param, export_type: "qti" },
                         {},
                         {},
                         { expected_status: 400 })
      end

      it "lists exports created by the user" do
        zip_export = past_export(t_student, t_student, "zip")
        past_export(t_student, t_teacher, "zip")
        json = api_call_as_user(t_student,
                                :get,
                                "/api/v1/users/#{t_student.id}/content_exports",
                                { controller: "content_exports_api", action: "index", format: "json", user_id: t_student.to_param })
        expect(json.pluck("id")).to eql [zip_export.id]
      end

      it "shows an export" do
        zip_export = past_export(t_student, t_student, "zip")
        json = api_call_as_user(t_student,
                                :get,
                                "/api/v1/users/#{t_student.id}/content_exports/#{zip_export.id}",
                                { controller: "content_exports_api", action: "show", format: "json", user_id: t_student.to_param, id: zip_export.to_param })
        expect(json["id"]).to eql zip_export.id
        expect(json["export_type"]).to eql "zip"
      end

      it "does not show another user's export" do
        zip_export = past_export(t_student, t_student, "zip")
        api_call_as_user(t_teacher,
                         :get,
                         "/api/v1/users/#{t_student.id}/content_exports/#{zip_export.id}",
                         { controller: "content_exports_api", action: "show", format: "json", user_id: t_student.to_param, id: zip_export.to_param },
                         {},
                         {},
                         expected_status: 401)
      end
    end
  end
end
