define ['Backbone', 'i18n!dashboard'], ({View}, I18n) ->

  ##
  # Top-level view of the entire dashboard
  class DashboardView extends View

    events:
      'click .make_group': ->
        createGroupForm = $('.create_group_form')
        createGroupForm.formSubmit
          required: ['name']
          disableWhileLoading: true
          success: (data) ->
            debugger
            window.location = "/groups/#{data.id}/edit?return_to=#{ENV.DASHBOARD_PATH}"
        createGroupForm.dialog
          title: I18n.t('creating_group', 'Creating a group...')
          buttons:
            'Create': => createGroupForm.submit()
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

