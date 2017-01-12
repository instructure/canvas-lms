define [
  'jsx/gradebook/grid/stores/sectionsStore'
  'helpers/fakeENV'
  'compiled/userSettings'
], (SectionsStore, fakeEnv, userSettings) ->
  module 'SectionsStore#getInitialState',
    setup: ->
      SectionsStore.getInitialState()
    teardown: ->
      SectionsStore.state = undefined

  test 'intializes all required values to null', ->
    expected =
      sections: null
      error: null
      selected: '0'
    actual = SectionsStore.state
    deepEqual(actual, expected)

  module 'SectionsStore#onSectionsLoadComplete',
    setup: ->
      @downloadedData = ['hello world']
      SectionsStore.getInitialState()
      SectionsStore.onLoadCompleted(@downloadedData)
    teardown: ->
      SectionsStore.state = undefined
      @downloadedData = undefined

  test 'sets state when data is loaded', ->
    expected =
      sections: @downloadedData
      error: null
      selected: '0'
    actual = SectionsStore.state
    deepEqual(actual, expected)

  sections = ->
    [
      {
        id: '1'
      },
      {
        id: '2'
      }
    ]

  defaultEnv = ->
    current_user_id: '1'
    context_asset_string: '1'

  module 'SectionsStore#selected',
    setup: ->
      SectionsStore.state =
        selected: '2'
        sections: sections()
        error: null
    teardown: ->
      SectionsStore.state = undefined

  test 'returns the stored section', ->
    expected = sections()[1]
    actual = SectionsStore.selected()
    deepEqual(actual, expected)

  module 'SectionsStore#sectionOnLoad with nothing stored',
    setup: ->
    teardown: ->

  test 'by default returns 0', ->
    expected = '0'
    actual = SectionsStore.sectionOnLoad()
    strictEqual(actual, expected)

  module 'SectionsStore#sectionOnLoad with something stored',
    setup: ->
      fakeEnv.setup(defaultEnv())
      userSettings.contextSet('grading_show_only_section', '2')
    teardown: ->
      userSettings.contextRemove('grading_show_only_section')
      fakeEnv.teardown()

  test 'returns the value stored in local storage', ->
    expected = '2'
    actual = SectionsStore.sectionOnLoad()
    strictEqual(actual, expected)

  module 'SectionsStore#onSelectSection',
    setup: ->
      fakeEnv.setup(defaultEnv())
      SectionsStore.state =
        selected: '2'
        sections: sections()
        error: null
      SectionsStore.onSelectSection('1')
    teardown: ->
      SectionsStore.state = undefined
      fakeEnv.teardown()

  test 'sets the selected section', ->
    expected = sections()[0]
    actual = SectionsStore.selected()
    deepEqual(actual, expected)
