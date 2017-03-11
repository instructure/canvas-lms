define [
  'compiled/views/assignments/SectionDropdownView'
  'compiled/models/AssignmentOverride'
  'compiled/models/Section'
], ( SectionDropdownView, AssignmentOverride, Section ) ->

  QUnit.module "SectionDropdownView",
    setup: ->
      @override = new AssignmentOverride( course_section_id: '1' )
      @sections = [
        new Section( id: 1, name: 'foo' )
        new Section( id: 2, name: 'bar' )
      ]
      @view = new SectionDropdownView( sections: @sections, override: @override )
      @view.render()

  test "updates the course_section_id when the form element changes", ->
    @view.$el.val('2').trigger 'change'
    strictEqual @override.get('course_section_id'), '2'

  test "renders all of the sections", ->
    viewHTML = @view.$el.html()
    @sections.forEach ( section ) ->
      ok viewHTML.match( section.get( 'name' ) )
