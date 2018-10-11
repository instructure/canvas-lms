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

import $ from 'jquery'
import startApp from '../start_app'
import Ember from 'ember'
import fixtures from '../shared_ajax_fixtures'

let App = null

const buttonDisabled = (trigger, expectedBoolean) =>
  equal(find(trigger).prop('disabled'), expectedBoolean)

const checkSelection = (id, selection) => equal(id, find(selection).val())

const checkSelectedText = (text, selection) =>
  equal(
    text,
    find(selection)
      .find('option:selected')
      .text()
  )

const checkText = (selector, expectedText) =>
  equal(Ember.$.trim(find(`.assignmentsPanel ${selector}`).text()), expectedText)

function studentSectionAssertions(selected, currentIndex, expectedIndex) {
  equal(currentIndex, expectedIndex)
  checkSelection(selected.id, '#student_select')
  return checkSelectedText(selected.name, '#student_select')
}

QUnit.module('screenreader_gradebook student/assignment navigation: on page load', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(
      () => (this.controller = App.__container__.lookup('controller:screenreader_gradebook'))
    )
  },
  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('Previous Student button is disabled', () =>
  buttonDisabled('.student_navigation .previous_object:first', true))

test('Previous Assignment button is disabled', () =>
  buttonDisabled('.assignment_navigation .previous_object', true))

test('Next Student button is active', () =>
  buttonDisabled('.student_navigation .next_object:first', false))

test('Next Assignment button is active', () =>
  buttonDisabled('.assignment_navigation .next_object', false))

test('no student or assignment is loaded', () => {
  checkText('.student_selection', 'Select a student to view additional information here.')
  return checkText(
    '.assignment_selection',
    'Select an assignment to view additional information here.'
  )
})

QUnit.module('screenreader_gradebook student/assignment navigation: with first item selected', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.controller = App.__container__.lookup('controller:screenreader_gradebook')
      return Ember.run(() => {
        this.controller.set('selectedStudent', this.controller.get('students.firstObject'))
        return this.controller.set(
          'selectedAssignment',
          this.controller.get('assignments.firstObject')
        )
      })
    })
  },
  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('Previous buttons are disabled', () => {
  buttonDisabled('.student_navigation .previous_object:first', true)
  buttonDisabled('.assignment_navigation .previous_object', true)
  checkText('.student_selection', 'Bob')
  return checkText('.assignment_selection', 'Z Eats Soup')
})

// compares & checks before/after objects
test('clicking Next Student button displays next student', function() {
  const before = this.controller.get('selectedStudent')
  checkSelection(before.id, '#student_select')
  return click('.student_navigation .next_object:first').then(() => {
    const after = this.controller.get('selectedStudent')
    checkSelection(after.id, '#student_select')
    notEqual(before.id, after.id)
    const next = this.controller.get('students').indexOf(before) + 1
    equal(next, this.controller.get('students').indexOf(after))
  })
})

// compares & checks before/after objects
test('clicking Next Assignment button displays next assignment', function() {
  const before = this.controller.get('selectedAssignment')
  checkSelection(before.id, '#assignment_select')
  return click('.assignment_navigation .next_object').then(() => {
    const after = this.controller.get('selectedAssignment')
    checkSelection(after.id, '#assignment_select')
    notEqual(before, after)
    const next = this.controller.get('assignments').indexOf(before) + 1
    equal(next, this.controller.get('assignments').indexOf(after))
  })
})

test('clicking next then previous will refocus on next student', () =>
  click('.student_navigation .next_object:first').then(() =>
    click('.student_navigation .previous_object:first').then(() => {
      equal($('.student_navigation .next_object:first')[0], document.activeElement)
    })
  ))

test('clicking next then previous will refocus on next assignment', () =>
  click('.assignment_navigation .next_object').then(() =>
    click('.assignment_navigation .previous_object').then(() => {
      equal($('.assignment_navigation .next_object')[0], document.activeElement)
    })
  ))

