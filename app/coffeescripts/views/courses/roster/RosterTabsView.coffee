define [
  'i18n!roster'
  'jquery'
  'underscore'
  'Backbone'
  'jst/courses/roster/rosterTabs'
], (I18n, $, _, Backbone, template) ->

  class RosterTabsView extends Backbone.View
    template: template

    tagName: 'li'
    className: 'collectionViewItems ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all'


    attach: ->
      @collection.on 'reset', @render, this

    fetch: ->
      if ENV.canManageCourse
        @collection.fetch()

    render: ->
      super
      @refreshTabs()

    refreshTabs: ->
      $tabs = $('#group_categories_tabs')
      $tabs.tabs().show()
      $tabs.tabs
        beforeActivate: (event, ui) ->
          ui.newTab.hasClass('static')

      $groupTabs = $tabs.find('li').not('.static')
      $groupTabs.find('a').unbind()
      $groupTabs.on 'keydown', (event) ->
        event.stopPropagation()
        if event.keyCode == 13 or event.keyCode == 32
          window.location.href = $(this).find('a').attr('href')

    toJSON: ->
      json = {}
      json.collection = super
      json.course = ENV.course
      json
