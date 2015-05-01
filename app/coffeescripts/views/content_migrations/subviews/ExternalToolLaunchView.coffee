define [
  'Backbone'
  'jst/content_migrations/subviews/ExternalToolLaunch'
  'jquery'
], (Backbone, template, $) ->
  class ExternalToolLaunchView extends Backbone.View
    template: template

    events:
      "click #externalToolLaunch": "launchExternalTool"

    els:
      '.file_name': '$fileName'

    @optionProperty 'contentReturnView'

    initialize: (options) ->
      super(options)
      @contentReturnView.on 'ready', @setUrl

    launchExternalTool: (event) ->
      event.preventDefault()
      @contentReturnView.render()

    setUrl: (data) =>
      item = data.contentItems[0]
      @$fileName.text(item.text)
      @model.set('settings', {file_url: item.url})
