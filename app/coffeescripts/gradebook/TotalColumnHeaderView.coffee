
define [
  'jquery'
  'Backbone'
  'jst/gradebook/total_column_header'
], ($, Backbone, template) ->

  class TotalColumnHeaderView extends Backbone.View

    el: '#total_column_header'

    events:
      "click .toggle_percent": "togglePercent"
      "click .move_column": "moveColumn"

    template: template

    togglePercent: =>
      @options.toggleShowingPoints()
      false

    switchTotalDisplay: (showAsPoints) =>
      @options.showingPoints = showAsPoints
      @render()

    moveColumn: =>
      @options.moveTotalColumn()
      @render()
      false

    render: ->
      # the menu doesn't live in @$el, so remove it manually
      @$menu.remove() if @$menu

      super()

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
        totalColumnInFront: @options.totalColumnInFront
