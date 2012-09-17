define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'compiled/models/OutcomeGroup'
  'compiled/views/DialogBaseView'
  'compiled/views/outcomes/SidebarView'
  'compiled/views/outcomes/ContentView'
  'jst/outcomes/browser'
  'jst/outcomes/findInstructions'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, _, OutcomeGroup, DialogBaseView, SidebarView, ContentView, browserTemplate, instructionsTemplate) ->

  # Creates a popup dialog similar to the main outcomes browser minus the toolbar.
  class FindDialog extends DialogBaseView

    dialogOptions: ->
      id: 'import_dialog'
      title: @title
      width: 1000
      resizable: true
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

      super()
      @render()
      # so we don't mess with other jquery dialogs
      @dialog.parent().find('.ui-dialog-buttonpane').css 'margin-top', 0

      @sidebar = new SidebarView
        el: @$el.find('.outcomes-sidebar .wrapper')
        directoryView: opts.directoryView
        rootOutcomeGroup: opts.rootOutcomeGroup
        readOnly: true
      @content = new ContentView
        el: @$el.find('.outcomes-content')
        instructionsTemplate: instructionsTemplate
        readOnly: true

      # sidebar events
      @sidebar.on 'select', @content.show
      @sidebar.on 'select', @showOrHideImport

      @showOrHideImport()

    # link an outcome or copy/link an outcome group into @selectedGroup
    import: (e) =>
      e.preventDefault()
      model = @sidebar.selectedModel()
      return alert I18n.t('dont_import', 'This group cannot be imported.') if model.get 'dontImport'
      if confirm @confirmText model
        if model instanceof OutcomeGroup
          url = @selectedGroup.get('import_url')
          dfd = $.ajaxJSON url, 'POST',
            source_outcome_group_id: model.get 'id'
        else
          url = @selectedGroup.get('outcomes_url')
          dfd = $.ajaxJSON url, 'POST',
            outcome_id: model.get 'id'
        @$el.disableWhileLoading dfd
        $.when(dfd)
          .done =>
            @trigger 'import', model
            @close()
            $.flashMessage I18n.t('flash.importSuccess', 'Import successful')
          .fail =>
            $.flashError I18n.t('flash.importError', "An error occurred while importing. Please try again later.")

    render: ->
      @$el.html browserTemplate skipToolbar: true
      this

    showOrHideImport: =>
      model = @sidebar.selectedModel()
      canShow = if !model || model.get 'dontImport' then false else true
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