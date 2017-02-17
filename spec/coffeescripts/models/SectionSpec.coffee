define [
  'compiled/models/Section'
  'i18n!overrides'
], ( Section, I18n ) ->

  QUnit.module "Section"

  test "#initialize doesn't assign value for id if not given", ->
    section = new Section
    strictEqual section.id, undefined

  test "#Section.defaultDueDateSectionID is '0'", ->
    strictEqual Section.defaultDueDateSectionID, '0'

  test "Section.defaultDueDateSection returns a section with id of '0'", ->
    section = Section.defaultDueDateSection()
    strictEqual section.id, '0'
    strictEqual section.get('name'), I18n.t( 'overrides.everyone', 'Everyone' )

  test "#isDefaultDueDateSection returns true if id is '0'", ->
    strictEqual Section.defaultDueDateSection().isDefaultDueDateSection(), true

  test "#isDefaultDueDateSection returns false if id is not '0'", ->
    strictEqual (new Section).isDefaultDueDateSection(), false
