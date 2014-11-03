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
  'jquery'
  'underscore'
  'i18n!contentview'
  'Backbone'
  'compiled/models/Outcome'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/OutcomeView'
  'compiled/views/outcomes/OutcomeGroupView'
  'compiled/views/TreeBrowserView'
  'compiled/views/RootOutcomesFinder'
  'jst/MoveOutcomeDialog'
], ($, _, I18n, Backbone, Outcome, OutcomeGroup, OutcomeView, OutcomeGroupView, TreeBrowserView, RootOutcomesFinder, dialogTemplate) ->

  # This view is a wrapper for showing details for outcomes and groups.
  # It uses OutcomeView and OutcomeGroupView to render
  class ContentView extends Backbone.View

    initialize: ({@readOnly, @setQuizMastery, @useForScoring, @instructionsTemplate, @renderInstructions}) ->
      super
      @render()

    # accepts: Outcome and OutcomeGroup
    show: (model) =>
      return if model?.isNew()
      @_show model: model

    # accepts: Outcome and OutcomeGroup
    add: (model) =>
      @_show model: model, state: 'add'
      @trigger 'adding'
      @innerView.on 'addSuccess', (m) => @trigger 'addSuccess', m

    # private
    _show: (viewOpts) ->
      viewOpts = _.extend {}, viewOpts, {@readOnly, @setQuizMastery, @useForScoring}
      @innerView?.remove()
      @innerView =
        if viewOpts.model instanceof Outcome
          new OutcomeView viewOpts
        else if viewOpts.model instanceof OutcomeGroup
          new OutcomeGroupView viewOpts
      @render()
      @innerView.screenreaderTitleFocus() if @innerView instanceof OutcomeView

    render: ->
      @attachEvents()
      html = if @innerView
          @innerView.render().el
        else if @renderInstructions
          @instructionsTemplate()
      @$el.html html
      this

    attachEvents: ->
      return unless @innerView?
      @innerView.on 'deleteSuccess', => @trigger('deleteSuccess')
      @innerView.on 'move', (outcomeItem) => @openDialog(outcomeItem)

    openDialog: (outcomeItem) ->
      dialogTree = @createTree()
      dialogWindow = @createDialog()

      moveDialog = {
        tree: dialogTree
        window: dialogWindow
        model: outcomeItem
      }

      $(dialogTree.$el).appendTo('.form-dialog-content')
      $('.form-controls .btn[type=button]').bind('click', =>
        dialogWindow.dialog('close'))
      $('.form-controls .btn[type=submit]').bind('click', (e) =>
        e.preventDefault()
        if dialogTree.activeTree
          @trigger 'move', moveDialog.model, dialogTree.activeTree.model
          moveDialog.model.on 'finishedMoving', =>
            dialogWindow.dialog('close')
        else
          $.flashError I18n.t("No directory is selected, please select a directory before clicking 'move'")
        )

      $(moveDialog.window).dialog('option', 'title', I18n.t("Where would you like to move %{title}?", title: outcomeItem.get('title')))
      $('.ui-dialog :button').blur()
      setTimeout (=>
        moveDialog.tree.focusOnOpen()
        ), 200

    createTree: ->
      treeBrowser = new TreeBrowserView({
        rootModelsFinder: new RootOutcomesFinder()
        focusStyleClass: 'MoveDialog__folderItem--focused'
        selectedStyleClass: 'MoveDialog__folderItem--selected'
        onlyShowSubtrees: true
        onClick: do ->
          setActiveTree = TreeBrowserView.prototype.setActiveTree
          ( -> setActiveTree(@, treeBrowser) )
        }).render()
      treeBrowser

    createDialog: ->
      dialog = $(dialogTemplate()).dialog({
        dialogClass: 'moveDialog'
        width: 600
        height: 270
        open: ->
          $(@).show()
        close: (e) ->
          $(@).remove()
      })
      dialog

    remove: ->
      @innerView?.off 'addSuccess'
