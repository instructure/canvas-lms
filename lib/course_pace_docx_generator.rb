# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
class CoursePaceDocxGenerator
  attr_reader :course_report, :section_ids, :enrollment_ids, :course

  def initialize(course_report, section_ids, enrollment_ids)
    @course_report = course_report
    @section_ids = section_ids
    @enrollment_ids = enrollment_ids
    @course = course_report.course
  end

  def generate(progress)
    files_by_name = {}

    loaded_sections = course.course_sections.where(id: section_ids)
    loaded_sections.each_with_index do |section, idx|
      progress.calculate_completion!(idx, loaded_sections.count + 1)
      course_pace = CoursePace.pace_for_context(course, section)

      docx_stream = CoursePacePresenter.new(course_pace).as_docx(section)
      entry_name = generate_file_name(section)

      f = Tempfile.open([entry_name, ".docx"])
      f.write docx_stream.read.force_encoding("UTF-8")
      f.close
      files_by_name[entry_name] = f
    end

    loaded_enrollments = course.enrollments.where(id: enrollment_ids)
    loaded_enrollments.each_with_index do |enrollment, idx|
      progress.calculate_completion!(idx, loaded_enrollments.count + 1)
      course_pace = CoursePace.pace_for_context(course, enrollment)

      docx_stream = CoursePacePresenter.new(course_pace).as_docx(enrollment)
      entry_name = generate_file_name(enrollment)

      f = Tempfile.open([entry_name, ".docx"])
      f.write docx_stream.read.force_encoding("UTF-8")
      f.close
      files_by_name[entry_name] = f
    end

    if files_by_name.size == 1
      filename = files_by_name.keys.first + ".docx"
      data = Canvas::UploadedFile.new(files_by_name.values.first.path, filename)
    elsif files_by_name.size > 1
      filename = "course_pace.zip"
      zipio = Zip::OutputStream.write_buffer do |zio|
        files_by_name.each_key do |entry_name|
          zio.put_next_entry(entry_name + ".docx")
          zio.write File.read(files_by_name[entry_name].path)
        end
      end
      zipio.rewind

      f = Tempfile.open(["course_paces", ".zip"])
      f << zipio.read.force_encoding("UTF-8")
      f.close

      files_by_name[filename] = f

      data = Canvas::UploadedFile.new(f.path, filename)
    end

    attachment = Attachment.new(context: course_report, display_name: filename, user: course_report.user)
    Attachments::Storage.store_for_attachment(attachment, data)
    attachment.save!
    course_report.update(attachment:)
  end

  private

  def generate_file_name(pace_context)
    case pace_context
    when Course
      "#{pace_context.name}_Default_Pace"
    when CourseSection
      "#{pace_context.name}_Section_Pace"
    when Enrollment
      "#{pace_context.user.name}'s_Pace"
    end
  end
end
