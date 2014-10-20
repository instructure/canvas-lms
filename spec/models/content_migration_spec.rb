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

    it "should not re-use the question_bank without overwrite_quizzes" do
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

      # run again
      cm.queue_migration
      run_jobs

      cm.migration_issues.should be_empty

      account.assessment_question_banks.count.should == 2
      account.assessment_question_banks.each do |bank|
        bank.title.should == "Unnamed Quiz"
        bank.assessment_questions.count.should == 1
      end
    end

    it "should re-use the question_bank (and everything else) with overwrite_quizzes" do
      pending unless Qti.qti_enabled?

      account = Account.create!(:name => 'account')
      @user = user
      account.account_users.create!(user: @user)
      cm = ContentMigration.new(:context => account, :user => @user)
      cm.migration_type = 'qti_converter'
      cm.migration_settings['import_immediately'] = true
      cm.migration_settings['overwrite_quizzes'] = true
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

      cm.migration_issues.should be_empty

      account.assessment_question_banks.count.should == 1
      bank = account.assessment_question_banks.first
      bank.title.should == "Unnamed Quiz"

      bank.assessment_questions.count.should == 1
    end
  end

  it "should identify and import compressed tarball archives" do
    pending unless Qti.qti_enabled?

    course_with_teacher
    cm = ContentMigration.new(:context => @course, :user => @user)
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

    cm.migration_issues.should be_empty

    @course.assessment_question_banks.count.should == 1
  end
end
