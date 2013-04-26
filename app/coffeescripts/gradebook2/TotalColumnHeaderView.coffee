
define [
  'jquery'
  'Backbone'
  'jst/gradebook2/total_column_header'
], ($, Backbone, template) ->

  class TotalColumnHeaderView extends Backbone.View

    el: '#total_column_header'

    events:
      "click .toggle_percent": "togglePercent"

    template: template

    togglePercent: =>
      @options.toggleShowingPoints()
      @render()
      false

    render: ->
      # the menu doesn't live in @$el, so remove it manually
      @$menu.remove() if @$menu

      super()

      # this line goes away when there is more stuff in the menu than just
      # points vs percent
      return this if @options.weightedGroups()

      @$menu = @$el.find('.gradebook-header-menu')
      @$el.find('#total_dropdown').kyleMenu
        noButton: true
        appendMenuTo: '#gradebook_grid'
      @$menu.css('width', '150')

      this

    toJSON: ->
      json =
        showingPoints: @options.showingPoints
        weightedGroups: @options.weightedGroups
