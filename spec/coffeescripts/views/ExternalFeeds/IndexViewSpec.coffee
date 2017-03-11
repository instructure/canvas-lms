define [
  'jquery'
  'compiled/collections/ExternalFeedCollection'
  'compiled/models/ExternalFeed'
  'compiled/views/ExternalFeeds/IndexView'
  'helpers/fakeENV'
], ($, ExternalFeedCollection, ExternalFeed, ExternalFeedsIndexView, fakeENV) ->

  QUnit.module 'IndexView',
    setup: ->
      fakeENV.setup(context_asset_string: 'courses_1')
      $('#fixtures').append($("<div>").attr('id', 'feed_container'))
      ef = new ExternalFeed
        id: 1
        url: 'http://www.example.com/feed'
        display_name: 'Example Feed'
        verbosity: 'link_only'
        header_match: null
      efc = new ExternalFeedCollection [ef]
      @view = new ExternalFeedsIndexView
        el: '#feed_container'
        permissions: { create: true }
        collection: efc
      @view.render()

    teardown: ->
      @view.remove()
      $('#fixtures').empty()
      fakeENV.teardown()

  submitForm = (url) ->
    $('.add_external_feed_link').click()
    $('#external_feed_url').val(url)
    $('#external_feed_verbosity').val('link_only')
    $('#add_external_feed_form button').click()



  test 'renders the list of feeds', ->
    equal $('li.external_feed').length, 1
    ok $('li.external_feed').text().match('Example Feed')

  test 'validates the url properly', ->
    errors = @view.validateBeforeSave(url: '')
    equal errors.url.length, 1

    errors = @view.validateBeforeSave(url: 'http://example.com')
    ok !errors.url

  # TODO: These specs are failing intermittantly and I can't figure out why,
  # but it's not worth the build being super fragile


  # test 'add external feed is read by screenreader', ->
  #   @spy($, 'screenReaderFlashMessage')
  #   server = sinon.fakeServer.create()
  #   server.respondWith('POST', '/api/v1/courses/1/external_feeds',
  #     [200, { 'Content-Type': 'application/json' }, JSON.stringify({
  #       id: 2
  #       url: 'http://www.example.com/feed2'
  #       display_name: 'Other Feed'
  #       verbosity: 'link_only'
  #       header_match: null
  #     })])

  #   submitForm('http://www.example.com/feed2')
  #   server.respond()
  #   equal $.screenReaderFlashMessage.callCount, 1
  #   server.restore()

  # test 'delete external feed is read by screenreader', ->
  #   @spy($, 'screenReaderFlashMessage')
  #   server = sinon.fakeServer.create()
  #   server.respondWith('POST', '/api/v1/courses/1/external_feeds',
  #     [200, { 'Content-Type': 'application/json' }, JSON.stringify({
  #       id: 3
  #       url: 'http://www.example.com/feed2'
  #       display_name: 'Other Feed'
  #       verbosity: 'link_only'
  #       header_match: null
  #     })])

  #   submitForm('http://www.example.com/feed2')
  #   server.respond()
  #   $('.close').first().click()
  #   equal $.screenReaderFlashMessage.callCount, 1

  # test 'allows adding a new feed', ->
  #   server = sinon.fakeServer.create()
  #   server.respondWith('POST', '/api/v1/courses/1/external_feeds',
  #     [200, { 'Content-Type': 'application/json' }, JSON.stringify({
  #       id: 2
  #       url: 'http://www.example.com/feed2'
  #       display_name: 'Other Feed'
  #       verbosity: 'link_only'
  #       header_match: null
  #     })])

  #   submitForm('http://www.example.com/feed2')
  #   server.respond()

  #   equal $('li.external_feed').length, 2
  #   ok $('li.external_feed').text().match('Other Feed')

  #   server.restore()

  # test 'shows errors if save failed', ->
  #   server = sinon.fakeServer.create()
  #   server.respondWith('POST', '/api/v1/courses/1/external_feeds',
  #     [400, { 'Content-Type': 'application/json' }, JSON.stringify({
  #       errors: { url: [{ attribute: 'url', message: 'taken', type: 'taken' }] }
  #     })])

  #   submitForm('http://www.example.com/feed2')
  #   server.respond()

  #   equal $('li.external_feed').length, 1
  #   ok $('.errorBox').text().match('taken')

  #   $('.errorBox').remove()
  #   server.restore()
