define [
  'underscore',
  'react',
  'jsx/shared/stores/ProgressStore'
], (_, React, ProgressStore, I18n) ->
  TestUtils = React.addons.TestUtils

  module 'ProgressStoreSpec',
    setup: ->
      @progress_id = 2
      @progress = {
        id: @progress_id,
        context_id: 1,
        context_type: 'EpubExport',
        user_id: 1,
        tag: 'epub_export',
        completion: 0,
        workflow_state: 'queued'
      }

      @server = sinon.fakeServer.create()

    teardown: ->
      ProgressStore.clearState()
      @server.restore()

  test 'get', ->
    @server.respondWith('GET', '/api/v1/progress/' + @progress_id, [
      200, {'Content-Type': 'application/json'},
      JSON.stringify(@progress)
    ])
    ok _.isEmpty(ProgressStore.getState()), 'precondition'
    ProgressStore.get(@progress_id)
    @server.respond()

    state = ProgressStore.getState()
    deepEqual state[@progress.id], @progress
