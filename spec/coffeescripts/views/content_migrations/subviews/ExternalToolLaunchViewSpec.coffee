define [
  'jquery'
  'Backbone'
  'compiled/views/content_migrations/subviews/ExternalToolLaunchView'
], ($, Backbone, ExternalToolLaunchView) ->

  module 'ExternalToolLaunchView',
    setup: ->
      @mockMigration = new Backbone.Model
      @mockReturnView = new Backbone.View

      @launchView = new ExternalToolLaunchView
        contentReturnView: @mockReturnView
        model: @mockMigration

      $('#fixtures').html @launchView.render().el

    teardown: ->
      @launchView.remove()

  test 'calls render on return view when launch button clicked', ->
    sinon.stub(@mockReturnView, 'render', -> this)
    @launchView.$el.find('#externalToolLaunch').click()
    ok @mockReturnView.render.calledOnce, 'render not called on return view'

  test "displays file name on 'ready'", ->
    @mockReturnView.trigger('ready', {text: 'data text', url: 'data url'})
    strictEqual @launchView.$fileName.text(), 'data text'

  test "sets settings.data_url on migration on 'ready'", ->
    @mockReturnView.trigger('ready', {text: 'data text', url: 'data url'})
    deepEqual @mockMigration.get('settings'), {file_url: 'data url'}