QUnit.module('screenreader_gradebook student/assignment navigation: with second item selected', {
  setup() {
    App = startApp()
    return visit('/').then(() => {
      this.controller = App.__container__.lookup('controller:screenreader_gradebook')
      return Ember.run(() => {
        this.controller.set('selectedStudent', this.controller.get('students').objectAt(1))
        return this.controller.set(
          'selectedAssignment',
          this.controller.get('assignments').objectAt(1)
        )
      })
    })
  },
  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('Previous/Next Student buttons are both active', () => {
  buttonDisabled('.student_navigation .previous_object:first', false)
  return buttonDisabled('.student_navigation .next_object:first', false)
})

test('Previous/Next Assignment buttons are both active', () => {
  buttonDisabled('.assignment_navigation .previous_object', false)
  return buttonDisabled('.assignment_navigation .next_object', false)
})

QUnit.module('screenreader_gradebook student/assignment navigation: with last item selected', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.controller = App.__container__.lookup('controller:screenreader_gradebook')
      return Ember.run(() => {
        this.controller.set('selectedStudent', this.controller.get('students.lastObject'))
        return this.controller.set(
          'selectedAssignment',
          this.controller.get('assignments.lastObject')
        )
      })
    })
  },
  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('Previous Student button is active', () =>
  buttonDisabled('.student_navigation .previous_object:first', false))

test('Previous Assignment button is active', () =>
  buttonDisabled('.assignment_navigation .previous_object', false))

test('Next Student button is disabled', () =>
  buttonDisabled('.student_navigation .next_object:first', true))

test('Next Assignment button is disabled', () =>
  buttonDisabled('.assignment_navigation .next_object', true))

// compares & checks before/after objects
test('clicking Previous Student button displays previous student', function() {
  const before = this.controller.get('selectedStudent')
  checkSelection(before.id, '#student_select')
  return click('.student_navigation .previous_object:first').then(() => {
    const after = this.controller.get('selectedStudent')
    checkSelection(after.id, '#student_select')
    notEqual(before.id, after.id)
    const previous = this.controller.get('students').indexOf(before) - 1
    equal(previous, this.controller.get('students').indexOf(after))
  })
})

// compares & checks before/after objects
test('clicking Previous Assignment button displays previous assignment', function() {
  const before = this.controller.get('selectedAssignment')
  checkSelection(before.id, '#assignment_select')
  return click('.assignment_navigation .previous_object').then(() => {
    const after = this.controller.get('selectedAssignment')
    checkSelection(after.id, '#assignment_select')
    notEqual(before.id, after.id)
    const previous = this.controller.get('assignments').indexOf(before) - 1
    equal(previous, this.controller.get('assignments').indexOf(after))
  })
})

test('clicking previous then next will reset the focus for students', () =>
  click('.student_navigation .previous_object:first').then(() =>
    click('.student_navigation .next_object:first').then(() => {
      equal($('.student_navigation .previous_object:first')[0], document.activeElement)
    })
  ))

test('clicking previous then next will reset the focus for assignments', () =>
  click('.assignment_navigation .previous_object').then(() =>
    click('.assignment_navigation .next_object').then(() => {
      equal($('.assignment_navigation .previous_object')[0], document.activeElement)
    })
  ))

QUnit.module('screenreader_gradebook assignment navigation: display update', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.controller = App.__container__.lookup('controller:screenreader_gradebook')
      return Ember.run(() => {
        this.controller.set('selectedStudent', this.controller.get('students.firstObject'))
        return this.controller.set(
          'selectedAssignment',
          this.controller.get('assignments.firstObject')
        )
      })
    })
  },
  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('screenreader_gradebook assignment selection: grade for field updates', function() {
  const assignment_name_selector = "label[for='student_and_assignment_grade']"

  const selectedAssigName = this.controller.get('selectedAssignment.name')
  checkText(assignment_name_selector, `Grade for: ${selectedAssigName}`)

  Ember.run(() =>
    this.controller.set('selectedAssignment', this.controller.get('assignments').objectAt(2))
  )

  const newSelectedAssigName = this.controller.get('selectedAssignment.name')
  return checkText(assignment_name_selector, `Grade for: ${newSelectedAssigName}`)
})

