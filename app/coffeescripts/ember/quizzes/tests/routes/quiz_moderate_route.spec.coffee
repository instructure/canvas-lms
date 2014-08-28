define [
  '../start_app'
  'ember'
  'ember-qunit'
], (startApp, Ember, emq) ->

  {run} = Ember
  App = startApp()
  emq.setResolver(Ember.DefaultResolver.create({namespace: App}))

  emq.moduleFor 'route:quiz_moderate', 'Quiz moderate route'

  emq.test 'sanity', ->
    route = @subject()
    ok(@subject)

  createTestSubmission = (userId, other) ->
    Ember.Object.create
      other: other
      user:
        id: userId

  createTestUser = (id) ->
    Ember.Object.create
      id: 1

  mockSubmissions = ->
    one = createTestSubmission(1, 'one')
    two = createTestSubmission(2, 'two')
    three = createTestSubmission(3, 'three')
    [one, two, three]

  mockUsers = ->
    one = createTestUser(1)
    two = createTestUser(2)
    three = createTestUser(3)
    four = createTestUser(4)
    [one, two, three, four]

  emq.test 'createSubHash: builds hash with user ids as keys', ->
    quizSubmissions = mockSubmissions()
    route = @subject()
    hash = route.createSubHash(quizSubmissions)
    equal hash[1].other, quizSubmissions[0].other


  emq.test 'combineModels: ensures a submission, or standin for each user', ->
    users = mockUsers()
    quizSubmissions = mockSubmissions()
    route = @subject()
    updatedUsers = route.combineModels(users, quizSubmissions)
    ok updatedUsers[3].quizSubmission
