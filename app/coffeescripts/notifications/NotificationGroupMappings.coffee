#
# Copyright (C) 2012 - present Instructure, Inc.
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

# This class create the Notification Preferences display table and manages the data storage for it.
define [
  'i18n!notification_preferences'
  'jquery'
  'underscore'
], (I18n, $, _) ->

  class NotificationGroupMappings

    constructor: (@options) ->
      # Define the visual grouping and order for the groups and items. The strings below are not used for direct
      # display but are the group names and category names used internally. The 'getGroupDisplayName' method
      # gets the I18n version of the group name. The display text used for the items gets set through the
      # ProfileController#communication. The values are defined in Notification#category_display_name.
      @groups =
        Course: ['due_date', 'grading_policies', 'course_content', 'files', 'announcement',
                 'announcement_created_by_you', 'announcement_reply', 'grading', 'invitation',
                 'all_submissions', 'late_grading', 'submission_comment', 'blueprint']
        Discussions: ['discussion', 'discussion_entry']
        Communication: ['added_to_conversation', 'conversation_message', 'conversation_created']
        Scheduling: ['student_appointment_signups', 'appointment_signups', 'appointment_cancelations',
                     'appointment_availability', 'calendar']
        Parent: []
        Groups: ['membership_update']
        Alerts: ['other']
        Conferences: ['recording_ready']

    # Get the I18n display text to use for the group name.
    getGroupDisplayName: (groupName) =>
      switch groupName
        when 'Course' then I18n.t('groups.course', 'Course Activities')
        when 'Discussions' then I18n.t('groups.discussions', 'Discussions')
        when 'Communication' then I18n.t('groups.communication', 'Conversations')
        when 'Scheduling' then I18n.t('groups.scheduling', 'Scheduling')
        when 'Parent' then I18n.t('groups.parent', 'Parent Emails')
        when 'Groups' then I18n.t('groups.groups', 'Groups')
        when 'Alerts' then I18n.t('groups.alerts', 'Alerts')
        when 'Other' then I18n.t('groups.admin', 'Administrative')
        when 'Conferences' then I18n.t('groups.conferences', 'Conferences')
        else I18n.t('groups.other', 'Other')
