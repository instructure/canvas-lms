#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'compiled/views/assignments/SectionDropdownView'
  'compiled/models/AssignmentOverride'
  'compiled/models/Section'
  'helpers/assertions'
], ( SectionDropdownView, AssignmentOverride, Section, assertions ) ->

  QUnit.module "SectionDropdownView",
    setup: ->
      @override = new AssignmentOverride( course_section_id: '1' )
      @sections = [
        new Section( id: 1, name: 'foo' )
        new Section( id: 2, name: 'bar' )
      ]
      @view = new SectionDropdownView( sections: @sections, override: @override )
      @view.render()

  test 'should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @view, done, {'a11yReport': true}

  test "updates the course_section_id when the form element changes", ->
    @view.$el.val('2').trigger 'change'
    strictEqual @override.get('course_section_id'), '2'

  test "renders all of the sections", ->
    viewHTML = @view.$el.html()
    @sections.forEach ( section ) ->
      ok viewHTML.match( section.get( 'name' ) )
