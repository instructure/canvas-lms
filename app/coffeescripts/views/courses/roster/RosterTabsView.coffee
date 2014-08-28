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

    toJSON: ->
      json = {}
      json.collection = super
      json.course = ENV.course
      json
