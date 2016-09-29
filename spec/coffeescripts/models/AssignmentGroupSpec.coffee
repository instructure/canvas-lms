define [
  'compiled/models/Assignment'
  'compiled/models/AssignmentGroup'
], (Assignment, AssignmentGroup) ->

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

  module "AssignmentGroup#canDelete"

  test "returns false if AssignmentGroup has frozen assignments", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', true
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    deepEqual group.canDelete(), false

  test "returns false if 'has_assignment_due_in_closed_grading_period' is true", ->
    group = new AssignmentGroup name: 'taco', assignments: []
    group.set 'has_assignment_due_in_closed_grading_period', true
    deepEqual group.canDelete(), false

  test "returns true if 'frozen' and 'has_due_date_in_closed_grading_period' are false", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', false
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    group.set 'has_assignment_due_in_closed_grading_period', false
    deepEqual group.canDelete(), true

  module "AssignmentGroup#hasFrozenAssignments"

  test "returns true if AssignmentGroup has frozen assignments", ->
    assignment = new Assignment name: 'cheese'
    assignment.set 'frozen', [ true ]
    group = new AssignmentGroup name: 'taco', assignments: [ assignment ]
    deepEqual group.hasFrozenAssignments(), true

  module "AssignmentGroup#hasAssignmentDueInClosedGradingPeriod"

  test "returns the value of 'has_assignment_due_in_closed_grading_period'", ->
    group = new AssignmentGroup name: 'taco', assignments: []
    group.set 'has_assignment_due_in_closed_grading_period', true
    deepEqual group.hasAssignmentDueInClosedGradingPeriod(), true
    group.set 'has_assignment_due_in_closed_grading_period', false
    deepEqual group.hasAssignmentDueInClosedGradingPeriod(), false
