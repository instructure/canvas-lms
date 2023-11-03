# frozen_string_literal: true

#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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

describe ContentMigrationsController, type: :request do
  before :once do
    course_with_teacher(active_all: true, user: user_with_pseudonym)
    @migration_url = "/api/v1/courses/#{@course.id}/content_migrations"
    @params = { controller: "content_migrations", format: "json", course_id: @course.id.to_param }

    @migration = @course.content_migrations.create
    @migration.migration_type = "common_cartridge_importer"
    @migration.context = @course
    @migration.user = @user
    @migration.started_at = 1.week.ago
    @migration.finished_at = 1.day.ago
    @migration.save!
  end

  before do
    user_session @teacher
  end

  describe "index" do
    before do
      @params = @params.merge(action: "index")
    end

    it "returns list" do
      json = api_call(:get, @migration_url, @params)
      expect(json.length).to eq 1
      expect(json.first["id"]).to eq @migration.id
    end

    it "paginates" do
      migration = @course.content_migrations.create!
      json = api_call(:get, @migration_url + "?per_page=1", @params.merge({ per_page: "1" }))
      expect(json.length).to eq 1
      expect(json.first["id"]).to eq migration.id
      json = api_call(:get, @migration_url + "?per_page=1&page=2", @params.merge({ per_page: "1", page: "2" }))
      expect(json.length).to eq 1
      expect(json.first["id"]).to eq @migration.id
    end

    it "401s" do
      course_with_student_logged_in(course: @course, active_all: true)
      api_call(:get, @migration_url, @params, {}, {}, expected_status: 401)
    end

    it "creates the course root folder" do
      expect(@course.folders).to be_empty
      api_call(:get, @migration_url, @params)
      expect(@course.reload.folders).not_to be_empty
    end

    context "User" do
      before do
        @migration = @user.content_migrations.create
        @migration.migration_type = "zip_file_import"
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/users/#{@user.id}/content_migrations"
        @params = @params.reject { |k| k == :course_id }.merge(user_id: @user.id)
      end

      it "returns list" do
        json = api_call(:get, @migration_url, @params)
        expect(json.length).to eq 1
        expect(json.first["id"]).to eq @migration.id
      end
    end

    context "Group" do
      before do
        group_with_user user: @user
        @migration = @group.content_migrations.create
        @migration.migration_type = "zip_file_import"
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/groups/#{@group.id}/content_migrations"
        @params = @params.reject { |k| k == :course_id }.merge(group_id: @group.id)
      end

      it "returns list" do
        json = api_call(:get, @migration_url, @params)
        expect(json.length).to eq 1
        expect(json.first["id"]).to eq @migration.id
      end
    end

    context "Account" do
      before do
        @account = Account.create!(name: "name")
        @account.account_users.create!(user: @user)
        @migration = @account.content_migrations.create
        @migration.migration_type = "qti_converter"
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/accounts/#{@account.id}/content_migrations"
        @params = @params.reject { |k| k == :course_id }.merge(account_id: @account.id)
      end

      it "returns list" do
        json = api_call(:get, @migration_url, @params)
        expect(json.length).to eq 1
        expect(json.first["id"]).to eq @migration.id
      end
    end

    it "does not return attachments for expired import" do
      ContentMigration.where(id: @migration.id).update_all(created_at: 405.days.ago)

      json = api_call(:get, @migration_url, @params)
      expect(json[0]["attachment"]).to be_nil
    end

    it "does not return a blank page when master_course_import migrations exist" do
      template = MasterCourses::MasterTemplate.set_as_master_course(Course.create!)
      sub = template.add_child_course!(@course)
      mm = @course.content_migrations.create migration_type: "master_course_import", child_subscription_id: sub.id
      mm.migration_settings[:hide_from_index] = true
      mm.save!
      json = api_call(:get, @migration_url + "?per_page=1", @params.merge(per_page: "1"))
      expect(json.length).to eq 1
      expect(json.first["id"]).to eq @migration.id
    end
  end

  describe "show" do
    before :once do
      @migration_url += "/#{@migration.id}"
      @params = @params.merge(action: "show", id: @migration.id.to_param)
    end

    it "returns migration" do
      @migration.attachment = Attachment.create!(context: @migration, filename: "test.txt", uploaded_data: StringIO.new("test file"))
      @migration.save!
      progress = Progress.create!(tag: "content_migration", context: @migration)
      json = api_call(:get, @migration_url, @params)

      expect(json["id"]).to eq @migration.id
      expect(json["migration_type"]).to eq @migration.migration_type
      expect(json["finished_at"]).not_to be_nil
      expect(json["started_at"]).not_to be_nil
      expect(json["user_id"]).to eq @user.id
      expect(json["workflow_state"]).to eq "pre_processing"
      expect(json["migration_issues_url"]).to eq "http://www.example.com/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/migration_issues"
      expect(json["migration_issues_count"]).to eq 0
      expect(json["attachment"]["url"]).to match %r{/files/#{@migration.attachment.id}/download}
      expect(json["progress_url"]).to eq "http://www.example.com/api/v1/progress/#{progress.id}"
      expect(json["migration_type_title"]).to eq "Common Cartridge"
    end

    it "returns waiting_for_select when it's supposed to" do
      @migration.workflow_state = "exported"
      @migration.migration_settings[:import_immediately] = false
      @migration.save!
      json = api_call(:get, @migration_url, @params)
      expect(json["workflow_state"]).to eq "waiting_for_select"
    end

    it "404s" do
      api_call(:get, @migration_url + "000", @params.merge({ id: @migration.id.to_param + "000" }), {}, {}, expected_status: 404)
    end

    it "401s" do
      course_with_student_logged_in(course: @course, active_all: true)
      api_call(:get, @migration_url, @params, {}, {}, expected_status: 401)
    end

    it "does not return attachment for course copies" do
      @migration.migration_type = "course_copy_importer"
      @migration.source_course_id = @course.id
      @migration.source_course = @course
      @attachment = Attachment.create!(context: @migration, filename: "test.zip", uploaded_data: StringIO.new("test file"))
      @attachment.file_state = "deleted"
      @attachment.workflow_state = "unattached"
      @attachment.save
      @migration.attachment = @attachment
      @migration.save!

      json = api_call(:get, @migration_url, @params)
      expect(json["attachment"]).to be_nil
    end

    it "returns source course info for course copy" do
      @migration.migration_type = "course_copy_importer"
      @migration.source_course_id = @course.id
      @migration.source_course = @course
      @migration.save!

      json = api_call(:get, @migration_url, @params)
      expect(json["settings"]["source_course_id"]).to eq @course.id
      expect(json["settings"]["source_course_name"]).to eq @course.name
    end

    it "does not return source course on unmatching root account ids" do
      unmatched_course = Course.create!(root_account_id: Account.create!)
      @migration.migration_type = "course_copy_importer"
      @migration.source_course_id = unmatched_course.id
      @migration.source_course = unmatched_course
      @migration.save!

      json = api_call(:get, @migration_url, @params)
      expect(json["settings"]).to be_nil
    end

    it "marks as failed if stuck in pre_processing" do
      @migration.workflow_state = "pre_processing"
      @migration.save!
      ContentMigration.where(id: @migration.id).update_all(updated_at: Time.now.utc - 2.hours)

      json = api_call(:get, @migration_url, @params)
      expect(json["workflow_state"]).to eq "failed"
      expect(json["migration_issues_count"]).to eq 1
      @migration.reload
      expect(@migration).to be_failed
      expect(@migration.migration_issues.first.description).to eq "The file upload process timed out."
    end

    context "Site Admin" do
      it "contains additional auditing information for site admins" do
        course_with_teacher_logged_in(course: @course, active_all: true, user: site_admin_user)
        json = api_call(:get, @migration_url, @params)
        expect(json["audit_info"]).not_to be_falsey
      end

      it "does not contain additional auditing information if not site admin" do
        course_with_teacher_logged_in(course: @course, active_all: true, user: user_with_pseudonym)
        json = api_call(:get, @migration_url, @params)
        expect(json["audit_info"]).to be_falsey
      end
    end

    context "User" do
      before do
        @migration = @user.content_migrations.create
        @migration.migration_type = "zip_file_import"
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/users/#{@user.id}/content_migrations/#{@migration.id}"
        @params = @params.reject { |k| k == :course_id }.merge(user_id: @user.id, id: @migration.to_param)
      end

      it "returns migration" do
        json = api_call(:get, @migration_url, @params)
        expect(json["id"]).to eq @migration.id
      end
    end

    context "Group" do
      before do
        group_with_user user: @user
        @migration = @group.content_migrations.create
        @migration.migration_type = "zip_file_import"
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/groups/#{@group.id}/content_migrations/#{@migration.id}"
        @params = @params.reject { |k| k == :course_id }.merge(group_id: @group.id, id: @migration.to_param)
      end

      it "returns migration" do
        json = api_call(:get, @migration_url, @params)
        expect(json["id"]).to eq @migration.id
      end
    end

    context "Account" do
      before do
        @account = Account.create!(name: "name")
        @account.account_users.create!(user: @user)
        @migration = @account.content_migrations.create
        @migration.migration_type = "qti_converter"
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/accounts/#{@account.id}/content_migrations/#{@migration.id}"
        @params = @params.reject { |k| k == :course_id }.merge(account_id: @account.id, id: @migration.to_param)
      end

      it "returns migration" do
        json = api_call(:get, @migration_url, @params)
        expect(json["id"]).to eq @migration.id
      end
    end
  end

  describe "create" do
    before :once do
      @params = { controller: "content_migrations", format: "json", course_id: @course.id.to_param, action: "create" }
      @post_params = { migration_type: "common_cartridge_importer", pre_attachment: { name: "test.zip" } }
    end

    it "errors for unknown type" do
      json = api_call(:post, @migration_url, @params, { migration_type: "jerk" }, {}, expected_status: 400)
      expect(json).to eq({ "message" => "Invalid migration_type" })
    end

    it "queues a migration" do
      @migration.fail_with_error!(nil) # clear out old migration

      @post_params.delete :pre_attachment
      p = Canvas::Plugin.new("hi")
      allow(p).to receive(:default_settings).and_return({ "worker" => "CCWorker", "valid_contexts" => ["Course"] }.with_indifferent_access)
      allow(Canvas::Plugin).to receive(:find).and_return(p)
      json = api_call(:post, @migration_url, @params, @post_params)
      expect(json["workflow_state"]).to eq "running"
      migration = ContentMigration.find json["id"]
      expect(migration.workflow_state).to eq "exporting"
      expect(migration.job_progress.workflow_state).to eq "queued"
    end

    it "does not queue a migration if do_not_run flag is set" do
      @post_params.delete :pre_attachment
      p = Canvas::Plugin.new("hi")
      allow(p).to receive(:default_settings).and_return({ "worker" => "CCWorker", "valid_contexts" => ["Course"] }.with_indifferent_access)
      allow(Canvas::Plugin).to receive(:find).and_return(p)
      json = api_call(:post, @migration_url, @params, @post_params.merge(do_not_run: true))
      expect(json["workflow_state"]).to eq "pre_processing"
      migration = ContentMigration.find json["id"]
      expect(migration.workflow_state).to eq "created"
      expect(migration.job_progress).to be_nil
    end

    it "errors if expected setting isn't set" do
      json = api_call(:post, @migration_url, @params, { migration_type: "course_copy_importer" }, {}, expected_status: 400)
      expect(json).to eq({ "message" => "A course copy requires a source course." })
    end

    it "queues if correct settings set" do
      # implicitly tests that the response was a 200
      api_call(:post, @migration_url, @params, { migration_type: "course_copy_importer", settings: { source_course_id: @course.id.to_param } })
    end

    it "does not queue for course copy and selective_import" do
      json = api_call(:post, @migration_url, @params, { migration_type: "course_copy_importer", selective_import: "1", settings: { source_course_id: @course.id.to_param } })
      expect(json["workflow_state"]).to eq "waiting_for_select"
      migration = ContentMigration.find json["id"]
      expect(migration.workflow_state).to eq "exported"
      expect(migration.job_progress).to be_nil
    end

    it "queues a course copy with immediate select" do
      assignment = @course.assignments.create! title: "test"
      json = api_call(:post, @migration_url, @params, { migration_type: "course_copy_importer", select: { assignments: [assignment.to_param] }, settings: { source_course_id: @course.to_param } })
      expect(json["workflow_state"]).to eq "running"
      migration = ContentMigration.find json["id"]
      expect(migration.workflow_state).to eq "exporting"
      expect(migration.job_progress).not_to be_nil
      key = CC::CCHelper.create_key(assignment, global: true)
      expect(migration.copy_options).to eq({ "assignments" => { key => "1" } })
    end

    it "records both jobs involved with a selective import" do
      # create the migration, specifying selective import
      json = api_call(:post,
                      @migration_url,
                      @params,
                      {
                        migration_type: "canvas_cartridge_importer",
                        selective_import: "1",
                        pre_attachment: { name: "example.imscc" }
                      })
      expect(json["workflow_state"]).to eq "pre_processing"

      # (pretend to) upload the file
      cm = ContentMigration.find json["id"]
      file = Attachment.new(context: cm, display_name: "example.imscc")
      file.uploaded_data = fixture_file_upload("migration/canvas_cc_minimum.zip")
      file.save!
      cm.attachment = file
      cm.save!
      cm.queue_migration
      allow(Delayed::Worker).to receive(:current_job).and_return(double("Delayed::Job", id: 123))
      run_jobs
      expect(cm.reload.workflow_state).to eq "exported"
      expect(cm.migration_settings["job_ids"]).to eq([123])

      # update the migration with the selection
      json = api_call(:put,
                      "#{@migration_url}/#{cm.id}",
                      @params.merge(action: "update", id: cm.to_param),
                      { copy: { "everything" => "1" } })
      expect(json["workflow_state"]).to eq "running"
      allow(Delayed::Worker).to receive(:current_job).and_return(double("Delayed::Job", id: 456))
      run_jobs
      expect(cm.reload.workflow_state).to eq "imported"
      expect(cm.migration_settings["job_ids"]).to match_array([123, 456])
    end

    it "queues for course copy on concluded courses" do
      source_course = Course.create(name: "source course")
      source_course.enroll_teacher(@user)
      source_course.workflow_state = "completed"
      source_course.save!
      # tests that the response was a 200
      api_call(:post,
               @migration_url,
               @params,
               { migration_type: "course_copy_importer",
                 settings: { source_course_id: source_course.id.to_param } })
    end

    it "translates a sis source_course_id" do
      course_with_teacher(active_all: true, user: @user)
      @course.sis_source_id = "booga"
      @course.save!
      json = api_call(:post,
                      @migration_url + "?settings[source_course_id]=sis_course_id:booga&migration_type=course_copy_importer",
                      @params.merge(migration_type: "course_copy_importer", settings: { "source_course_id" => "sis_course_id:booga" }))
      migration = ContentMigration.find json["id"]
      expect(migration.migration_settings[:source_course_id]).to eql @course.id
    end

    context "sharding" do
      specs_require_sharding

      it "can queue a cross-shard course for course copy" do
        @shard1.activate do
          @other_account = Account.create
          @copy_from = @other_account.courses.create!
          @copy_from.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
        end
        json = api_call(:post,
                        @migration_url + "?settings[source_course_id]=#{@copy_from.global_id}&migration_type=course_copy_importer",
                        @params.merge(migration_type: "course_copy_importer", settings: { "source_course_id" => @copy_from.global_id.to_s }))

        migration = ContentMigration.find json["id"]
        expect(migration.source_course).to eq @copy_from
      end

      it "can queue to a cross-shard course for course copy" do
        @shard1.activate do
          @other_account = Account.create
          @copy_to = @other_account.courses.create!
          @copy_to.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
        end

        @copy_from = @course
        json = api_call(:post,
                        "/api/v1/courses/#{@copy_to.global_id}/content_migrations?settings[source_course_id]=#{@copy_from.local_id}&migration_type=course_copy_importer",
                        @params.merge(course_id: @copy_to.global_id.to_s,
                                      migration_type: "course_copy_importer",
                                      settings: { "source_course_id" => @copy_from.local_id.to_s }))

        migration = @copy_to.content_migrations.find(json["id"])
        expect(migration.source_course).to eq @copy_from
      end

      it "can queue to a cross-shard course for course copy with selective_content" do
        @shard1.activate do
          @other_account = Account.create
          @copy_to = @other_account.courses.create!
          @copy_to.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
        end

        @copy_from = @course
        @copy_from.content_exports.create!(global_identifiers: false) # turns out this is important to repro-ing a certain terrible bug
        @page = @copy_from.wiki_pages.create!(title: "aaaa")
        json = api_call(:post,
                        "/api/v1/courses/#{@copy_to.global_id}/content_migrations?" \
                        "settings[source_course_id]=#{@copy_from.local_id}&migration_type=course_copy_importer&select[pages][]=#{@page.id}",
                        @params.merge(course_id: @copy_to.global_id.to_s,
                                      migration_type: "course_copy_importer",
                                      settings: { "source_course_id" => @copy_from.local_id.to_s },
                                      select: { "pages" => [@page.id.to_s] }))

        migration = @copy_to.content_migrations.find(json["id"])
        expect(migration.source_course).to eq @copy_from
        run_jobs
        expect(@copy_to.wiki_pages.last.title).to eq @page.title
      end

      it "can queue to a cross-shard course for course copy with selective_content inserted into a module" do
        @shard1.activate do
          @other_account = Account.create
          @copy_to = @other_account.courses.create!
          @copy_to.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")
          @mod = @copy_to.context_modules.create!
        end

        @copy_from = @course
        @copy_from.content_exports.create!(global_identifiers: false) # turns out this is important to repro-ing a certain terrible bug
        @page = @copy_from.wiki_pages.create!(title: "aaaa")
        json = api_call(:post,
                        "/api/v1/courses/#{@copy_to.global_id}/content_migrations?" \
                        "settings[source_course_id]=#{@copy_from.local_id}&migration_type=course_copy_importer&settings[insert_into_module_id]=#{@mod.global_id}&select[pages][]=#{@page.id}",
                        @params.merge(course_id: @copy_to.global_id.to_s,
                                      migration_type: "course_copy_importer",
                                      settings: { "source_course_id" => @copy_from.local_id.to_s, "insert_into_module_id" => @mod.global_id.to_s },
                                      select: { "pages" => [@page.id.to_s] }))

        migration = @copy_to.content_migrations.find(json["id"])
        expect(migration.source_course).to eq @copy_from
        run_jobs
        expect(@copy_to.wiki_pages.last.title).to eq @page.title
        expect(@mod.content_tags.first.content_type).to eq "WikiPage"
      end
    end

    context "migration file upload" do
      it "sets attachment pre-flight data" do
        json = api_call(:post, @migration_url, @params, @post_params)
        expect(json["pre_attachment"]).not_to be_nil
        expect(json["pre_attachment"]["upload_params"]["key"].end_with?("test.zip")).to be true
      end

      it "does not queue migration with pre_attachent on create" do
        json = api_call(:post, @migration_url, @params, @post_params)
        expect(json["workflow_state"]).to eq "pre_processing"
        migration = ContentMigration.find json["id"]
        expect(migration.workflow_state).to eq "pre_processing"
        expect(json["progress_url"]).not_to be_nil
      end

      it "errors if upload file required but not provided" do
        @post_params.delete :pre_attachment
        json = api_call(:post, @migration_url, @params, @post_params, {}, expected_status: 400)
        expect(json).to eq({ "message" => "File upload, file_url, or content_export_id is required" })
      end

      it "queues the migration when file finishes uploading" do
        local_storage!
        @attachment = Attachment.create!(context: @migration, filename: "test.zip", uploaded_data: StringIO.new("test file"))
        @attachment.file_state = "deleted"
        @attachment.workflow_state = "unattached"
        @attachment.save
        @migration.attachment = @attachment
        @migration.save!
        @attachment.workflow_state = nil
        @content = Tempfile.new(["test", ".zip"])
        def @content.content_type
          "application/zip"
        end
        @content.write("test file")
        @content.rewind
        @attachment.uploaded_data = @content
        @attachment.save!
        api_call(:post,
                 "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
                 { controller: "files", action: "api_create_success", format: "json", id: @attachment.to_param, uuid: @attachment.uuid })

        @migration.reload
        expect(@migration.attachment).not_to be_nil
        expect(@migration.workflow_state).to eq "exporting"
        expect(@migration.job_progress.workflow_state).to eq "queued"
      end

      it "errors if course quota exceeded" do
        @post_params[:pre_attachment] = { name: "test.zip", size: 1.gigabyte }
        json = api_call(:post, @migration_url, @params, @post_params)
        expect(json["pre_attachment"]).to eq({ "message" => "file size exceeds quota", "error" => true })
        expect(json["workflow_state"]).to eq "failed"
        migration = ContentMigration.find json["id"]
        migration.workflow_state = "pre_process_error"
      end
    end

    context "by url" do
      it "queues migration with url sent" do
        post_params = { migration_type: "common_cartridge_importer", settings: { file_url: "http://example.com/oi.imscc" } }
        json = api_call(:post, @migration_url, @params, post_params)
        migration = ContentMigration.find json["id"]
        expect(migration.attachment).to be_nil
        expect(migration.migration_settings[:file_url]).to eq post_params[:settings][:file_url]
      end
    end

    context "by content_export_id" do
      def stub_export(context, user, state, stub_attachment)
        export = context.content_exports.create
        export.export_type = "common_cartridge"
        export.workflow_state = state
        export.user = user
        export.attachment = export.attachments.create!(filename: "test.imscc", uploaded_data: StringIO.new("test file")) if stub_attachment
        export.save
        export
      end

      it "links the file from the content export to the content migration" do
        export = stub_export(@course, @user, "exported", true)
        post_params = { migration_type: "common_cartridge_importer", settings: { content_export_id: export.id } }
        json = api_call(:post, @migration_url, @params, post_params)
        migration = ContentMigration.find json["id"]
        expect(migration.attachment).not_to be_nil
        expect(migration.attachment.root_attachment).to eq export.attachment
      end

      it "verifies the content export exists" do
        post_params = { migration_type: "common_cartridge_importer", settings: { content_export_id: 0 } }
        json = api_call(:post, @migration_url, @params, post_params)
        expect(response).to have_http_status :bad_request
        expect(json["message"]).to eq "invalid content export"
        expect(ContentMigration.last).to be_pre_process_error
      end

      it "verifies the user has permission to read the content export" do
        me = @user
        course_with_teacher(active_all: true)
        export = stub_export(@course, @teacher, "exported", true)
        @user = me
        post_params = { migration_type: "common_cartridge_importer", settings: { content_export_id: export.id } }
        json = api_call(:post, @migration_url, @params, post_params)
        expect(response).to have_http_status :bad_request
        expect(json["message"]).to eq "invalid content export"
        expect(ContentMigration.last).to be_pre_process_error
      end

      it "rejects an incomplete export" do
        export = stub_export(@course, @user, "exporting", false)
        post_params = { migration_type: "common_cartridge_importer", settings: { content_export_id: export.id } }
        json = api_call(:post, @migration_url, @params, post_params)
        expect(response).to have_http_status :bad_request
        expect(json["message"]).to eq "content export is incomplete"
        expect(ContentMigration.last).to be_pre_process_error
      end
    end

    context "by LTI extension" do
      it "queues migration with LTI url sent" do
        # @migration.fail_with_error!(nil) # clear out old migration

        post_params = { migration_type: "context_external_tool", settings: { file_url: "http://example.com/oi.imscc" } }
        json = api_call(:post, @migration_url, @params, post_params)
        migration = ContentMigration.find json["id"]
        expect(migration.attachment).to be_nil
        expect(migration.migration_settings[:file_url]).to eq post_params[:settings][:file_url]
        expect(migration.workflow_state).to eq "exporting"
        expect(migration.job_progress.workflow_state).to eq "queued"
      end

      it "requires a file upload" do
        post_params = { migration_type: "context_external_tool", settings: { course_course_id: 42 } }
        api_call(:post, @migration_url, @params, post_params, {}, expected_status: 400)
      end
    end

    context "User" do
      before :once do
        @migration_url = "/api/v1/users/#{@user.id}/content_migrations"
        @params = @params.reject { |k| k == :course_id }.merge(user_id: @user.to_param)
        @folder = Folder.root_folders(@user).first
      end

      it "errors for an unsupported type" do
        json = api_call(:post,
                        @migration_url,
                        @params,
                        { migration_type: "common_cartridge_importer" },
                        {},
                        expected_status: 400)
        expect(json).to eq({ "message" => "Unsupported migration_type for context" })
      end

      it "queues a migration" do
        json = api_call(:post,
                        @migration_url,
                        @params,
                        { migration_type: "zip_file_importer",
                          settings: { file_url: "http://example.com/oi.zip",
                                      folder_id: @folder.id } })
        migration = ContentMigration.find json["id"]
        expect(migration.context).to eql @user
      end
    end

    context "Group" do
      before do
        group_with_user user: @user
        @migration_url = "/api/v1/groups/#{@group.id}/content_migrations"
        @params = @params.reject { |k| k == :course_id }.merge(group_id: @group.to_param)
        @folder = Folder.root_folders(@group).first
      end

      it "queues a migration" do
        json = api_call(:post,
                        @migration_url,
                        @params,
                        { migration_type: "zip_file_importer",
                          settings: { file_url: "http://example.com/oi.zip",
                                      folder_id: @folder.id } })
        migration = ContentMigration.find json["id"]
        expect(migration.context).to eql @group
      end
    end

    context "Account" do
      before do
        @account = Account.create!(name: "migration account")
        @account.account_users.create!(user: @user)
        @migration_url = "/api/v1/accounts/#{@account.id}/content_migrations"
        @params = @params.reject { |k| k == :course_id }.merge(account_id: @account.to_param)
      end

      it "queues a migration" do
        json = api_call(:post,
                        @migration_url,
                        @params,
                        { migration_type: "qti_converter",
                          settings: { file_url: "http://example.com/oi.zip" } })
        migration = ContentMigration.find json["id"]
        expect(migration.context).to eql @account
      end
    end
  end

  describe "update" do
    before do
      @migration_url = "/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}"
      @params = { controller: "content_migrations", format: "json", course_id: @course.id.to_param, action: "update", id: @migration.id.to_param }
      @post_params = {}
    end

    it "queues a migration" do
      json = api_call(:put, @migration_url, @params, @post_params)
      expect(json["workflow_state"]).to eq "running"
      @migration.reload
      expect(@migration.workflow_state).to eq "exporting"
      expect(@migration.job_progress.workflow_state).to eq "queued"
    end

    it "does not queue a migration if do_not_run flag is set" do
      json = api_call(:put, @migration_url, @params, @post_params.merge(do_not_run: true))
      expect(json["workflow_state"]).to eq "pre_processing"
      migration = ContentMigration.find json["id"]
      expect(migration.workflow_state).to eq "created"
      expect(migration.job_progress).to be_nil
    end

    it "does not change migration_type" do
      json = api_call(:put, @migration_url, @params, @post_params.merge(migration_type: "oioioi"))
      expect(json["migration_type"]).to eq "common_cartridge_importer"
    end

    it "resets progress after queue" do
      p = @migration.reset_job_progress
      p.completion = 100
      p.workflow_state = "completed"
      p.save!
      api_call(:put, @migration_url, @params, @post_params)
      p.reload
      expect(p.completion).to eq 0
      expect(p.workflow_state).to eq "queued"
    end

    context "selective content" do
      before :once do
        @migration.workflow_state = "exported"
        @migration.migration_settings[:import_immediately] = false
        @migration.save!
        @post_params = { copy: { all_assignments: true, context_modules: { "id_9000" => true } } }
      end

      it "sets the selective data" do
        api_call(:put, @migration_url, @params, @post_params)
        @migration.reload
        copy_options = { "all_assignments" => "true", "context_modules" => { "9000" => "true" } }
        expect(@migration.migration_settings[:migration_ids_to_import]).to eq({ "copy" => copy_options })
        expect(@migration.copy_options).to eq copy_options
      end

      it "queues a course copy after selecting content" do
        @migration.migration_type = "course_copy_importer"
        @migration.migration_settings[:source_course_id] = @course.id
        @migration.save!
        json = api_call(:put, @migration_url, @params, @post_params)
        expect(json["workflow_state"]).to eq "running"
        @migration.reload
        expect(@migration.workflow_state).to eq "exporting"
      end

      it "queues a file migration after selecting content" do
        json = api_call(:put, @migration_url, @params, @post_params)
        expect(json["workflow_state"]).to eq "running"
        @migration.reload
        expect(@migration.workflow_state).to eq "importing"
      end
    end
  end

  describe "migration_systems" do
    it "returns the migrators" do
      p = Canvas::Plugin.find("common_cartridge_importer")
      allow(Canvas::Plugin).to receive(:all_for_tag).and_return([p])
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/content_migrations/migrators",
                      { controller: "content_migrations", action: "available_migrators", format: "json", course_id: @course.id.to_param })
      expect(json).to eq [{
        "type" => "common_cartridge_importer",
        "requires_file_upload" => true,
        "name" => "Common Cartridge 1.x Package",
        "required_settings" => []
      }]
    end

    it "filters by context type" do
      allow(Canvas::Plugin).to receive(:all_for_tag).and_return([Canvas::Plugin.find("common_cartridge_importer"),
                                                                 Canvas::Plugin.find("zip_file_importer")])
      json = api_call(:get,
                      "/api/v1/users/#{@user.id}/content_migrations/migrators",
                      { controller: "content_migrations", action: "available_migrators", format: "json", user_id: @user.to_param })
      expect(json).to eq [{
        "type" => "zip_file_importer",
        "requires_file_upload" => true,
        "name" => "Unzip .zip file into folder",
        "required_settings" => ["source_folder_id"]
      }]
    end
  end

  describe "content selection" do
    before :once do
      @migration_url = "/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/selective_data"
      @params = { controller: "content_migrations", format: "json", course_id: @course.id.to_param, action: "content_list", id: @migration.id.to_param }
      @orig_course = @course

      course_factory
      @dt1 = @course.discussion_topics.create!(message: "hi", title: "discussion title")
      @cm = @course.context_modules.create!(name: "some module")
      @att = Attachment.create!(filename: "first.txt", uploaded_data: StringIO.new("ohai"), folder: Folder.unfiled_folder(@course), context: @course)
      @wiki = @course.wiki_pages.create!(title: "wiki", body: "ohai")
      @migration.migration_type = "course_copy_importer"
      @migration.migration_settings[:source_course_id] = @course.id
      @migration.source_course = @course
      @migration.save!
    end

    it "returns the top-level list" do
      json = api_call(:get, @migration_url, @params)
      expect(json).to eq [{ "type" => "course_settings", "property" => "copy[all_course_settings]", "title" => "Course Settings" },
                          { "type" => "syllabus_body", "property" => "copy[all_syllabus_body]", "title" => "Syllabus Body" },
                          { "type" => "context_modules", "property" => "copy[all_context_modules]", "title" => "Modules", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=context_modules" },
                          { "type" => "discussion_topics", "property" => "copy[all_discussion_topics]", "title" => "Discussion Topics", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=discussion_topics" },
                          { "type" => "wiki_pages", "property" => "copy[all_wiki_pages]", "title" => "Pages", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=wiki_pages" },
                          { "type" => "attachments", "property" => "copy[all_attachments]", "title" => "Files", "count" => 1, "sub_items_url" => "http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=attachments" }]
    end

    it "returns individual types" do
      json = api_call(:get, @migration_url + "?type=context_modules", @params.merge({ type: "context_modules" }))
      expect(json.length).to eq 1
      expect(json.first["type"]).to eq "context_modules"
      expect(json.first["title"]).to eq @cm.name
    end

    it "returns global identifiers if available" do
      json = api_call(:get, @migration_url + "?type=discussion_topics", @params.merge({ type: "discussion_topics" }))
      key = CC::CCHelper.create_key(@dt1, global: true)
      expect(json.first["migration_id"]).to eq key
      expect(json.first["property"]).to include key
    end

    it "returns local identifiers if needed" do
      prev_export = @course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      prev_export.update_attribute(:global_identifiers, false)
      json = api_call(:get, @migration_url + "?type=discussion_topics", @params.merge({ type: "discussion_topics" }))
      key = CC::CCHelper.create_key(@dt1, global: false)
      expect(json.first["migration_id"]).to eq key
      expect(json.first["property"]).to include key
    end
  end

  describe "content selection cross-shard" do
    specs_require_sharding

    it "actually returns local identifiers created from the correct shard if needed" do
      @migration_url = "/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/selective_data"
      @params = { controller: "content_migrations", format: "json", course_id: @course.id.to_param, action: "content_list", id: @migration.id.to_param }

      @shard1.activate do
        account = Account.create!
        @cs_course = Course.create!(account:)
        @dt1 = @cs_course.discussion_topics.create!(message: "hi", title: "discussion title")
      end
      @migration.migration_type = "course_copy_importer"
      @migration.migration_settings[:source_course_id] = @cs_course.id
      @migration.source_course = @cs_course
      @migration.save!

      prev_export = @cs_course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      prev_export.update_attribute(:global_identifiers, false)
      json = api_call(:get, @migration_url + "?type=discussion_topics", @params.merge({ type: "discussion_topics" }))
      key = @shard1.activate { CC::CCHelper.create_key(@dt1, global: false) }
      expect(json.first["migration_id"]).to eq key
      expect(json.first["property"]).to include key
    end
  end

  describe "asset_id_mapping" do
    before :once do
      @src = course_factory active_all: true
      @ann = @src.announcements.create! title: "ann", message: "ohai"
      @assign = @src.assignments.create! name: "assign"
      @shell_assign = @src.assignments.create! submission_types: "discussion_topic", description: "assigned"
      @assign_topic = @shell_assign.discussion_topic
      @mod = @src.context_modules.create! name: "mod"
      @tag = @mod.add_item type: "sub_header", title: "blah"
      @page = @src.wiki_pages.create! title: "der page"
      @topic = @src.discussion_topics.create! message: "some topic"
      @quiz = @src.quizzes.create! title: "a quiz", quiz_type: "assignment"
      @file = @src.attachments.create! filename: "teh_file.txt", uploaded_data: StringIO.new("data")

      @media_object = @src.media_objects.create!(media_id: "m1234_fish_and_wildlife", title: "fish_and_wildlife.mp4")
      @media_file = @media_object.attachment

      @dst = course_factory active_all: true
      @user = @dst.teachers.first
    end

    def test_asset_id_mapping(json)
      expect(@dst.announcements.find(json["announcements"][@ann.id.to_s]).title).to eq "ann"
      expect(@dst.assignments.find(json["assignments"][@assign.id.to_s]).name).to eq "assign"
      expect(@dst.assignments.find(json["assignments"][@shell_assign.id.to_s]).description).to eq "assigned"
      expect(@dst.context_modules.find(json["modules"][@mod.id.to_s]).name).to eq "mod"
      expect(@dst.context_module_tags.find(json["module_items"][@tag.id.to_s]).title).to eq "blah"
      expect(@dst.wiki_pages.find(json["pages"][@page.id.to_s]).title).to eq "der page"
      expect(@dst.discussion_topics.find(json["discussion_topics"][@topic.id.to_s]).message).to eq "some topic"
      expect(@dst.discussion_topics.find(json["discussion_topics"][@assign_topic.id.to_s]).message).to eq "assigned"
      expect(@dst.quizzes.find(json["quizzes"][@quiz.id.to_s]).title).to eq "a quiz"
      expect(@dst.attachments.find(json["files"][@file.id.to_s]).filename).to eq "teh_file.txt"
    end

    # accepts block which should return the migration id
    def test_asset_migration_id_mapping(json)
      expect(@dst.announcements.find(json["announcements"][yield(@ann)]["destination"]["id"]).title).to eq "ann"
      expect(@dst.assignments.find(json["assignments"][yield(@assign)]["destination"]["id"]).name).to eq "assign"
      expect(@dst.assignments.find(json["assignments"][yield(@shell_assign)]["destination"]["id"]).description).to eq "assigned"
      expect(@dst.context_modules.find(json["modules"][yield(@mod)]["destination"]["id"]).name).to eq "mod"
      expect(@dst.context_module_tags.find(json["module_items"][yield(@tag)]["destination"]["id"]).title).to eq "blah"

      dst_page = @dst.wiki_pages.find(json["pages"][yield(@page)]["destination"]["id"])
      expect(dst_page.title).to eq "der page"
      expect(json["pages"][yield(@page)]["destination"]["url"]).to eq "der-page"
      expect(dst_page.url).to eq "der-page"

      expect(@dst.wiki_pages.find(json["pages"][yield(@page)]["destination"]["id"]).title).to eq "der page"
      expect(@dst.discussion_topics.find(json["discussion_topics"][yield(@topic)]["destination"]["id"]).message).to eq "some topic"
      expect(@dst.discussion_topics.find(json["discussion_topics"][yield(@assign_topic)]["destination"]["id"]).message).to eq "assigned"
      expect(@dst.quizzes.find(json["quizzes"][yield(@quiz)]["destination"]["id"]).title).to eq "a quiz"
      expect(@dst.attachments.find(json["files"][yield(@file)]["destination"]["id"]).filename).to eq "teh_file.txt"

      dst_media_attachment = @dst.attachments.find(json["files"][yield(@media_file)]["destination"]["id"])
      expect(dst_media_attachment.filename).to eq "fish_and_wildlife.mp4"
      expect(json["files"][yield(@media_file)]["destination"]["media_entry_id"]).to eq "m1234_fish_and_wildlife"
    end

    def test_asset_migration_id_mapping_nil(json)
      expect(json["announcements"][yield(@ann)]).to be_nil
      expect(json["assignments"][yield(@assign)]).to be_nil
      expect(json["assignments"][yield(@shell_assign)]).to be_nil
      expect(json["modules"][yield(@mod)]).to be_nil
      expect(json["module_items"][yield(@tag)]).to be_nil
      expect(json["pages"][yield(@page)]).to be_nil
      expect(json["discussion_topics"][yield(@topic)]).to be_nil
      expect(json["discussion_topics"][yield(@assign_topic)]).to be_nil
      expect(json["quizzes"][yield(@quiz)]).to be_nil
      expect(json["files"][yield(@file)]).to be_nil
    end

    describe "course copy" do
      before :once do
        @migration = @dst.content_migrations.create!(source_course: @src, migration_type: "course_copy_importer")
        @migration.queue_migration
        run_jobs
      end

      def migration_id(asset)
        asset_string = asset.class.asset_string(asset.id)
        CC::CCHelper.create_key(asset_string, global: true)
      end

      it "requires permission" do
        user_factory
        api_call(:get,
                 "/api/v1/courses/#{@dst.to_param}/content_migrations/#{@migration.to_param}/asset_id_mapping",
                 { controller: "content_migrations",
                   action: "asset_id_mapping",
                   format: "json",
                   course_id: @dst.to_param,
                   id: @migration.to_param },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "maps ids" do
        json = api_call(:get,
                        "/api/v1/courses/#{@dst.to_param}/content_migrations/#{@migration.to_param}/asset_id_mapping",
                        { controller: "content_migrations",
                          action: "asset_id_mapping",
                          format: "json",
                          course_id: @dst.to_param,
                          id: @migration.to_param })
        test_asset_id_mapping(json)
      end

      context "with the :content_migration_asset_map_v2 flag on" do
        it "maps migration_ids to a hash containing the destination id" do
          Account.site_admin.enable_feature!(:content_migration_asset_map_v2)
          json = api_call(:get,
                          "/api/v1/courses/#{@dst.to_param}/content_migrations/#{@migration.to_param}/asset_id_mapping",
                          { controller: "content_migrations",
                            action: "asset_id_mapping",
                            format: "json",
                            course_id: @dst.to_param,
                            id: @migration.to_param })
          test_asset_migration_id_mapping(json) do |asset|
            migration_id(asset)
          end
          Account.site_admin.disable_feature!(:content_migration_asset_map_v2)
        end
      end

      context "with the :content_migration_asset_map_v2 flag off" do
        it "does not map migration_ids to a hash containing the destination id" do
          json = api_call(:get,
                          "/api/v1/courses/#{@dst.to_param}/content_migrations/#{@migration.to_param}/asset_id_mapping",
                          { controller: "content_migrations",
                            action: "asset_id_mapping",
                            format: "json",
                            course_id: @dst.to_param,
                            id: @migration.to_param })
          test_asset_migration_id_mapping_nil(json) do |asset|
            migration_id(asset)
          end
        end
      end
    end

    describe "blueprint course" do
      before :once do
        @template = MasterCourses::MasterTemplate.set_as_master_course(@src)
        @template.add_child_course!(@dst)
        @mm = MasterCourses::MasterMigration.start_new_migration!(@template, nil)
        run_jobs
        @mm.reload
        @migration = @mm.migration_results.first.content_migration

        @master_content_tags = @template.master_content_tags.select(:content_id, :migration_id, :content_type)
      end

      def migration_id(asset)
        if asset.instance_of?(ContentTag)
          global_asset_string = asset.class.asset_string(Shard.global_id_for(asset.id, @src.shard))
          @template.migration_id_for(global_asset_string)
        elsif asset.instance_of?(Assignment) && asset.submission_types == "discussion_topic"
          dt = DiscussionTopic.where(assignment_id: asset.id).first
          mct = @master_content_tags.find do |t|
            t.content_type == "DiscussionTopic" && t.content_id == dt.id
          end

          mct&.migration_id
        else
          mct = @master_content_tags.find do |t|
            asset_type = asset.class.name
            content_type = (asset_type == "Announcement") ? "DiscussionTopic" : asset_type
            t.content_type == content_type && t.content_id == asset.id
          end

          mct&.migration_id
        end
      end

      it "maps ids" do
        json = api_call(:get,
                        "/api/v1/courses/#{@dst.to_param}/content_migrations/#{@migration.to_param}/asset_id_mapping",
                        { controller: "content_migrations",
                          action: "asset_id_mapping",
                          format: "json",
                          course_id: @dst.to_param,
                          id: @migration.to_param })
        test_asset_id_mapping(json)
      end

      context "with the :content_migration_asset_map_v2 on" do
        it "maps migration_ids to a hash containing the destination id" do
          Account.site_admin.enable_feature!(:content_migration_asset_map_v2)
          json = api_call(:get,
                          "/api/v1/courses/#{@dst.to_param}/content_migrations/#{@migration.to_param}/asset_id_mapping",
                          { controller: "content_migrations",
                            action: "asset_id_mapping",
                            format: "json",
                            course_id: @dst.to_param,
                            id: @migration.to_param })
          test_asset_migration_id_mapping(json) do |asset|
            migration_id(asset)
          end
          Account.site_admin.disable_feature!(:content_migration_asset_map_v2)
        end
      end

      context "with the :content_migration_asset_map_v2 off" do
        it "does not map migration_ids to a hash containing the destination id" do
          json = api_call(:get,
                          "/api/v1/courses/#{@dst.to_param}/content_migrations/#{@migration.to_param}/asset_id_mapping",
                          { controller: "content_migrations",
                            action: "asset_id_mapping",
                            format: "json",
                            course_id: @dst.to_param,
                            id: @migration.to_param })
          test_asset_migration_id_mapping_nil(json) do |asset|
            migration_id(asset)
          end
        end
      end

      it "includes assets from previous syncs" do
        new_assignment = @src.assignments.create! name: "booga"
        mm = MasterCourses::MasterMigration.start_new_migration!(@template, nil)
        run_jobs
        migration = mm.reload.migration_results.first.content_migration
        json = api_call(:get,
                        "/api/v1/courses/#{@dst.to_param}/content_migrations/#{migration.to_param}/asset_id_mapping",
                        { controller: "content_migrations",
                          action: "asset_id_mapping",
                          format: "json",
                          course_id: @dst.to_param,
                          id: migration.to_param })
        test_asset_id_mapping(json)
        expect(@dst.assignments.find(json["assignments"][new_assignment.id.to_s]).name).to eq "booga"
      end
    end
  end
end
