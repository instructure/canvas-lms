define [
  'compiled/collections/AssignmentOverrideCollection'
  'compiled/models/Assignment'
  'compiled/collections/SectionCollection'
  'compiled/models/DueDateList'
  'compiled/views/assignments/DueDateView'
  'Backbone'
  'compiled/views/assignments/DueDateList'
  'underscore'
], ( AssignmentOverrideCollection, Assignment, SectionCollection, DueDateList,
  DueDateView, {View}, DueDateListView, _ ) ->
  stub = sinon.stub

  module "DueDateListView",
    setup: ->
      @clock = sinon.useFakeTimers()
      @assignment = new Assignment
      @overrides = new AssignmentOverrideCollection [
        {id: '1', course_section_id: '1'}
        {id: '2', course_section_id: '2'}
      ]
      @sections = new SectionCollection [
        {id: '1', name: "foo" }
        {id: '2', name: "bar" }
        {id: '3', name: "baz" }
      ]
      @dueDateList = new DueDateList @overrides, @sections, @assignment
      @dueDateListView = new DueDateListView model: @dueDateList
      @stubReRenderSections = ( stubAvailableSections = true )->
        @dueDateListView.dueDateViews.forEach ( dueDateView ) ->
          stub dueDateView, 'reRenderSections'

    teardown: -> @clock.restore()

  test "creates child DueDateViews for each override", ->
    strictEqual @dueDateListView.dueDateViews.length, 3 # 2 overrides + 1 default

  test """
    when a child duedate view emits model change event for course_section_id,
    tells each of its child views to re-render with a newly calculated list of
    available sections
  """, ->
    override = @overrides.get 2
    @stubReRenderSections()
    @overrides.on 'change:course_section_id', ( override ) =>
      @dueDateListView.dueDateViews.forEach ( dueDateView ) ->
        strictEqual dueDateView.reRenderSections.called, true, "sections not set!"
    @clock.tick 1
    override.set 'course_section_id', 3

  test """
    when override is removed views are told to re render with the freshly
    generated list of available sections
  """, ->
    @stubReRenderSections()
    override = @overrides.get 2
    @overrides.on 'change:course_section_id', ( override ) =>
      @dueDateListView.dueDateViews.forEach ( dueDateView ) ->
        strictEqual dueDateView.reRenderSections.called, true
    @clock.tick 1
    override.set 'course_section_id', 3

  test """
    when override is added views are told to re render with the freshly
      generated list of available sections
  """, ->
    @stubReRenderSections()
    override = @overrides.get 2
    @overrides.on 'add', ( override ) =>
      strictEqual @dueDateListView.dueDateViews.length, 4 # 3 overrides + 1 default
      @dueDateListView.dueDateViews.pop()
      @dueDateListView.dueDateViews.forEach ( dueDateView ) ->
        strictEqual dueDateView.reRenderSections.called, true
    @clock.tick 1
    @overrides.add {id: 'foo', 'course_section_id': '4' }
