define [
  'jquery'
  'Backbone'
  'compiled/views/ValidatedFormView'
  'helpers/simulateClick'
], ($, {Model}, ValidatedFormView, click) ->

  module 'ValidatedFormView',
    setup: ->
      @server = sinon.fakeServer.create()
      @clock = sinon.useFakeTimers()
      @form = new MyForm
      $('#fixtures').append @form.el

    teardown: ->
      @form.$el.remove()
      $('.errorBox').remove()
      @server.restore()
      @clock.tick 250 # tick past errorBox animations
      @clock.restore()
      $('#fixtures').empty()

  sendFail = (server, response = '') ->
    server.respond 'POST', '/fail', [
      400
      'Content-Type': 'application/json'
      JSON.stringify response
    ]

  sendSuccess = (server, response = '') ->
    server.respond 'POST', '/success', [
      200
      'Content-Type': 'application/json'
      JSON.stringify response
    ]


  ##
  # Dummy form view for testing
  class MyForm extends ValidatedFormView
    initialize: ->
      super
      @model = new Model
      @model.url = '/fail'
      @render()
    fieldSelectors:
      last_name: '[name="user[last_name]"]'
    template: ->
      """
        <input type="text" name="first_name" value="123">
        <input type="text" name="user[last_name]" value="123">
        <button type="submit">submit</button>
      """

  ###
  # sinon eats some errors, manual sanity debugging follows
  json =
    first_name: [{
      "message": "first name required"
      "type": "required"
    }]
    last_name: [{
      message: "last name required"
      type: "required"
    }]
  form = new MyForm().render()
  form.$el.appendTo $('#fixtures')
  form.showErrors json
  ###


  test 'displays errors when validation fails and remove them on click', 4, ->
    @form.on 'fail', (errors) ->
      ok errors.first_name.$errorBox.is ':visible'
      ok errors.last_name.$errorBox.is ':visible'

      equal errors.first_name.$errorBox.text(), errors.first_name[0].message
      equal errors.last_name.$errorBox.text(), errors.last_name[0].message

    @form.submit()

    sendFail @server,
      errors:
        first_name: [
          "message": "first name required"
          "type": "required"
        ]
        last_name: [
          message: "last name required"
          type: "required"
        ]

  test 'triggers success, submit events', 3, ->
    @form.model.url = '/success'
    @form.on 'submit', ->
      ok true, 'submit handler called'

    @form.on 'success', (resp) ->
      ok true, 'success handler called'
      equal 'ok', resp, 'passes response in'
    @form.submit()
    sendSuccess @server, 'ok'

  test 'triggers fail, submit events', 6, ->
    @form.model.url = '/fail'
    @form.on 'submit', ->
      ok true, 'submit handler called'
    @form.on 'fail', (errors, xhr, status, statusText) ->
      ok true, 'fail handler called'
      equal errors.first_name[0].type, 'required', 'passes errors in'
      ok xhr, 'passes xhr in'
      equal status, 'error', 'passes status in'
      equal statusText, 'Bad Request', 'passes statusText in'
    @form.submit()
    sendFail @server, errors: first_name: [
      "message": "first name required"
      "type": "required"
    ]

  test 'calls submit on DOM form submit', 1, ->
    @form.on 'submit', -> ok true, 'submitted'
    @form.$el.submit()

  test 'disables inputs while loading', 2, ->
    equal @form.$(':disabled').length, 0
    @form.on 'submit', =>
      @clock.tick 20 # disableWhileLoading does its thing in a setTimeout
      equal @form.$(':disabled').length, 3
    @form.submit()
    sendSuccess(@server)

  test 'submit delegates to saveFormData', 1, ->
    sinon.spy(@form, 'saveFormData')

    @form.submit()
    ok @form.saveFormData.called, 'saveFormData called'

  test 'submit calls validateBeforeSave', 1, ->
    sinon.spy(@form, 'validateBeforeSave')

    @form.submit()
    ok @form.validateBeforeSave.called, 'validateBeforeSave called'

  test 'submit always calls hideErrors', 1, ->
    sinon.spy(@form, 'hideErrors')

    @form.submit()
    ok @form.hideErrors.called, 'hideErrors called'

  test 'validateBeforeSave delegates to validateFormData, by default', 1, ->
    sinon.spy(@form, 'validateFormData')

    @form.validateBeforeSave({})
    ok @form.validateFormData.called, 'validateFormData called'

  test 'validate delegates to validateFormData', 1, ->
    sinon.spy(@form, 'validateFormData')

    @form.validate()
    ok @form.validateFormData.called, 'validateFormData called'

  test 'validate always calls hideErrors', 2, ->
    sinon.stub(@form, 'validateFormData')
    sinon.spy(@form, 'hideErrors')

    @form.validateFormData.returns({})
    @form.validate()
    ok @form.hideErrors.called, 'hideErrors called with no errors'

    @form.hideErrors.reset()
    @form.validateFormData.returns
      errors: [
        type: 'required'
        message: 'REQUIRED!'
      ]
    @form.validate()
    ok @form.hideErrors.called, 'hideErrors called with errors'

  test 'validate always calls showErrors', 2, ->
    sinon.stub(@form, 'validateFormData')
    sinon.spy(@form, 'showErrors')

    @form.validateFormData.returns({})
    @form.validate()
    ok @form.showErrors.called, 'showErrors called with no errors'

    @form.showErrors.reset()
    @form.validateFormData.returns
      errors: [
        type: 'required'
        message: 'REQUIRED!'
      ]
    @form.validate()
    ok @form.showErrors.called, 'showErrors called with errors'
