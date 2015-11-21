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

describe EpubExport do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "after_create" do
    it "should create one job progress" do
      expect{@course.epub_exports.create(user: @student)}.to change{Progress.count}.from(0).to(1)
    end
  end

  describe "#export" do
    let_once(:epub_export) do
      @course.epub_exports.create({
        user: @student
      })
    end

    context "method is successful" do
      it "should create one content_export" do
        expect{epub_export.export_without_send_later}.to change{ContentExport.count}.from(0).to(1)
      end

      it "should set state to 'exporting'" do
        epub_export.export_without_send_later
        expect(epub_export.workflow_state).to eq 'exporting'
      end

      it "should set job_progress completion to 25%" do
        epub_export.export_without_send_later
        expect(epub_export.job_progress.completion).to eq 25.0
      end

      it "should start job_progress" do
        epub_export.export_without_send_later
        expect(epub_export.job_progress.reload.running?).to be_truthy
      end
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
        content_export: content_export
      })
    end

    context "when content export is successful" do
      before(:once) do
        epub_export.content_export.update_attribute(:workflow_state, 'exported')
        epub_export.mark_exported_without_send_later
      end

      it "should change the workflow state of epub_export to exported" do
        expect(epub_export.workflow_state).to eq 'exported'
      end

      it "should set job_progress completion to 50" do
        expect(epub_export.job_progress.completion).to eq 50.0
      end
    end

    context "when content export is failed" do
      it "should change the workflow state of epub_export to failed" do
        epub_export.content_export.update_attribute(:workflow_state, 'failed')
        epub_export.mark_exported_without_send_later
        expect(epub_export.workflow_state).to eq 'failed'
      end
    end
  end

  describe "#generate" do
    let_once(:epub_export) do
      @course.epub_exports.create({
        user: @student
      }).tap do |epub_export|
        epub_export.update_attribute(:workflow_state, 'exported')
      end
    end

    it "should set job_progress completion to 75" do
      epub_export.generate_without_send_later
      expect(epub_export.job_progress.completion).to eq 75.0
    end

    it "should set state to generating" do
      epub_export.generate_without_send_later
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
        content_export: content_export
      })
    end

    it 'should create and associate an attachment' do
      expect(epub_export.epub_attachment).to be_nil, 'precondition'
      expect(epub_export.zip_attachment).to be_nil, 'precondition'

      expect{epub_export.convert_to_epub_without_send_later}.to change{Attachment.count}.by(2)

      epub_export.reload
      expect(epub_export.epub_attachment).not_to be_nil
      expect(epub_export.zip_attachment).not_to be_nil
    end
  end

  describe "permissions" do
    describe ":create" do
      context "when user can :read_as_admin" do
        it "should be able to :create an epub export instance" do
          expect(@course.grants_right?(@teacher, :read_as_admin)).to be_truthy, 'precondition'
          expect(EpubExport.new(course: @course).grants_right?(@teacher, :create)).to be_truthy
        end
      end

      context "when user can :participate_as_student" do
        it "should be able to :create an epub export instance" do
          expect(@course.grants_right?(@student, :participate_as_student)).to be_truthy, 'precondition'
          expect(EpubExport.new(course: @course).grants_right?(@student, :create)).to be_truthy
        end
      end

      context "when user cannot :participate_as_student" do
        it "should not be able to :create an epub export" do
          student_in_course
          expect(@course.grants_right?(@student, :participate_as_student)).to be_falsey, 'precondition'
          expect(EpubExport.new(course: @course).grants_right?(@student, :create)).to be_falsey
        end
      end
    end

    describe ":regenerate" do
      let_once(:epub_export) do
        @course.epub_exports.create(user: @student)
      end

      [ "generated", "failed" ].each do |state|
        context "when state is #{state}" do
          it "should allow regeneration" do
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
      ['created', 'exporting', 'exported', 'generating'].each do |state|
        it "should return epub export when workflow_state is #{state}" do
          epub_export.update_attribute(:workflow_state, state)
          expect(EpubExport.running.count).to eq 1
        end
      end

      ['generated', 'failed', 'deleted'].each do |state|
        it "should return epub export when workflow_state is #{state}" do
          epub_export.update_attribute(:workflow_state, state)
          expect(EpubExport.running.count).to eq 0
        end
      end
    end

    context "visible_to" do
      it "should be visible to the user who created the epub export" do
        expect(EpubExport.visible_to(@student.id).count).to eq 1
      end

      it "should not be visible to the user who didn't create the epub export" do
        expect(EpubExport.visible_to(@teacher.id).count).to eq 0
      end
    end
  end
end
