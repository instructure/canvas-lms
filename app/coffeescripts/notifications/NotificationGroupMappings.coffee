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
        Course: ['Due Date', 'Grading Policies', 'Course Content', 'Files', 'Announcement', 'Grading', 'Invitation',
                 'All Submissions', 'Late Grading', 'Submission Comment']
        Discussions: ['DiscussionEntry', 'Discussion']
        Communication: ['Added To Conversation', 'Conversation Message']
        Scheduling: ['Student Appointment Signups', 'Appointment Signups', 'Appointment Cancelations',
                     'Appointment Availability', 'Calendar']
        Parent: []
        Groups: ['Membership Update']
        Alerts: ['Alert', 'Other']

    # Get the I18n display text to use for the group name.
    getGroupDisplayName: (groupName) =>
      switch groupName
        when 'Course' then I18n.t('groups.course', 'Course Activities')
        when 'Discussions' then I18n.t('groups.discussions', 'Discussions')
        when 'Communication' then I18n.t('groups.communication', 'Communications')
        when 'Scheduling' then I18n.t('groups.scheduling', 'Scheduling')
        when 'Parent' then I18n.t('groups.parent', 'Parent Emails')
        when 'Groups' then I18n.t('groups.groups', 'Groups')
        when 'Alerts' then I18n.t('groups.alerts', 'Alerts')
        when 'Other' then I18n.t('groups.admin', 'Administrative')
        else I18n.t('groups.other', 'Other')