QUnit.module('screenreader_gradebook assignment navigation: assignment sorting', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(
      () => (this.controller = App.__container__.lookup('controller:screenreader_gradebook'))
    )
  },
  teardown() {
    // resetting userSettings to default
    Ember.run(() =>
      this.controller.set(
        'assignmentSort',
        this.controller.get('assignmentSortOptions').findBy('value', 'assignment_group')
      )
    )
    return Ember.run(App, 'destroy')
  }
})

test('alphabetical', function() {
  const before = this.controller.get('assignments.firstObject')
  Ember.run(() =>
    this.controller.set(
      'assignmentSort',
      this.controller.get('assignmentSortOptions').findBy('value', 'alpha')
    )
  )
  buttonDisabled('.assignment_navigation .next_object', false)
  buttonDisabled('.assignment_navigation .previous_object', true)
  const first = this.controller.get('assignments.firstObject')
  notEqual(before, first)
  return click('.assignment_navigation .next_object').then(() =>
    checkSelection(first.id, '#assignment_select')
  )
})

test('due date', function() {
  const before = this.controller.get('assignments.firstObject')
  Ember.run(() =>
    this.controller.set(
      'assignmentSort',
      this.controller.get('assignmentSortOptions').findBy('value', 'due_date')
    )
  )
  buttonDisabled('.assignment_navigation .next_object', false)
  buttonDisabled('.assignment_navigation .previous_object', true)
  const first = this.controller.get('assignments.firstObject')
  notEqual(before, first)
  return click('.assignment_navigation .next_object').then(() =>
    checkSelection(first.id, '#assignment_select')
  )
})

test('changing sorting option with selectedAssignment', function() {
  // SORT BY: alphabetical
  Ember.run(() =>
    this.controller.set(
      'assignmentSort',
      this.controller.get('assignmentSortOptions').findBy('value', 'alpha')
    )
  )

  // check first assignment
  return click('.assignment_navigation .next_object').then(() => {
    const first = this.controller.get('selectedAssignment')
    checkSelection(first.id, '#assignment_select')
    equal(first.name, 'Apples are good')
    const second = this.controller
      .get('assignments')
      .objectAt(this.controller.get('assignmentIndex') + 1)

    // check Next
    return click('.assignment_navigation .next_object').then(() => {
      checkSelection(second.id, '#assignment_select')
      notEqual(first.id, second.id)
      equal(second.name, 'Big Bowl of Nachos')

      // check Previous
      return click('.assignment_navigation .previous_object').then(() => {
        const selected = this.controller.get('selectedAssignment')
        equal(selected.id, first.id)
        checkSelection(selected.id, '#assignment_select')
        const oldIndex = this.controller.get('assignmentIndex')

        // SORT BY: due date
        Ember.run(() =>
          this.controller.set(
            'assignmentSort',
            this.controller.get('assignmentSortOptions').findBy('value', 'due_date')
          )
        )

        // check selectedAssignment identity and index
        equal(selected.id, this.controller.get('selectedAssignment.id'))
        notEqual(oldIndex, this.controller.get('assignmentIndex'))

        // check Next
        const selectedIndex = this.controller.get('assignmentIndex')
        const next = this.controller.get('assignments').objectAt(selectedIndex + 1)
        return click('.assignment_navigation .next_object').then(() =>
          checkSelection(next.id, '#assignment_select')
        )
      })
    })
  })
})

QUnit.module('screenreader_gradebook student navigation: section selection', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.controller = App.__container__.lookup('controller:screenreader_gradebook')
      return Ember.run(() =>
        this.controller.set('selectedSection', this.controller.get('sections.lastObject'))
      )
    })
  },
  teardown() {
    return Ember.run(App, 'destroy')
  }
})

