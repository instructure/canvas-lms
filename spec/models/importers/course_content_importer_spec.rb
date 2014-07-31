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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe Course do
  it "should import a whole json file" do
    # TODO: pull this out into smaller tests... right now I'm using
    # the whole example JSON from Bracken because the formatting is
    # somewhat in flux
    json = File.open(File.join(IMPORT_JSON_DIR, 'import_from_migration.json')).read
    data = JSON.parse(json).with_indifferent_access
    data['all_files_export'] = {
      'file_path'  => File.join(IMPORT_JSON_DIR, 'import_from_migration_small.zip')
    }
    course = course_model
    migration = ContentMigration.create!(:context => course)
    file_count = 0
    # data['file_map'].each do |id, file|
      # if !file['is_folder']
        # file_count += 1
        # from_file_path(file['path_name'], course)
      # end
    # end
    migration.migration_ids_to_import = {:copy => {
      :topics => {'1864019689002' => true, '1865116155002' => true},
      :announcements => {'4488523052421' => true},
      :files => {'1865116527002' => true, '1865116044002' => true, '1864019880002' => true, '1864019921002' => true},
      :rubrics => {'4469882249231' => true},
      :events => {},
      :modules => {'1864019977002' => true, '1865116190002' => true},
      :assignments => {'1865116014002' => true, '1865116155002' => true, '4407365899221' => true, '4469882339231' => true},
      :outline_folders => {'1865116206002' => true, '1865116207002' => true},
      :quizzes => {'1865116175002' => true},
      :all_groups => true,
      :shift_dates=>"1",
      :old_start_date=>"Jan 23, 2009",
      :old_end_date=>"Apr 10, 2009",
      :new_start_date=>"Jan 3, 2011",
      :new_end_date=>"Apr 13, 2011"
    }}.with_indifferent_access

    Importers::CourseContentImporter.import_content(course, data, migration.migration_settings[:migration_ids_to_import], migration)
    course.reload

    # discussion topic tests
    course.discussion_topics.length.should eql(3)
    migration_ids = ["1864019689002", "1865116155002", "4488523052421"].sort
    added_migration_ids = course.discussion_topics.map(&:migration_id).uniq.sort
    added_migration_ids.should eql(migration_ids)
    topic = course.discussion_topics.find_by_migration_id("1864019689002")
    topic.should_not be_nil
    topic.title.should eql("Post here for group events, etc.")
    topic.discussion_entries.should be_empty
    topic = course.discussion_topics.find_by_migration_id("1865116155002")
    topic.should_not be_nil
    topic.assignment.should_not be_nil

    # quizzes
    course.quizzes.length.should eql(1)
    quiz = course.quizzes.first
    quiz.migration_id = '1865116175002'
    quiz.title.should eql("Orientation Quiz")

    # wiki pages tests
    migration_ids = ["1865116206002", "1865116207002"].sort
    added_migration_ids = course.wiki.wiki_pages.map(&:migration_id).uniq.sort
    added_migration_ids.should eql(migration_ids)
    course.wiki.wiki_pages.length.should eql(migration_ids.length)
    # front page
    page = course.wiki.front_page
    page.should_not be_nil
    page.migration_id.should eql("1865116206002")
    page.body.should_not be_nil
    page.body.scan(/<li>/).length.should eql(4)
    page.body.should match(/Orientation/)
    page.body.should match(/Orientation Quiz/)
    file = course.attachments.find_by_migration_id("1865116527002")
    file.should_not be_nil
    re = Regexp.new("\\/courses\\/#{course.id}\\/files\\/#{file.id}\\/preview")
    page.body.should match(re) #)

    # assignment tests
    course.reload
    length = course.root_account.feature_enabled?(:draft_state) ? 5 : 4
    course.assignments.length.should eql(length)
    course.assignments.map(&:migration_id).sort.should eql(['1865116155002', '1865116014002', '4407365899221', '4469882339231'].sort)
    # assignment with due date
    assignment = course.assignments.find_by_migration_id("1865116014002")
    assignment.should_not be_nil
    assignment.title.should eql("Concert Review Assignment")
    assignment.description.should match(Regexp.new("USE THE TEXT BOX!  DO NOT ATTACH YOUR ASSIGNMENT!!"))
    # The old due date (Fri Mar 27 23:55:00 -0600 2009) should have been adjusted to new time frame
    assignment.due_at.year.should == 2011

    # discussion topic assignment
    assignment = course.assignments.find_by_migration_id("1865116155002")
    assignment.should_not be_nil
    assignment.title.should eql("Introduce yourself!")
    assignment.points_possible.should eql(10.0)
    assignment.discussion_topic.should_not be_nil
    # assignment with rubric
    assignment = course.assignments.find_by_migration_id("4469882339231")
    assignment.should_not be_nil
    assignment.title.should eql("Rubric assignment")
    assignment.rubric.should_not be_nil
    assignment.rubric.migration_id.should eql("4469882249231")
    # assignment with file
    assignment = course.assignments.find_by_migration_id("4407365899221")
    assignment.should_not be_nil
    assignment.title.should eql("new assignment")
    file = course.attachments.find_by_migration_id("1865116527002")
    file.should_not be_nil
    assignment.description.should match(Regexp.new("/files/#{file.id}/download"))

    # calendar events
    course.calendar_events.should be_empty

    # rubrics
    course.rubrics.length.should eql(1)
    rubric = course.rubrics.first
    rubric.data.length.should eql(3)
    # Spelling
    criterion = rubric.data[0].with_indifferent_access
    criterion["description"].should eql("Spelling")
    criterion["points"].should eql(15.0)
    criterion["ratings"].length.should eql(3)
    criterion["ratings"][0]["points"].should eql(15.0)
    criterion["ratings"][0]["description"].should eql("Exceptional - fff")
    criterion["ratings"][1]["points"].should eql(10.0)
    criterion["ratings"][1]["description"].should eql("Meet Expectations - asdf")
    criterion["ratings"][2]["points"].should eql(5.0)
    criterion["ratings"][2]["description"].should eql("Need Improvement - rubric entry text")

    # Grammar
    criterion = rubric.data[1]
    criterion["description"].should eql("Grammar")
    criterion["points"].should eql(15.0)
    criterion["ratings"].length.should eql(3)
    criterion["ratings"][0]["points"].should eql(15.0)
    criterion["ratings"][0]["description"].should eql("Exceptional")
    criterion["ratings"][1]["points"].should eql(10.0)
    criterion["ratings"][1]["description"].should eql("Meet Expectations")
    criterion["ratings"][2]["points"].should eql(5.0)
    criterion["ratings"][2]["description"].should eql("Need Improvement - you smell")

    # Style
    criterion = rubric.data[2]
    criterion["description"].should eql("Style")
    criterion["points"].should eql(15.0)
    criterion["ratings"].length.should eql(3)
    criterion["ratings"][0]["points"].should eql(15.0)
    criterion["ratings"][0]["description"].should eql("Exceptional")
    criterion["ratings"][1]["points"].should eql(10.0)
    criterion["ratings"][1]["description"].should eql("Meet Expectations")
    criterion["ratings"][2]["points"].should eql(5.0)
    criterion["ratings"][2]["description"].should eql("Need Improvement")

    #groups
    course.groups.length.should eql(2)

    # files
    course.attachments.length.should eql(4)
    course.attachments.each do |file|
      File.should be_exist(file.full_filename)
    end
    file = course.attachments.find_by_migration_id("1865116044002")
    file.should_not be_nil
    file.filename.should eql("theatre_example.htm")
    file.folder.full_name.should eql("course files/Writing Assignments/Examples")
    file = course.attachments.find_by_migration_id("1864019880002")
    file.should_not be_nil
    file.filename.should eql("dropbox.zip")
    file.folder.full_name.should eql("course files/Course Content/Orientation/WebCT specific and old stuff")
  end

  it "should not duplicate assessment questions in question banks" do
    course

    json = File.open(File.join(IMPORT_JSON_DIR, 'assessments.json')).read
    data = JSON.parse(json).with_indifferent_access

    params = {:copy => {"everything" => true}}
    migration = ContentMigration.create!(:context => @course)
    migration.migration_settings[:migration_ids_to_import] = params
    migration.save!

    Importers::CourseContentImporter.import_content(@course, data, params, migration)

    aqb1 = @course.assessment_question_banks.find_by_migration_id("i7c16375e1a00381824d060d3d4f9acc4")
    aqb1.assessment_questions.count.should == 3
    aqb2 = @course.assessment_question_banks.find_by_migration_id("i966491408fab70dfc76ae02b197938a3")
    aqb2.assessment_questions.count.should == 2
  end

  it "should not create assessment question banks if they are not selected" do
    course

    json = File.open(File.join(IMPORT_JSON_DIR, 'assessments.json')).read
    data = JSON.parse(json).with_indifferent_access

    params = {"copy" => {"assessment_question_banks" => {"i7c16375e1a00381824d060d3d4f9acc4" => true},
                         "quizzes" => {"i7ed12d5eade40d9ee8ecb5300b8e02b2" => true,
                                       "ife86eb19e30869506ee219b17a6a1d4e" => true}}}

    migration = ContentMigration.create!(:context => @course)
    migration.migration_settings[:migration_ids_to_import] = params
    migration.save!

    Importers::CourseContentImporter.import_content(@course, data, params, migration)

    @course.assessment_question_banks.count.should == 1
    aqb1 = @course.assessment_question_banks.find_by_migration_id("i7c16375e1a00381824d060d3d4f9acc4")
    aqb1.assessment_questions.count.should == 3
    @course.assessment_questions.count.should == 3

    @course.quizzes.count.should == 2
    quiz1 = @course.quizzes.find_by_migration_id("i7ed12d5eade40d9ee8ecb5300b8e02b2")
    quiz1.quiz_questions.each{|qq| qq.assessment_question.should_not be_nil }

    quiz2 = @course.quizzes.find_by_migration_id("ife86eb19e30869506ee219b17a6a1d4e")
    quiz2.quiz_questions.each{|qq| qq.assessment_question.should be_nil } # since the bank wasn't brought in
  end

  describe "shift_date_options" do
    it "should default options[:time_zone] to the root account's time zone" do
      account = Account.default.sub_accounts.create!
      course_with_teacher(account: account)
      @course.root_account.default_time_zone = 'America/New_York'
      @course.start_at = 1.month.ago
      @course.conclude_at = 1.month.from_now
      options = Importers::CourseContentImporter.shift_date_options(@course, {})
      options[:time_zone].should == ActiveSupport::TimeZone['Eastern Time (US & Canada)']
    end
  end

  describe "import_media_objects" do
    before do
      attachment_model(:uploaded_data => stub_file_data('test.m4v', 'asdf', 'video/mp4'))
    end

    it "should wait for media objects on canvas cartridge import" do
      migration = mock(:canvas_import? => true)
      MediaObject.expects(:add_media_files).with([@attachment], true)
      Importers::CourseContentImporter.import_media_objects([@attachment], migration)
    end

    it "should not wait for media objects on other import" do
      migration = mock(:canvas_import? => false)
      MediaObject.expects(:add_media_files).with([@attachment], false)
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

    it "should not adjust for unauthorized user" do
      Importers::CourseContentImporter.import_settings_from_migration(@course, {:course=>{:storage_quota => 4}}, @cm)
      @course.storage_quota.should == 1
    end

    it "should adjust for authorized user" do
      account_admin_user(:user => @user)
      Importers::CourseContentImporter.import_settings_from_migration(@course, {:course=>{:storage_quota => 4}}, @cm)
      @course.storage_quota.should == 4
    end

    it "should be set for course copy" do
      @cm.migration_type = 'course_copy_importer'
      Importers::CourseContentImporter.import_settings_from_migration(@course, {:course=>{:storage_quota => 4}}, @cm)
      @course.storage_quota.should == 4
    end
  end

  describe "audit logging" do
    it "should log content migration in audit logs" do
      course

      json = File.open(File.join(IMPORT_JSON_DIR, 'assessments.json')).read
      data = JSON.parse(json).with_indifferent_access

      params = {"copy" => {"quizzes" => {"i7ed12d5eade40d9ee8ecb5300b8e02b2" => true}}}

      migration = ContentMigration.create!(:context => @course)
      migration.migration_settings[:migration_ids_to_import] = params
      migration.source_course = @course
      migration.initiated_source = :manual
      migration.user = @user
      migration.save!

      Auditors::Course.expects(:record_copied).once.with(migration.source_course, @course, migration.user, source: migration.initiated_source)

      Importers::CourseContentImporter.import_content(@course, data, params, migration)
    end
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
