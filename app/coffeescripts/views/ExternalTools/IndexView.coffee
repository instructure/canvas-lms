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
      '#app_center_filter': '$appCenterFilter'
      '#app_center_filter_wrapper': '$appCenterFilterWrapper'
      '[data-view=appFull]': '$appFull'

    events:
      'click .view_tools_link': 'showExternalToolsView'
      'click .view_app_center_link': 'showAppCenterView'
      'click .app': 'showAppFullView'
      'keyup .app': 'showAppFullView'
      'click .add_tool_link': 'addTool'
      'click [data-edit-external-tool]': 'editTool'
      'click [data-delete-external-tool]': 'deleteTool'
      'change #app_center_filter': 'filterApps'
      'keyup #app_center_filter': 'filterApps'
      'click [data-toggle-installed-state]': 'toggleInstalledState'

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
      @$appCenterFilterWrapper.hide()
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
      delay = (ms, func) -> setTimeout func, ms
      delay 1, -> @$(".view_app_center_link").first().focus()

    showAppCenterView: =>
      @removeAppFullView()
      @hideExternalToolsView()
      @$viewAppCenterLink.hide()
      @appCenterView.show()
      @$appCenterFilterWrapper.show()
      $(document).scrollTop(@currentAppCenterPosition)
      delay = (ms, func) -> setTimeout func, ms
      delay 1, -> @$(".view_tools_link").first().focus()

    showAppFullView: (event) ->
      if event.type != 'keyup' || event.keyCode == 32
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
      @editView = new EditView(model: newTool, title: I18n.t 'dialog_title_add_tool', 'Add New App').render()

    editTool: (event) ->
      view = @$(event.currentTarget).closest('.external_tool_item').data('view')
      tool = view.model
      tool.on 'sync', @onToolSync
      @editView = new EditView(model: tool).render()
      false

    onToolSync: (model) =>
      @addAppView.remove() if @addAppView
      @editView.remove() if @editView
      @showExternalToolsView()
      $.flashMessage(htmlEscape(I18n.t('app_saved_message', "%{app} saved successfully!", { app: model.get('name') })))

    filterApps: (event) =>
      @appCenterView.filterText = @$appCenterFilter.val()
      @appCenterView.render()

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
            tool.on('sync', =>
                @externalToolsView.collection.fetch()
                @appCenterView.collection.fetch()
            )
            tool.destroy()
            dialog.dialog 'close'
        ]
      false

    toggleInstalledState: (event) =>
      elm = @$(event.currentTarget)
      @appCenterView.targetInstalledState = elm.data('toggle-installed-state')
      @$('[data-installed-state] > a').attr('aria-selected', 'false')
      @$('[data-installed-state]').removeClass('active')
      @$('[data-installed-state="' + @appCenterView.targetInstalledState + '"]').addClass('active')
      @$('[data-installed-state="' + @appCenterView.targetInstalledState + '"] > a').attr('aria-selected', 'true')
      @appCenterView.render()