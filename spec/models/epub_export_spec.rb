# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe EpubExport do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "after_create" do
    it "creates one job progress" do
      expect { @course.epub_exports.create(user: @student) }.to change { Progress.count }.from(0).to(1)
    end
  end

  describe "#export" do
    let_once(:epub_export) do
      @course.epub_exports.create({
                                    user: @student
                                  })
    end

    context "method is successful" do
      it "creates one content_export" do
        expect { epub_export.export(synchronous: true) }.to change { ContentExport.count }.from(0).to(1)
      end

      it "sets state to 'exporting'" do
        epub_export.export(synchronous: true)
        expect(epub_export.workflow_state).to eq "exporting"
      end

      it "starts job_progress" do
        epub_export.export(synchronous: true)
        expect(epub_export.job_progress.reload.running?).to be_truthy
      end
    end
  end

  describe "attachment" do
    let_once(:cartridge_path) do
      File.join(File.dirname(__FILE__), "/../fixtures/migration/unicode-filename-test-export.imscc")
    end

    let_once(:content_export) do
      @course.content_exports.create({
                                       user: @student
                                     }).tap do |content_export|
        content_export.create_attachment({
                                           context: @course,
                                           filename: File.basename(cartridge_path),
                                           uploaded_data: File.open(cartridge_path)
                                         })
      end
    end

    let_once(:epub_export) do
      @course.epub_exports.create({
                                    user: @student,
                                    content_export:
                                  })
    end

    it "is stored in instfs if instfs is enabled" do
      uuid = "1234-abcd"
      allow(InstFS).to receive_messages(enabled?: true, direct_upload: uuid)
      epub_export.convert_to_epub(synchronous: true)
      expect(epub_export.epub_attachment.instfs_uuid).to eq uuid
    end
  end

  describe "mark_exported" do
    let_once(:content_export) do
      @course.content_exports.create({
                                       user: @student
                                     })
    end
    let_once(:epub_export) do
      @course.epub_exports.create({
                                    user: @student,
                                    content_export:
                                  })
    end

    context "when content export is successful" do
      before(:once) do
        epub_export.content_export.update_attribute(:workflow_state, "exported")
        epub_export.mark_exported(synchronous: true)
      end

      it "changes the workflow state of epub_export to exported" do
        expect(epub_export.workflow_state).to eq "exported"
      end

      it "updates job_progress completion" do
        expect(epub_export.job_progress.completion).to eq EpubExport::PERCENTAGE_COMPLETE[:exported]
      end
    end

    context "when content export is failed" do
      it "changes the workflow state of epub_export to failed" do
        epub_export.content_export.update_attribute(:workflow_state, "failed")
        epub_export.mark_exported(synchronous: true)
        expect(epub_export.workflow_state).to eq "failed"
      end
    end
  end

  describe "#generate" do
    let_once(:epub_export) do
      @course.epub_exports.create({
                                    user: @student
                                  }).tap do |epub_export|
        epub_export.update_attribute(:workflow_state, "exported")
      end
    end

    it "updates job_progress completion" do
      epub_export.generate(synchronous: true)
      expect(epub_export.job_progress.completion).to eq EpubExport::PERCENTAGE_COMPLETE[:generating]
    end

    it "sets state to generating" do
      epub_export.generate(synchronous: true)
      expect(epub_export.generating?).to be_truthy
    end
  end

  describe "#convert_to_epub" do
    let_once(:cartridge_path) do
      File.join(File.dirname(__FILE__), "/../fixtures/migration/unicode-filename-test-export.imscc")
    end

    let_once(:content_export) do
      @course.content_exports.create({
                                       user: @student
                                     }).tap do |content_export|
        content_export.create_attachment({
                                           context: @course,
                                           filename: File.basename(cartridge_path),
                                           uploaded_data: File.open(cartridge_path)
                                         })
      end
    end

    let_once(:epub_export) do
      @course.epub_exports.create({
                                    user: @student,
                                    content_export:
                                  })
    end

    it "creates and associate an attachment" do
      expect(epub_export.epub_attachment).to be_nil, "precondition"
      expect(epub_export.zip_attachment).to be_nil, "precondition"

      expect { epub_export.convert_to_epub(synchronous: true) }.to change { Attachment.count }.by(2)

      epub_export.reload
      expect(epub_export.epub_attachment).not_to be_nil
      expect(epub_export.zip_attachment).not_to be_nil
    end
  end

  describe "permissions" do
    describe ":create" do
      context "when user can :read_as_admin" do
        it "is able to :create an epub export instance" do
          expect(@course.grants_right?(@teacher, :read_as_admin)).to be_truthy, "precondition"
          expect(EpubExport.new(course: @course).grants_right?(@teacher, :create)).to be_truthy
        end
      end

      context "when user can :participate_as_student" do
        it "is able to :create an epub export instance" do
          expect(@course.grants_right?(@student, :participate_as_student)).to be_truthy, "precondition"
          expect(EpubExport.new(course: @course).grants_right?(@student, :create)).to be_truthy
        end
      end

      context "when user cannot :participate_as_student" do
        it "is not able to :create an epub export" do
          student_in_course
          expect(@course.grants_right?(@student, :participate_as_student)).to be_falsey, "precondition"
          expect(EpubExport.new(course: @course).grants_right?(@student, :create)).to be_falsey
        end
      end
    end

    describe ":regenerate" do
      let_once(:epub_export) do
        @course.epub_exports.create(user: @student)
      end

      ["generated", "failed"].each do |state|
        context "when state is #{state}" do
          it "allows regeneration" do
            epub_export.update_attribute(:workflow_state, state)
            expect(epub_export.grants_right?(@student, :regenerate)).to be_truthy
          end
        end
      end
    end
  end

  describe "scopes" do
    let_once(:epub_export) do
      @course.epub_exports.create({
                                    user: @student
                                  })
    end

    context "running" do
      %w[created exporting exported generating].each do |state|
        it "returns epub export when workflow_state is #{state}" do # rubocop:disable RSpec/RepeatedDescription
          epub_export.update_attribute(:workflow_state, state)
          expect(EpubExport.running.count).to eq 1
        end
      end

      %w[generated failed deleted].each do |state|
        it "returns epub export when workflow_state is #{state}" do # rubocop:disable RSpec/RepeatedDescription
          epub_export.update_attribute(:workflow_state, state)
          expect(EpubExport.running.count).to eq 0
        end
      end
    end

    context "visible_to" do
      it "is visible to the user who created the epub export" do
        expect(EpubExport.visible_to(@student.id).count).to eq 1
      end

      it "is not visible to the user who didn't create the epub export" do
        expect(EpubExport.visible_to(@teacher.id).count).to eq 0
      end
    end
  end

  describe "#set_locale" do
    let_once(:cartridge_path) do
      File.join(File.dirname(__FILE__), "/../fixtures/migration/unicode-filename-test-export.imscc")
    end
    let_once(:content_export) do
      @course.content_exports.create({
                                       user: @student
                                     }).tap do |content_export|
        content_export.create_attachment({
                                           context: @course,
                                           filename: File.basename(cartridge_path),
                                           uploaded_data: File.open(cartridge_path)
                                         })
      end
    end
    let_once(:epub_export) do
      @course.epub_exports.create({
                                    user: @student,
                                    content_export:
                                  })
    end

    it "is called during export and resets locale after" do
      expect(epub_export).to receive(:infer_locale).once
                                                   .with(context: @course, user: @student, root_account: @course.root_account)
                                                   .and_return(:ru)
      epub_export.convert_to_epub(synchronous: true)
      expect(I18n.locale).to be :en
    end

    it "sets locale based on user preference" do
      @student.update_attribute(:locale, "es")
      expect(epub_export.reload.send(:set_locale)).to eq "es"
    end

    it "sets locale based on course override" do
      @course.update_attribute(:locale, "da")
      expect(epub_export.reload.send(:set_locale)).to eq "da"
    end

    it "allows course locale to override user locale" do
      @student.update_attribute(:locale, "es")
      @course.update_attribute(:locale, "da")
      expect(epub_export.reload.send(:set_locale)).to eq "da"
    end
  end

  context "notifications" do
    before :once do
      course_with_teacher(active_all: true)
      @ce = @course.content_exports.create! { |ce| ce.user = @user }
      @epub = EpubExport.create!(course: @course, user: @user, content_export: @ce)

      Notification.create!(name: "Content Export Finished", category: "Migration")
      Notification.create!(name: "Content Export Failed", category: "Migration")
    end

    it "sends notifications immediately" do
      communication_channel_model.confirm!

      @epub.workflow_state = "generated"
      expect { @epub.save! }.not_to change(DelayedMessage, :count)
      expect(@epub.messages_sent["Content Export Finished"]).not_to be_blank

      @epub.workflow_state = "failed"
      expect { @epub.save! }.not_to change(DelayedMessage, :count)
      expect(@epub.messages_sent["Content Export Failed"]).not_to be_blank
    end

    it "does not send emails for epub or webzip exports when content export has exported" do
      @ce.workflow_state = "exported"
      expect { @ce.save! }.not_to change(DelayedMessage, :count)
      expect(@ce.messages_sent["Content Export Finished"]).to be_blank

      @ce.workflow_state = "failed"
      expect { @ce.save! }.not_to change(DelayedMessage, :count)
      expect(@ce.messages_sent["Content Export Failed"]).to be_blank
    end
  end

  it "escapes html characters in titles" do
    course_with_student(active_all: true)
    @course.assignments.create!({
                                  title: "here you go </html> lol",
                                  description: "beep beep"
                                })

    EpubExports::CreateService.new(@course, @student, :epub_export).save
    run_jobs

    epub_export = @course.epub_exports.where(user_id: @student).first
    expect(epub_export).to be_generated
    path = epub_export.epub_attachment.open.path
    zip_file = Zip::File.open(path)
    html = zip_file.read(zip_file.entries.map(&:name).detect { |n| n.include?("assignments") })
    expect(html).to include("here you go &lt;/html&gt; lol")
  end
end
