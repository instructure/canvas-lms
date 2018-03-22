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

require_relative '../../api_spec_helper'

describe MasterCourses::MasterTemplatesController, type: :request do
  def setup_template
    Account.default.enable_feature!(:master_courses)
    course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    account_admin_user(:active_all => true)
    @base_params = {:controller => 'master_courses/master_templates', :format => 'json',
      :course_id => @course.id.to_s, :template_id => 'default'}
  end

  describe "#show" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default"
      @params = @base_params.merge(:action => 'show')
    end

    it "should require the feature flag" do
      Account.default.disable_feature!(:master_courses)
      api_call(:get, @url, @params, {}, {}, {:expected_status => 401})
    end

    it "should require authorization" do
      Account.default.role_overrides.create!(:role => admin_role, :permission => "manage_courses", :enabled => false)
      api_call(:get, @url, @params, {}, {}, {:expected_status => 401})
    end

    it "should let teachers in the master course view details" do
      course_with_teacher(:course => @course, :active_all => true)
      json = api_call(:get, @url, @params)
      expect(json['id']).to eq @template.id
    end

    it "should require am active template" do
      @template.destroy!
      api_call(:get, @url, @params, {}, {}, {:expected_status => 404})
    end

    it "should return stuff" do
      time = 2.days.ago
      @template.add_child_course!(Course.create!)
      mig = @template.master_migrations.create!(:imports_completed_at => time, :workflow_state => 'completed')
      @template.update_attribute(:active_migration_id, mig.id)
      json = api_call(:get, @url, @params)
      expect(json['id']).to eq @template.id
      expect(json['course_id']).to eq @course.id
      expect(json['last_export_completed_at']).to eq time.iso8601
      expect(json['associated_course_count']).to eq 1
      expect(json['latest_migration']['id']).to eq mig.id
      expect(json['latest_migration']['workflow_state']).to eq 'completed'
    end
  end

  describe "#associated_courses" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/associated_courses"
      @params = @base_params.merge(:action => 'associated_courses')
    end

    it "should get some data for associated courses" do
      term = Account.default.enrollment_terms.create!(:name => "termname")
      child_course1 = course_factory(:course_name => "immachildcourse1", :active_all => true)
      @teacher.update_attribute(:short_name, "displayname")
      child_course1.update_attributes(:sis_source_id => "sisid", :course_code => "shortname", :enrollment_term => term)
      child_course2 = course_factory(:course_name => "immachildcourse2")
      [child_course1, child_course2].each{|c| @template.add_child_course!(c)}

      json = api_call(:get, @url, @params)
      expect(json.count).to eq 2
      expect(json.map{|c| c['id']}).to match_array([child_course1.id, child_course2.id])
      course1_json = json.detect{|c| c['id'] == child_course1.id}
      expect(course1_json['name']).to eq child_course1.name
      expect(course1_json['course_code']).to eq child_course1.course_code
      expect(course1_json['term_name']).to eq term.name
      expect(course1_json['teachers'].first['display_name']).to eq @teacher.short_name
    end
  end

  describe "#update_associations" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/update_associations"
      @params = @base_params.merge(:action => 'update_associations')
    end

    it "should only add courses in the blueprint courses' account (or sub-accounts)" do
      sub1 = Account.default.sub_accounts.create!
      sub2 = Account.default.sub_accounts.create!
      @course.update_attribute(:account, sub1)

      other_course = course_factory(:account => sub2)

      json = api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]}, {}, {:expected_status => 400})
      expect(json['message']).to include("invalid courses")
    end

    it "should require account-level authorization" do
      course_with_teacher(:course => @course, :active_all => true)
      json = api_call(:put, @url, @params, {}, {}, {:expected_status => 401})
    end

    it "should require account-level blueprint permissions" do
      Account.default.role_overrides.create!(:role => admin_role, :permission => "manage_master_courses", :enabled => false)
      json = api_call(:put, @url, @params, {}, {}, {:expected_status => 401})
    end

    it "should not try to add other blueprint courses" do
      other_course = course_factory
      MasterCourses::MasterTemplate.set_as_master_course(other_course)

      json = api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]}, {}, {:expected_status => 400})
      expect(json['message']).to include("invalid courses")
    end

    it "should not try to add other blueprint-associated courses" do
      other_master_course = course_factory
      other_template = MasterCourses::MasterTemplate.set_as_master_course(other_master_course)
      other_course = course_factory
      other_template.add_child_course!(other_course)

      json = api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]}, {}, {:expected_status => 400})
      expect(json['message']).to include("cannot add courses already associated")
    end

    it "should skip existing associations" do
      other_course = course_factory
      @template.add_child_course!(other_course)

      expect_any_instantiation_of(@template).to receive(:add_child_course!).never
      api_call(:put, @url, @params, {:course_ids_to_add => [other_course.id]})
    end

    it "should be able to add and remove courses" do
      existing_child = course_factory
      existing_sub = @template.add_child_course!(existing_child)

      subaccount1 = Account.default.sub_accounts.create!
      subaccount2 = subaccount1.sub_accounts.create!
      c1 = course_factory(:account => subaccount1)
      c2 = course_factory(:account => subaccount2)

      api_call(:put, @url, @params, {:course_ids_to_add => [c1.id, c2.id], :course_ids_to_remove => existing_child.id})

      @template.reload
      expect(@template.child_subscriptions.active.pluck(:child_course_id)).to match_array([c1.id, c2.id])
    end
  end

  describe "#queue_migration" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations"
      @params = @base_params.merge(:action => 'queue_migration')
      @child_course = course_factory
      @sub = @template.add_child_course!(@child_course)
    end

    it "should require some associated courses" do
      @sub.destroy! # deleted ones shouldn't count
      json = api_call(:post, @url, @params, {}, {}, {:expected_status => 400})
      expect(json['message']).to include("No associated courses")
    end

    it "should not allow double-queueing" do
      MasterCourses::MasterMigration.start_new_migration!(@template, @user)

      json = api_call(:post, @url, @params, {}, {}, {:expected_status => 400})
      expect(json['message']).to include("currently running")
    end

    it "should queue a master migration" do
      json = api_call(:post, @url, @params.merge(:comment => 'seriously', :copy_settings => '1'))
      migration = @template.master_migrations.find(json['id'])
      expect(migration).to be_queued
      expect(migration.comment).to eq 'seriously'
      expect(migration.migration_settings[:copy_settings]).to eq true
      expect(migration.send_notification).to eq false
    end

    it "should accept the send_notification option" do
      json = api_call(:post, @url, @params.merge(:send_notification => true))
      migration = @template.master_migrations.find(json['id'])
      expect(migration).to be_queued
      expect(migration.send_notification).to eq true
    end
  end

  describe "migrations show/index" do
    before :once do
      setup_template
      @child_course = Account.default.courses.create!
      @sub = @template.add_child_course!(@child_course)
      @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @user, :comment => 'Hark!')
    end

    describe "blueprint side" do
      it "should show a migration" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations/#{@migration.id}",
          @base_params.merge(:action => 'migrations_show', :id => @migration.to_param))
        expect(json['workflow_state']).to eq 'queued'
        expect(json['comment']).to eq 'Hark!'
      end

      it "should show migrations" do
        run_jobs
        expect(@migration.reload).to be_completed
        migration2 = MasterCourses::MasterMigration.start_new_migration!(@template, @user)

        json = api_call(:get, "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations", @base_params.merge(:action => 'migrations_index'))
        pairs = json.map{|hash| [hash['id'], hash['workflow_state']]}
        expect(pairs).to eq [[migration2.id, 'queued'], [@migration.id, 'completed']]
      end

      it "should resolve an expired job if necessary" do
        MasterCourses::MasterMigration.where(:id => @migration.id).update_all(:created_at => 3.days.ago)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/blueprint_templates/default/migrations/#{@migration.id}",
          @base_params.merge(:action => 'migrations_show', :id => @migration.to_param))
        expect(json['workflow_state']).to eq 'exports_failed'
      end
    end

    describe "minion side" do
      before :once do
        run_jobs
        @minion_migration = @child_course.content_migrations.last
        teacher_in_course(:course => @child_course, :active_all => true)
      end

      it "should show a migration" do
        json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/#{@sub.id}/migrations/#{@minion_migration.id}",
                                @base_params.merge(:subscription_id => @sub.to_param, :course_id => @child_course.to_param, :action => 'imports_show', :id => @minion_migration.to_param))
        expect(json['workflow_state']).to eq 'completed'
        expect(json['subscription_id']).to eq @sub.id
        expect(json['comment']).to eq 'Hark!'
      end

      it "should show migrations" do
        json = api_call_as_user(@teacher, :get, "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/default/migrations",
                                @base_params.merge(:subscription_id => 'default', :course_id => @child_course.to_param, :action => 'imports_index'))
        expect(json.size).to eq 1
        expect(json[0]['id']).to eq @minion_migration.id
        expect(json[0]['subscription_id']).to eq @sub.id
      end

      it "filters by subscription and enumerates old subscriptions" do
        me = @teacher
        @sub.destroy
        other_master_course = course_model
        other_template = MasterCourses::MasterTemplate.set_as_master_course(other_master_course)
        other_sub = other_template.add_child_course!(@child_course)
        other_migration = MasterCourses::MasterMigration.start_new_migration!(other_template, @admin, :comment => 'Blah!')
        run_jobs

        json = api_call_as_user(me, :get, "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/default/migrations",
                                @base_params.merge(:subscription_id => 'default', :course_id => @child_course.to_param, :action => 'imports_index'))
        expect(json.size).to eq 1
        expect(json[0]['subscription_id']).to eq other_sub.id
        expect(json[0]['comment']).to eq "Blah!"

        json = api_call_as_user(me, :get, "/api/v1/courses/#{@child_course.id}/blueprint_subscriptions/#{@sub.id}/migrations",
                                @base_params.merge(:subscription_id => @sub.to_param, :course_id => @child_course.to_param, :action => 'imports_index'))
        expect(json.size).to eq 1
        expect(json[0]['subscription_id']).to eq @sub.id
        expect(json[0]['comment']).to eq "Hark!"
      end
    end
  end

  describe "#restrict_item" do
    before :once do
      setup_template
      @url = "/api/v1/courses/#{@course.id}/blueprint_templates/default/restrict_item"
      @params = @base_params.merge(:action => 'restrict_item')
    end

    it "should validate content type" do
      json = api_call(:put, @url, @params, {:content_type => 'passignment', :content_id => "2", :restricted => '1'}, {}, {:expected_status => 400})
      expect(json['message']).to include("Must be a valid content type")
    end

    it "should give a useful error when content is missing" do
      other_course = Course.create!
      other_assmt = other_course.assignments.create!
      json = api_call(:put, @url, @params, {:content_type => 'assignment', :content_id => other_assmt.id, :restricted => '1'}, {}, {:expected_status => 404})
      expect(json['message']).to include("Could not find content")
    end

    it "should be able to find all the (currently) supported types" do
      expect(@template.default_restrictions[:content]).to be_truthy

      assmt = @course.assignments.create!
      topic = @course.discussion_topics.create!(:message => "hi", :title => "discussion title")
      page = @course.wiki_pages.create!(:title => "wiki", :body => "ohai")
      quiz = @course.quizzes.create!
      file = @course.attachments.create!(:filename => 'blah', :uploaded_data => default_uploaded_data)
      tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key",
        :shared_secret => "secret", :custom_fields => {'a' => '1', 'b' => '2'}, :url => "http://www.example.com")

      type_pairs = {'assignment' => assmt, 'attachment' => file, 'discussion_topic' => topic,
        'external_tool' => tool, 'quiz' => quiz, 'wiki_page' => page}
      type_pairs.each do |content_type, obj|
        api_call(:put, @url, @params, {:content_type => content_type, :content_id => obj.id, :restricted => '1'}, {}, {:expected_status => 200})
        mc_tag = @template.content_tag_for(obj)
        expect(mc_tag.restrictions).to eq @template.default_restrictions
        expect(mc_tag.use_default_restrictions).to be_truthy
      end
    end

    it "should be able to set custom restrictions" do
      assmt = @course.assignments.create!
      api_call(:put, @url, @params, {:content_type => 'assignment', :content_id => assmt.id,
        :restricted => '1', :restrictions => {'content' => '1', 'points' => '1'}}, {}, {:expected_status => 200})

      mc_tag = @template.content_tag_for(assmt)
      expect(mc_tag.restrictions).to eq({:content => true, :points => true})
      expect(mc_tag.use_default_restrictions).to be_falsey
    end

    it "should validate custom restrictions" do
      assmt = @course.assignments.create!
      api_call(:put, @url, @params, {:content_type => 'assignment', :content_id => assmt.id,
        :restricted => '1', :restrictions => {'content' => '1', 'not_a_real_thing' => '1'}}, {}, {:expected_status => 400})
    end

    it "should be able to unset restrictions" do
      assmt = @course.assignments.create!
      mc_tag = @template.content_tag_for(assmt, {:restrictions => @template.default_restrictions, :use_default_restrictions => true})
      api_call(:put, @url, @params, {:content_type => 'assignment', :content_id => assmt.id,
        :restricted => '0'}, {}, {:expected_status => 200})
      mc_tag.reload
      expect(mc_tag.restrictions).to be_blank
      expect(mc_tag.use_default_restrictions).to be_falsey
    end

    it "should use default restrictions by object type if enabled" do
      assmt = @course.assignments.create!
      assmt_tag = @template.content_tag_for(assmt)
      page = @course.wiki_pages.create!(:title => "blah")
      page_tag = @template.content_tag_for(page)

      assmt_restricts = {:content => true, :points => true}
      page_restricts = {:content => true}
      @template.update_attributes(:use_default_restrictions_by_type => true,
        :default_restrictions_by_type => {'Assignment' => assmt_restricts, 'WikiPage' => page_restricts})

      api_call(:put, @url, @params, {:content_type => 'assignment', :content_id => assmt.id, :restricted => '1'}, {}, {:expected_status => 200})
      expect(assmt_tag.reload.restrictions).to eq assmt_restricts

      api_call(:put, @url, @params, {:content_type => 'wiki_page', :content_id => page.id, :restricted => '1'}, {}, {:expected_status => 200})
      expect(page_tag.reload.restrictions).to eq page_restricts
    end

    it "should use quiz object type restrictions if the quiz assignment is locked" do
      quiz_assmt = @course.assignments.create!(:submission_types => 'online_quiz').reload
      quiz = quiz_assmt.quiz
      quiz_tag = @template.content_tag_for(quiz)

      assmt_restricts = {:content => true, :points => true}
      quiz_restricts = {:content => true}
      @template.update_attributes(:use_default_restrictions_by_type => true,
        :default_restrictions_by_type => {'Assignment' => assmt_restricts, 'Quizzes::Quiz' => quiz_restricts})

      api_call(:put, @url, @params, {:content_type => 'assignment', :content_id => quiz_assmt.id, :restricted => '1'}, {}, {:expected_status => 200})
      expect(quiz_tag.reload.restrictions).to eq quiz_restricts
    end
  end

  def run_master_migration
    @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @admin)
    run_jobs
    @migration.reload
  end

  describe "migration_details / import_details" do
    before :once do
      setup_template
      @master = @course
      @minions = (1..2).map do |n|
        @template.add_child_course!(course_factory(:name => "Minion #{n}", :active_all => true)).child_course
      end

      # set up some stuff
      @file = attachment_model(:context => @master, :display_name => 'Some File')
      @assignment = @master.assignments.create! :title => 'Blah', :points_possible => 10
      @full_migration = run_master_migration

      # prepare some exceptions
      @minions.first.attachments.first.update_attribute :display_name, 'Some Renamed Nonsense'
      @minions.last.assignments.first.update_attribute :points_possible, 11

      # now push some incremental changes
      @page = @master.wiki_pages.create! :title => 'Unicorn'
      page_tag = @template.content_tag_for(@page)
      page_tag.restrictions = @template.default_restrictions
      page_tag.save!
      @quiz = @master.quizzes.create! :title => 'TestQuiz'
      @file.update_attribute :display_name, 'I Can Rename Files Too'
      @assignment.destroy
      run_master_migration
    end

    it "returns change information from the blueprint side" do
      json = api_call_as_user(@admin, :get, "/api/v1/courses/#{@master.id}/blueprint_templates/default/migrations/#{@migration.id}/details",
                 :controller => 'master_courses/master_templates', :format => 'json', :template_id => 'default',
                 :id => @migration.to_param, :course_id => @master.to_param, :action => 'migration_details')
      expect(json).to match_array([
         {"asset_id"=>@page.id,"asset_type"=>"wiki_page","asset_name"=>"Unicorn","change_type"=>"created",
          "html_url"=>"http://www.example.com/courses/#{@master.id}/pages/unicorn","locked"=>true,"exceptions"=>[]},
         {"asset_id"=>@quiz.id,"asset_type"=>"quiz","asset_name"=>"TestQuiz","change_type"=>"created",
          "html_url"=>"http://www.example.com/courses/#{@master.id}/quizzes/#{@quiz.id}","locked"=>false,"exceptions"=>[]},
         {"asset_id"=>@assignment.id,"asset_type"=>"assignment","asset_name"=>"Blah","change_type"=>"deleted",
          "html_url"=>"http://www.example.com/courses/#{@master.id}/assignments/#{@assignment.id}",
          "locked"=>false,"exceptions"=>[{"course_id"=>@minions.last.id, "conflicting_changes"=>["points"]}]},
         {"asset_id"=>@file.id,"asset_type"=>"attachment","asset_name"=>"I Can Rename Files Too",
          "change_type"=>"updated","html_url"=>"http://www.example.com/courses/#{@master.id}/files/#{@file.id}",
          "locked"=>false,"exceptions"=>[{"course_id"=>@minions.first.id, "conflicting_changes"=>["content"]}]}
      ])
    end

    it "returns change information from the minion side" do
      skip 'Requires QtiMigrationTool' unless Qti.qti_enabled?

      minion = @minions.first
      minion_migration = minion.content_migrations.last
      minion_page = minion.wiki_pages.where(migration_id: @template.migration_id_for(@page)).first
      minion_assignment = minion.assignments.where(migration_id: @template.migration_id_for(@assignment)).first
      minion_file = minion.attachments.where(migration_id: @template.migration_id_for(@file)).first
      minion_quiz = minion.quizzes.where(migration_id: @template.migration_id_for(@quiz)).first
      json = api_call_as_user(minion.teachers.first, :get,
                 "/api/v1/courses/#{minion.id}/blueprint_subscriptions/default/migrations/#{minion_migration.id}/details",
                 :controller => 'master_courses/master_templates', :format => 'json', :subscription_id => 'default',
                 :id => minion_migration.to_param, :course_id => minion.to_param, :action => 'import_details')
      expect(json).to match_array([
         {"asset_id"=>minion_page.id,"asset_type"=>"wiki_page","asset_name"=>"Unicorn","change_type"=>"created",
          "html_url"=>"http://www.example.com/courses/#{minion.id}/pages/unicorn","locked"=>true,"exceptions"=>[]},
         {"asset_id"=>minion_quiz.id,"asset_type"=>"quiz","asset_name"=>"TestQuiz","change_type"=>"created",
          "html_url"=>"http://www.example.com/courses/#{minion.id}/quizzes/#{minion_quiz.id}","locked"=>false,"exceptions"=>[]},
         {"asset_id"=>minion_assignment.id,"asset_type"=>"assignment","asset_name"=>"Blah","change_type"=>"deleted",
          "html_url"=>"http://www.example.com/courses/#{minion.id}/assignments/#{minion_assignment.id}","locked"=>false,"exceptions"=>[]},
         {"asset_id"=>minion_file.id,"asset_type"=>"attachment","asset_name"=>"Some Renamed Nonsense",
          "change_type"=>"updated","html_url"=>"http://www.example.com/courses/#{minion.id}/files/#{minion_file.id}",
          "locked"=>false,"exceptions"=>[{"course_id"=>minion.id, "conflicting_changes"=>["content"]}]}
      ])
    end

    it "returns empty for a non-selective migration" do
      @template.add_child_course!(course_factory(:name => 'Minion 3'))
      json = api_call_as_user(@admin, :get, "/api/v1/courses/#{@master.id}/blueprint_templates/default/migrations/#{@full_migration.id}/details",
                 :controller => 'master_courses/master_templates', :format => 'json', :template_id => 'default',
                 :id => @full_migration.to_param, :course_id => @master.to_param, :action => 'migration_details')
      expect(json).to eq([])
    end

    it "is not tripped up by subscriptions created after the sync" do
      @template.add_child_course!(course_factory(:name => 'Minion 3'))
      api_call_as_user(@admin, :get, "/api/v1/courses/#{@master.id}/blueprint_templates/default/migrations/#{@migration.id}/details",
                 :controller => 'master_courses/master_templates', :format => 'json', :template_id => 'default',
                 :id => @migration.to_param, :course_id => @master.to_param, :action => 'migration_details')
      expect(response).to be_success
    end

    it "requires manage rights on the course" do
      minion_migration = @minions.first.content_migrations.last
      api_call_as_user(@minions.last.teachers.first, :get,
                 "/api/v1/courses/#{@minions.first.id}/blueprint_subscriptions/default/migrations/#{minion_migration.id}/details",
                 { :controller => 'master_courses/master_templates', :format => 'json', :subscription_id => 'default',
                   :id => minion_migration.to_param, :course_id => @minions.first.to_param, :action => 'import_details' },
                 {}, {}, { :expected_status => 401 })
    end
  end

  describe 'unsynced_changes' do
    before do
      local_storage!
      Timecop.travel(1.hour.ago) do
        setup_template
        @master = @course
        @template.add_child_course!(course_factory(:name => 'Minion'))
        @page = @master.wiki_pages.create! :title => 'Old News'
        @ann = @master.announcements.create! :title => 'Boring', :message => 'Yawn'
        @file = attachment_model(:context => @master, :display_name => 'Some File')
        @folder = @master.folders.create!(:name => 'Blargh')
        @template.content_tag_for(@file).update_attribute(:restrictions, {:content => true})
        run_master_migration
      end
    end

    it 'detects creates, updates, and deletes since the last sync' do
      @ann.destroy
      @file.update_attribute(:display_name, 'Renamed')
      @folder.update_attribute(:name, 'Blergh')
      @new_page = @master.wiki_pages.create! :title => 'New News'

      json = api_call_as_user(@admin, :get, "/api/v1/courses/#{@master.id}/blueprint_templates/default/unsynced_changes",
        :controller => 'master_courses/master_templates', :format => 'json', :template_id => 'default',
        :course_id => @master.to_param, :action => 'unsynced_changes')
      expect(json).to match_array([
       {"asset_id"=>@ann.id,"asset_type"=>"announcement","asset_name"=>"Boring","change_type"=>"deleted",
        "html_url"=>"http://www.example.com/courses/#{@master.id}/announcements/#{@ann.id}","locked"=>false},
       {"asset_id"=>@file.id,"asset_type"=>"attachment","asset_name"=>"Renamed","change_type"=>"updated",
        "html_url"=>"http://www.example.com/courses/#{@master.id}/files/#{@file.id}","locked"=>true},
       {"asset_id"=>@new_page.id,"asset_type"=>"wiki_page","asset_name"=>"New News","change_type"=>"created",
        "html_url"=>"http://www.example.com/courses/#{@master.id}/pages/new-news","locked"=>false},
       {"asset_id"=>@folder.id,"asset_type"=>"folder","asset_name"=>"Blergh","change_type"=>"updated",
        "html_url"=>"http://www.example.com/courses/#{@master.id}/folders/#{@folder.id}","locked"=>false},
      ])
    end

    it "limits result size" do
      Setting.set('master_courses_history_count', '2')

      3.times { |x| @master.wiki_pages.create! :title => "Page #{x}" }

      json = api_call_as_user(@admin, :get, "/api/v1/courses/#{@master.id}/blueprint_templates/default/unsynced_changes",
        :controller => 'master_courses/master_templates', :format => 'json', :template_id => 'default',
        :course_id => @master.to_param, :action => 'unsynced_changes')

      expect(json.length).to eq 2
    end
  end
end
