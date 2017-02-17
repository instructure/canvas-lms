define [
  'compiled/models/WikiPage'
  'compiled/collections/WikiPageRevisionsCollection'
], (WikiPage, WikiPageRevisionsCollection) ->

  QUnit.module 'WikiPageRevisionsCollection'

  test 'parentModel accepted in constructor', ->
    parentModel = new WikiPage
    collection = new WikiPageRevisionsCollection([], parentModel: parentModel)
    strictEqual collection.parentModel, parentModel, 'parentModel accepted in constructor'

  test 'url based on parentModel', ->
    parentModel = new WikiPage {url: 'a-page'}, contextAssetString: 'course_73'
    collection = new WikiPageRevisionsCollection([], parentModel: parentModel)
    equal collection.url(), '/api/v1/courses/73/pages/a-page/revisions', 'url built properly'

  test 'child models inherit parent url propertly', ->
    parentModel = new WikiPage {url: 'a-page'}, contextAssetString: 'course_73'
    collection = new WikiPageRevisionsCollection([], parentModel: parentModel)
    collection.add(revision_id: 37)
    equal collection.models.length, 1, 'child model added'
    equal collection.models[0].url(), '/api/v1/courses/73/pages/a-page/revisions/37', 'child url built properly'
