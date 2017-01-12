define [
  'jsx/gradebook/grid/stores/tableStore'
], (TableStore) ->

  module 'TableStore',
    setup: ->
      @stateBeforeInitializing = TableStore.state
      TableStore.init()
    teardown: ->
      TableStore.state = @stateBeforeInitializing

  test 'initializes in a loading state', ->
    ok TableStore.state.loading

  test 'onEnterLoadingState sets loading to true', ->
    TableStore.state.loading = false
    TableStore.onEnterLoadingState()
    ok TableStore.state.loading
