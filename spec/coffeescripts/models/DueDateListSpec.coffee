define [
  'compiled/models/DueDateList'
  'compiled/models/Assignment'
  'compiled/models/AssignmentOverride'
  'compiled/collections/AssignmentOverrideCollection'
  'compiled/models/Section'
  'compiled/collections/SectionCollection'
  'underscore'
], ( DueDateList, Assignment, AssignmentOverride, AssignmentOverrideCollection,
Section, SectionList, _ ) ->

  stub = sinon.stub

  module "DueDateList",
    setup: ->
      @date = Date.now()
      @assignment = new Assignment
        due_at: @date
        unlock_at: @date
        lock_at: @date
      @overrides = new AssignmentOverrideCollection [
        new AssignmentOverride
          course_section_id: '1'
        new AssignmentOverride
          course_section_id: '2'
      ]
      @sections = new SectionList [
        new Section id: '1', name: "CourseSection1"
        new Section id: '2', name: "CourseSection2"
        new Section id: '3', name: "CourseSection3"
      ]
      @dueDateList = new DueDateList @overrides, @sections

  test """
  #availableSections returns list of course sections that
  are not being used by the AssignmentOverrideCollection
  """, ->
    availableSections = @dueDateList.availableSections()
    strictEqual availableSections.length, 1
    strictEqual availableSections[0].id, '3'

  test """
  #containsSectionsWithoutOverrides returns true when a section's id
  does not belong to an AssignmentOverride and there isn't an
  override representing a default due date present
  """, ->
    strictEqual @dueDateList.containsSectionsWithoutOverrides(), true

  test """
  #containsSectionsWithoutOverrides returns false when overrides contain
  an override representing the default due date
  """, ->
    overridesWithDefaultDueDate =
      new AssignmentOverrideCollection(@overrides.toJSON())
    overridesWithDefaultDueDate.add AssignmentOverride.defaultDueDate()
    dueDateList =
      new DueDateList overridesWithDefaultDueDate, @sections,@assignment
    strictEqual dueDateList.containsSectionsWithoutOverrides(), false

  test """
  #containsSectionsWithoutOverrides returns false if all sections belong to
  an assignment override
  """, ->
    @overrides.add new AssignmentOverride( course_section_id: '3' )
    @dueDateList = new DueDateList @overrides, @sections, @assignment
    strictEqual @dueDateList.containsSectionsWithoutOverrides(), false

  test """
  #containsBlankOverrides returns true if at least one override has a
  falsy due_at
  """, ->
    strictEqual @dueDateList.containsBlankOverrides(), true

  test """
  #containsBlankOverrides returns false if no overrides have a falsy due_at
  """, ->
    @overrides.forEach ( override ) -> override.set 'due_at', Date.now()
    strictEqual @dueDateList.containsBlankOverrides(), false

  test "#blankOverrides returns blank overrides in the overrides", ->
    stub(@overrides, 'blank').returns [ 1, 2, 3 ]
    deepEqual @dueDateList.blankOverrides(), [1, 2, 3]

  test """
  updates name to 'everyone' or 'everyone else' when the number of overrides
  changes
  """, ->
    defaultDueDate = AssignmentOverride.defaultDueDate()
    defaultSection = Section.defaultDueDateSection()
    @overrides = new AssignmentOverrideCollection [
      defaultDueDate.toJSON()
    ]
    @sections = new SectionList [
      defaultSection
    ]
    @dueDateList = new DueDateList @overrides, @sections
    override = new AssignmentOverride id: '1'
    @dueDateList.addOverride override
    strictEqual defaultSection.get('name'), 'Everyone Else'
    @dueDateList.removeOverride override
    strictEqual defaultSection.get('name'), 'Everyone'

  test """
  constructor adds an override representing the default due date using the
  assignment's due date, lock_at, and unlock_at, if an assignment is given
  """, ->
    @dueDateList = new DueDateList @overrides, @sections, @assignment
    strictEqual @dueDateList.overrides.length, 3
    override = @dueDateList.overrides.pop()
    strictEqual override.get('due_at'), @date
    strictEqual override.get('unlock_at'), @date
    strictEqual override.get('lock_at'), @date

  test """
    constructor adds a section to the list of sections representing the
    assignment's default due date if an assignment is given
  """, ->
    @dueDateList = new DueDateList @overrides, @sections, @assignment
    strictEqual @dueDateList.sections.length, 4
    strictEqual @dueDateList.sections.shift().id,Section.defaultDueDateSectionID

  test """
  constructor adds a default due date section if the section list passed
  is empty
  """, ->
    @dueDateList = new DueDateList @overrides, new SectionList([]), @assignment
    strictEqual @dueDateList.sections.length, 1

  test "constructor does not add a section if no assignment given", ->
    strictEqual @dueDateList.sections.length, 3

  test "constructor does not add an override of no assignment given", ->
    strictEqual @dueDateList.overrides.length, 2

  test "#toJSON includes sections", ->
    deepEqual @dueDateList.toJSON().sections, @sections.toJSON()

  test "#toJSON includes overrides", ->
    deepEqual @dueDateList.toJSON().overrides, @overrides.toJSON()
