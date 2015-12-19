define [
  'jsx/gradebook/grid/stores/customColumnsStore'
], (CustomColumnsStore) ->
  baseSetup = ->
    CustomColumnsStore.state = undefined
    CustomColumnsStore.getInitialState()

  module 'CustomColumnsStore#getInitialState',
    setup: ->
      baseSetup()
    teardown: ->
      CustomColumnsStore.state = undefined

  test 'initializes with expected state', ->
    expected =
      teacherNotes: null,
      customColumns:
        data: []
        columnData: {}

    actual = CustomColumnsStore.state
    deepEqual(actual, expected)

  module 'CustomColumnsStore#onLoadCompleted',
    setup: ->
      baseSetup()
      @loadedData = [
        hidden: false
        id: "1"
        position: 1
        teacher_notes: false
        title: "Custom Column 1"
      ]
      CustomColumnsStore.onLoadCompleted(@loadedData)
    teardown: ->
      @loadedData = undefined
      CustomColumnsStore.state = undefined

  test 'sets incoming data to state.customColumns.data', ->
    expected = @loadedData
    actual = CustomColumnsStore.state.customColumns.data
    deepEqual(actual, expected)

  module 'CustomColumnsStore#onLoadColumnDataCompleted',
    setup: ->
      @columnId = 1
      @downloadedData = [
        {
          content: 'hi'
          user_id: 3
        },
        {
          content: 'there'
          user_id: 4
        }
      ]

      baseSetup()
      CustomColumnsStore.onLoadColumnDataCompleted(@downloadedData, @columnId)
    teardown: ->
      CustomColumnsStore.state = undefined
      @columnId = undefined
      @downloadedData = undefined

  test 'correctly sets up column data', ->
    expected = {
      1: {
        3:
          content: 'hi'
          user_id: 3
        4:
          content: 'there'
          user_id: 4
      }
    }

    actual = CustomColumnsStore.state.customColumns.columnData
    debugger
    deepEqual(actual, expected)

  module 'CustomColumnsStore#getColumnDatum',
    setup: ->
      @columnId = 1
      @downloadedData = [
        {
          content: 'hi'
          user_id: 3
        },
        {
          content: 'there'
          user_id: 4
        }
      ]
      baseSetup()
      CustomColumnsStore.onLoadColumnDataCompleted(@downloadedData, @columnId)
    teardown: ->
      CustomColumnsStore.state = undefined
      @columnId = undefined
      @downloadedData = undefined

  test 'returns undefined if no such column', ->
    expected = undefined
    actual = CustomColumnsStore.getColumnDatum(2, 3)
    strictEqual(actual, expected)

  test 'returns undefined if no entry for that user', ->
    expected = undefined
    actual = CustomColumnsStore.getColumnDatum(1, 2)
    strictEqual(actual, expected)

  test 'returns the correct value', ->
    expected = @downloadedData[1]
    actual = CustomColumnsStore.getColumnDatum(1,4)
    deepEqual(actual, expected)

