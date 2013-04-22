define [
  'compiled/models/AssignmentOverride'
  'compiled/models/Assignment'
], ( AssignmentOverride, Assignment ) ->

  module "AssignmentOverride",
    setup: ->
      @clock = sinon.useFakeTimers()

    teardown: -> @clock.restore()


  test "#representsDefaultDueDate returns true if course_section_id == 0", ->
    override = new AssignmentOverride course_section_id: 0
    strictEqual override.representsDefaultDueDate(), true

  test "#representsDefaultDueDate returns false if course_section_id != 0", ->
    override = new AssignmentOverride course_section_id: 11
    strictEqual override.representsDefaultDueDate(), false

  test "#AssignmentOverride.defaultDueDate class method returns an AssignmentOverride that represents the default due date", ->
    override = AssignmentOverride.defaultDueDate()
    strictEqual override.representsDefaultDueDate(), true

