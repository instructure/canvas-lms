//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('course_logging')

const last = obj => obj.at(-1)
const notEmpty = obj => Object.keys(obj).length > 0

export default class CourseEvent extends Backbone.Model {
  present() {
    const json = Backbone.Model.prototype.toJSON.call(this)
    const data = {}
    let iterator = (dataKey, dataValues) => {
      const key = this.presentLabel(dataKey)
      data[key] = this.presentField(dataValues)
    }

    switch (json.event_type) {
      case 'created':
        json.event_type_present = I18n.t('event_type.created', 'Created')
        iterator = (dataKey, dataValues) => {
          const key = this.presentLabel(dataKey)
          data[key] = this.presentField(last(dataValues))
        }
        break
      case 'updated':
        json.event_type_present = I18n.t('event_type.updated', 'Updated')
        iterator = (dataKey, dataValues) => {
          const key = this.presentLabel(dataKey)
          const values = this.presentField(dataValues)
          data[key] = {from: values[0], to: values[1]}
        }
        break
      case 'concluded':
        json.event_type_present = I18n.t('event_type.concluded', 'Concluded')
        break
      case 'unconcluded':
        json.event_type_present = I18n.t('event_type.unconcluded', 'Unconcluded')
        break
      case 'restored':
        json.event_type_present = I18n.t('event_type.restored', 'Restored')
        break
      case 'deleted':
        json.event_type_present = I18n.t('event_type.deleted', 'Deleted')
        break
      case 'published':
        json.event_type_present = I18n.t('event_type.published', 'Published')
        break
      case 'copied_from':
        json.event_type_present = I18n.t('event_type.copied_from', 'Copied From')
        break
      case 'copied_to':
        json.event_type_present = I18n.t('event_type.copied_to', 'Copied To')
        break
      case 'reset_from':
        json.event_type_present = I18n.t('event_type.reset_from', 'Reset From')
        break
      case 'reset_to':
        json.event_type_present = I18n.t('event_type.reset_to', 'Reset To')
        break
      case 'corrupted':
        json.event_type_present = I18n.t('event_type.corrupted', 'Details Not Available')
        break
      case 'claimed':
        // This occurs when a teacher unpublishes a course, but they don't leave the course
        // so we'll make this a bit more user friendly in the audit log UI
        json.event_type_present = I18n.t('Unpublished')
        break
      default:
        json.event_type_present = json.event_type
    }

    switch (json.event_source) {
      case 'manual':
        json.event_source_present = I18n.t('event_source.manual', 'Manual')
        break
      case 'api':
        json.event_source_present = I18n.t('event_source.api', 'Api')
        break
      case 'sis':
        json.event_source_present = I18n.t('event_source.sis', 'SIS')
        break
      case 'blueprint_sync':
        json.event_source_present = I18n.t('Blueprint Sync')
        break
      default:
        json.event_source_present = json.event_source || I18n.t('blank_placeholder', '-')
    }

    for (const [key, value] of Object.entries(json.event_data || {})) {
      iterator(key, value)
    }
    if (notEmpty(data)) json.event_data = data
    return json
  }

  presentField(value) {
    const blank = I18n.t('blank_placeholder', '-')
    if (value === null) return blank
    if (value === true || value === false) return value.toString()
    if (Array.isArray(value)) return value.map(this.presentField, this)
    if (typeof value?.valueOf() === 'string') {
      if (value.length === 0) return blank
      if (value.match(/^\d{4}-\d{2}-\d{2}(T| )\d{2}:\d{2}:\d{2}(.\d+)?Z$/)) {
        return I18n.l('#date.formats.medium', value) + ' ' + I18n.l('#time.formats.tiny', value)
      }
    }
    return value
  }

