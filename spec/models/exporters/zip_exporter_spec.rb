# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"

describe "Exporters::ZipExporter" do
  describe "#export" do
    let(:course) { Course.create!(workflow_state: "available") }
    let(:folder) { course.folders.create! }
    let(:student) { course.enroll_student(User.create!).user }
    let(:teacher) { course.enroll_teacher(User.create!).user }

    shared_examples_for "exports for users with file access" do
      it "includes the course attachment" do
        expect(Zip::File.open(subject.open).entries.map(&:to_s)).to eq ["file.txt"]
      end
    end

    shared_examples_for "exports for users without file access" do
      it "does not include the course attachments" do
        expect(Zip::File.open(subject.open).entries.map(&:to_s)).to be_empty
      end
    end

    describe "exporting attachments" do
      def exporter_for_attachment(attachment, course, user)
        content_export = course.content_exports.create!(
          user: user,
          workflow_state: "created",
          selected_content: { attachments: { "attachment_#{attachment.id}": "1" } }
        )

        Exporters::ZipExporter.new(content_export)
      end

      context "when exporting a published attachment" do
        before(:each) do
          attachment_model(
            context: course,
            folder: folder,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain")
          )
        end

        let(:exporter) { exporter_for_attachment(@attachment, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }

          it_behaves_like "exports for users with file access"
        end
      end

      context "when exporting an unpublished attachment" do
        before(:each) do
          attachment_model(
            context: course,
            folder: folder,
            locked: true,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain")
          )
        end

        let(:exporter) { exporter_for_attachment(@attachment, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }

          it_behaves_like "exports for users without file access"
        end
      end

      context "when exporting an availability locked attachment" do
        before(:each) do
          attachment_model(
            context: course,
            folder: folder,
            lock_at: 1.day.ago,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain"),
            unlock_at: 3.days.ago
          )
        end

        let(:exporter) { exporter_for_attachment(@attachment, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }

          it_behaves_like "exports for users without file access"
        end
      end

      context "when exporting a hidden attachment" do
        before(:each) do
          attachment_model(
            context: course,
            file_state: "hidden",
            folder: folder,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain")
          )
        end

        let(:exporter) { exporter_for_attachment(@attachment, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }
          # This is different from the spec in this test file where there is no
          # attachment when exporting a hidden folder, but the UI allows for
          # downloading hidden attachments when the user has a direct link.
          it_behaves_like "exports for users with file access"
        end
      end
    end

    describe "exporting folders" do
      def exporter_for_folder(folder, course, user)
        content_export = course.content_exports.create!(
          user: user,
          workflow_state: "created",
          selected_content: { folders: { "folder_#{folder.id}": "1" } }
        )

        Exporters::ZipExporter.new(content_export)
      end

      context "when exporting a published folder with published files" do
        before(:each) do
          attachment_model(
            context: course,
            folder: folder,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain")
          )
        end

        let(:exporter) { exporter_for_folder(folder, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }

          it_behaves_like "exports for users with file access"
        end
      end

      context "when exporting an unpublished folder containing unpublished files" do
        before(:each) do
          folder.update!(locked: true)

          attachment_model(
            context: course,
            folder: folder,
            locked: true,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain")
          )
        end

        let(:exporter) { exporter_for_folder(folder, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }

          it_behaves_like "exports for users without file access"
        end
      end

      context "when exporting an availability locked folder with availability locked files" do
        before(:each) do
          folder.update!(lock_at: 1.day.ago, unlock_at: 3.days.ago)

          attachment_model(
            context: course,
            folder: folder,
            lock_at: 1.day.ago,
            unlock_at: 3.days.ago,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain")
          )
        end

        let(:exporter) { exporter_for_folder(folder, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }

          it_behaves_like "exports for users without file access"
        end
      end

      context "when exporting a hidden folder with hidden files" do
        before(:each) do
          folder.update!(workflow_state: "hidden")

          attachment_model(
            context: course,
            file_state: "hidden",
            folder: folder,
            uploaded_data: stub_file_data("file.txt", "some text", "text/plain"),
          )
        end

        let(:exporter) { exporter_for_folder(folder, course, @user) }

        subject { exporter.export }

        context "when the user is an active teacher" do
          before(:each) { @user = teacher }

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a concluded teacher" do
          before(:each) do
            teacher.enrollments.find_by(course: course).conclude
            @user = teacher
          end

          it_behaves_like "exports for users with file access"
        end

        context "when the user is a student" do
          before(:each) { @user = student }

          it_behaves_like "exports for users without file access"
        end
      end
    end
  end
end
