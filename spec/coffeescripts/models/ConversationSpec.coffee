define [
  'compiled/models/Conversation'
], (Conversation) ->

  QUnit.module "Conversation",
    setup: ->
      @conversation = new Conversation

  test "#validate validates body length", ->
    ok @conversation.validate(body: '')
    ok @conversation.validate(body: null).body
    ok @conversation.validate(body: 'body', recipients: [{}]) == undefined

  test "#validate validates there must be at least one recipient object", ->
    testData = body: 'i love testing javascript', recipients: [ {} ]
    ok @conversation.validate(testData) == undefined
    testData.recipients = []
    ok @conversation.validate(testData).recipients
    delete testData.recipients
    ok @conversation.validate(testData).recipients

  test "#url is the correct API url", ->
    equal @conversation.url, '/api/v1/conversations'

