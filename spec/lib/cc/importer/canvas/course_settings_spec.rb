# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class CourseSettingConverterTestClass
  include CC::Importer::Canvas::CourseSettings
end

describe CC::Importer::Canvas::CourseSettings do
  subject { CourseSettingConverterTestClass.new.convert_course_settings(mock_html_meta) }

  describe "#convert_course_settings" do
    %w[allow_final_grade_override
       allow_student_anonymous_discussion_topics
       allow_student_assignment_edits
       allow_student_discussion_editing
       allow_student_discussion_reporting
       allow_student_discussion_topics
       allow_student_forum_attachments
       allow_student_organized_groups
       allow_student_wiki_edits
       allow_wiki_comments
       enable_course_paces
       enable_offline_web_export
       filter_speed_grader_by_student_group
       grading_standard_enabled
       hide_distribution_graphs
       hide_final_grade
       homeroom_course
       indexed
       is_public
       is_public_to_auth_users
       lock_all_announcements
       open_enrollment
       organize_epub_by_content_type
       public_syllabus
       public_syllabus_to_auth
       restrict_enrollments_to_course_dates
       restrict_quantitative_data
       restrict_student_future_view
       restrict_student_past_view
       self_enrollment
       show_announcements_on_home_page
       show_public_context_messages
       show_total_grade_as_points
       syllabus_course_summary
       usage_rights_required].each do |boolean_field|
      describe boolean_field do
        context "when #{boolean_field} is true" do
          let(:mock_html_meta) do
            builder = Nokogiri::XML::Builder.new do |xml|
              xml.course(identifier: "mock-id") do
                xml.send(boolean_field, true)
              end
            end

            Nokogiri::XML(builder.to_xml)
          end

          it "should be true" do
            expect(subject[boolean_field]).to be_truthy
          end
        end

        context "when #{boolean_field} is false" do
          let(:mock_html_meta) do
            builder = Nokogiri::XML::Builder.new do |xml|
              xml.course(identifier: "mock-id") do
                xml.send(boolean_field, false)
              end
            end

            Nokogiri::XML(builder.to_xml)
          end

          it "should be false" do
            expect(subject[boolean_field]).to be_falsey
          end
        end

        context "when #{boolean_field} is missing from input" do
          let(:mock_html_meta) do
            Nokogiri::XML(Nokogiri::XML::Builder.new { |xml| xml.course(identifier: "mock-id") }.to_xml)
          end

          it "should missing from result hash" do
            expect(subject).not_to have_key(boolean_field)
          end
        end
      end
    end
  end
end
