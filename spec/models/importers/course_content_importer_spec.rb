# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe Course do
  describe "import_content" do
    before(:once) do
      @course = course_factory()
    end

    it "should import a whole json file" do
      local_storage!

      # TODO: pull this out into smaller tests... right now I'm using
      # the whole example JSON from Bracken because the formatting is
      # somewhat in flux
      json = File.open(File.join(IMPORT_JSON_DIR, 'import_from_migration.json')).read
      data = JSON.parse(json).with_indifferent_access
      data['all_files_export'] = {
        'file_path' => File.join(IMPORT_JSON_DIR, 'import_from_migration_small.zip')
      }
      migration = ContentMigration.create!(:context => @course, started_at: Time.zone.now)
      allow(migration).to receive(:canvas_import?).and_return(true)

      params = {:copy => {
        :topics => {'1864019689002' => true, '1865116155002' => true},
        :announcements => {'4488523052421' => true},
        :files => {'1865116527002' => true, '1865116044002' => true, '1864019880002' => true, '1864019921002' => true},
        :rubrics => {'4469882249231' => true},
        :events => {},
        :modules => {'1864019977002' => true, '1865116190002' => true},
        :assignments => {
          '1865116014002' => true,
          '1865116155002' => true,
          '4407365899221' => true,
          '4469882339231' => true
        },
        :outline_folders => {'1865116206002' => true, '1865116207002' => true},
        :quizzes => {'1865116175002' => true},
        :all_course_outline => true,
        :all_groups => true,
        :shift_dates=>"1",
        :old_start_date=>"Jan 23, 2009",
        :old_end_date=>"Apr 10, 2009",
        :new_start_date=>"Jan 3, 2011",
        :new_end_date=>"Apr 13, 2011"
      }}.with_indifferent_access
      migration.migration_ids_to_import = params

      expect(migration).to receive(:trigger_live_events!).once

      # tool profile tests
      expect(Importers::ToolProfileImporter).to receive(:process_migration)

      Importers::CourseContentImporter.import_content(@course, data, params, migration)
      @course.reload

      # discussion topic tests
      expect(@course.discussion_topics.length).to eq(3)
      migration_ids = ["1864019689002", "1865116155002", "4488523052421"].sort
      added_migration_ids = @course.discussion_topics.map(&:migration_id).uniq.sort
      expect(added_migration_ids).to eq(migration_ids)
      topic = @course.discussion_topics.where(migration_id: "1864019689002").first
      expect(topic).not_to be_nil
      expect(topic.title).to eq("Post here for group events, etc.")
      expect(topic.discussion_entries).to be_empty
      topic = @course.discussion_topics.where(migration_id: "1865116155002").first
      expect(topic).not_to be_nil
      expect(topic.assignment).not_to be_nil

      # quizzes
      expect(@course.quizzes.length).to eq(1)
      quiz = @course.quizzes.first
      quiz.migration_id = '1865116175002'
      expect(quiz.title).to eq("Orientation Quiz")

      # wiki pages tests
      migration_ids = ["1865116206002", "1865116207002"].sort
      added_migration_ids = @course.wiki_pages.map(&:migration_id).uniq.sort
      expect(added_migration_ids).to eq(migration_ids)
      expect(@course.wiki_pages.length).to eq(migration_ids.length)
      # front page
      page = @course.wiki.front_page
      expect(page).not_to be_nil
      expect(page.migration_id).to eq("1865116206002")
      expect(page.body).not_to be_nil
      expect(page.body.scan(/<li>/).length).to eq(4)
      expect(page.body).to match(/Orientation/)
      expect(page.body).to match(/Orientation Quiz/)
      file = @course.attachments.where(migration_id: "1865116527002").first
      expect(file).not_to be_nil
      re = Regexp.new("\\/courses\\/#{@course.id}\\/files\\/#{file.id}\\/preview")
      expect(page.body).to match(re)

      # assignment tests
      @course.reload
      expect(@course.assignments.length).to eq 4
      expect(@course.assignments.map(&:migration_id).sort).to(
        eq(['1865116155002', '1865116014002', '4407365899221', '4469882339231'].sort))
      # assignment with due date
      assignment = @course.assignments.where(migration_id: "1865116014002").first
      expect(assignment).not_to be_nil
      expect(assignment.title).to eq("Concert Review Assignment")
      expect(assignment.description).to match(Regexp.new("USE THE TEXT BOX!  DO NOT ATTACH YOUR ASSIGNMENT!!"))
      # The old due date (Fri Mar 27 23:55:00 -0600 2009) should have been adjusted to new time frame
      expect(assignment.due_at.year).to eq 2011
      # overrides
      expect(assignment.assignment_overrides.count).to eq 1
      expect(assignment.assignment_overrides.first.due_at.year).to eq 2011

      # discussion topic assignment
      assignment = @course.assignments.where(migration_id: "1865116155002").first
      expect(assignment).not_to be_nil
      expect(assignment.title).to eq("Introduce yourself!")
      expect(assignment.points_possible).to eq(10.0)
      expect(assignment.discussion_topic).not_to be_nil
      # assignment with rubric
      assignment = @course.assignments.where(migration_id: "4469882339231").first
      expect(assignment).not_to be_nil
      expect(assignment.title).to eq("Rubric assignment")
      expect(assignment.rubric).not_to be_nil
      expect(assignment.rubric.migration_id).to eq("4469882249231")
      # assignment with file
      assignment = @course.assignments.where(migration_id: "4407365899221").first
      expect(assignment).not_to be_nil
      expect(assignment.title).to eq("new assignment")
      file = @course.attachments.where(migration_id: "1865116527002").first
      expect(file).not_to be_nil
      expect(assignment.description).to match(Regexp.new("/files/#{file.id}/download"))

      # calendar events
      expect(@course.calendar_events).to be_empty

      # rubrics
      expect(@course.rubrics.length).to eq(1)
      rubric = @course.rubrics.first
      expect(rubric.data.length).to eq(3)
      # Spelling
      criterion = rubric.data[0].with_indifferent_access
      expect(criterion["description"]).to eq("Spelling")
      expect(criterion["points"]).to eq(15.0)
      expect(criterion["ratings"].length).to eq(3)
      expect(criterion["ratings"][0]["points"]).to eq(15.0)
      expect(criterion["ratings"][0]["description"]).to eq("Exceptional - fff")
      expect(criterion["ratings"][1]["points"]).to eq(10.0)
      expect(criterion["ratings"][1]["description"]).to eq("Meet Expectations - asdf")
      expect(criterion["ratings"][2]["points"]).to eq(5.0)
      expect(criterion["ratings"][2]["description"]).to eq("Need Improvement - rubric entry text")

      # Grammar
      criterion = rubric.data[1]
      expect(criterion["description"]).to eq("Grammar")
      expect(criterion["points"]).to eq(15.0)
      expect(criterion["ratings"].length).to eq(3)
      expect(criterion["ratings"][0]["points"]).to eq(15.0)
      expect(criterion["ratings"][0]["description"]).to eq("Exceptional")
      expect(criterion["ratings"][1]["points"]).to eq(10.0)
      expect(criterion["ratings"][1]["description"]).to eq("Meet Expectations")
      expect(criterion["ratings"][2]["points"]).to eq(5.0)
      expect(criterion["ratings"][2]["description"]).to eq("Need Improvement - you smell")

      # Style
      criterion = rubric.data[2]
      expect(criterion["description"]).to eq("Style")
      expect(criterion["points"]).to eq(15.0)
      expect(criterion["ratings"].length).to eq(3)
      expect(criterion["ratings"][0]["points"]).to eq(15.0)
      expect(criterion["ratings"][0]["description"]).to eq("Exceptional")
      expect(criterion["ratings"][1]["points"]).to eq(10.0)
      expect(criterion["ratings"][1]["description"]).to eq("Meet Expectations")
      expect(criterion["ratings"][2]["points"]).to eq(5.0)
      expect(criterion["ratings"][2]["description"]).to eq("Need Improvement")

      # groups
      expect(@course.groups.length).to eq(2)

      # files
      expect(@course.attachments.length).to eq(4)
      @course.attachments.each do |f|
        expect(File).to be_exist(f.full_filename)
      end
      file = @course.attachments.where(migration_id: "1865116044002").first
      expect(file).not_to be_nil
      expect(file.filename).to eq("theatre_example.htm")
      expect(file.folder.full_name).to eq("course files/Writing Assignments/Examples")
      file = @course.attachments.where(migration_id: "1864019880002").first
      expect(file).not_to be_nil
      expect(file.filename).to eq("dropbox.zip")
      expect(file.folder.full_name).to eq("course files/Course Content/Orientation/WebCT specific and old stuff")
    end

    def build_migration(import_course, params, copy_options={})
      migration = ContentMigration.create!(:context => import_course)
      migration.migration_settings[:migration_ids_to_import] = params
      migration.migration_settings[:copy_options] = copy_options
      migration.save!
      migration
    end

    def setup_import(import_course, filename, migration)
      json = File.open(File.join(IMPORT_JSON_DIR, filename)).read
      data = JSON.parse(json).with_indifferent_access
      Importers::CourseContentImporter.import_content(
        import_course,
        data,
        migration.migration_settings[:migration_ids_to_import],
        migration
      )
    end

    it "should not duplicate assessment questions in question banks" do
      params = {:copy => {"everything" => true}}
      migration = build_migration(@course, params)
      setup_import(@course, 'assessments.json', migration)

      aqb1 = @course.assessment_question_banks.where(migration_id: "ic0f7230f2694436788cedf4d6e93ce252483978f878b8050a390d5940e78737b").first
      expect(aqb1.assessment_questions.count).to eq 3
      aqb2 = @course.assessment_question_banks.where(migration_id: "i71b5a954dcd0e22e59adc1032a75e8c2e1b8176f203bdf110a9ac97e4fed1754").first
      expect(aqb2.assessment_questions.count).to eq 2
      expect(migration.workflow_state).to eq('imported')
    end

    it "should not create assessment question banks if they are not selected" do
      params = {"copy" => {"assessment_question_banks" => {"ic0f7230f2694436788cedf4d6e93ce252483978f878b8050a390d5940e78737b" => true},
                           "quizzes" => {"i7ed12d5eade40d9ee8ecb5300b8e02b2" => true,
                                         "ife86eb19e30869506ee219b17a6a1d4e" => true}}}

      migration = build_migration(@course, params)
      setup_import(@course, 'assessments.json', migration)

      expect(@course.assessment_question_banks.count).to eq 1
      aqb1 = @course.assessment_question_banks.where(migration_id: "ic0f7230f2694436788cedf4d6e93ce252483978f878b8050a390d5940e78737b").first
      expect(aqb1.assessment_questions.count).to eq 3
      expect(@course.assessment_questions.count).to eq 3

      expect(@course.quizzes.count).to eq 2
      quiz1 = @course.quizzes.where(migration_id: "i7ed12d5eade40d9ee8ecb5300b8e02b2").first
      quiz1.quiz_questions.preload(:assessment_question).each{|qq| expect(qq.assessment_question).not_to be_nil }

      quiz2 = @course.quizzes.where(migration_id: "ife86eb19e30869506ee219b17a6a1d4e").first
      quiz2.quiz_questions.preload(:assessment_question).each{|qq| expect(qq.assessment_question).to be_nil } # since the bank wasn't brought in
      expect(migration.workflow_state).to eq('imported')
    end

    it "should lock announcements if 'lock_all_annoucements' setting is true" do
      @course.update_attribute(:lock_all_announcements, true)
      params = {"copy" => {"announcements" => {"4488523052421" => true}}}
      migration = build_migration(@course, params, all_course_settings: true)
      setup_import(@course, 'announcements.json', migration)

      ann = @course.announcements.first
      expect(ann).to be_locked
      expect(migration.workflow_state).to eq('imported')
    end

    it "should not lock announcements if 'lock_all_annoucements' setting is false" do
      @course.update_attribute(:lock_all_announcements, false)
      params = {"copy" => {"announcements" => {"4488523052421" => true}}}
      migration = build_migration(@course, params, all_course_settings: true)
      setup_import(@course, 'announcements.json', migration)

      ann = @course.announcements.first
      expect(ann).to_not be_locked
      expect(migration.workflow_state).to eq('imported')
    end

    it "runs DueDateCacher never if no assignments are imported" do
      params = {:copy => {"everything" => true}}
      migration = build_migration(@course, params)
      @course.reload # seems to be holding onto saved_changes for some reason

      expect(DueDateCacher).to receive(:recompute_course).never
      setup_import(@course, 'assessments.json', migration)
      expect(migration.workflow_state).to eq('imported')
    end

    it "runs DueDateCacher once if assignments with dates are imported" do
      params = {:copy => {"everything" => true}}
      migration = build_migration(@course, params)
      @course.reload

      expect(DueDateCacher).to receive(:recompute_course).once
      json = File.open(File.join(IMPORT_JSON_DIR, 'assignment.json')).read
      @data = {"assignments" => JSON.parse(json)}.with_indifferent_access
      Importers::CourseContentImporter.import_content(
        @course, @data, migration.migration_settings[:migration_ids_to_import], migration
      )
      expect(migration.workflow_state).to eq('imported')
    end

    it "automatically restores assignment groups for object assignment types (i.e. topics/quizzes)" do
      params = {:copy => {"assignments" => {"gf455e2add230724ba190bb20c1491aa9" => true}}}
      migration = build_migration(@course, params)
      setup_import(@course, 'discussion_assignments.json', migration)
      a1 = @course.assignments.where(:migration_id => "gf455e2add230724ba190bb20c1491aa9").take
      a1.assignment_group.destroy!

      # import again but just the discus
      params = {:copy => {"discussion_topics" => {"g8bacee869e70bf19cd6784db3efade7e" => true}}}
      migration = build_migration(@course, params)
      setup_import(@course, 'discussion_assignments.json', migration)
      dt = @course.discussion_topics.where(:migration_id => "g8bacee869e70bf19cd6784db3efade7e").take
      expect(dt.assignment.assignment_group).to eq a1.assignment_group
      expect(dt.assignment.assignment_group).to_not be_deleted
      expect(a1.reload).to be_deleted # didn't restore the previously deleted assignment too
    end

    context "when it is a Quizzes.Next migration" do
      let(:migration) do
        params = {:copy => {"everything" => true}}
        build_migration(@course, params)
      end

      before do
        allow(migration).to receive(:quizzes_next_migration?).and_return(true)
      end

      it "shouldn't set workflow_state to imported" do
        setup_import(@course, 'assessments.json', migration)
        expect(migration.workflow_state).not_to eq('imported')
      end
    end

    describe "default_post_policy" do
      let(:migration) do
        build_migration(@course, {}, all_course_settings: true)
      end

      it "sets the course to manually-posted when default_post_policy['post_manually'] is true" do
        import_data = {"course": {"default_post_policy": {"post_manually": true}}}.with_indifferent_access
        Importers::CourseContentImporter.import_content(@course, import_data, nil, migration)

        expect(@course.default_post_policy).to be_post_manually
      end

      it "sets the course to auto-posted when default_post_policy['post_manually'] is false" do
        @course.default_post_policy.update!(post_manually: true)
        import_data = {"course": {"default_post_policy": {"post_manually": false}}}.with_indifferent_access
        Importers::CourseContentImporter.import_content(@course, import_data, nil, migration)

        expect(@course.default_post_policy).not_to be_post_manually
      end

      it "does not update the course's post policy when default_post_policy['post_manually'] is missing" do
        @course.default_post_policy.update!(post_manually: true)
        import_data = {"course": {}}.with_indifferent_access
        Importers::CourseContentImporter.import_content(@course, import_data, nil, migration)

        expect(@course.default_post_policy).to be_post_manually
      end
    end
  end

  describe "shift_date_options" do
    it "should default options[:time_zone] to the root account's time zone" do
      account = Account.default.sub_accounts.create!
      course_with_teacher(account: account)
      @course.root_account.default_time_zone = 'America/New_York'
      @course.start_at = 1.month.ago
      @course.conclude_at = 1.month.from_now
      options = Importers::CourseContentImporter.shift_date_options(@course, {})
      expect(options[:time_zone]).to eq ActiveSupport::TimeZone['Eastern Time (US & Canada)']
    end
  end

  describe "shift_date" do
    it "should round sanely" do
      course_factory
      @course.root_account.default_time_zone = Time.zone
      options = Importers::CourseContentImporter.shift_date_options(@course, {
          old_start_date: '2014-3-2',  old_end_date: '2014-4-26',
          new_start_date: '2014-5-11', new_end_date: '2014-7-5'
      })
      unlock_at = DateTime.new(2014, 3, 23,  0,  0)
      due_at    = DateTime.new(2014, 3, 29, 23, 59)
      lock_at   = DateTime.new(2014, 4,  1, 23, 59)

      new_unlock_at = Importers::CourseContentImporter.shift_date(unlock_at, options)
      new_due_at    = Importers::CourseContentImporter.shift_date(due_at, options)
      new_lock_at   = Importers::CourseContentImporter.shift_date(lock_at, options)

      expect(new_unlock_at).to eq DateTime.new(2014, 6,  1,  0,  0)
      expect(new_due_at).to    eq DateTime.new(2014, 6,  7, 23, 59)
      expect(new_lock_at).to   eq DateTime.new(2014, 6, 10, 23, 59)
    end

    it "should return error when removing dates and new_sis_integrations is enabled" do
      course_factory
      @course.root_account.enable_feature!(:new_sis_integrations)
      @course.root_account.settings[:sis_syncing] = true
      @course.root_account.settings[:sis_require_assignment_due_date] = true
      @course.root_account.save!
      @course.account.enable_feature!(:new_sis_integrations)
      @course.account.settings[:sis_syncing] = true
      @course.account.settings[:sis_require_assignment_due_date] = true
      @course.account.save!

      assignment = @course.assignments.create!(due_at: Time.now + 1.day)
      assignment.post_to_sis = true
      assignment.due_at = Time.now + 1.day
      assignment.name = "lalala"
      assignment.save!

      migration = ContentMigration.create!(:context => @course)
      migration.migration_ids_to_import = {:copy => { :copy_options => { :all_assignments => "1" } }}.with_indifferent_access
      migration.migration_settings[:date_shift_options] = Importers::CourseContentImporter.shift_date_options(@course, { remove_dates: true })
      migration.add_imported_item(assignment)
      migration.source_course = @course
      migration.initiated_source = :manual
      migration.user = @user
      migration.save!

      Importers::CourseContentImporter.adjust_dates(@course, migration)
      expect(migration.warnings.length).to eq 1
      expect(migration.warnings[0]).to eq "Couldn't adjust dates on assignment lalala (ID #{assignment.id})"
    end
  end

  describe "import_media_objects" do
    before do
      attachment_model(:uploaded_data => stub_file_data('test.m4v', 'asdf', 'video/mp4'))
    end

    it "should wait for media objects on canvas cartridge import" do
      migration = double(:canvas_import? => true)
      expect(MediaObject).to receive(:add_media_files).with([@attachment], true)
      Importers::CourseContentImporter.import_media_objects([@attachment], migration)
    end

    it "should not wait for media objects on other import" do
      migration = double(:canvas_import? => false)
      expect(MediaObject).to receive(:add_media_files).with([@attachment], false)
      Importers::CourseContentImporter.import_media_objects([@attachment], migration)
    end
  end

  describe "import_settings_from_migration" do
    before :once do
      course_with_teacher
      @course.storage_quota = 1
      @cm = ContentMigration.create!(
        :context => @course,
        :user => @user,
        :source_course => @course,
        :copy_options => {:everything => "1"}
      )
    end

    context "with unauthorized user" do
      it "should not adjust in course import" do
        Importers::CourseContentImporter.import_settings_from_migration(@course, {:course=>{:storage_quota => 4}}, @cm)
        expect(@course.storage_quota).to eq 1
      end

      it "should not adjust in course copy" do
        @cm.migration_type = 'course_copy_importer'
        Importers::CourseContentImporter.import_settings_from_migration(@course, {:course=>{:storage_quota => 4}}, @cm)
        expect(@course.storage_quota).to eq 1
      end
    end

    context "with account admin" do
      before :once do
        account_admin_user(:user => @user)
      end

      it "should adjust in course import" do
        Importers::CourseContentImporter.import_settings_from_migration(@course, {:course=>{:storage_quota => 4}}, @cm)
        expect(@course.storage_quota).to eq 4
      end

      it "should adjust in course copy" do
        @cm.migration_type = 'course_copy_importer'
        Importers::CourseContentImporter.import_settings_from_migration(@course, {:course=>{:storage_quota => 4}}, @cm)
        expect(@course.storage_quota).to eq 4
      end
    end
  end

  describe "audit logging" do
    it "should log content migration in audit logs" do
      course_factory

      json = File.open(File.join(IMPORT_JSON_DIR, 'assessments.json')).read
      data = JSON.parse(json).with_indifferent_access

      params = {"copy" => {"quizzes" => {"i7ed12d5eade40d9ee8ecb5300b8e02b2" => true}}}

      migration = ContentMigration.create!(:context => @course)
      migration.migration_settings[:migration_ids_to_import] = params
      migration.source_course = @course
      migration.initiated_source = :manual
      migration.user = @user
      migration.save!

      expect(Auditors::Course).to receive(:record_copied).once.with(migration.source_course, @course, migration.user, source: migration.initiated_source)

      Importers::CourseContentImporter.import_content(@course, data, params, migration)
    end
  end

  describe "insert into module" do
    before :once do
      course_factory
      @module = @course.context_modules.create! name: 'test'
      @module.add_item(type: 'context_module_sub_header', title: 'blah')
      @params = {"copy" => {"assignments" => {"1865116198002" => true}}}
      json = File.open(File.join(IMPORT_JSON_DIR, 'import_from_migration.json')).read
      @data = JSON.parse(json).with_indifferent_access
    end

    it "appends imported items to a module" do
      migration = @course.content_migrations.build
      migration.migration_settings[:migration_ids_to_import] = @params
      migration.migration_settings[:insert_into_module_id] = @module.id
      migration.save!

      Importers::CourseContentImporter.import_content(@course, @data, @params, migration)
      expect(@module.content_tags.order('position').pluck(:content_type)).to eq(%w(ContextModuleSubHeader Assignment))
    end

    it "can insert items from one module to an existing module" do
      migration = @course.content_migrations.build
      @params["copy"].merge!("context_modules" => {"1864019962002" => true})
      migration.migration_settings[:migration_ids_to_import] = @params
      migration.migration_settings[:insert_into_module_id] = @module.id
      migration.save!

      Importers::CourseContentImporter.import_content(@course, @data, @params, migration)
      expect(migration.migration_issues.count).to eq 0
      expect(@course.context_modules.where.not(:migration_id => nil).count).to eq 0 # doesn't import other modules
      expect(@module.content_tags.last.content.migration_id).to eq '1865116198002'
    end

    it "inserts imported items into a module" do
      migration = @course.content_migrations.build
      migration.migration_settings[:migration_ids_to_import] = @params
      migration.migration_settings[:insert_into_module_id] = @module.id
      migration.migration_settings[:insert_into_module_position] = 1
      migration.save!

      Importers::CourseContentImporter.import_content(@course, @data, @params, migration)
      expect(@module.content_tags.order('position').pluck(:content_type)).to eq(%w(Assignment ContextModuleSubHeader))
    end

    it "respects insert_into_module_type" do
      @params['copy']['discussion_topics'] = {'1864019689002' => true}
      migration = @course.content_migrations.build
      migration.migration_settings[:migration_ids_to_import] = @params
      migration.migration_settings[:insert_into_module_id] = @module.id
      migration.migration_settings[:insert_into_module_type] = 'assignment'
      migration.save!
      Importers::CourseContentImporter.import_content(@course, @data, @params, migration)
      expect(@module.content_tags.order('position').pluck(:content_type)).to eq(%w(ContextModuleSubHeader Assignment))
    end
  end

  describe "move to assignment group" do
    before :once do
      course_factory
      @course.require_assignment_group
      @new_group = @course.assignment_groups.create!(name: 'new group')
      @params = {"copy" => {"assignments" => {"1865116014002" => true}}}
      json = File.open(File.join(IMPORT_JSON_DIR, 'assignment.json')).read
      @data = {"assignments" => JSON.parse(json)}.with_indifferent_access
      @migration = @course.content_migrations.build
      @migration.migration_settings[:migration_ids_to_import] = @params
      @migration.migration_settings[:move_to_assignment_group_id] = @new_group.id
      @migration.save!
    end

    it "puts a new assignment into assignment group" do
      other_assign = @course.assignments.create! title: 'other', assignment_group: @new_group
      Importers::CourseContentImporter.import_content(@course, @data, @params, @migration)
      new_assign = @course.assignments.where(migration_id: '1865116014002').take
      expect(new_assign.assignment_group_id).to eq @new_group.id
    end

    it "moves existing assignment into assignment group" do
      existing_assign = @course.assignments.create! title: 'blah', migration_id: '1865116014002'
      expect(existing_assign.assignment_group_id).not_to eq @new_group.id
      Importers::CourseContentImporter.import_content(@course, @data, @params, @migration)
      expect(existing_assign.reload.assignment_group_id).to eq @new_group.id
    end

  end

  it 'should be able to i18n without keys' do
    expect { Importers::CourseContentImporter.translate('stuff') }.not_to raise_error
  end

  it "shouldn't create missing link migration issues if the link got sanitized away" do
    data = {:assignments => [
      {:migration_id => "broken", :description => "heres a normal bad link <a href='/badness'>blah</a>"},
      {:migration_id => "kindabroken", :description => "here's a link that's going to go away in a bit <link rel=\"stylesheet\" href=\"/badness\"/>"}
    ]}.with_indifferent_access

    course_factory
    migration = @course.content_migrations.create!
    Importers::CourseContentImporter.import_content(@course, data, {}, migration)

    broken_assmt = @course.assignments.where(:migration_id => "broken").first
    unbroken_assmt = @course.assignments.where(:migration_id => "kindabroken").first
    expect(unbroken_assmt.description).to_not include("stylesheet")

    expect(migration.migration_issues.count).to eq 1 # should ignore the sanitized one
    expect(migration.migration_issues.first.fix_issue_html_url).to eq "/courses/#{@course.id}/assignments/#{broken_assmt.id}"
  end
end

def from_file_path(path, course)
  list = path.split("/").select{|f| !f.empty? }
  filename = list.pop
  folder = Folder.assert_path(list.join('/'), course)
  file = folder.file_attachments.build(:display_name => filename, :filename => filename, :content_type => "text/plain")
  file.uploaded_data = StringIO.new("fake data")
  file.context = course
  file.save!
  file
end
