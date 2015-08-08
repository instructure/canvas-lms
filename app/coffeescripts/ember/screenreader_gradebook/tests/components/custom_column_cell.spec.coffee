define [
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
], (Ember, startApp, fixtures) ->

  {run} = Ember

  fixtures.create()

  setType = null

  module 'custom_column_cell',
    setup: ->
      App = startApp()
      @component = App.CustomColumnCellComponent.create()

      @component.reopen
        customColURL: ->
          "/api/v1/custom_gradebook_columns/:id/:user_id"
      run =>
        @column = Ember.Object.create
          id: '22'
          title: 'Notes'
        @student = Ember.Object.create
          id: '45'
        @dataForStudent = [
          Ember.Object.create {
            column_id: '22'
            content: 'lots of content here'
          }
        ]
        @component.setProperties
          student: @student
          column: @column
          dataForStudent: @dataForStudent
        @component.append()

    teardown: ->
      run =>
        @component.destroy()
        App.destroy()

  test "id", ->
    equal @component.get('id'), 'custom_col_22'

  test "value", ->
    equal @component.get('value'), 'lots of content here'

  test "saveUrl", ->
    equal @component.get('saveURL'), '/api/v1/custom_gradebook_columns/22/45'

  asyncTest "focusOut", ->
    stub = sinon.stub @component, 'boundSaveSuccess'

    requestStub = null
    run =>
      requestStub = Ember.RSVP.resolve(
        id: '22'
        title: 'Notes'
        content: 'less content now'
      )

    sinon.stub(@component, 'ajax').returns requestStub

    run =>
      @component.set('value', 'such success')
      @component.send('focusOut')

      start()
      setTimeout =>
        ok stub.called