test('prev/next still work', function() {
  buttonDisabled('.student_navigation .previous_object:first', true)
  buttonDisabled('.student_navigation .next_object:first', false)

  // first in section
  return click('.student_navigation .next_object:first').then(() => {
    const first = this.controller.get('selectedStudent')
    let index = this.controller.get('studentIndex')
    buttonDisabled('.student_navigation .previous_object:first', true)
    studentSectionAssertions(first, index, 0)

    // second in section
    click('.student_navigation .next_object:first').then(() => {
      const second = this.controller.get('selectedStudent')
      index = this.controller.get('studentIndex')
      buttonDisabled('.student_navigation .previous_object:first', false)
      studentSectionAssertions(second, index, 1)
      return notEqual(first, second)
    })

    return click('.student_navigation .previous_object:first').then(() => {
      buttonDisabled('.student_navigation .previous_object:first', true)
      return buttonDisabled('.student_navigation .next_object:first', false)
    })
  })
})

test('resets selectedStudent when student is not in both sections', function() {
  return click('.student_navigation .next_object:first').then(() => {
    const firstStudent = this.controller.get('selectedStudent')

    Ember.run(() =>
      this.controller.set('selectedSection', this.controller.get('sections.firstObject'))
    )
    const resetStudent = this.controller.get('selectedStudent')
    notEqual(firstStudent, resetStudent)
    equal(resetStudent, null)

    return click('.student_navigation .next_object:first').then(() => {
      const current = this.controller.get('selectedStudent')
      notEqual(current, firstStudent)
      return notEqual(current, resetStudent)
    })
  })
})

test('maintains selectedStudent when student is in both sections and updates navigation points', function() {
  Ember.run(() =>
    // requires a fixture for a student with enrollment in 2 sections
    // and a previous/next option for all sections
    this.controller.set('selectedStudent', this.controller.get('students').objectAt(4))
  )

  return visit('/').then(() => {
    buttonDisabled('.student_navigation .previous_object:first', false)
    buttonDisabled('.student_navigation .next_object:first', false)

    const selected = this.controller.get('selectedStudent')
    checkSelectedText(selected.name, '#student_select')
    checkSelectedText(this.controller.get('selectedSection.name'), '#section_select')

    // position in selected dropdown
    let position = this.controller.get('studentsInSelectedSection').indexOf(selected)
    equal(position, 1)
    equal(this.controller.get('studentIndex'), position)

    // change section
    Ember.run(() =>
      this.controller.set('selectedSection', this.controller.get('sections.firstObject'))
    )
    buttonDisabled('.student_navigation .previous_object:first', false)
    buttonDisabled('.student_navigation .next_object:first', false)

    const newSelected = this.controller.get('selectedStudent')
    checkSelectedText(newSelected.name, '#student_select')
    checkSelectedText(this.controller.get('selectedSection.name'), '#section_select')
    equal(selected, newSelected)

    // position in selected dropdown
    position = this.controller.get('studentsInSelectedSection').indexOf(selected)
    equal(position, 3)
    equal(this.controller.get('studentIndex'), position)
  })
})

QUnit.module(
  'screenreader_gradebook student/assignment navigation: announcing selection with aria-live',
  {
    setup() {
      fixtures.create()
      App = startApp()
      return visit('/').then(() => {
        this.controller = App.__container__.lookup('controller:screenreader_gradebook')
        return Ember.run(() => {
          this.controller.set('selectedStudent', this.controller.get('students.firstObject'))
          return this.controller.set(
            'selectedAssignment',
            this.controller.get('assignments.firstObject')
          )
        })
      })
    },
    teardown() {
      return Ember.run(App, 'destroy')
    }
  }
)

test('aria-announcer', function() {
  equal(Ember.$.trim(find('.aria-announcer').text()), '')

  click('.student_navigation .next_object:first').then(() => {
    const expected = this.controller.get('selectedStudent.name')
    equal(Ember.$.trim(find('.aria-announcer').text()), expected)
  })

  click('.assignment_navigation .next_object').then(() => {
    const expected = this.controller.get('selectedAssignment.name')
    equal(Ember.$.trim(find('.aria-announcer').text()), expected)
  })

  return click('#hide_names_checkbox').then(() =>
    Ember.run(() => equal(Ember.$.trim(find('.aria-announcer').text()), ''))
  )
})
