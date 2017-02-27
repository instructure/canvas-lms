define [
  'jquery'
  'Backbone'
  'compiled/views/outcomes/ContentView'
  'helpers/fakeENV'
  'jst/outcomes/mainInstructions'
], ($, Backbone, ContentView, fakeENV, instructionsTemplate) ->

  QUnit.module 'CollectionView',
    setup: ->
      fakeENV.setup()
      viewEl = $('<div id="content-view-el">original_text</div>')
      viewEl.appendTo fixtures
      @contentView = new ContentView
        el: viewEl
        instructionsTemplate: instructionsTemplate
        renderengInstructions: false
      @contentView.$el.appendTo $('#fixtures')
      @contentView.render()
    teardown: ->
      fakeENV.teardown()
      @contentView.remove()

  test 'collectionView replaces text with warning and link on renderNoOutcomeWarning event', ->
    ok @contentView.$el?.text().match(/original_text/)
    $.publish "renderNoOutcomeWarning"
    ok @contentView.$el?.text().match(/You have no outcomes/)
    ok not @contentView.$el?.text().match(/original_text/)
    ok @contentView.$el?.find('a')?.attr('href')?.search(@contentView._contextPath() + '/outcomes') > 0
