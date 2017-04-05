define [
  'jquery'
  'compiled/util/SisValidationHelper'
  'Backbone'
], ($, SisValidationHelper, Backbone) ->

  class AssignmentStub extends Backbone.Model
    url: '/fake'
    postToSIS: (postToSisBoolean) =>
      return @get 'post_to_sis' unless arguments.length > 0
      @set 'post_to_sis', postToSisBoolean

    name: (newName) =>
      return @get 'name' unless arguments.length > 0
      @set 'name', newName

    maxNameLength: =>
      return ENV.MAX_NAME_LENGTH

    dueAt: (date) =>
      return @get 'due_at' unless arguments.length > 0
      @set 'due_at', date

  QUnit.module "SisValidationHelper"

  test 'nameTooLong returns true if name is too long AND postToSIS is true', ->
    @helper = new SisValidationHelper(
                                model: new AssignmentStub()
                                postToSIS: true
                                name: 'Too Much Tuna'
                                maxNameLength: 5)
    ok @helper.nameTooLong()

  test 'nameTooLong returns false if name is too long AND postToSIS is false', ->
    @helper = new SisValidationHelper(
                                model: new AssignmentStub()
                                postToSIS: false
                                name: 'Too Much Tuna'
                                maxNameLength: 5)
    ok !@helper.nameTooLong()

  test 'dueDateMissing returns true if dueAt is null AND postToSIS is true', ->
    @helper = new SisValidationHelper(
                                model: new AssignmentStub()
                                postToSIS: true
                                dueDateRequired: true)
    ok @helper.dueDateMissing()

  test 'dueDateMissing returns false if dueAt is null AND postToSIS is false', ->
    @helper = new SisValidationHelper(
                                model: new AssignmentStub()
                                postToSIS: true
                                dueDateRequired: false)
    ok !@helper.dueDateMissing()
