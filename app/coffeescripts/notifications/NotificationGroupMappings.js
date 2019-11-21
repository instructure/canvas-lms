//
// Copyright (C) 2012 - present Instructure, Inc.
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

import I18n from 'i18n!notification_preferences'

// This class create the Notification Preferences display table and manages the data storage for it.
export default class NotificationGroupMappings {
  constructor(options) {
    // Define the visual grouping and order for the groups and items. The strings below are not used for direct
    // display but are the group names and category names used internally. The 'getGroupDisplayName' method
    // gets the I18n version of the group name. The display text used for the items gets set through the
    // ProfileController#communication. The values are defined in Notification#category_display_name.
    this.getGroupDisplayName = this.getGroupDisplayName.bind(this)
    this.options = options
    this.groups = {
      Course: [
        'due_date',
        'grading_policies',
        'course_content',
        'files',
        'announcement',
        'announcement_created_by_you',
        'announcement_reply',
        'grading',
        'invitation',
        'all_submissions',
        'late_grading',
        'submission_comment',
        'blueprint'
      ],
      Discussions: ['discussion', 'discussion_entry'],
      Communication: ['added_to_conversation', 'conversation_message', 'conversation_created'],
      Scheduling: [
        'student_appointment_signups',
        'appointment_signups',
        'appointment_cancelations',
        'appointment_availability',
        'calendar'
      ],
      Parent: [],
      Groups: ['membership_update'],
      Conferences: ['recording_ready'],
      Alerts: ['other', 'content_link_error', 'account_notification']
    }
  }

  // Get the I18n display text to use for the group name.
  getGroupDisplayName(groupName) {
    switch (groupName) {
      case 'Course':
        return I18n.t('groups.course', 'Course Activities')
      case 'Discussions':
        return I18n.t('groups.discussions', 'Discussions')
      case 'Communication':
        return I18n.t('groups.communication', 'Conversations')
      case 'Scheduling':
        return I18n.t('groups.scheduling', 'Scheduling')
      case 'Parent':
        return I18n.t('groups.parent', 'Parent Emails')
      case 'Groups':
        return I18n.t('groups.groups', 'Groups')
      case 'Alerts':
        return I18n.t('groups.alerts', 'Alerts')
      case 'Other':
        return I18n.t('groups.admin', 'Administrative')
      case 'Conferences':
        return I18n.t('groups.conferences', 'Conferences')
      default:
        return I18n.t('groups.other', 'Other')
    }
  }
}
