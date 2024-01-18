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
module CC::Importer::Canvas
  module CourseSettings
    include CC::Importer
    include LearningOutcomesConverter
    include RubricsConverter
    include ModuleConverter
    include CoursePacesConverter
    include BlueprintSettingsConverter

    def settings_doc(file, html = false)
      path = @package_root.item_path(COURSE_SETTINGS_DIR, file)
      return nil unless File.exist? path
      return nil if File.size(path) > 25.megabytes.to_i # totally arbitrary hack to keep some broken exports from killing things

      if html
        open_file path
      else
        open_file_xml path
      end
    end

    def convert_all_course_settings
      @course[:course] = convert_course_settings(settings_doc(COURSE_SETTINGS))
      if (doc = settings_doc(SYLLABUS, true))
        @course[:course][:syllabus_body] = convert_syllabus(doc)
      end
      @course[:assignment_groups] = convert_assignment_groups(settings_doc(ASSIGNMENT_GROUPS))
      @course[:external_tools] = convert_external_tools(settings_doc(EXTERNAL_TOOLS))
      @course[:external_feeds] = convert_external_feeds(settings_doc(EXTERNAL_FEEDS))
      @course[:grading_standards] = convert_grading_standards(settings_doc(GRADING_STANDARDS))
      @course[:learning_outcomes] = convert_learning_outcomes(settings_doc(LEARNING_OUTCOMES))
      @course[:modules] = convert_modules(settings_doc(MODULE_META))
      @course[:course_paces] = convert_course_paces(settings_doc(COURSE_PACES))
      @course[:rubrics] = convert_rubrics(settings_doc(RUBRICS))
      @course[:calendar_events] = convert_events(settings_doc(EVENTS))
      @course[:late_policy] = convert_late_policy(settings_doc(LATE_POLICY))
      @course[:blueprint_settings] = convert_blueprint_settings(settings_doc(BLUEPRINT_SETTINGS))
      @course[:context_info] = convert_context_info(settings_doc(CONTEXT_INFO))
    end

    def convert_course_settings(doc)
      course = {}
      return course unless doc

      course[:migration_id] = get_node_att(doc, "course", "identifier")

      %w[title
         course_code
         default_wiki_editing_roles
         turnitin_comments
         default_view
         license
         locale
         group_weighting_scheme
         storage_quota
         grading_standard_identifier_ref
         overridden_course_visibility
         root_account_uuid
         image_url
         image_identifier_ref
         banner_image_url
         banner_image_identifier_ref
         course_color
         alt_name
         time_zone].each do |string_type|
        val = get_node_val(doc, string_type)
        course[string_type] = val unless val.nil?
      end
      %w[is_public
         is_public_to_auth_users
         public_syllabus
         public_syllabus_to_auth
         syllabus_course_summary
         indexed
         allow_student_wiki_edits
         allow_student_assignment_edits
         show_public_context_messages
         allow_student_forum_attachments
         allow_student_organized_groups
         lock_all_announcements
         open_enrollment
         allow_wiki_comments
         self_enrollment
         hide_final_grade
         filter_speed_grader_by_student_group
         grading_standard_enabled
         hide_distribution_graphs
         allow_student_discussion_topics
         allow_student_discussion_editing
         show_announcements_on_home_page
         usage_rights_required
         restrict_student_future_view
         restrict_student_past_view
         restrict_quantitative_data
         show_total_grade_as_points
         organize_epub_by_content_type
         enable_offline_web_export
         restrict_enrollments_to_course_dates
         homeroom_course
         allow_final_grade_override
         enable_course_paces].each do |bool_val|
        val = get_bool_val(doc, bool_val)
        course[bool_val] = val unless val.nil?
      end
      ["start_at", "conclude_at"].each do |date_type|
        val = get_time_val(doc, date_type)
        course[date_type] = val
      end
      ["grading_standard_id", "home_page_announcement_limit"].each do |int_val|
        if (val = get_int_val(doc, int_val))
          course[int_val] = val
        end
      end
      if (nav = get_node_val(doc, "tab_configuration"))
        begin
          nav = JSON.parse(nav)
          # Validate the format a little bit
          # Should be something like [{"id"=>0},{"id"=>5},{"id"=>4}]
          if nav.present? && nav.is_a?(Array)
            course[:tab_configuration] = nav.select { |i| i.is_a?(Hash) && i["id"] }
          end
        rescue
          add_warning(I18n.t("errors.bad_navigation_config", "Invalid course tab configuration"), $!)
        end
      end

      post_manually = get_bool_val(doc, "default_post_policy post_manually")
      course[:default_post_policy] = { post_manually: } unless post_manually.nil?

      course
    end

    def convert_syllabus(doc)
      get_html_title_and_body(doc).last
    end

    def convert_assignment_groups(doc = nil)
      groups = []
      return groups unless doc

      doc.css("assignmentGroup").each do |node|
        group = {}
        group["migration_id"] = node["identifier"]
        group["title"] = get_node_val(node, "title")
        group["position"] = get_int_val(node, "position")
        group["group_weight"] = get_float_val(node, "group_weight")
        group["rules"] = []
        node.css("rules rule").each do |r_node|
          rule = {}
          rule["drop_type"] = get_node_val(r_node, "drop_type")
          rule["drop_count"] = get_int_val(r_node, "drop_count")
          rule["assignment_migration_id"] = get_node_val(r_node, "identifierref")
          group["rules"] << rule
        end

        groups << group
      end

      groups
    end

    # This is deprecated in favor of 'extensions' on the normal CC:BLTI xml format
    def convert_external_tools(doc)
      tools = []
      return tools unless doc

      doc.css("externalTool").each do |node|
        tool = {}
        tool["migration_id"] = node["identifier"]
        tool["title"] = get_node_val(node, "title")
        tool["description"] = get_node_val(node, "description")
        tool["domain"] = get_node_val(node, "domain")
        tool["url"] = get_node_val(node, "url")
        tool["privacy_level"] = get_node_val(node, "privacy_level")

        tools << tool
      end

      tools
    end

    def convert_external_feeds(doc)
      feeds = []
      return feeds unless doc

      doc.css("externalFeed").each do |node|
        feed = {}
        feed["migration_id"] = node["identifier"]
        feed["title"] = get_node_val(node, "title")
        feed["url"] = get_node_val(node, "url")
        feed["verbosity"] = get_node_val(node, "verbosity")
        feed["header_match"] = get_node_val(node, "header_match")

        feeds << feed
      end

      feeds
    end

    def convert_grading_standards(doc)
      standards = []
      return standards unless doc

      doc.css("gradingStandard").each do |node|
        standard = {}
        standard["migration_id"] = node["identifier"]
        standard["version"] = node["version"]
        standard["title"] = get_node_val(node, "title")
        standard["data"] = get_node_val(node, "data")
        standard["points_based"] = get_bool_val(node, "points_based")
        standard["scaling_factor"] = get_node_val(node, "scaling_factor")
        standards << standard
      end

      standards
    end

    def convert_events(doc)
      events = []
      return events unless doc

      doc.css("event").each do |node|
        event = {}
        event["migration_id"] = node["identifier"]
        event["title"] = get_node_val(node, "title")
        event["description"] = get_node_val(node, "description")
        event["start_at"] = get_time_val(node, "start_at")
        event["end_at"] = get_time_val(node, "end_at")
        event["all_day_date"] = get_time_val(node, "all_day_date")
        event["all_day"] = get_bool_val(node, "all_day", false)
        event["rrule"] = get_node_val(node, "rrule")
        event["series_uuid"] = get_node_val(node, "series_uuid")
        event["series_head"] = get_node_val(node, "series_head", nil)
        events << event
      end

      events
    end

    def convert_late_policy(doc)
      late_policy = {}
      return late_policy unless doc

      late_policy_node = doc.at_css("late_policy")
      late_policy["migration_id"] = late_policy_node["identifier"]
      late_policy["missing_submission_deduction_enabled"] = get_bool_val(late_policy_node, "missing_submission_deduction_enabled")
      late_policy["missing_submission_deduction"] = get_node_val(late_policy_node, "missing_submission_deduction")
      late_policy["late_submission_deduction_enabled"] = get_bool_val(late_policy_node, "late_submission_deduction_enabled")
      late_policy["late_submission_deduction"] = get_node_val(late_policy_node, "late_submission_deduction")
      late_policy["late_submission_interval"] = get_node_val(late_policy_node, "late_submission_interval")
      late_policy["late_submission_minimum_percent_enabled"] = get_bool_val(late_policy_node, "late_submission_minimum_percent_enabled")
      late_policy["late_submission_minimum_percent"] = get_node_val(late_policy_node, "late_submission_minimum_percent")

      late_policy
    end

    def convert_context_info(doc)
      context_info = {}
      return context_info unless doc

      node = doc.at_css("context_info")
      context_info["course_id"] = get_node_val(node, "course_id")
      context_info["course_name"] = get_node_val(node, "course_name")
      context_info["root_account_id"] = get_node_val(node, "root_account_id")
      context_info["root_account_uuid"] = get_node_val(node, "root_account_uuid")
      context_info["root_account_name"] = get_node_val(node, "root_account_name")
      context_info["canvas_domain"] = get_node_val(node, "canvas_domain")

      context_info
    end
  end
end
