define [
  'underscore'
  'Backbone'
  'i18n!course_logging'
], (_, Backbone, I18n) ->
  class CourseEvent extends Backbone.Model
    present: ->
      json = Backbone.Model::toJSON.call(@)
      data = {}
      iterator = (dataValue, dataKey) =>
        dataKey = @presentLabel(dataKey)
        data[dataKey] = @presentField(dataValue)

      switch json.event_type
        when "created"
          json.event_type_present = I18n.t("event_type.created", "Created")
          iterator = (dataValues, dataKey) =>
            dataKey = @presentLabel(dataKey)
            data[dataKey] = @presentField(_.last(dataValues))
        when "updated"
          json.event_type_present = I18n.t("event_type.updated", "Updated")
          iterator = (dataValues, dataKey) =>
            dataKey = @presentLabel(dataKey)
            data[dataKey] = _.object([ "from", "to" ], @presentField(dataValues))
        when "concluded"
          json.event_type_present = I18n.t("event_type.concluded", "Concluded")
        when "unconcluded"
          json.event_type_present = I18n.t("event_type.unconcluded", "Unconcluded")
        when "restored"
          json.event_type_present = I18n.t("event_type.restored", "Restored")
        when "deleted"
          json.event_type_present = I18n.t("event_type.deleted", "Deleted")
        when "published"
          json.event_type_present = I18n.t("event_type.published", "Published")
        when "copied_from"
          json.event_type_present = I18n.t("event_type.copied_from", "Copied From")
        when "copied_to"
          json.event_type_present = I18n.t("event_type.copied_to", "Copied To")
        when "reset_from"
          json.event_type_present = I18n.t("event_type.reset_from", "Reset From")
        when "reset_to"
          json.event_type_present = I18n.t("event_type.reset_to", "Reset To")
        else
          json.event_type_present = json.event_type

      switch json.event_source
        when "manual"
          json.event_source_present = I18n.t("event_source.manual", "Manual")
        when "api"
          json.event_source_present = I18n.t("event_source.api", "Api")
        when "sis"
          json.event_source_present = I18n.t("event_source.sis", "SIS")
        else
          json.event_source_present = json.event_source || I18n.t("blank_placeholder", "-")

      _.each json.event_data, iterator
      json.event_data = data unless _.isEmpty(data)
      return json

    presentField: (value) ->
      blank = I18n.t("blank_placeholder", "-")
      return blank if _.isNull(value)
      return value.toString() if _.isBoolean(value)
      if _.isArray(value)
        return _.map value, @presentField, @
      if _.isString(value)
        return blank if !value.length
        if value.match /^\d{4}-\d{2}-\d{2}(T| )\d{2}:\d{2}:\d{2}(.\d+)?Z$/
          return I18n.l("#date.formats.medium", value) + " " + I18n.l("#time.formats.tiny", value)
      return value

    presentLabel: (label) ->
      switch label.toLowerCase()
        when "name"
            I18n.t("field_label.name", "Name")
        when "account_id"
            I18n.t("field_label.account_id", "Account Id")
        when "group_weighting_scheme"
            I18n.t("field_label.group_weighting_scheme", "Group Weighting Scheme")
        when "old_account_id"
            I18n.t("field_label.old_account_id", "Old Account Id")
        when "workflow_state"
            I18n.t("field_label.workflow_state", "Workflow State")
        when "uuid"
            I18n.t("field_label.uuid", "UUID")
        when "start_at"
            I18n.t("field_label.start_at", "Start At")
        when "conclude_at"
            I18n.t("field_label.conclude_at", "Concluded At")
        when "grading_standard_id"
            I18n.t("field_label.grading_standard_id", "Grading Standard Id")
        when "is_public"
            I18n.t("field_label.is_public", "Is Public")
        when "allow_student_wiki_edits"
            I18n.t("field_label.allow_student_wiki_edits", "Allow Student Wiki Edit")
        when "created_at"
            I18n.t("field_label.created_at", "Created At")
        when "updated_at"
            I18n.t("field_label.updated_at", "Updated At")
        when "show_public_context_messages"
            I18n.t("field_label.show_public_context_messages", "Show Public Context Message")
        when "syllabus_body"
            I18n.t("field_label.syllabus_body", "syllabus_body")
        when "allow_student_forum_attachments"
            I18n.t("field_label.allow_student_forum_attachments", "Allow Student Forum Attachments")
        when "default_wiki_editing_roles"
            I18n.t("field_label.default_wiki_editing_roles", "Default Wiki Editing Roles")
        when "wiki_id"
            I18n.t("field_label.wiki_id", "Wiki Id")
        when "allow_student_organized_groups"
            I18n.t("field_label.allow_student_organized_groups", "Allow Student Organized Groups")
        when "course_code"
            I18n.t("field_label.course_code", "Course Code")
        when "default_view"
            I18n.t("field_label.default_view", "Default View")
        when "abstract_course_id"
            I18n.t("field_label.abstract_course_id", "Abstract Course Id")
        when "root_account_id"
            I18n.t("field_label.root_account_id", "Root Account Id")
        when "enrollment_term_id"
            I18n.t("field_label.enrollment_term_id", "Enrollment Term Id")
        when "sis_source_id"
            I18n.t("field_label.sis_source_id", "SIS Source Id")
        when "sis_batch_id"
            I18n.t("field_label.sis_batch_id", "SIS Batch Id")
        when "show_all_discussion_entries"
            I18n.t("field_label.show_all_discussion_entries", "Show All Discussion Entries")
        when "open_enrollment"
            I18n.t("field_label.open_enrollment", "Open Enrollment")
        when "storage_quota"
            I18n.t("field_label.storage_quota", "Storage Quota")
        when "tab_configuration"
            I18n.t("field_label.tab_configuration", "Tab Configuration")
        when "allow_wiki_comments"
            I18n.t("field_label.allow_wiki_comments", "Allow Wiki Comments")
        when "turnitin_comments"
            I18n.t("field_label.turnitin_comments", "Turnitin Comments")
        when "self_enrollment"
            I18n.t("field_label.self_enrollment", "Self Enrollment")
        when "license"
            I18n.t("field_label.license", "License")
        when "indexed"
            I18n.t("field_label.indexed", "Indexed")
        when "restrict_enrollments_to_course_dates"
            I18n.t("field_label.restrict_enrollments_to_course_dates", "Restrict Enrollments To Course Dates")
        when "template_course_id"
            I18n.t("field_label.template_course_id", "Template Course Id")
        when "locale"
            I18n.t("field_label.locale", "Locale")
        when "replacement_course_id"
            I18n.t("field_label.replacement_course_id", "Replacement Course Id")
        when "public_description"
            I18n.t("field_label.public_description", "Public Description")
        when "self_enrollment_code"
            I18n.t("field_label.self_enrollment_code", "Self Enrollment Code")
        when "self_enrollment_limit"
            I18n.t("field_label.self_enrollment_limit", "Self Enrollment Limit")
        when "integration_id"
            I18n.t("field_label.integration_id", "Integration Id")
        when "hide_final_grade"
            I18n.t("field_label.hide_final_grade", "Hide Final Grade")
        when "hide_distribution_graphs"
            I18n.t("field_label.hide_distribution_graphs", "Hide Distribution Graphs")
        when "allow_student_discussion_topics"
            I18n.t("field_label.allow_student_discussion_topics", "Allow Student Discussion Topics")
        when "allow_student_discussion_editing"
            I18n.t("field_label.allow_student_discussion_editing", "Allow Student Discussion Editing")
        when "lock_all_announcements"
            I18n.t("field_label.lock_all_announcements", "Lock All Announcements")
        when "large_roster"
            I18n.t("field_label.large_roster", "Large Roster")
        when "public_syllabus"
            I18n.t("field_label.public_syllabus", "Public Syllabus")
        else
          label