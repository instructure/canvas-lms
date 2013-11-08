define [
  'underscore'
  'compiled/models/WikiPageRevision'
], (_, WikiPageRevision) ->

  module 'WikiPageRevision::urls'
  test 'captures contextAssetString, pageUrl, latest, and summary as constructor options', ->
    revision = new WikiPageRevision {}, contextAssetString: 'course_73', pageUrl: 'page-url', latest: true, summary: true
    strictEqual revision.contextAssetString, 'course_73', 'contextAssetString'
    strictEqual revision.pageUrl, 'page-url', 'pageUrl'
    strictEqual revision.latest, true, 'latest'
    strictEqual revision.summary, true, 'summary'

  test 'urlRoot uses the context path and pageUrl', ->
    revision = new WikiPageRevision {}, contextAssetString: 'course_73', pageUrl: 'page-url'
    strictEqual revision.urlRoot(), '/api/v1/courses/73/pages/page-url/revisions', 'base url'

  test 'url returns urlRoot if latest and id are not specified', ->
    revision = new WikiPageRevision {}, contextAssetString: 'course_73', pageUrl: 'page-url'
    strictEqual revision.url(), '/api/v1/courses/73/pages/page-url/revisions', 'base url'

  test 'url is affected by the latest flag', ->
    revision = new WikiPageRevision {id: 42}, contextAssetString: 'course_73', pageUrl: 'page-url', latest: true
    strictEqual revision.url(), '/api/v1/courses/73/pages/page-url/revisions/latest', 'latest'

  test 'url is affected by the id', ->
    revision = new WikiPageRevision {id: 42}, contextAssetString: 'course_73', pageUrl: 'page-url'
    strictEqual revision.url(), '/api/v1/courses/73/pages/page-url/revisions/42', 'id'

  module 'WikiPageRevision::parse'
  test 'parse sets the id to the url', ->
    revision = new WikiPageRevision {url: 'url'}
    strictEqual revision.get('id'), 'url', 'url set through constructor'
    strictEqual revision.parse({url: 'bob'}).id, 'bob', 'url set through parse'

  test 'toJSON omits the id', ->
    revision = new WikiPageRevision {url: 'url'}
    strictEqual revision.toJSON().id, undefined, 'id omitted'


  module 'WikiPageRevision::fetch'
  test 'the summary flag is passed to the server', ->
    @stub($, 'ajax').returns($.Deferred())

    revision = new WikiPageRevision {}, contextAssetString: 'course_73', pageUrl: 'page-url', summary: true
    revision.fetch()
    strictEqual $.ajax.args[0]?[0]?.data?.summary, true, 'summary provided'

  test 'pollForChanges performs a fetch at most every interval', ->
    revision = new WikiPageRevision {}, pageUrl: 'page-url'
    @sandbox.useFakeTimers()
    @stub(revision, 'fetch').returns($.Deferred())

    revision.pollForChanges(5000)
    revision.pollForChanges(5000)
    @sandbox.clock.tick(4000)
    ok !revision.fetch.called, 'not called until interval elapses'

    @sandbox.clock.tick(2000)
    ok revision.fetch.calledOnce, 'called once interval elapses'
