define [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageContentView'
], ($, WikiPage, WikiPageContentView) ->

  module 'WikiPageContentView'

  test 'setModel causes a re-render', ->
    wikiPage = new WikiPage
    contentView = new WikiPageContentView
    @mock(contentView).expects('render').atLeast(1)
    contentView.setModel(wikiPage)

  test 'setModel binds to the model change:title trigger', ->
    wikiPage = new WikiPage
    contentView = new WikiPageContentView
    contentView.setModel(wikiPage)
    @mock(contentView).expects('render').atLeast(1)
    wikiPage.set('title', 'A New Title')

  test 'setModel binds to the model change:title trigger', ->
    wikiPage = new WikiPage
    contentView = new WikiPageContentView
    contentView.setModel(wikiPage)
    @mock(contentView).expects('render').atLeast(1)
    wikiPage.set('body', 'A New Body')

  test 'render publishes a "userContent/change" (to enhance user content)', ->
    contentView = new WikiPageContentView
    $.subscribe('userContent/change', @mock().atLeast(1))
    contentView.render()
