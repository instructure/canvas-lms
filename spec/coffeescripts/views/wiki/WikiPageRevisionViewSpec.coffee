define [
  'jquery'
  'compiled/models/WikiPageRevision'
  'compiled/collections/WikiPageRevisionsCollection'
  'compiled/views/wiki/WikiPageRevisionView'
], ($, WikiPageRevision, WikiPageRevisionsCollection, WikiPageRevisionView) ->

  QUnit.module 'WikiPageRevisionView'

  test 'binds to model change triggers', ->
    revision = new WikiPageRevision
    view = new WikiPageRevisionView model: revision
    @mock(view).expects('render').atLeast(1)
    revision.set('body', 'A New Body')

  test 'restore delegates to model.restore', ->
    revision = new WikiPageRevision
    view = new WikiPageRevisionView model: revision
    @stub(view, 'windowLocation').returns({
      href: ""
      reload: -> true
    })
    @mock(revision).expects('restore').atLeast(1).returns($.Deferred().resolve())
    view.restore()

  test 'toJSON serializes expected values', ->
    attributes =
      latest: true
      selected: true
      title: 'Title'
      body: 'Body'

    revision = new WikiPageRevision attributes
    collection = new WikiPageRevisionsCollection [revision]
    collection.latest = new WikiPageRevision attributes
    view = new WikiPageRevisionView model: revision
    json = view.toJSON()

    strictEqual json.IS?.LATEST, true, 'IS.LATEST'
    strictEqual json.IS?.SELECTED, true, 'IS.SELECTED'
    strictEqual json.IS?.LOADED, true, 'IS.LOADED'
    strictEqual json.IS?.SAME_AS_LATEST, true, 'IS.SAME_AS_LATEST'
