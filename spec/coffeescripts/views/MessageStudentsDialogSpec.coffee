define [
  'compiled/views/MessageStudentsDialog'
  'jquery'
  'underscore'
], (MessageStudentsDialog,$,_) ->

  QUnit.module "MessageStudentsDialog",
    setup: ->
      @testData =
        context: 'The Quiz'
        recipientGroups: [
          {
            name: 'have taken the quiz'
            recipients: [ {id: 1, short_name: 'bob'}]
          }
          {
            name: "haven't taken the quiz"
            recipients: [ {id: 2, short_name: 'alice'} ]
          }
        ]
      @dialog = new MessageStudentsDialog @testData
      @dialog.render()
      $('#fixtures').append @dialog.$el

    teardown: ->
      @dialog.remove()
      $('#fixtures').empty()

  test "#initialize", ->

    deepEqual @dialog.recipientGroups, @testData.recipientGroups,
      'saves recipientGroups'

    deepEqual @dialog.recipients, @testData.recipientGroups[0].recipients,
      'saves first recipientGroups recipients to be displayed'

    ok @dialog.options.title.match(@testData.context), 'saves the title to be displayed'

    ok @dialog.model, 'creates conversation automatically'

  test "updates list of recipients when dropdown changes", ->
    @dialog.$recipientGroupName.val("haven't taken the quiz").trigger 'change'
    html = @dialog.$el.html()

    ok html.match('alice'), 'updated with the new list of recipients'
    ok !html.match('bob'), "doesn't contain old list of recipients"

  test "#getFormValues returns correct values", ->
    messageBody = 'Students please take your quiz, dang it!'
    @dialog.$messageBody.val messageBody
    json = @dialog.getFormData()
    {body,recipients} = json

    strictEqual json.body, messageBody, 'includes message body'
    strictEqual json.recipientGroupName, undefined,
      "doesn't include recipientGroupName"
    deepEqual json.recipients,
      _.pluck(@testData.recipientGroups[0].recipients, 'id'),
      'includes list of ids'

  test "validateBeforeSave", ->
    errors = @dialog.validateBeforeSave({body: ''},{})
    ok errors.body[0].message, 'validates empty body'
    errors = @dialog.validateBeforeSave({body: 'take your dang quiz'},{recipients: []})
    ok errors.recipientGroupName[0].message, 'validates when sending to empty list of users'



