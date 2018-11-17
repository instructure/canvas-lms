//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Ember from 'ember'
import AssignmentMuter from '../../components/assignment_muter_component'
import startApp from '../start_app'
import fixtures from '../shared_ajax_fixtures'
import $ from 'jquery'

const {ContainerView, run} = Ember

let mutedAssignment = null
let unmutedAssignment = null

function compareIdentity(assignment, fixture) {
  equal(assignment.muted, fixture.muted, 'muted status')
  equal(assignment.id, fixture.id, 'assignment id')
}

QUnit.module('screenreader_gradebook assignment_muter_component', hooks => {
  hooks.beforeEach(function(assert) {
    fixtures.create()
    mutedAssignment = fixtures.assignment_groups[0].assignments[1]
    unmutedAssignment = fixtures.assignment_groups[0].assignments[0]
    const App = startApp()
    return run(() => {
      this.assignment = Ember.copy(mutedAssignment, true)
      return (this.component = App.AssignmentMuterComponent.create({assignment: this.assignment}))
    })
  })

  hooks.afterEach(function(assert) {
    return run(() => {
      this.component.destroy()
      return (this.component = null)
    })
  })

  QUnit.test('it works', function() {
    compareIdentity(this.component.get('assignment'), mutedAssignment)

    Ember.run(() => {
      this.assignment = Ember.copy(unmutedAssignment, true)
      return this.component.setProperties({
        assignment: this.assignment
      })
    })

    compareIdentity(this.component.get('assignment'), unmutedAssignment)
  })

  QUnit.module('moderated grading', hooks => {
    QUnit.test('it is not disabled if assignment is not muted', function() {
      unmutedAssignment = fixtures.assignment_groups[4].assignments[1]
      Ember.run(() => {
        this.assignment = Ember.copy(unmutedAssignment, true)
        return (this.component = App.AssignmentMuterComponent.create({assignment: this.assignment}))
      })
      strictEqual(this.component.get('disabled'), false)
    })

    QUnit.test('it is not disabled if assignment is not moderated', function() {
      const nonmoderatedAssignment = fixtures.assignment_groups[4].assignments[2]
      Ember.run(() => {
        this.assignment = Ember.copy(nonmoderatedAssignment, true)
        return (this.component = App.AssignmentMuterComponent.create({assignment: this.assignment}))
      })
      strictEqual(this.component.get('disabled'), false)
    })

    QUnit.test('it is not disabled if assignment has grades published', function() {
      const gradesPublishedAssignment = fixtures.assignment_groups[4].assignments[3]
      Ember.run(() => {
        this.assignment = Ember.copy(gradesPublishedAssignment, true)
        return (this.component = App.AssignmentMuterComponent.create({assignment: this.assignment}))
      })
      strictEqual(this.component.get('disabled'), false)
    })

    QUnit.test('it is disabled if muted, moderated, and grades not published', function() {
      const mutedModeratedGradesNotPublishedAssignment =
        fixtures.assignment_groups[4].assignments[0]
      Ember.run(() => {
        this.assignment = Ember.copy(mutedModeratedGradesNotPublishedAssignment, true)
        return (this.component = App.AssignmentMuterComponent.create({assignment: this.assignment}))
      })
      strictEqual(this.component.get('disabled'), true)
    })
  })
})
