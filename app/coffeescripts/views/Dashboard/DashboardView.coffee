define [
  'Backbone'
  'i18n!dashboard'
  'jquery'
  'jquery.ajaxJSON'
], ({View}, I18n, $) ->

  ##
  # Top-level view of the entire dashboard
  class DashboardView extends View

    events:
      'click .make_group': 'makeGroup'
      'click .make_course': 'makeCourse'

    ###
    views:
      quickStartBar:
      activityFeed:
        views:
          activityFeedFilter:
          activityFeedItems:
      dashboardAside:
        views:
          todo:
          comingUp:
    ###

    initialize: ->
      @renderViews()
      @options.views.quickStartBar.on 'save',
        @options.views.activityFeed.options.views.activityFeedItems.refresh

    makeGroup: ->
      createGroupForm = $('.create_group_form')
      createGroupForm.formSubmit
        required: ['name']
        disableWhileLoading: true
        success: (data) ->
          window.location = "/groups/#{data.id}/edit?return_to=#{ENV.DASHBOARD_PATH}"
      createGroupForm.dialog
        title: I18n.t('creating_group', 'Creating a group...')
        open: -> createGroupForm.css('overflow', 'hidden')
        buttons:
          'Create': => createGroupForm.submit()

    makeCourse: ->
      createCourseForm = $('.create_course_form')
      createCourseForm.dialog
        title: I18n.t('creating_course', 'Creating a course...')
        buttons: [
          text: I18n.t 'cancel', 'Cancel'
          click: -> createCourseForm.data('dialog').close()
        ,
          text: I18n.t 'create', 'Create'
          'class' : 'btn-primary'
          click: -> createCourseForm.submit()
        ]
      dialog = createCourseForm.data('dialog')
      createCourseForm.formSubmit
        required: [
          'course[name]'
          'course[course_code]'
        ]
        disableWhileLoading: true
        processData: (data) ->
          data.enroll_me = true
          data.offer = true
          data
        success: (course) ->
          course.state = course.workflow_state
          window.dashboard.activityFeed.activityFeedFilter.addCourse(course)
          dialog.close()
