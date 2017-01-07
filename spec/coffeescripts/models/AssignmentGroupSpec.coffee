define [
  'compiled/models/Assignment'
  'compiled/models/AssignmentGroup'
  'helpers/fakeENV'
], (Assignment, AssignmentGroup, fakeENV) ->

  module "AssignmentGroup"

  test "#hasRules returns true if group has regular rules", ->
    ag = new AssignmentGroup rules: { drop_lowest: 1 }
    strictEqual ag.hasRules(), true

  test "#hasRules returns true if group has never drop rules", ->
    ag = new AssignmentGroup assignments: { id: 1 }, rules: { never_drop: [1] }
    strictEqual ag.hasRules(), true

  test "#hasRules returns false if the group has empty rules", ->
    ag = new AssignmentGroup rules: {}
    strictEqual ag.hasRules(), false

  test "#hasRules returns false if the group has no rules", ->
    ag = new AssignmentGroup
    strictEqual ag.hasRules(), false

  test "#countRules works for regular rules", ->
    ag = new AssignmentGroup rules: { drop_lowest: 1 }
    strictEqual ag.countRules(), 1

  test "#countRules works for never drop rules", ->
    ag = new AssignmentGroup assignments: {id: 1}, rules: { never_drop: [1] }
    strictEqual ag.countRules(), 1

  test "#countRules only counts drop rules for assignments it has", ->
    ag = new AssignmentGroup assignments: {id: 2}, rules: { never_drop: [1] }
    strictEqual ag.countRules(), 0

  test "#countRules returns false if the group has empty rules", ->
    ag = new AssignmentGroup rules: {}
    strictEqual ag.countRules(), 0

  test "#countRules returns false if the group has no rules", ->
    ag = new AssignmentGroup
    strictEqual ag.countRules(), 0

  module "AssignmentGroup#canDelete as admin",
    setup: ->
      fakeENV.setup({
        current_user_roles: ['admin']
      })
    teardown: ->
      fakeENV.teardown()

  test "returns true if AssignmentGroup has frozen assignments and 'any_assignment_in_closed_grading_period' false", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', true
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    group.set 'any_assignment_in_closed_grading_period', false
    deepEqual group.canDelete(), true

  test "returns true if 'any_assignment_in_closed_grading_period' true and there are no frozen assignments", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', false
    group = new AssignmentGroup name: 'taco', assignments: []
    group.set 'any_assignment_in_closed_grading_period', true
    equal group.canDelete(), true

  test "returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are true", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', true
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    group.set 'any_assignment_in_closed_grading_period', true
    deepEqual group.canDelete(), true

  test "returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are false", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', false
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    group.set 'any_assignment_in_closed_grading_period', false
    deepEqual group.canDelete(), true

  module "AssignmentGroup#canDelete as non admin",
    setup: ->
      fakeENV.setup({
        current_user_roles: ['teacher']
      })
    teardown: ->
      fakeENV.teardown()

  test "returns false if AssignmentGroup has frozen assignments and 'any_assignment_in_closed_Grading_period is false", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', true
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    group.set 'any_assignment_in_closed_grading_period', false
    deepEqual group.canDelete(), false

  test "returns false if 'any_assignment_in_closed_grading_period' is true and there are no frozen assignments", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', false
    group = new AssignmentGroup name: 'taco', assignments: []
    group.set 'any_assignment_in_closed_grading_period', true
    equal group.canDelete(), false

  test "returns true if 'frozen' and 'any_assignment_in_closed_grading_period' are false", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', false
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    group.set 'any_assignment_in_closed_grading_period', false
    deepEqual group.canDelete(), true

  test "returns false if 'frozen' and 'any_assignment_in_closed_grading_period' are true", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', true
    group = new AssignmentGroup name: 'taco', assignments: []
    group.set 'any_assignment_in_closed_grading_period', true
    equal group.canDelete(), false

  module "AssignmentGroup#hasFrozenAssignments"

  test "returns true if AssignmentGroup has frozen assignments", ->
    assignment = new Assignment name: 'cheese'
    assignment.set 'frozen', [ true ]
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    deepEqual group.hasFrozenAssignments(), true

  module "AssignmentGroup#anyAssignmentInClosedGradingPeriod"

  test "returns the value of 'any_assignment_in_closed_grading_period'", ->
    group = new AssignmentGroup name: 'taco', assignments: []
    group.set 'any_assignment_in_closed_grading_period', true
    deepEqual group.anyAssignmentInClosedGradingPeriod(), true
    group.set 'any_assignment_in_closed_grading_period', false
    deepEqual group.anyAssignmentInClosedGradingPeriod(), false
