# coding: utf-8
#
# Copyright (C) 2012 - present Instructure, Inc.
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
  before :once do
    course_with_teacher
    @cm = ContentMigration.create!(context: @course, user: @teacher)
  end

  context "#prepare_data" do
    it "should strip invalid utf8" do
      data = {
        'assessment_questions' => [{
          'question_name' => "hai\xfbabcd"
        }]
      }
      expect(ContentMigration.new.prepare_data(data)[:assessment_questions][0][:question_name]).to eq "haiabcd"
    end
  end

  context "import_object?" do
    it "should return true for everything if there are no copy options" do
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq true
    end

    it "should return true for everything if 'everything' is selected" do
      @cm.migration_ids_to_import = {:copy => {:everything => "1"}}
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq true
    end

    it "should return true if there are no copy options" do
      @cm.migration_ids_to_import = {:copy => {}}
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq true
    end

    it "should return false for nil objects" do
      expect(@cm.import_object?("content_migrations", nil)).to eq false
    end

    it "should return true for all object types if the all_ option is true" do
      @cm.migration_ids_to_import = {:copy => {:all_content_migrations => "1"}}
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq true
    end

    it "should return false for objects not selected" do
      @cm.save!
      @cm.migration_ids_to_import = {:copy => {:all_content_migrations => "0"}}
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq false
      @cm.migration_ids_to_import = {:copy => {:content_migrations => {}}}
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq false
      @cm.migration_ids_to_import = {:copy => {:content_migrations => {CC::CCHelper.create_key(@cm) => "0"}}}
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq false
    end

    it "should return true for selected objects" do
      @cm.save!
      @cm.migration_ids_to_import = {:copy => {:content_migrations => {CC::CCHelper.create_key(@cm) => "1"}}}
      expect(@cm.import_object?("content_migrations", CC::CCHelper.create_key(@cm))).to eq true
    end

  end

  it "should exclude user-hidden migration plugins" do
    ab = Canvas::Plugin.find(:academic_benchmark_importer)
    expect(ContentMigration.migration_plugins(true).include?(ab)).to be_falsey
  end

  context "zip file import" do
    def test_zip_import(context, filename="file.zip", filecount=1)
      zip_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/#{filename}")
      cm = ContentMigration.new(:context => context, :user => @user)
      cm.migration_type = 'zip_file_importer'
      cm.migration_settings[:folder_id] = Folder.root_folders(context).first.id
      cm.save!

      attachment = Attachment.new
      attachment.context = cm
      attachment.uploaded_data = File.open(zip_path, 'rb')
      attachment.filename = filename
      attachment.save!

      cm.attachment = attachment
      cm.save!

      cm.queue_migration
      run_jobs
      expect(context.reload.attachments.count).to eq filecount
    end

    it "should import into a course" do
      test_zip_import(@course)
    end

    it "should import into a user" do
      test_zip_import(@user)
    end

    it "should import into a group" do
      group_with_user
      test_zip_import(@group)
    end

    it "should not expand the mac system folder" do
      test_zip_import(@course, "macfile.zip", 4)
      expect(@course.folders.pluck(:name)).to_not include("__MACOSX")
    end
  end

  it "should use url for migration file" do
    cm = @cm
    cm.migration_type = 'zip_file_importer'
    cm.migration_settings[:folder_id] = Folder.root_folders(@course).first.id
    # the double below should prevent it from actually hitting the url
    cm.migration_settings[:file_url] = "http://localhost:3000/file.zip"
    cm.save!

    expect_any_instance_of(Attachment).to receive(:clone_url).with(cm.migration_settings[:file_url], false, true, :quota_context => cm.context)

    cm.queue_migration
    worker = Canvas::Migration::Worker::CCWorker.new
    worker.perform(cm)
  end

  context "account-level import" do
    it "should import question banks from qti migrations" do
      skip unless Qti.qti_enabled?

      account = Account.create!(:name => 'account')
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

      expect(cm.migration_issues).to be_empty

      expect(account.assessment_question_banks.count).to eq 1
      bank = account.assessment_question_banks.first
      expect(bank.title).to eq qb_name

      expect(bank.assessment_questions.count).to eq 1
    end

    it "should import questions from quizzes into question banks" do
      skip unless Qti.qti_enabled?

      account = Account.create!(:name => 'account')
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

      expect(cm.migration_issues).to be_empty

      expect(account.assessment_question_banks.count).to eq 1
      bank = account.assessment_question_banks.first
      expect(bank.title).to eq "Unnamed Quiz"

      expect(bank.assessment_questions.count).to eq 1
    end

    it "should not re-use the question_bank without overwrite_quizzes" do
      skip unless Qti.qti_enabled?

      account = Account.create!(:name => 'account')
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

      # run again
      cm.queue_migration
      run_jobs

      expect(cm.migration_issues).to be_empty

      expect(account.assessment_question_banks.count).to eq 2
      account.assessment_question_banks.each do |bank|
        expect(bank.title).to eq "Unnamed Quiz"
        expect(bank.assessment_questions.count).to eq 1
      end
    end

    it "should re-use the question_bank (and everything else) with overwrite_quizzes" do
      skip unless Qti.qti_enabled?

      account = Account.create!(:name => 'account')
      account.account_users.create!(user: @user)
      cm = ContentMigration.new(:context => account, :user => @user)
      cm.migration_type = 'qti_converter'
      cm.migration_settings['import_immediately'] = true

      # having this set used to always prepend the id, and it would get set it there were any other imported quizzes/questions
      cm.migration_settings['id_prepender'] = 'thisusedtobreakstuff'
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

      cm.migration_settings['overwrite_quizzes'] = true
      cm.migration_settings['id_prepender'] = 'somethingelse'
      cm.save!
      # run again
      cm.queue_migration
      run_jobs

      expect(cm.migration_issues).to be_empty

      expect(account.assessment_question_banks.count).to eq 1
      bank = account.assessment_question_banks.first
      expect(bank.title).to eq "Unnamed Quiz"

      expect(bank.assessment_questions.count).to eq 1
    end
  end

  it "should not overwrite deleted quizzes unless overwrite_quizzes is true" do
    skip unless Qti.qti_enabled?

    cm = @cm
    cm.migration_type = 'qti_converter'
    cm.migration_settings['import_immediately'] = true

    # having this set used to always prepend the id, and it would get set it there were any other imported quizzes/questions
    cm.migration_settings['id_prepender'] = 'thisusedtobreakstuff'
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

    expect(@course.quizzes.count).to eq 1
    orig_quiz = @course.quizzes.first
    qq = orig_quiz.quiz_questions.first
    qq.question_data[:question_text] = "boooring"
    qq.save!
    orig_quiz.destroy

    cm.migration_settings['id_prepender'] = 'somethingelse'
    cm.save!
    # run again, should create a new quiz
    cm.queue_migration
    run_jobs

    @course.reload
    expect(@course.quizzes.count).to eq 2
    expect(@course.quizzes.active.count).to eq 1

    new_quiz = @course.quizzes.active.first

    cm.migration_settings['overwrite_quizzes'] = true
    cm.migration_settings['id_prepender'] = 'somethingelse_again'
    cm.save!
    # run again, but this time restore the deleted quiz
    cm.queue_migration
    run_jobs

    @course.reload
    expect(@course.quizzes.count).to eq 2
    expect(@course.quizzes.active.count).to eq 2

    orig_quiz.reload
    # should overwrite the old quiz question data
    expect(orig_quiz.quiz_questions.first.question_data[:question_text]).to eq(
      new_quiz.quiz_questions.first.question_data[:question_text])
  end

  it "selectively imports quizzes when id_prepender is in use" do
    skip unless Qti.qti_enabled?

    cm = @cm
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

    expect(@course.quizzes.count).to eq 1
    teh_quiz = @course.quizzes.first
    teh_quiz.destroy!

    cm.migration_settings['id_prepender'] = 'blah!'
    cm.migration_settings['migration_ids_to_import'] = {'copy' => {'quizzes' => {teh_quiz.migration_id => '1'}}}
    cm.save!
    cm.queue_migration
    run_jobs
    expect(@course.quizzes.active.find_by_migration_id("blah!_#{teh_quiz.migration_id}")).not_to be_nil
  end

  it "should identify and import compressed tarball archives" do
    skip unless Qti.qti_enabled?

    cm = @cm
    cm.migration_type = 'qti_converter'
    cm.migration_settings['import_immediately'] = true
    cm.save!

    package_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/cc_default_qb_test.tar.gz")
    attachment = Attachment.new
    attachment.context = cm
    attachment.uploaded_data = File.open(package_path, 'rb')
    attachment.filename = 'file.zip'
    attachment.save!

    cm.attachment = attachment
    cm.save!

    cm.queue_migration
    run_jobs

    expect(cm.migration_issues).to be_empty

    expect(@course.assessment_question_banks.count).to eq 1
  end

  it "should try to handle utf-16 encoding errors" do
    cm = @cm
    cm.migration_type = 'canvas_cartridge_importer'
    cm.migration_settings['import_immediately'] = true
    cm.save!

    package_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/canvas_cc_utf16_error.zip")
    attachment = Attachment.new
    attachment.context = cm
    attachment.uploaded_data = File.open(package_path, 'rb')
    attachment.filename = 'file.zip'
    attachment.save!

    cm.attachment = attachment
    cm.save!

    cm.queue_migration
    run_jobs

    expect(cm.migration_issues).to be_empty
  end

  it "should correclty handle media comment resolution in quizzes" do
    skip 'Requires QtiMigrationTool' unless Qti.qti_enabled?

    cm = @cm
    cm.migration_type = 'canvas_cartridge_importer'
    cm.migration_settings['import_immediately'] = true
    cm.save!

    package_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/canvas_quiz_media_comment.zip")
    attachment = Attachment.new
    attachment.context = cm
    attachment.uploaded_data = File.open(package_path, 'rb')
    attachment.filename = 'file.zip'
    attachment.save!

    cm.attachment = attachment
    cm.save!

    cm.queue_migration
    run_jobs

    expect(cm.migration_issues).to be_empty
    quiz = @course.quizzes.available.first
    expect(quiz.quiz_data).to be_present
    expect(quiz.quiz_data.to_yaml).to include("/media_objects/m-5U5Jww6HL7zG35CgyaYGyA5bhzsremxY")

    qq = quiz.quiz_questions.first
    expect(qq.question_data).to be_present
    expect(qq.question_data.to_yaml).to include("/media_objects/m-5U5Jww6HL7zG35CgyaYGyA5bhzsremxY")

  end

  context "migrations with skip_job_progress enabled" do
    before :once do
      @account = Account.create!(:name => 'account')
    end

    def create_ab_cm
      cm = ContentMigration.new(:context => @account)
      cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
      cm.migration_settings[:import_immediately] = true
      cm.migration_settings[:no_archive_file] = true
      cm.migration_settings[:skip_import_notification] = true
      cm.migration_settings[:skip_job_progress] = true
      cm.save!
      cm
    end

    it "should not throw an error when checking if blocked by current migration" do
      cm = create_ab_cm
      cm.queue_migration
      cm = create_ab_cm
      expect(cm.blocked_by_current_migration?(nil, 0, nil)).to be_truthy
    end

    it "should not throw an error checking for blocked migrations on save" do
      cm1 = create_ab_cm
      cm1.queue_migration
      cm2 = create_ab_cm
      cm2.queue_migration
      cm1.workflow_state = 'imported'
      expect { cm1.save! }.not_to raise_error
    end
  end

  it "expires migration jobs after 48 hours" do
    cm = @cm
    cm.migration_type = 'common_cartridge_importer'
    cm.workflow_state = 'created'
    cm.save!
    cm.queue_migration

    expect_any_instance_of(Canvas::Migration::Worker::CCWorker).to receive(:perform).never
    Timecop.travel(50.hours.from_now) do
      run_jobs
    end

    cm.reload
    expect(cm).to be_failed
    expect(cm.migration_issues).not_to be_empty
    expect(cm.migration_issues.last.error_report.message).to include 'job expired'
  end

  it "expires import jobs after 48 hours" do
    cm = @cm
    cm.migration_type = 'common_cartridge_importer'
    cm.workflow_state = 'exported'
    cm.save!
    expect(Canvas::Migration::Worker::CCWorker).to receive(:new).never
    cm.queue_migration

    expect_any_instance_of(ContentMigration).to receive(:import_content).never
    Timecop.travel(50.hours.from_now) do
      run_jobs
    end

    cm.reload
    expect(cm).to be_failed
    expect(cm.migration_issues).not_to be_empty
    expect(cm.migration_issues.last.error_report.message).to include 'job expired'
  end

  it "delays queueing imports if one in course is already running" do
    cms = []
    Timecop.freeze(Time.now) do
      2.times do
        cm = ContentMigration.new(:context => @course, :user => @teacher)
        cm.migration_type = 'common_cartridge_importer'
        cm.workflow_state = 'exported'
        cm.save!
        cm.queue_migration
        cms << cm
      end

      dj = Delayed::Job.last
      expect(dj.tag).to eq "ContentMigration#queue_migration"
      expect(dj.run_at > 30.minutes.from_now).to be_truthy # should run in the future if something goes wrong
    end

    expect_any_instantiation_of(cms[1]).to receive(:queue_migration) do |_plugin, opts|
      expect(opts[:retry_count]).to eq 1
      expect(opts[:expires_at]).to be_present
    end

    run_jobs # even though the requeue is set to happen in the future, it should get run right away after the first one completes
  end

  it "should try to handle zip files with a nested root directory" do
    cm = @cm
    cm.migration_type = 'common_cartridge_importer'
    cm.migration_settings['import_immediately'] = true
    cm.save!

    package_path = File.join(File.dirname(__FILE__) + "/../fixtures/migration/cc_nested.zip")
    attachment = Attachment.new(:context => cm, :filename => 'file.zip')
    attachment.uploaded_data = File.open(package_path, 'rb')
    attachment.save!

    cm.update_attribute(:attachment, attachment)
    cm.queue_migration
    run_jobs

    expect(cm.reload.migration_issues).to be_empty
  end

  describe "#expired?" do
    it "marks as expired after X days" do
      ContentMigration.where(id: @cm.id).update_all(created_at: 405.days.ago)
      expect(@cm.reload).to be_expired
    end

    it "does not mark new exports as expired" do
      expect(@cm.reload).not_to be_expired
    end

    it "does not mark as expired if setting is 0" do
      Setting.set('content_migrations_expire_after_days', '0')
      ContentMigration.where(id: @cm.id).update_all(created_at: 405.days.ago)
      expect(@cm.reload).not_to be_expired
    end
  end

  describe "#expired" do
    it "marks as expired after X days" do
      ContentMigration.where(id: @cm.id).update_all(created_at: 405.days.ago)
      expect(ContentMigration.expired.pluck(:id)).to eq [@cm.id]
    end

    it "does not mark new exports as expired" do
      expect(ContentMigration.expired.pluck(:id)).to be_empty
    end

    it "does not mark as expired if setting is 0" do
      Setting.set('content_migrations_expire_after_days', '0')
      ContentMigration.where(id: @cm.id).update_all(created_at: 405.days.ago)
      expect(ContentMigration.expired.pluck(:id)).to be_empty
    end
  end
end
