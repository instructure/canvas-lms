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

require "delayed/testing"

describe Folder do
  before(:once) do
    course_factory
  end

  it "creates a new instance given valid attributes" do
    expect(folder_model).to be_present
  end

  it "infers its full name if it has a parent folder" do
    f = Folder.root_folders(@course).first
    expect(f.full_name).to eql("course files")
    child = f.active_sub_folders.build(name: "child")
    child.context = @course
    child.save!
    expect(child.parent_folder).to eql(f)
    expect(child.full_name).to eql("course files/child")
    grandchild = child.sub_folders.build(name: "grandchild")
    grandchild.context = @course
    grandchild.save!
    expect(grandchild.full_name).to eql("course files/child/grandchild")
    great_grandchild = grandchild.sub_folders.build(name: "great_grandchild")
    great_grandchild.context = @course
    great_grandchild.save!
    expect(great_grandchild.full_name).to eql("course files/child/grandchild/great_grandchild")

    grandchild.parent_folder = f
    grandchild.save!
    grandchild.reload
    expect(grandchild.full_name).to eql("course files/grandchild")
    great_grandchild.reload
    expect(great_grandchild.full_name).to eql("course files/grandchild/great_grandchild")
  end

  it "trims trailing whitespaces from folder names" do
    f = Folder.root_folders(@course).first
    expect(f.full_name).to eql("course files")
    child = f.active_sub_folders.build(name: "space cadet            ")
    child.context = @course
    child.save!
    expect(child.parent_folder).to eql(f)
    expect(child.full_name).to eql("course files/space cadet")
  end

  it "adds an iterator to duplicate folder names" do
    f = Folder.root_folders(@course).first
    expect(f.full_name).to eql("course files")
    child = f.active_sub_folders.build(name: "child")
    child.context = @course
    child.save!
    expect(child.parent_folder).to eql(f)
    expect(child.full_name).to eql("course files/child")
    child2 = f.active_sub_folders.build(name: "child")
    child2.context = @course
    child2.save!
    expect(child2.parent_folder).to eql(f)
    expect(child2.full_name).to eql("course files/child 2")
  end

  it "allows the iterator to increase beyond 10 for duplicate folder names" do
    f = Folder.root_folders(@course).first
    expect(f.full_name).to eql("course files")
    child = f.active_sub_folders.build(name: "child")
    child.context = @course
    child.save!
    expect(child.parent_folder).to eql(f)
    expect(child.full_name).to eql("course files/child")

    2.upto(11) do |i|
      duplicate = f.active_sub_folders.build(name: "child")
      duplicate.context = @course
      duplicate.save!
      expect(duplicate.parent_folder).to eql(f)
      expect(duplicate.full_name).to eql("course files/child #{i}")
    end
  end

  it "raises an error if you create in a deleted parent folder" do
    f1 = @course.folders.create!(name: "f1", workflow_state: "deleted")
    expect { f1.sub_folders.create!(name: "f2", context: @course) }.to raise_error ActiveRecord::StatementInvalid, /Cannot create sub-folders in deleted folders/
  end

  it "does not allow recursive folder structures" do
    f1 = @course.folders.create!(name: "f1")
    f2 = f1.sub_folders.create!(name: "f2", context: @course)
    f3 = f2.sub_folders.create!(name: "f3", context: @course)
    f1.parent_folder = f3
    expect(f1.save).to be false
    expect(f1.errors.detect { |e| e.first.to_s == "parent_folder_id" }).to be_present
  end

  it "does not allow root folders to have their names changed" do
    f1 = Folder.root_folders(@course).first
    f1.reload
    f1.update(name: "something")
    expect(f1.save).to be false
    expect(f1.errors.detect { |e| e.first.to_s == "name" }).to be_present
  end

  describe "set folder root account id" do
    before(:once) do
      student_in_course
      group_model(context: @course)
    end

    it "when context is group" do
      folder = @group.folders.create!
      expect(folder.root_account_id).to eq @group.root_account_id
    end

    it "when context is account" do
      account = @course.account.root_account.manually_created_courses_account
      folder = account.folders.create!
      expect(folder.root_account_id).to eq account.root_account_id
    end

    it "when context is a root account" do
      folder = @course.root_account.folders.create!
      expect(folder.root_account_id).to eq @course.root_account_id
    end

    it "when context is course" do
      folder = @course.folders.create!
      expect(folder.root_account_id).to eq @course.root_account_id
    end

    it "does not happen when context is user" do
      folder = @user.folders.create!
      expect(folder.root_account_id).to eq 0
    end
  end

  it "files without an explicit folder_id should be inferred" do
    f = @course.folders.create!(name: "unfiled")
    a = f.active_file_attachments.build
    a.context = @course
    a.uploaded_data = default_uploaded_data
    a.save!
    nil_a = @course.attachments.new
    nil_a.update(uploaded_data: default_uploaded_data)
    expect(nil_a.folder_id).not_to be_nil
    expect(f.active_file_attachments).to include(a)
    # f.active_file_attachments.should be_include(nil_a)
  end

  it "assigns unfiled files to the 'unfiled' folder" do
    f = Folder.unfiled_folder(@course)
    a = f.file_attachments.build
    a.context = @course
    a.uploaded_data = default_uploaded_data
    a.save!
    nil_a = @course.attachments.new
    nil_a.update(uploaded_data: default_uploaded_data)
    expect(f.active_file_attachments).to include(a)
    expect(f.active_file_attachments).to include(nil_a)
  end

  it "does not return files without a folder_id if it's not the 'unfiled' folder" do
    f = @course.folders.create!(name: "not_unfiled")
    a = f.active_file_attachments.build
    a.context = @course
    a.uploaded_data = default_uploaded_data
    a.save!
    nil_a = @course.attachments.create!(uploaded_data: default_uploaded_data)
    expect(f.active_file_attachments).to include(a)
    expect(f.active_file_attachments).not_to include(nil_a)
  end

  it "implements the not_locked scope correctly" do
    not_locked = [
      Folder.root_folders(@course).first,
      @course.folders.create!(name: "not locked 1", locked: false),
      @course.folders.create!(name: "not locked 2", lock_at: 1.day.from_now),
      @course.folders.create!(name: "not locked 3", lock_at: 2.days.ago, unlock_at: 1.day.ago)
    ]
    locked = [
      @course.folders.create!(name: "locked 1", locked: true),
      @course.folders.create!(name: "locked 2", lock_at: 1.day.ago),
      @course.folders.create!(name: "locked 3", lock_at: 1.day.ago, unlock_at: 1.day.from_now)
    ]
    expect(@course.folders.map(&:id).sort).to eq (not_locked + locked).map(&:id).sort
    expect(@course.folders.not_locked.map(&:id).sort).to eq not_locked.map(&:id).sort
  end

  it "does not create multiple root folders for a course" do
    skip("spec requires postgres index") unless Folder.connection.adapter_name == "PostgreSQL"

    @course.folders.create!(name: Folder::ROOT_FOLDER_NAME, full_name: Folder::ROOT_FOLDER_NAME, workflow_state: "visible")
    expect { @course.folders.create!(name: Folder::ROOT_FOLDER_NAME, full_name: Folder::ROOT_FOLDER_NAME, workflow_state: "visible") }.to raise_error(ActiveRecord::RecordNotUnique)

    @course.reload
    expect(@course.folders.count).to eq 1
  end

  describe ".assert_path" do
    specs_require_sharding

    it "does not get confused by the same context on multiple shards" do
      user1 = User.create!
      f1 = Folder.assert_path("myfolder", user1)
      @shard1.activate do
        user2 = User.new
        user2.id = user1.local_id
        user2.save!
        f2 = Folder.assert_path("myfolder", user2)
        expect(f2).not_to eq f1
      end
    end
  end

  describe "resolve_path" do
    before :once do
      @root_folder = Folder.root_folders(@course).first
    end

    it "returns a sequence of Folders" do
      foo = @course.folders.create! name: "foo", parent_folder: @root_folder
      bar = @course.folders.create! name: "bar", parent_folder: foo
      expect(Folder.resolve_path(@course, "foo/bar")).to eql [@root_folder, foo, bar]
    end

    it "ignores trailing slashes" do
      foo = @course.folders.create! name: "foo", parent_folder: @root_folder
      expect(Folder.resolve_path(@course, "foo/")).to eql [@root_folder, foo]
    end

    it "finds the root folder given an empty path" do
      expect(Folder.resolve_path(@course, "")).to eql [@root_folder]
    end

    it "finds the root folder given '/'" do
      expect(Folder.resolve_path(@course, "/")).to eql [@root_folder]
    end

    it "finds the root folder given a nil path" do
      expect(Folder.resolve_path(@course, nil)).to eql [@root_folder]
    end

    it "finds the root folder given an empty array" do
      expect(Folder.resolve_path(@course, [])).to eql [@root_folder]
    end

    it "returns nil on incomplete match" do
      @course.folders.create! name: "foo", parent_folder: @root_folder
      expect(Folder.resolve_path(@course, "foo/bar")).to be_nil
    end

    it "excludes hidden if specified" do
      foo = @course.folders.create! name: "foo", parent_folder: @root_folder
      foo.update_attribute(:workflow_state, "hidden")
      bar = @course.folders.create! name: "bar", parent_folder: foo
      expect(Folder.resolve_path(@course, "foo/bar", true)).to eql [@root_folder, foo, bar]
      expect(Folder.resolve_path(@course, "foo/bar", false)).to be_nil
    end

    it "excludes locked if specified" do
      foo = @course.folders.create! name: "foo", parent_folder: @root_folder, locked: true
      bar = @course.folders.create! name: "bar", parent_folder: foo
      expect(Folder.resolve_path(@course, "foo/bar", true)).to eql [@root_folder, foo, bar]
      expect(Folder.resolve_path(@course, "foo/bar", false)).to be_nil
    end

    it "accepts an array" do
      foo = @course.folders.create! name: "foo", parent_folder: @root_folder
      bar = @course.folders.create! name: "bar", parent_folder: foo
      expect(Folder.resolve_path(@course, ["foo", "bar"])).to eql [@root_folder, foo, bar]
    end
  end

  describe "file_attachments_visible_to" do
    before(:once) do
      @root_folder = Folder.root_folders(@course).first
      attachment_model context: @course, display_name: "normal.txt", folder: @root_folder, uploaded_data: default_uploaded_data
      attachment_model context: @course, display_name: "hidden.txt", folder: @root_folder, uploaded_data: default_uploaded_data, hidden: true
      attachment_model context: @course, display_name: "locked.txt", folder: @root_folder, uploaded_data: default_uploaded_data, locked: true
      attachment_model context: @course, display_name: "date_restricted_unlocked.txt", folder: @root_folder, uploaded_data: default_uploaded_data, unlock_at: 1.day.ago, lock_at: 1.year.from_now
      attachment_model context: @course, display_name: "date_restricted_locked.txt", folder: @root_folder, uploaded_data: default_uploaded_data, lock_at: 1.day.ago, unlock_at: 1.year.from_now
    end

    it "includes all files for teachers" do
      teacher_in_course active_all: true
      expect(@root_folder.file_attachments_visible_to(@teacher).map(&:name)).to match_array %w[normal.txt hidden.txt locked.txt date_restricted_unlocked.txt date_restricted_locked.txt]
    end

    it "excludes locked and hidden files for students" do
      student_in_course active_all: true
      expect(@root_folder.file_attachments_visible_to(@student).map(&:name)).to match_array %w[normal.txt date_restricted_unlocked.txt]
    end
  end

  describe "all_visible_folder_ids" do
    before(:once) do
      @root_folder = Folder.root_folders(@course).first
      @normal_folder = @root_folder.active_sub_folders.create!(context: @course, name: "normal")
      @normal_sub1 = @normal_folder.active_sub_folders.create!(context: @course, name: "normal_sub1")
      @normal_sub2 = @normal_sub1.active_sub_folders.create!(context: @course, name: "normal_sub2")
      @locked_folder = @root_folder.active_sub_folders.create!(context: @course, name: "locked", lock_at: 1.week.ago)
      @locked_sub1 = @locked_folder.active_sub_folders.create!(context: @course, name: "locked_sub1")
      @locked_sub2 = @locked_sub1.active_sub_folders.create!(context: @course, name: "locked_sub2")
    end

    it "excludes all descendants of locked folders" do
      expect(Folder.all_visible_folder_ids(@course)).to match_array([@root_folder, @normal_folder, @normal_sub1, @normal_sub2].map(&:id))
    end
  end

  describe "read_contents permission" do
    before(:once) do
      @course.offer!
      @root_folder = Folder.root_folders(@course).first
      student_in_course(course: @course, active_all: true)
      teacher_in_course(course: @course, active_all: true)
    end

    it "grants right to students and teachers" do
      expect(@root_folder.grants_right?(@student, :read_contents)).to be_truthy
      expect(@root_folder.grants_right?(@teacher, :read_contents)).to be_truthy
    end

    context "with files tab hidden to students" do
      before :once do
        @course.tab_configuration = [{ "id" => Course::TAB_FILES, "hidden" => true }]
        @course.save!
        @root_folder.reload
      end

      it "grants right to teachers but not students" do
        expect(@root_folder.grants_right?(@student, :read_contents)).to be_falsey
        expect(@root_folder.grants_right?(@teacher, :read_contents)).to be_truthy
      end

      it "still grants rights to teachers even if the teacher enrollment is concluded" do
        @teacher.enrollments.where(course_id: @course).first.complete!
        expect(@course.grants_right?(@teacher, :manage_files_add)).to be_falsey
        expect(@course.grants_right?(@teacher, :manage_files_edit)).to be_falsey
        expect(@course.grants_right?(@teacher, :manage_files_delete)).to be_falsey
        expect(@root_folder.grants_right?(@teacher, :read_contents)).to be_truthy
      end
    end
  end

  describe ".from_context_or_id" do
    it "delegate to root_folders when context is provided" do
      folder = Folder.root_folders(@course).first
      expect(Folder.from_context_or_id(@course, nil)).to eq(folder)
    end

    it "finds by id when context is not provided and id is" do
      Folder.root_folders(@course).first
      account_model
      folder_model(context: @account)
      expect(Folder.root_folders(@course).first).not_to eq(@folder),
                                                        "precondition"
      expect(Folder.from_context_or_id(nil, @folder.id)).to eq(@folder)
    end

    it "raises ActiveRecord::RecordNotFound when no record is found" do
      expect(Folder.where(id: 1)).to be_empty, "precondition"
      expect do
        Folder.from_context_or_id(nil, 1)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "submissions folders" do
    it "restricts valid contexts for submissions folders" do
      student_in_course
      group_model(context: @course)

      sf = Folder.new(name: "test")
      sf.submission_context_code = "root"

      sf.context = @user
      expect(sf).to be_valid

      sf.context = @group
      expect(sf).to be_valid

      sf.context = @course
      expect(sf).not_to be_valid
    end

    it "ensures only one root submissions folder per user exists" do
      user_factory
      @user.submissions_folder
      dup = @user.folders.build(name: "dup", parent_folder: Folder.root_folders(@user).first)
      dup.submission_context_code = "root"
      expect { dup.save! }.to raise_exception(ActiveRecord::RecordNotUnique)
    end

    it "ensures only one course submissions subfolder exists" do
      student_in_course
      @user.submissions_folder(@course)
      dup = @user.folders.build(name: "dup", parent_folder: @user.submissions_folder)
      dup.submission_context_code = @course.asset_string
      expect { dup.save! }.to raise_exception(ActiveRecord::RecordNotUnique)
    end
  end

  describe "permissions" do
    before(:once) do
      @course.offer!
      student_in_course(active_all: true)
    end

    let_once(:folder) { @course.folders.create!(name: "f") }
    let_once(:file) { attachment_model context: @course, display_name: "normal.txt", folder: }

    context "clears own permissions" do
      def student_can_read_contents?
        Folder.find(folder.id).grants_right? @student, :read_contents
      end

      it "when unlock_at set" do
        Timecop.freeze do
          folder.update! unlock_at: 5.minutes.from_now
          expect(student_can_read_contents?).to be false
          Timecop.travel(10.minutes)
          Delayed::Testing.drain
          expect(student_can_read_contents?).to be true
        end
      end

      it "when lock_at set" do
        Timecop.freeze do
          folder.update! lock_at: 5.minutes.from_now
          expect(student_can_read_contents?).to be true
          Timecop.travel(10.minutes)
          Delayed::Testing.drain
          expect(student_can_read_contents?).to be false
        end
      end

      it "when lock_at and unlock_at set" do
        Timecop.freeze do
          folder.update! unlock_at: 5.minutes.from_now, lock_at: 15.minutes.from_now
          expect(student_can_read_contents?).to be false
          Timecop.travel(10.minutes)
          Delayed::Testing.drain
          expect(student_can_read_contents?).to be true
          Timecop.travel(10.minutes)
          Delayed::Testing.drain
          expect(student_can_read_contents?).to be false
        end
      end
    end

    context "clears file permissions" do
      def student_can_download?
        file.reload.grants_right? @student, :download
      end

      it "when locked" do
        expect(student_can_download?).to be true
        folder.update! locked: true
        expect(student_can_download?).to be false
      end

      it "when unlocked" do
        folder.update! locked: true
        expect(student_can_download?).to be false
        folder.update! locked: false
        expect(student_can_download?).to be true
      end

      it "when moved" do
        expect(student_can_download?).to be true
        parent_folder = @course.folders.create!(name: "parent", locked: true)
        folder.update!(parent_folder:)
        expect(student_can_download?).to be false
      end

      it "in subfolders" do
        parent_folder = @course.folders.create!(name: "parent")
        parent_folder.sub_folders << folder
        expect(student_can_download?).to be true
        parent_folder.reload.update! locked: true
        expect(student_can_download?).to be false
      end
    end
  end

  describe "icon_maker_folder" do
    let_once(:course) { Course.create! }

    subject { Folder.icon_maker_folder(course) }

    context "when a 'Icon Maker' folder does not yet exist" do
      it "creates a folder with ICON_MAKER_UNIQUE_TYPE unique type when one does not exist" do
        expect do
          subject
        end.to change {
          course.folders.where(unique_type: Folder::ICON_MAKER_UNIQUE_TYPE).count
        }.from(0).to(1)
      end

      it "creates a folder with a default name of 'Icon Maker Icons'" do
        expect(subject.name).to eq "Icon Maker Icons"
      end
    end

    context "when an 'Icon Maker Icons' folder already exists" do
      before do
        @existing_folder = Folder.icon_maker_folder(course)
      end

      it "returns, rather than creates, the existing ICON_MAKER_UNIQUE_TYPE folder" do
        expect(subject).to eq @existing_folder
      end
    end
  end

  describe "#for_student_annotation_documents?" do
    it "is false when it does not have the correct unique_type" do
      annotation_documents_folder = @course.student_annotation_documents_folder
      folder_without_unique_type = @course.folders.create!(
        name: annotation_documents_folder.name,
        parent_folder: annotation_documents_folder.parent_folder,
        workflow_state: annotation_documents_folder.workflow_state
      )

      expect(folder_without_unique_type).not_to be_for_student_annotation_documents
    end

    it "is true when the folder is the student annotation documents folder for a course" do
      expect(@course.student_annotation_documents_folder).to be_for_student_annotation_documents
    end
  end

  describe "#destroy" do
    it "destroys sub-folders and files" do
      parent_folder = folder_model
      child_folder = folder_model(parent_folder_id: parent_folder.id)
      attachment = attachment_model(folder: child_folder)
      parent_folder.destroy
      expect(parent_folder).to be_deleted
      expect(child_folder.reload).to be_deleted
      expect(attachment.reload).to be_deleted
    end
  end

  describe "#restore" do
    it "restores until first non-deleted folder" do
      root_folder = folder_model
      grandparent_folder = folder_model(parent_folder_id: root_folder)
      parent_folder = folder_model(parent_folder_id: grandparent_folder)
      child_folder = folder_model(parent_folder_id: parent_folder.id)
      root_folder.workflow_state = "deleted"
      root_folder.save!

      parent_folder.destroy
      child_folder.reload

      child_folder.restore
      parent_folder.reload
      grandparent_folder.reload
      root_folder.reload

      expect(child_folder.workflow_state).to eq "visible"
      expect(parent_folder.workflow_state).to eq "visible"
      expect(grandparent_folder.workflow_state).to eq "visible"
      expect(root_folder.workflow_state).to eq "deleted"
    end

    it "deals with name collisions" do
      f = Folder.root_folders(@course).first
      expect(f.full_name).to eql("course files")
      child = f.active_sub_folders.build(name: "child")
      child.context = @course
      child.save!
      child.destroy
      child2 = f.active_sub_folders.build(name: "child")
      child2.context = @course
      child2.save!
      expect(child2.parent_folder).to eql(f)
      child.restore
      expect(child.full_name).to eql("course files/child 2")
    end
  end
end
