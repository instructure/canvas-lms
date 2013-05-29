define [
  'jquery'
  'i18n!external_tools'
  'str/htmlEscape'
  'jst/ExternalTools/IndexView'
  'compiled/views/ExternalTools/AddAppView'
  'compiled/views/ExternalTools/EditView'
  'compiled/views/ExternalTools/AppFullView'
  'compiled/models/ExternalTool'
], ($, I18n, htmlEscape, template, AddAppView, EditView, AppFullView, ExternalTool) ->

  class IndexView extends Backbone.View

    @child 'appCenterView',     '[data-view=appCenter]'
    @child 'externalToolsView', '[data-view=externalTools]'

    template: template

    els:
      '.view_tools_link': '$viewToolsLink'
      '.view_app_center_link': '$viewAppCenterLink'
      '.add_tool_link': '$addToolLink'
      '[data-view=appFull]': '$appFull'

    events:
      'click .view_tools_link': 'showExternalToolsView'
      'click .view_app_center_link': 'showAppCenterView'
      'click .app': 'showAppFullView'
      'click .add_tool_link': 'addTool'
      'click [data-edit-external-tool]': 'editTool'
      'click [data-delete-external-tool]': 'deleteTool'

    currentAppCenterPosition: 0

    afterRender: ->
      if @options.appCenterEnabled
        @appCenterView.collection.fetch()
        @showAppCenterView()
      else
        @showExternalToolsView()

    hideExternalToolsView: =>
      @externalToolsView.hide()
      @$viewToolsLink.show()
      @$addToolLink.hide()

    hideAppCenterView: =>
      @currentAppCenterPosition = $(document).scrollTop()
      @appCenterView.hide()
      @$viewAppCenterLink.show() if @options.appCenterEnabled

    removeAppFullView: ->
      @appFullView.remove() if @appFullView

    showExternalToolsView: =>
      @removeAppFullView()
      @hideAppCenterView()
      @$viewAppCenterLink.hide() unless @options.appCenterEnabled
      @$viewToolsLink.hide()
      @$addToolLink.show()
      @externalToolsView.collection.fetch()
      @externalToolsView.show()

    showAppCenterView: =>
      @removeAppFullView()
      @hideExternalToolsView()
      @$viewAppCenterLink.hide()
      @appCenterView.show()
      $(document).scrollTop(@currentAppCenterPosition)

    showAppFullView: (event) ->
      @hideExternalToolsView()
      @hideAppCenterView()
      view = @$(event.currentTarget).data('view')
      @appFullView = new AppFullView
        model: view.model
      @appFullView.on 'cancel', @showAppCenterView, this
      @appFullView.on 'addApp', @addApp, this
      @appFullView.render()
      @$appFull.append @appFullView.$el
      
    addApp: ->
      newTool = new ExternalTool
      newTool.on 'sync', @onToolSync
      @addAppView = new AddAppView(app: @appFullView.model, model: newTool).render()

    addTool: ->
      newTool = new ExternalTool
      newTool.on 'sync', @onToolSync
      @editView = new EditView(model: newTool).render()

    editTool: (event) ->
      view = @$(event.currentTarget).closest('.external_tool_item').data('view')
      tool = view.model
      tool.on 'sync', @onToolSync
      @editView = new EditView(model: tool).render()

    onToolSync: (model) =>
      @addAppView.remove() if @addAppView
      @editView.remove() if @editView
      @showExternalToolsView()
      $.flashMessage(htmlEscape(I18n.t('app_saved_message', "%{app} saved successfully!", { app: model.get('name') })))

    deleteTool: (event) ->
      view = @$(event.currentTarget).closest('.external_tool_item').data('view')
      tool = view.model
      msg = I18n.t 'remove_tool', "Are you sure you want to remove this tool?"
      dialog = $("<div>#{msg}</div>").dialog
        modal: true,
        resizable: false
        title: I18n.t('delete', 'Delete') + ' ' + tool.get('name') + '?'
        buttons: [
          text: I18n.t 'buttons.cancel', 'Cancel'
          click: => dialog.dialog 'close'
        ,
          text: I18n.t 'buttons.delete', 'Delete'
          click: =>
            tool.destroy()
            @externalToolsView.collection.fetch()
            dialog.dialog 'close'
        ]