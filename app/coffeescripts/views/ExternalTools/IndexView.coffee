define [
  'underscore'
  'jquery'
  'jst/ExternalTools/IndexView'
  'compiled/views/ExternalTools/EditView'
  'compiled/views/PaginatedView'
  'i18n!external_tools'
], (_, $, template, EditView, PaginatedView, I18n) ->

  class IndexView extends PaginatedView

    template: template

    events:
      'click [data-delete-external-tool]': 'deleteExternalToolHandler'
      'click [data-edit-external-tool]': 'editExternalToolHandler'
      'click .add_tool_link': 'addTool'

    initialize: ->
      super
      @collection.on 'sync', @render, this
      @collection.on 'reset', @render, this
      @collection.on 'destroy', @render, this
      @render()

    deleteExternalToolHandler: (e) =>
      id = @$(e.target).closest('a').data('delete-external-tool')
      @confirmDelete =>
        @collection.get(id).destroy()

    confirmDelete: (deleteFunc) ->
      msg = I18n.t 'remove_tool',
        "Are you sure you want to remove this tool?
         Any courses using this tool will no longer work."
      dialog = $("<div>#{msg}</div>").dialog
        modal: true,
        resizable: false
        title: I18n.t 'are_you_sure', 'Are you sure?'
        buttons: [
          text: I18n.t 'buttons.cancel', 'Cancel'
          click: => dialog.dialog 'close'
        ,
          text: I18n.t 'buttons.delete', 'Delete'
          click: =>
            deleteFunc()
            dialog.dialog 'close'
        ]

    editExternalToolHandler: (e) =>
      id = @$(e.target).closest('a').data('edit-external-tool')
      new EditView(model: @collection.get(id)).render()

    addTool: =>
      @collection.add({}, silent: true)
      new EditView(model: @collection.last()).render()

    toJSON: ->
      extras = [
        {extension_type: 'editor_button', text: I18n.t 'editor_button_configured', 'Editor button configured'}
        {extension_type: 'resource_selection', text: I18n.t 'resource_selection_configured', 'Resource selection configured'}
        {extension_type: 'course_navigation', text: I18n.t 'course_navigation_configured', 'Course navigation configured'}
        {extension_type: 'account_navigation', text: I18n.t 'account_navigation_configured', 'Account navigation configured'}
        {extension_type: 'user_navigation', text: I18n.t 'user_navigation_configured', 'User navigation configured'}
        {extension_type: 'homework_submission', text: I18n.t 'homework_submission_configured', 'Homework submission configured'}
      ]

      json = super
      for tool in json
        tool.extras = (extra for extra in extras when tool[extra.extension_type]?)
      json
