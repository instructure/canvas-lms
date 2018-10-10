#
# Copyright (C) 2012 - present Instructure, Inc.
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
  '../../models/OutcomeGroup'
  '../../models/Progress'
  '../DialogBaseView'
  './SidebarView'
  './ContentView'
  'jst/outcomes/browser'
  'jst/outcomes/findInstructions'
  '../../jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, _, OutcomeGroup, Progress, DialogBaseView, SidebarView, ContentView, browserTemplate, instructionsTemplate) ->

  # Creates a popup dialog similar to the main outcomes browser minus the toolbar.
  class FindDialog extends DialogBaseView

    dialogOptions: ->
      id: 'import_dialog'
      title: @title
      width: 1000
      resizable: true
      close: -> $('.find_outcome').focus()
      buttons: [
        text: I18n.t '#buttons.cancel', 'Cancel'
        click: @cancel
      ,
        text: I18n.t '#buttons.import', 'Import'
        'class' : 'btn-primary'
        click: @import
      ]

    # Required options:
    #   selectedGroup, title
    # For the sidebar either directoryView or rootOutcomeGroup is required
    initialize: (opts) ->
      @selectedGroup = opts.selectedGroup
      @title = opts.title
      @shouldImport = if opts.shouldImport is false then false else true
      @disableGroupImport = opts.disableGroupImport

      super
      @render()
      # so we don't mess with other jquery dialogs
      @dialog.parent().find('.ui-dialog-buttonpane').css 'margin-top', 0

      @sidebar = new SidebarView
        el: @$el.find('.outcomes-sidebar .wrapper')
        directoryView: opts.directoryView
        rootOutcomeGroup: opts.rootOutcomeGroup
        readOnly: true
        inFindDialog: true
      @content = new ContentView
        el: @$el.find('.outcomes-content')
        instructionsTemplate: instructionsTemplate
        readOnly: true
        setQuizMastery: opts.setQuizMastery
        useForScoring: opts.useForScoring

      # sidebar events
      @sidebar.on 'select', @content.show
      @sidebar.on 'select', @showOrHideImport

      @showOrHideImport()

    updateSelection: (selectedGroup) =>
      @selectedGroup = selectedGroup

    # link an outcome or copy/link an outcome group into @selectedGroup
    import: (e) =>
      e.preventDefault()
      model = @sidebar.selectedModel()
      # add optional attributes for use in logic elsewhere
      model.quizMasteryLevel = (parseFloat(@$el.find('#outcome_mastery_at').val()) or 0) if @content.setQuizMastery
      model.useForScoring = @$el.find('#outcome_use_for_scoring').prop('checked') if @content.useForScoring
      return alert I18n.t('dont_import', 'This group cannot be imported.') if model.get 'dontImport'
      unless @shouldImport
        @trigger('import', model)
        @close()
        return
      if confirm(@confirmText(model))
        if model instanceof OutcomeGroup
          url = @selectedGroup.get('import_url')
          progress = new Progress
          dfd = $.ajaxJSON(url, 'POST', {
            source_outcome_group_id: model.get('id'),
            async: true,
          }).pipe((resp) ->
            progress.set('url', resp.url)
            progress.poll()
            return progress.pollDfd
          ).pipe(->
            return $.ajaxJSON(progress.get('results').outcome_group_url, 'GET')
          )
        else
          url = @selectedGroup.get('outcomes_url')
          dfd = $.ajaxJSON url, 'POST',
            outcome_id: model.get 'id'
        @$el.disableWhileLoading dfd
        $.when(dfd)
          .done (response, status, deferred) =>
            importedModel = model.clone()
            if importedModel instanceof OutcomeGroup
              importedModel.set(response)
            else
              importedModel.outcomeLink     = _.extend({}, model.outcomeLink)
              importedModel.outcomeGroup    = response.outcome_group
              importedModel.outcomeLink.url = response.url
              importedModel.set(context_id: response.context_id, context_type: response.context_type)
            @trigger 'import', importedModel
            @close()
            $.flashMessage I18n.t('flash.importSuccess', 'Import successful')
          .fail =>
            $.flashError I18n.t('flash.importError', "An error occurred while importing. Please try again later.")

    render: ->
      @$el.html browserTemplate skipToolbar: true
      this

    showOrHideImport: =>
      model = @sidebar.selectedModel()
      canShow = true
      if !model || model.get 'dontImport'
        canShow = false
      else if model && model instanceof OutcomeGroup && @disableGroupImport
        canShow = false
      $('.ui-dialog-buttonpane .btn-primary').toggle canShow

    confirmText: (model) ->
      target = @selectedGroup.get('title') || I18n.t 'top_level', "%{context} Top Level", context: @selectedGroup.get('context_type')
      if model instanceof OutcomeGroup
        I18n.t 'confirm.import_group', 'Import group "%{group}" to group "%{target}"?',
          group: model.get('title')
          target: target
      else
        I18n.t 'confirm.import_outcome', 'Import outcome "%{outcome}" to group "%{target}"?',
          outcome: model.get('title')
          target: target
