define [
  'compiled/models/WikiPage'
  'underscore'
], (WikiPage, _) ->
  wikiPageObj = (options={}) -> 
    defaults = 
              body: "<p>content for the uploading of content</p>"
              created_at: "2013-05-10T13:18:27-06:00"
              editing_roles: "teachers"
              front_page: false
              hide_from_students: false
              locked_for_user: false
              published: false
              title: "Front Page-3"
              updated_at: "2013-06-13T10:30:37-06:00"
              url: "front-page-2"

    _.extend defaults, options

  module 'WikiPageSpec:Sync'
  test 'sets the id during construction', ->
    wikiPage = new WikiPage wikiPageObj()
    equal wikiPage.get('url'), 'front-page-2'
    equal wikiPage.get('id'), wikiPage.get('url'), 'Sets id to url'

  test 'sets the id during parse', ->
    wikiPage = new WikiPage
    parseResponse = wikiPage.parse(wikiPageObj())
    equal parseResponse.url, 'front-page-2'
    equal parseResponse.id, parseResponse.url, 'Sets id to url'

  test 'removes the id during toJSON', ->
    wikiPage = new WikiPage wikiPageObj()
    json = wikiPage.toJSON()
    equal json.id, undefined, 'Removes id from serialized json'

  test 'parse removes wiki_page namespace added by api', ->
    wikiPage = new WikiPage
    namespacedObj = {}
    namespacedObj.wiki_page = wikiPageObj()
    parseResponse = wikiPage.parse(namespacedObj)

    ok !_.isObject(parseResponse.wiki_page), "Removes the wiki_page namespace"

  test 'present includes the context information', ->
    wikiPage = new WikiPage {}, contextAssetString: 'course_31'
    json = wikiPage.present()
    equal json.contextName, 'courses', 'contextName'
    equal json.contextId, 31, 'contextId'

  test 'publish convenience method', 3, ->
    wikiPage = new WikiPage wikiPageObj()
    sinon.stub wikiPage, 'save', (attributes, options) ->
      ok attributes, 'attributes present'
      ok attributes.wiki_page, 'wiki_page present'
      strictEqual attributes.wiki_page.published, true, 'published provided correctly'
    wikiPage.publish()

  test 'unpublish convenience method', 3, ->
    wikiPage = new WikiPage wikiPageObj()
    sinon.stub wikiPage, 'save', (attributes, options) ->
      ok attributes, 'attributes present'
      ok attributes.wiki_page, 'wiki_page present'
      strictEqual attributes.wiki_page.published, false, 'published provided correctly'
    wikiPage.unpublish()

  test 'setAsFrontPage convenience method', 3, ->
    wikiPage = new WikiPage wikiPageObj()
    sinon.stub wikiPage, 'save', (attributes, options) ->
      ok attributes, 'attributes present'
      ok attributes.wiki_page, 'wiki_page present'
      strictEqual attributes.wiki_page.front_page, true, 'front_page provided correctly'
    wikiPage.setAsFrontPage()