  presentLabel(label) {
    switch (label.toLowerCase()) {
      case 'name':
        return I18n.t('field_label.name', 'Name')
      case 'account_id':
        return I18n.t('field_label.account_id', 'Account Id')
      case 'group_weighting_scheme':
        return I18n.t('field_label.group_weighting_scheme', 'Group Weighting Scheme')
      case 'workflow_state':
        return I18n.t('field_label.workflow_state', 'Workflow State')
      case 'uuid':
        return I18n.t('field_label.uuid', 'UUID')
      case 'start_at':
        return I18n.t('field_label.start_at', 'Start At')
      case 'conclude_at':
        return I18n.t('field_label.conclude_at', 'Concluded At')
      case 'grading_standard_id':
        return I18n.t('field_label.grading_standard_id', 'Grading Standard Id')
      case 'is_public':
        return I18n.t('field_label.is_public', 'Is Public')
      case 'allow_student_wiki_edits':
        return I18n.t('field_label.allow_student_wiki_edits', 'Allow Student Wiki Edit')
      case 'created_at':
        return I18n.t('field_label.created_at', 'Created At')
      case 'updated_at':
        return I18n.t('field_label.updated_at', 'Updated At')
      case 'show_public_context_messages':
        return I18n.t('field_label.show_public_context_messages', 'Show Public Context Message')
      case 'syllabus_body':
        return I18n.t('field_label.syllabus_body', 'syllabus_body')
      case 'allow_student_forum_attachments':
        return I18n.t(
          'field_label.allow_student_forum_attachments',
          'Allow Student Forum Attachments'
        )
      case 'default_wiki_editing_roles':
        return I18n.t('field_label.default_wiki_editing_roles', 'Default Wiki Editing Roles')
      case 'wiki_id':
        return I18n.t('field_label.wiki_id', 'Wiki Id')
      case 'allow_student_organized_groups':
        return I18n.t(
          'field_label.allow_student_organized_groups',
          'Allow Student Organized Groups'
        )
      case 'course_code':
        return I18n.t('field_label.course_code', 'Course Code')
      case 'default_view':
        return I18n.t('field_label.default_view', 'Default View')
      case 'abstract_course_id':
        return I18n.t('field_label.abstract_course_id', 'Abstract Course Id')
      case 'root_account_id':
        return I18n.t('field_label.root_account_id', 'Root Account Id')
      case 'enrollment_term_id':
        return I18n.t('field_label.enrollment_term_id', 'Enrollment Term Id')
      case 'sis_source_id':
        return I18n.t('field_label.sis_source_id', 'SIS Source Id')
      case 'sis_batch_id':
        return I18n.t('field_label.sis_batch_id', 'SIS Batch Id')
      case 'open_enrollment':
        return I18n.t('field_label.open_enrollment', 'Open Enrollment')
      case 'storage_quota':
        return I18n.t('field_label.storage_quota', 'Storage Quota')
      case 'tab_configuration':
        return I18n.t('field_label.tab_configuration', 'Tab Configuration')
      case 'allow_wiki_comments':
        return I18n.t('field_label.allow_wiki_comments', 'Allow Wiki Comments')
      case 'turnitin_comments':
        return I18n.t('field_label.turnitin_comments', 'Turnitin Comments')
      case 'self_enrollment':
        return I18n.t('field_label.self_enrollment', 'Self Enrollment')
      case 'license':
        return I18n.t('field_label.license', 'License')
      case 'indexed':
        return I18n.t('field_label.indexed', 'Indexed')
      case 'restrict_enrollments_to_course_dates':
        return I18n.t(
          'field_label.restrict_enrollments_to_course_dates',
          'Restrict Enrollments To Course Dates'
        )
      case 'template_course_id':
        return I18n.t('field_label.template_course_id', 'Template Course Id')
      case 'locale':
        return I18n.t('field_label.locale', 'Locale')
      case 'replacement_course_id':
        return I18n.t('field_label.replacement_course_id', 'Replacement Course Id')
      case 'public_description':
        return I18n.t('field_label.public_description', 'Public Description')
      case 'self_enrollment_code':
        return I18n.t('field_label.self_enrollment_code', 'Self Enrollment Code')
      case 'self_enrollment_limit':
        return I18n.t('field_label.self_enrollment_limit', 'Self Enrollment Limit')
      case 'integration_id':
        return I18n.t('field_label.integration_id', 'Integration Id')
      case 'hide_final_grade':
        return I18n.t('field_label.hide_final_grade', 'Hide Final Grade')
      case 'hide_distribution_graphs':
        return I18n.t('field_label.hide_distribution_graphs', 'Hide Distribution Graphs')
      case 'allow_student_discussion_topics':
        return I18n.t(
          'field_label.allow_student_discussion_topics',
          'Allow Student Discussion Topics'
        )
      case 'allow_student_discussion_editing':
        return I18n.t(
          'field_label.allow_student_discussion_editing',
          'Allow Student Discussion Editing'
        )
      case 'lock_all_announcements':
        return I18n.t('field_label.lock_all_announcements', 'Lock All Announcements')
      case 'large_roster':
        return I18n.t('field_label.large_roster', 'Large Roster')
      case 'public_syllabus':
        return I18n.t('field_label.public_syllabus', 'Public Syllabus')
      default:
        return label
    }
  }
}
