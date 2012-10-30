#
# Copyright (C) 2012 Instructure, Inc.
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
#

define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Outcome'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/OutcomesDirectoryView'
  'compiled/views/outcomes/FindDirectoryView'
], (I18n, $, _, Backbone, Outcome, OutcomeGroup, OutcomesDirectoryView, FindDirectoryView) ->

  findDialog = undefined

  # Manages the directory views.
  class SidebarView extends Backbone.View

    directoryWidth: 200
    entryHeight: 30

    events:
      'click .outcome-level': 'clickOutcomeLevel'

    # options must include rootOutcomeGroup or directoryView
    initialize: (opts) ->
      @readOnly = opts.readOnly
      @directories = []
      @cachedDirectories = {}
      @$sidebar = @$el.parent()
      @$sidebar.width @directoryWidth
      if @rootOutcomeGroup = opts.rootOutcomeGroup
        @addDirFor @rootOutcomeGroup
      else
        @addDir opts.directoryView
      @render()

    clickOutcomeLevel: (e) ->
      clickedOutside = e.target is e.currentTarget
      return unless clickedOutside
      dir = $(e.target).data 'view'
      if dir.parent
        dir.parent.selectedModel.trigger 'select'
      else
        @selectDir dir

    # Adds a directory view for an outcome group.
    # Returns the directory view.
    addDirFor: (outcomeGroup) ->
      if @cachedDirectories[outcomeGroup.id]
        dir = @cachedDirectories[outcomeGroup.id]
      else
        parent = _.last @directories
        directoryClass = outcomeGroup.get('directoryClass') || OutcomesDirectoryView
        dir = new directoryClass {outcomeGroup, parent, @readOnly}
      @addDir dir

    # Adds a directory view.
    # Returns the directory view.
    addDir: (dir) ->
      @cachedDirectories[dir.outcomeGroup.id] = dir if dir.outcomeGroup
      dir.off 'select'
      dir.on 'select', @selectDir
      dir.sidebar = this
      dir.clearSelection()
      @directories.push dir
      @updateSidebarWidth()
      @renderDir dir
      dir

    # Insert and select a newly created/imported outcome or group.
    addAndSelect: (model) =>
      # verify outcomeGroup is set
      if model instanceof Outcome
        model.outcomeGroup = @selectedGroup().toJSON()
      else
        model.set 'parent_outcome_group', @selectedGroup().toJSON()

      # add to collection
      dir = @_findLastDir (d) -> ! d.selectedModel or d.selectedModel instanceof Outcome
      if model instanceof Outcome
        dir.outcomes.add model
      else
        dir.groups.add model
      @_scrollToDir _.indexOf(@directories, dir), model

      # select the view
      model.trigger 'select'

    # Select the directory view and optionally select an Outcome or Group.
    selectDir: (dir, selectedModel) =>
      dfd = $.Deferred()
      # don't re-select the same model
      if selectedModel and dir is @selectedDir() and selectedModel is @selectedDir()?.prevSelectedModel
        dfd.resolve()
        return dfd.promise()

      complete = =>
        # remove all directories after the selected dir
        _.each @directories.splice(i + 1), (d) -> d.remove()
        @addDirFor selectedModel if selectedModel instanceof OutcomeGroup and !selectedModel.isNew()
        @updateSidebarWidth()
        @trigger 'select', selectedModel, @directories
        dfd.resolve()

      dir.clearSelection() unless selectedModel
      i = _.indexOf @directories, dir
      # only scroll to dir if the selection is not the last dir
      if @directories.length is i + 1
        complete()
      else
        @_scrollToDir i, selectedModel, complete

      dfd.promise()

    refreshSelection: (model) =>
      dir = @selectedDir()
      if model is dir.selectedModel
        dir.clearSelection()
        model.trigger 'select'

    selectedDir: ->
      @_findLastDir (d) -> d.selectedModel

    selectedModel: ->
      @selectedDir()?.selectedModel

    selectedGroup: ->
      g = null
      @_findLastDir (d) ->
        if d.selectedModel instanceof OutcomeGroup
          g = d.selectedModel
      g || @rootOutcomeGroup

    clearOutcomeSelection: =>
      _.last(@directories).clearOutcomeSelection()

    # Go up a directory.
    goBack: =>
      i = _.indexOf @directories, @selectedDir()
      @goingBack = true
      if i < 1
        @directories[0].clearSelection()
        @selectDir @directories[0]
      else
        prevDir = @directories[i - 1]
        @selectDir prevDir, prevDir.selectedModel

    updateSidebarWidth: ->
      sidebarWidth = if @directories.length is 1 then @directoryWidth + 1 else (@directoryWidth * 2) + 2
      @$el.css width: (@directoryWidth * @directories.length) + @directories.length
      @$sidebar.animate width: sidebarWidth

    renderDir: (dir) =>
      @$el.append dir.render().el
      @$sidebar.animate scrollLeft: @scrollNextPosition

    scrollNextPosition: ->
      @$sidebar.get(0).scrollWidth - @$sidebar.get(0).clientWidth

    render: ->
      @$el.empty()
      _.each @directories, @renderDir
      this

    # passing in FindDialog because of circular dependency
    findDialog: (FindDialog) =>
      unless findDialog
        findDialog = new FindDialog
          title: I18n.t 'titles.find_outcomes', 'Find Outcomes'
          selectedGroup: @selectedGroup()
          directoryView: new FindDirectoryView
            outcomeGroup: @selectedGroup()
        findDialog.on 'import', @addAndSelect, this
      findDialog.show()

    # Find a directory for a given outcome group or add a new directory view.
    dirForGroup: (outcomeGroup) ->
      _.find(@directories, (d) -> d.outcomeGroup is outcomeGroup) || @addDirFor(outcomeGroup)

    _scrollToDir: (dirIndex, model, complete) ->
      scrollLeft = (@directoryWidth + 1) * (if model instanceof Outcome then dirIndex - 1 else dirIndex)
      @$sidebar.animate {scrollLeft: scrollLeft}, duration: @directoryWidth, complete: complete
      scrollTop = (@entryHeight + 1) * _.indexOf(@directories[dirIndex].views(), _.find(@directories[dirIndex].views(), (v) -> v.model is model))
      @directories[dirIndex].$el.animate {scrollTop: scrollTop}, duration: @directoryWidth

    _findLastDir: (f) ->
      _.find(_.clone(@directories).reverse(), f) || _.last @directories
