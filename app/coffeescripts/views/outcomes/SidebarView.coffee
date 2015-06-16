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
      super
      @inFindDialog = opts.inFindDialog
      @readOnly = opts.readOnly
      @selectFirstItem = opts.selectFirstItem
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
      @selectDir dir

    # Adds a directory view for an outcome group.
    # Returns the directory view.
    addDirFor: (outcomeGroup) ->
      if @cachedDirectories[outcomeGroup.id]
        dir = @cachedDirectories[outcomeGroup.id]
      else
        parent = _.last @directories
        directoryClass = outcomeGroup.get('directoryClass') || OutcomesDirectoryView
        dir = new directoryClass {outcomeGroup, parent, @readOnly, selectFirstItem: @selectFirstItem, inFindDialog: @inFindDialog}
        @firstDir = false
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
      # don't re-select the same model
      return if selectedModel and dir is @selectedDir() and selectedModel is @selectedDir()?.prevSelectedModel

      # If root selection is an outcome, don't have a dir. Get root most dir to clear selection.
      useDir = if dir then dir else @directories[0]
      useDir.clearSelection() if useDir and !selectedModel

      # remove all directories after the selected dir from @directories and the view
      i = _.indexOf @directories, useDir
      dirsToRemove = @directories.splice(i + 1, @directories.length - (i + 1))
      _.each dirsToRemove, (d) -> d.remove()
      isAddingDir = selectedModel instanceof OutcomeGroup and !selectedModel.isNew()
      @addDirFor selectedModel if isAddingDir
      @updateSidebarWidth()
      scrollIndex = if isAddingDir then i + 1 else i
      @_scrollToDir scrollIndex, selectedModel
      # Determine which model to select based on going forward/backward and where we are in the tree.
      wantSelectModel = selectedModel
      if @goingBack
        if !useDir.parent
          wantSelectModel = null
        else
          wantSelectModel = useDir.outcomeGroup
      @trigger 'select', wantSelectModel, @directories

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
      @goingBack = true
      if @selectedModel() instanceof OutcomeGroup
        @selectDir @selectedDir()
      else
        i = _.indexOf @directories, @selectedDir()
        @selectDir @directories[i - 1]
      @goingBack = false
#      if @selectedModel() instanceof OutcomeGroup
#        parentDir = @selectedDir().parent
##        @selectDir @selectedDir(), @selectedDir().parent?.selectedModel
#      else
#        i = _.indexOf @directories, @selectedDir()
#        @selectDir @directories[i - 1]
#      @goingBack = false

    updateSidebarWidth: ->
      sidebarWidth = if @directories.length is 1 then @directoryWidth else (@directoryWidth * 2)
      @$el.css width: (@directoryWidth * @directories.length)
      @$sidebar.animate width: sidebarWidth

    renderDir: (dir) =>
      @$el.append dir.render().el

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

    moveItem: (model, newGroup) ->
      originalGroup = model.get('parent_outcome_group') || model.outcomeGroup
      originalDir = @cachedDirectories[originalGroup.id]
      targetDir =  @cachedDirectories[newGroup.id]
      if originalGroup.id == newGroup.id
        $.flashError I18n.t("%{model} is already located in %{newGroup}", {model: model.get('title'), newGroup: newGroup.get('title')})
        return
      if model instanceof OutcomeGroup
        dfd = originalDir.moveGroup(model, newGroup.toJSON())
      else
        dfd = originalDir.changeLink(model, newGroup.toJSON())
      dfd.done =>
        itemType = if model instanceof OutcomeGroup then 'groups' else 'outcomes'
        if targetDir
          dfd = targetDir[itemType].fetch()
          dfd.done => targetDir.needsReset = true
        originalDir[itemType].fetch()
        parentDir = originalDir.parent
        if parentDir
          @selectDir(parentDir, parentDir.selectedModel)
        model.trigger 'finishedMoving'
        $(".selected:last").focus()
        #timeout necessary to announce move after modal closes following finishedMoving event
        setTimeout (->
          $.flashMessage I18n.t("Successfully moved %{model} to %{newGroup}", {model: model.get('title'), newGroup: newGroup.get('title')})
        ), 1500

    _scrollToDir: (dirIndex, model) ->
      scrollLeft = @directoryWidth * (if model instanceof Outcome then dirIndex - 1 else dirIndex)
      @$sidebar.animate {scrollLeft: scrollLeft}, duration: 200
      scrollTop = (@entryHeight + 1) * _.indexOf(@directories[dirIndex].views(), _.find(@directories[dirIndex].views(), (v) -> v.model is model))
      @directories[dirIndex].$el.animate {scrollTop: scrollTop}, duration: 200

    _findLastDir: (f) ->
      _.find(_.clone(@directories).reverse(), f) || _.last @directories
