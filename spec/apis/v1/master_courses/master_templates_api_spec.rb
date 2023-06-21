# frozen_string_literal: true

#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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

require_relative "../../api_spec_helper"

describe MasterCourses::MasterTemplatesController, type: :request do
  def setup_template
    course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    account_admin_user(active_all: true)
    @base_params = { controller: "master_courses/master_templates",
                     format: "json",
                     course_id: @course.id.to_s,
                     template_id: "default" }
  end

  describe "#show" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default"
      @params = @base_params.merge(action: "show")
      @account = Account.default
    end

    it "requires authorization" do
      @account.disable_feature!(:granular_permissions_manage_courses)
      @account.role_overrides.create!(
        role: admin_role,
        permission: "manage_courses",
        enabled: false
      )
      api_call(:get, @url, @params, {}, {}, { expected_status: 401 })
    end

    it "requires authorization (granular permissions)" do
      @account.enable_feature!(:granular_permissions_manage_courses)
      @account.role_overrides.create!(
        role: admin_role,
        permission: "manage_courses_admin",
        enabled: false
      )
      api_call(:get, @url, @params, {}, {}, { expected_status: 401 })
    end

    it "lets teachers in the master course view details" do
      course_with_teacher(course: @course, active_all: true)
      json = api_call(:get, @url, @params)
      expect(json["id"]).to eq @template.id
    end

    it "requires am active template" do
      @template.destroy!
      api_call(:get, @url, @params, {}, {}, { expected_status: 404 })
    end

    it "returns stuff" do
      time = 2.days.ago
      @template.add_child_course!(Course.create!)
      mig = @template.master_migrations.create!(imports_completed_at: time, workflow_state: "completed")
      @template.update_attribute(:active_migration_id, mig.id)
      json = api_call(:get, @url, @params)
      expect(json["id"]).to eq @template.id
      expect(json["course_id"]).to eq @course.id
      expect(json["last_export_completed_at"]).to eq time.iso8601
      expect(json["associated_course_count"]).to eq 1
      expect(json["latest_migration"]["id"]).to eq mig.id
      expect(json["latest_migration"]["workflow_state"]).to eq "completed"
    end
  end

  describe "#associated_courses" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/associated_courses"
      @params = @base_params.merge(action: "associated_courses")
    end

    it "gets some data for associated courses" do
      term = Account.default.enrollment_terms.create!(name: "termname")
      child_course1 = course_factory(course_name: "immachildcourse1", active_all: true)
      @teacher.update_attribute(:short_name, "displayname")
      child_course1.update(sis_source_id: "sisid", course_code: "shortname", enrollment_term: term)
      child_course2 = course_factory(course_name: "immachildcourse2")
      [child_course1, child_course2].each { |c| @template.add_child_course!(c) }

      json = api_call(:get, @url, @params)
      expect(json.count).to eq 2
      expect(json.pluck("id")).to match_array([child_course1.id, child_course2.id])
      course1_json = json.detect { |c| c["id"] == child_course1.id }
      expect(course1_json["name"]).to eq child_course1.name
      expect(course1_json["course_code"]).to eq child_course1.course_code
      expect(course1_json["term_name"]).to eq term.name
      expect(course1_json["sis_course_id"]).to eq "sisid"
      expect(course1_json["teachers"].first["display_name"]).to eq @teacher.short_name
    end
  end

  describe "#update_associations" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/update_associations"
      @params = @base_params.merge(action: "update_associations")
    end

    it "only adds courses in the blueprint courses' account (or sub-accounts)" do
      sub1 = Account.default.sub_accounts.create!
      sub2 = Account.default.sub_accounts.create!
      @course.update_attribute(:account, sub1)

      other_course = course_factory(account: sub2)

      json = api_call(:put, @url, @params, { course_ids_to_add: [other_course.id] }, {}, { expected_status: 400 })
      expect(json["message"]).to include("invalid courses")
    end

    it "requires account-level authorization" do
      course_with_teacher(course: @course, active_all: true)
      api_call(:put, @url, @params, {}, {}, { expected_status: 401 })
    end

    it "requires account-level blueprint permissions" do
      Account.default.role_overrides.create!(role: admin_role, permission: "manage_master_courses", enabled: false)
      api_call(:put, @url, @params, {}, {}, { expected_status: 401 })
    end

    it "does not try to add other blueprint courses" do
      other_course = course_factory
      MasterCourses::MasterTemplate.set_as_master_course(other_course)

      json = api_call(:put, @url, @params, { course_ids_to_add: [other_course.id] }, {}, { expected_status: 400 })
      expect(json["message"]).to include("invalid courses")
    end

    it "does not allow for disassociations during sync" do
      existing_child = course_factory
      @template.add_child_course!(existing_child)
      mig = @template.master_migrations.create!(workflow_state: "queued")
      @template.update_attribute(:active_migration_id, mig.id)
      json = api_call(:put, @url, @params, { course_ids_to_remove: [existing_child.id] }, {}, { expected_status: 400 })
      expect(json["message"]).to include("cannot remove courses while a sync is ongoing")
    end

    it "does not try to add other blueprint-associated courses" do
      other_master_course = course_factory
      other_template = MasterCourses::MasterTemplate.set_as_master_course(other_master_course)
      other_course = course_factory
      other_template.add_child_course!(other_course)

      json = api_call(:put, @url, @params, { course_ids_to_add: [other_course.id] }, {}, { expected_status: 400 })
      expect(json["message"]).to include("cannot add courses already associated")
    end

    it "skips existing associations" do
      other_course = course_factory
      @template.add_child_course!(other_course)

      expect_any_instantiation_of(@template).not_to receive(:add_child_course!)
      api_call(:put, @url, @params, { course_ids_to_add: [other_course.id] })
    end

    it "is able to add and remove courses" do
      existing_child = course_factory
      @template.add_child_course!(existing_child)

      subaccount1 = Account.default.sub_accounts.create!
      subaccount2 = subaccount1.sub_accounts.create!
      c1 = course_factory(account: subaccount1)
      c2 = course_factory(account: subaccount2)

      api_call(:put, @url, @params, { course_ids_to_add: [c1.id, c2.id], course_ids_to_remove: existing_child.id })

      @template.reload
      expect(@template.child_subscriptions.active.pluck(:child_course_id)).to match_array([c1.id, c2.id])
    end

    it "is able to add and remove courses by sis_source_id" do
      existing_child = course_factory(sis_source_id: "bleep")
      @template.add_child_course!(existing_child)

      subaccount1 = Account.default.sub_accounts.create!
      subaccount2 = subaccount1.sub_accounts.create!
      c1 = course_factory(account: subaccount1, sis_source_id: "beep")
      c2 = course_factory(account: subaccount2, sis_source_id: "beep2")

      api_call(:put, @url, @params, { course_ids_to_add: ["sis_course_id:#{c1.sis_source_id}", "sis_course_id:#{c2.sis_source_id}"],
                                      course_ids_to_remove: "sis_course_id:#{existing_child.sis_source_id}" })

      @template.reload
      expect(@template.child_subscriptions.active.pluck(:child_course_id)).to match_array([c1.id, c2.id])
    end
  end

  describe "#queue_migration" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations"
      @params = @base_params.merge(action: "queue_migration")
      @child_course = course_factory
      @sub = @template.add_child_course!(@child_course)
    end

    it "requires some associated courses" do
      @sub.destroy! # deleted ones shouldn't count
      json = api_call(:post, @url, @params, {}, {}, { expected_status: 400 })
      expect(json["message"]).to include("No associated courses")
    end

    it "does not allow double-queueing" do
      MasterCourses::MasterMigration.start_new_migration!(@template, @user)

      json = api_call(:post, @url, @params, {}, {}, { expected_status: 400 })
      expect(json["message"]).to include("currently running")
    end

    it "queues a master migration" do
      json = api_call(:post, @url, @params.merge(comment: "seriously", copy_settings: "1"))
      migration = @template.master_migrations.find(json["id"])
      expect(migration).to be_queued
      expect(migration.comment).to eq "seriously"
      expect(migration.migration_settings[:copy_settings]).to be true
      expect(migration.send_notification).to be false
    end

    it "accepts the send_notification option" do
      json = api_call(:post, @url, @params.merge(send_notification: true))
      migration = @template.master_migrations.find(json["id"])
      expect(migration).to be_queued
      expect(migration.send_notification).to be true
    end
  end

  describe "migrations show/index" do
    before :once do
      setup_template
      @child_course = Account.default.courses.create!
      @sub = @template.add_child_course!(@child_course)
      @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @user, comment: "Hark!")
    end

    describe "blueprint side" do
      it "shows a migration" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations/#{@migration.id}",
                        @base_params.merge(action: "migrations_show", id: @migration.to_param))
        expect(json["workflow_state"]).to eq "queued"
        expect(json["user"]["display_name"]).to eq @user.short_name
        expect(json["comment"]).to eq "Hark!"
      end

      it "shows migrations" do
        run_jobs
        expect(@migration.reload).to be_completed
        migration2 = MasterCourses::MasterMigration.start_new_migration!(@template, @user)

        json = api_call(:get, "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations", @base_params.merge(action: "migrations_index"))
        expect(json[0]["user"]["display_name"]).to eq @user.short_name
        pairs = json.map { |hash| [hash["id"], hash["workflow_state"]] }
        expect(pairs).to eq [[migration2.id, "queued"], [@migration.id, "completed"]]
      end

      it "resolves an expired job if necessary" do
        MasterCourses::MasterMigration.where(id: @migration.id).update_all(created_at: 3.days.ago)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations/#{@migration.id}",
                        @base_params.merge(action: "migrations_show", id: @migration.to_param))
        expect(json["workflow_state"]).to eq "exports_failed"
      end
    end

    describe "minion side" do
      before :once do
        run_jobs
        @minion_migration = @child_course.content_migrations.last
        teacher_in_course(course: @child_course, active_all: true)
      end

      it "shows a migration" do
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/#{@sub.id}/migrations/#{@minion_migration.id}",
                                @base_params.merge(subscription_id: @sub.to_param, course_id: @child_course.to_param, action: "imports_show", id: @minion_migration.to_param))
        expect(json["workflow_state"]).to eq "completed"
        expect(json["subscription_id"]).to eq @sub.id
        expect(json["user"]["display_name"]).to eq @user.short_name
        expect(json["comment"]).to eq "Hark!"
      end

      it "shows migrations" do
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/default/migrations",
                                @base_params.merge(subscription_id: "default", course_id: @child_course.to_param, action: "imports_index"))
        expect(json.size).to eq 1
        expect(json[0]["id"]).to eq @minion_migration.id
        expect(json[0]["subscription_id"]).to eq @sub.id
        expect(json[0]["user"]["display_name"]).to eq @user.short_name
      end

      it "filters by subscription and enumerates old subscriptions" do
        me = @teacher
        @sub.destroy
        other_master_course = course_model
        other_template = MasterCourses::MasterTemplate.set_as_master_course(other_master_course)
        other_sub = other_template.add_child_course!(@child_course)
        MasterCourses::MasterMigration.start_new_migration!(other_template, @admin, comment: "Blah!")
        run_jobs

        json = api_call_as_user(me,
                                :get,
                                "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/default/migrations",
                                @base_params.merge(subscription_id: "default", course_id: @child_course.to_param, action: "imports_index"))
        expect(json.size).to eq 1
        expect(json[0]["subscription_id"]).to eq other_sub.id
        expect(json[0]["comment"]).to eq "Blah!"

        json = api_call_as_user(me,
                                :get,
                                "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/#{@sub.id}/migrations",
                                @base_params.merge(subscription_id: @sub.to_param, course_id: @child_course.to_param, action: "imports_index"))
        expect(json.size).to eq 1
        expect(json[0]["subscription_id"]).to eq @sub.id
        expect(json[0]["comment"]).to eq "Hark!"
      end
    end
  end

  describe "#restrict_item" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/restrict_item"
      @params = @base_params.merge(action: "restrict_item")
    end

    it "validates content type" do
      json = api_call(:put, @url, @params, { content_type: "passignment", content_id: "2", restricted: "1" }, {}, { expected_status: 400 })
      expect(json["message"]).to include("Must be a valid content type")
    end

    it "gives a useful error when content is missing" do
      other_course = Course.create!
      other_assmt = other_course.assignments.create!
      json = api_call(:put, @url, @params, { content_type: "assignment", content_id: other_assmt.id, restricted: "1" }, {}, { expected_status: 404 })
      expect(json["message"]).to include("Could not find content")
    end

    it "is able to find all the (currently) supported types" do
      expect(@template.default_restrictions[:content]).to be_truthy

      assmt = @course.assignments.create!
      topic = @course.discussion_topics.create!(message: "hi", title: "discussion title")
      page = @course.wiki_pages.create!(title: "wiki", body: "ohai")
      quiz = @course.quizzes.create!
      file = @course.attachments.create!(filename: "blah", uploaded_data: default_uploaded_data)
      tool = @course.context_external_tools.create!(name: "new tool",
                                                    consumer_key: "key",
                                                    shared_secret: "secret",
                                                    custom_fields: { "a" => "1", "b" => "2" },
                                                    url: "http://www.example.com")

      type_pairs = { "assignment" => assmt,
                     "attachment" => file,
                     "discussion_topic" => topic,
                     "external_tool" => tool,
                     "lti-quiz" => assmt,
                     "quiz" => quiz,
                     "wiki_page" => page }
      type_pairs.each do |content_type, obj|
        api_call(:put, @url, @params, { content_type:, content_id: obj.id, restricted: "1" }, {}, { expected_status: 200 })
        mc_tag = @template.content_tag_for(obj)
        expect(mc_tag.restrictions).to eq @template.default_restrictions
        expect(mc_tag.use_default_restrictions).to be_truthy
      end
    end

    it "is able to set custom restrictions" do
      assmt = @course.assignments.create!
      api_call(:put,
               @url,
               @params,
               { content_type: "assignment",
                 content_id: assmt.id,
                 restricted: "1",
                 restrictions: { "content" => "1", "points" => "1" } },
               {},
               { expected_status: 200 })

      mc_tag = @template.content_tag_for(assmt)
      expect(mc_tag.restrictions).to eq({ content: true, points: true })
      expect(mc_tag.use_default_restrictions).to be_falsey
    end

    it "validates custom restrictions" do
      assmt = @course.assignments.create!
      api_call(:put,
               @url,
               @params,
               { content_type: "assignment",
                 content_id: assmt.id,
                 restricted: "1",
                 restrictions: { "content" => "1", "not_a_real_thing" => "1" } },
               {},
               { expected_status: 400 })
    end

    it "is able to unset restrictions" do
      assmt = @course.assignments.create!
      mc_tag = @template.content_tag_for(assmt, { restrictions: @template.default_restrictions, use_default_restrictions: true })
      api_call(:put,
               @url,
               @params,
               { content_type: "assignment",
                 content_id: assmt.id,
                 restricted: "0" },
               {},
               { expected_status: 200 })
      mc_tag.reload
      expect(mc_tag.restrictions).to be_blank
      expect(mc_tag.use_default_restrictions).to be_falsey
    end

    it "uses default restrictions by object type if enabled" do
      assmt = @course.assignments.create!
      assmt_tag = @template.content_tag_for(assmt)
      page = @course.wiki_pages.create!(title: "blah")
      page_tag = @template.content_tag_for(page)

      assmt_restricts = { content: true, points: true }
      page_restricts = { content: true }
      @template.update(use_default_restrictions_by_type: true,
                       default_restrictions_by_type: { "Assignment" => assmt_restricts, "WikiPage" => page_restricts })

      api_call(:put, @url, @params, { content_type: "assignment", content_id: assmt.id, restricted: "1" }, {}, { expected_status: 200 })
      expect(assmt_tag.reload.restrictions).to eq assmt_restricts

      api_call(:put, @url, @params, { content_type: "wiki_page", content_id: page.id, restricted: "1" }, {}, { expected_status: 200 })
      expect(page_tag.reload.restrictions).to eq page_restricts
    end

    it "uses quiz object type restrictions if the quiz assignment is locked" do
      quiz_assmt = @course.assignments.create!(submission_types: "online_quiz").reload
      quiz = quiz_assmt.quiz
      quiz_tag = @template.content_tag_for(quiz)

      assmt_restricts = { content: true, points: true }
      quiz_restricts = { content: true }
      @template.update(use_default_restrictions_by_type: true,
                       default_restrictions_by_type: { "Assignment" => assmt_restricts, "Quizzes::Quiz" => quiz_restricts })

      api_call(:put, @url, @params, { content_type: "assignment", content_id: quiz_assmt.id, restricted: "1" }, {}, { expected_status: 200 })
      expect(quiz_tag.reload.restrictions).to eq quiz_restricts
    end
  end

  def run_master_migration(opts = {})
    @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @admin, opts)
    run_jobs
    @migration.reload
  end

  describe "migration_details / import_details" do
    before :once do
      Timecop.travel(1.hour.ago) do
        setup_template
        @master = @course
        @minions = (1..2).map do |n|
          @template.add_child_course!(course_factory(name: "Minion #{n}", active_all: true)).child_course
        end
        # set up some stuff
        @file = attachment_model(context: @master, display_name: "Some File")
        @assignment = @master.assignments.create! title: "Blah", points_possible: 10
      end

      Timecop.travel(55.minutes.ago) do
        @full_migration = run_master_migration
      end

      Timecop.travel(5.minutes.ago) do
        # prepare some exceptions
        @minions.first.attachments.first.update_attribute :display_name, "Some Renamed Nonsense"
        @minions.first.syllabus_body = "go away"
        @minions.first.save!
        @minions.last.assignments.first.update_attribute :points_possible, 11

        # now push some incremental changes
        @page = @master.wiki_pages.create! title: "Unicorn"
        page_tag = @template.content_tag_for(@page)
        page_tag.restrictions = @template.default_restrictions
        page_tag.save!
        @quiz = @master.quizzes.create! title: "TestQuiz"
        @file.update_attribute :display_name, "I Can Rename Files Too"
        @assignment.destroy
        @master.syllabus_body = "syllablah frd"
        @master.save!
        @external_assignment = @master.assignments.create!(title: "external tool assignment", submission_types: "external_tool")
        tag = @external_assignment.build_external_tool_tag(url: "http://example.com/tool")
        tag.content_type = "ContextExternalTool"
        tag.save!
      end
      run_master_migration(copy_settings: true)
    end

    it "returns change information from the blueprint side" do
      json = api_call_as_user(@admin,
                              :get,
                              "/api/v1/courses/#{@master.id}/blueprint_templates/default/migrations/#{@migration.id}/details",
                              controller: "master_courses/master_templates",
                              format: "json",
                              template_id: "default",
                              id: @migration.to_param,
                              course_id: @master.to_param,
                              action: "migration_details")
      expected_result = [
        { "asset_id" => @page.id,
          "asset_type" => "wiki_page",
          "asset_name" => "Unicorn",
          "change_type" => "created",
          "html_url" => "http://www.example.com/courses/#{@master.id}/pages/unicorn",
          "locked" => true,
          "exceptions" => [] },
        { "asset_id" => @quiz.id,
          "asset_type" => "quiz",
          "asset_name" => "TestQuiz",
          "change_type" => "created",
          "html_url" => "http://www.example.com/courses/#{@master.id}/quizzes/#{@quiz.id}",
          "locked" => false,
          "exceptions" => [] },
        { "asset_id" => @assignment.id,
          "asset_type" => "assignment",
          "asset_name" => "Blah",
          "change_type" => "deleted",
          "html_url" => "http://www.example.com/courses/#{@master.id}/assignments/#{@assignment.id}",
          "locked" => false,
          "exceptions" => [{ "course_id" => @minions.last.id, "conflicting_changes" => ["points"] }] },
        { "asset_id" => @file.id,
          "asset_type" => "attachment",
          "asset_name" => "I Can Rename Files Too",
          "change_type" => "updated",
          "html_url" => "http://www.example.com/courses/#{@master.id}/files/#{@file.id}",
          "locked" => false,
          "exceptions" => [{ "course_id" => @minions.first.id, "conflicting_changes" => ["content"] }] },
        { "asset_id" => @master.id,
          "asset_type" => "syllabus",
          "asset_name" => "Syllabus",
          "change_type" => "updated",
          "html_url" => "http://www.example.com/courses/#{@master.id}/assignments/syllabus",
          "locked" => false,
          "exceptions" => [{ "course_id" => @minions.first.id, "conflicting_changes" => ["content"] }] },
        { "asset_id" => @master.id,
          "asset_type" => "settings",
          "asset_name" => "Course Settings",
          "change_type" => "updated",
          "html_url" => "http://www.example.com/courses/#{@master.id}/settings",
          "locked" => false,
          "exceptions" => [] },
        { "asset_id" => @external_assignment.id,
          "asset_type" => "assignment",
          "asset_name" => "external tool assignment",
          "change_type" => "created",
          "html_url" => "http://www.example.com/courses/#{@master.id}/assignments/#{@external_assignment.id}",
          "locked" => false,
          "exceptions" => [] }
      ]
      expect(json).to match_array(expected_result)
    end

    it "returns change information from the minion side" do
      skip "Requires QtiMigrationTool" unless Qti.qti_enabled?

      minion = @minions.first
      minion_migration = minion.content_migrations.last
      minion_page = minion.wiki_pages.where(migration_id: @template.migration_id_for(@page)).first
      minion_assignment = minion.assignments.where(migration_id: @template.migration_id_for(@assignment)).first
      minion_file = minion.attachments.where(migration_id: @template.migration_id_for(@file)).first
      minion_quiz = minion.quizzes.where(migration_id: @template.migration_id_for(@quiz)).first
      minion_external_assignment = minion.assignments.where(migration_id: @template.migration_id_for(@external_assignment)).first
      json = api_call_as_user(minion.teachers.first,
                              :get,
                              "/api/v1/courses/#{minion.id}/blueprint_subscriptions/default/migrations/#{minion_migration.id}/details",
                              controller: "master_courses/master_templates",
                              format: "json",
                              subscription_id: "default",
                              id: minion_migration.to_param,
                              course_id: minion.to_param,
                              action: "import_details")
      expected_result = [
        { "asset_id" => minion_page.id,
          "asset_type" => "wiki_page",
          "asset_name" => "Unicorn",
          "change_type" => "created",
          "html_url" => "http://www.example.com/courses/#{minion.id}/pages/unicorn",
          "locked" => true,
          "exceptions" => [] },
        { "asset_id" => minion_quiz.id,
          "asset_type" => "quiz",
          "asset_name" => "TestQuiz",
          "change_type" => "created",
          "html_url" => "http://www.example.com/courses/#{minion.id}/quizzes/#{minion_quiz.id}",
          "locked" => false,
          "exceptions" => [] },
        { "asset_id" => minion_assignment.id,
          "asset_type" => "assignment",
          "asset_name" => "Blah",
          "change_type" => "deleted",
          "html_url" => "http://www.example.com/courses/#{minion.id}/assignments/#{minion_assignment.id}",
          "locked" => false,
          "exceptions" => [] },
        { "asset_id" => minion_file.id,
          "asset_type" => "attachment",
          "asset_name" => "Some Renamed Nonsense",
          "change_type" => "updated",
          "html_url" => "http://www.example.com/courses/#{minion.id}/files/#{minion_file.id}",
          "locked" => false,
          "exceptions" => [{ "course_id" => minion.id, "conflicting_changes" => ["content"] }] },
        { "asset_id" => minion.id,
          "asset_type" => "syllabus",
          "asset_name" => "Syllabus",
          "change_type" => "updated",
          "html_url" => "http://www.example.com/courses/#{minion.id}/assignments/syllabus",
          "locked" => false,
          "exceptions" => [{ "course_id" => minion.id, "conflicting_changes" => ["content"] }] },
        { "asset_id" => minion.id,
          "asset_type" => "settings",
          "asset_name" => "Course Settings",
          "change_type" => "updated",
          "html_url" => "http://www.example.com/courses/#{minion.id}/settings",
          "locked" => false,
          "exceptions" => [] },
        { "asset_id" => minion_external_assignment.id,
          "asset_type" => "assignment",
          "asset_name" => "external tool assignment",
          "change_type" => "created",
          "html_url" => "http://www.example.com/courses/#{minion.id}/assignments/#{minion_external_assignment.id}",
          "locked" => false,
          "exceptions" => [] }
      ]
      expect(json).to match_array(expected_result)
    end

    it "returns empty for a non-selective migration" do
      @template.add_child_course!(course_factory(name: "Minion 3"))
      json = api_call_as_user(@admin,
                              :get,
                              "/api/v1/courses/#{@master.id}/blueprint_templates/default/migrations/#{@full_migration.id}/details",
                              controller: "master_courses/master_templates",
                              format: "json",
                              template_id: "default",
                              id: @full_migration.to_param,
                              course_id: @master.to_param,
                              action: "migration_details")
      expect(json).to eq([])
    end

    it "is not tripped up by subscriptions created after the sync" do
      @template.add_child_course!(course_factory(name: "Minion 3"))
      api_call_as_user(@admin,
                       :get,
                       "/api/v1/courses/#{@master.id}/blueprint_templates/default/migrations/#{@migration.id}/details",
                       controller: "master_courses/master_templates",
                       format: "json",
                       template_id: "default",
                       id: @migration.to_param,
                       course_id: @master.to_param,
                       action: "migration_details")
      expect(response).to be_successful
    end

    it "requires manage rights on the course" do
      minion_migration = @minions.first.content_migrations.last
      api_call_as_user(@minions.last.teachers.first,
                       :get,
                       "/api/v1/courses/#{@minions.first.id}/blueprint_subscriptions/default/migrations/#{minion_migration.id}/details",
                       { controller: "master_courses/master_templates",
                         format: "json",
                         subscription_id: "default",
                         id: minion_migration.to_param,
                         course_id: @minions.first.to_param,
                         action: "import_details" },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "syncs syllabus content unless changed downstream" do
      expect(@minions.first.reload.syllabus_body).to include "go away"
      expect(@minions.last.reload.syllabus_body).to include "syllablah frd"
    end
  end

  describe "unsynced_changes" do
    before do
      local_storage!
      Timecop.travel(1.hour.ago) do
        setup_template
        @master = @course
        @template.add_child_course!(course_factory(name: "Minion"))
        @page = @master.wiki_pages.create! title: "Old News"
        @ann = @master.announcements.create! title: "Boring", message: "Yawn"
        @file = attachment_model(context: @master, display_name: "Some File")
        @folder = @master.folders.create!(name: "Blargh")
        @template.content_tag_for(@file).update_attribute(:restrictions, { content: true })
      end
    end

    it "reports an incomplete initial sync" do
      json = api_call_as_user(@admin,
                              :get,
                              "/api/v1/courses/#{@master.id}/blueprint_templates/default/unsynced_changes",
                              controller: "master_courses/master_templates",
                              format: "json",
                              template_id: "default",
                              course_id: @master.to_param,
                              action: "unsynced_changes")
      expect(json).to eq([{ "asset_name" => @master.name, "change_type" => "initial_sync" }])
    end

    context "after migration is run" do
      before do
        Timecop.travel(30.minutes.ago) do
          run_master_migration
        end
      end

      it "detects creates, updates, and deletes since the last sync" do
        @ann.destroy
        @file.update_attribute(:display_name, "Renamed")
        @folder.update_attribute(:name, "Blergh")
        @new_page = @master.wiki_pages.create! title: "New News"
        @master.syllabus_body = "srslywat"
        @master.save!

        json = api_call_as_user(@admin,
                                :get,
                                "/api/v1/courses/#{@master.id}/blueprint_templates/default/unsynced_changes",
                                controller: "master_courses/master_templates",
                                format: "json",
                                template_id: "default",
                                course_id: @master.to_param,
                                action: "unsynced_changes")
        expect(json).to match_array([
                                      { "asset_id" => @ann.id,
                                        "asset_type" => "announcement",
                                        "asset_name" => "Boring",
                                        "change_type" => "deleted",
                                        "html_url" => "http://www.example.com/courses/#{@master.id}/announcements/#{@ann.id}",
                                        "locked" => false },
                                      { "asset_id" => @file.id,
                                        "asset_type" => "attachment",
                                        "asset_name" => "Renamed",
                                        "change_type" => "updated",
                                        "html_url" => "http://www.example.com/courses/#{@master.id}/files/#{@file.id}",
                                        "locked" => true },
                                      { "asset_id" => @new_page.id,
                                        "asset_type" => "wiki_page",
                                        "asset_name" => "New News",
                                        "change_type" => "created",
                                        "html_url" => "http://www.example.com/courses/#{@master.id}/pages/new-news",
                                        "locked" => false },
                                      { "asset_id" => @folder.id,
                                        "asset_type" => "folder",
                                        "asset_name" => "Blergh",
                                        "change_type" => "updated",
                                        "html_url" => "http://www.example.com/courses/#{@master.id}/folders/#{@folder.id}",
                                        "locked" => false },
                                      { "asset_id" => @master.id,
                                        "asset_type" => "syllabus",
                                        "asset_name" => "Syllabus",
                                        "change_type" => "updated",
                                        "html_url" => "http://www.example.com/courses/#{@master.id}/assignments/syllabus",
                                        "locked" => false }
                                    ])
      end

      it "limits result size" do
        Setting.set("master_courses_history_count", "2")

        3.times { |x| @master.wiki_pages.create! title: "Page #{x}" }

        json = api_call_as_user(@admin,
                                :get,
                                "/api/v1/courses/#{@master.id}/blueprint_templates/default/unsynced_changes",
                                controller: "master_courses/master_templates",
                                format: "json",
                                template_id: "default",
                                course_id: @master.to_param,
                                action: "unsynced_changes")

        expect(json.length).to eq 2
      end
    end
  end

  describe "subscriptions_index" do
    before :once do
      setup_template
      @blueprint = @template.course
      @blueprint.update_attribute(:sis_source_id, "sisid")
      @minion = course_factory(name: "Minion", active_all: true)
      @subscription = @template.add_child_course!(@minion)
    end

    it "returns information about the subscription" do
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/courses/#{@minion.id}/blueprint_subscriptions",
                              controller: "master_courses/master_templates",
                              format: "json",
                              course_id: @minion.to_param,
                              action: "subscriptions_index")
      expect(json).to eq([{
                           "id" => @subscription.id,
                           "template_id" => @template.id,
                           "blueprint_course" => {
                             "id" => @blueprint.id,
                             "name" => @blueprint.name,
                             "course_code" => @blueprint.course_code,
                             "term_name" => @blueprint.enrollment_term.name
                           }
                         }])
    end

    it "includes sis_course_id if the caller has permission to see it" do
      json = api_call_as_user(@admin,
                              :get,
                              "/api/v1/courses/#{@minion.id}/blueprint_subscriptions",
                              controller: "master_courses/master_templates",
                              format: "json",
                              course_id: @minion.to_param,
                              action: "subscriptions_index")
      expect(json).to eq([{
                           "id" => @subscription.id,
                           "template_id" => @template.id,
                           "blueprint_course" => {
                             "id" => @blueprint.id,
                             "name" => @blueprint.name,
                             "course_code" => @blueprint.course_code,
                             "term_name" => @blueprint.enrollment_term.name,
                             "sis_course_id" => "sisid"
                           }
                         }])
    end

    it "returns an empty array if there is no subscription" do
      course_factory(active_all: true)
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/courses/#{@course.id}/blueprint_subscriptions",
                              controller: "master_courses/master_templates",
                              format: "json",
                              course_id: @course.to_param,
                              action: "subscriptions_index")
      expect(json).to eq([])
    end
  end
end
