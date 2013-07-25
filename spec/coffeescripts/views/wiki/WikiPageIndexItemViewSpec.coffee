define [
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageIndexItemView'
], (WikiPage, WikiPageIndexItemView) ->
  
  module 'WikiPageIndexItemView'

  test 'model.view maintained by item view', ->
    model = new WikiPage
    view = new WikiPageIndexItemView
      model: model

    strictEqual model.view, view, 'model.view is set to the item view'
    view.render()
    strictEqual model.view, view, 'model.view is set to the item view'

  test 'detach/reattach the publish icon view', ->
    model = new WikiPage
    view = new WikiPageIndexItemView
      model: model
    view.render()

    $previousEl = view.$el.find('> *:first-child')
    view.publishIconView.$el.data('test-data', 'test-is-good')

    view.render()

    equal $previousEl.parent().length, 0, 'previous content removed'
    equal view.publishIconView.$el.data('test-data'), 'test-is-good', 'test data preserved (by detach)'

  test 'delegate setAsFrontPage to the model', ->
    model = new WikiPage
    view = new WikiPageIndexItemView
      model: model
    stub = sinon.stub(model, 'setAsFrontPage')

    view.setAsFrontPage()
    ok stub.calledOnce

  test 'delegate removeAsFrontPage to the model', ->
    model = new WikiPage
    view = new WikiPageIndexItemView
      model: model
    stub = sinon.stub(model, 'removeAsFrontPage')

    view.removeAsFrontPage()
    ok stub.calledOnce


  module 'WikiPageIndexItemView:JSON'

  test 'WIKI_RIGHTS', ->
    model = new WikiPage
    view = new WikiPageIndexItemView
      model: model
      WIKI_RIGHTS:
        good: true
    strictEqual view.toJSON().WIKI_RIGHTS.good, true, 'WIKI_RIGHTS represented in toJSON'

  test 'contextName', ->
    model = new WikiPage
    view = new WikiPageIndexItemView
      model: model
      contextName: 'groups'
    strictEqual view.toJSON().contextName, 'groups', 'contextName represented in toJSON'

