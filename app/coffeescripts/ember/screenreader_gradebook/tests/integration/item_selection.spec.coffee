define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

  fixtures.create()

  buttonDisabled = (trigger, expectedBoolean) ->
    equal find(trigger).prop('disabled'), expectedBoolean

  checkSelection = (id, selection) ->
    equal id, find(selection).val()

  checkSelectedText = (text, selection) ->
    equal text, find(selection).find('option:selected').text()

  checkText = (selector, expectedText) ->
    equal Ember.$.trim(find(".assignmentsPanel #{selector}").text()), expectedText

  studentSectionAssertions = (selected, currentIndex, expectedIndex) ->
    equal currentIndex, expectedIndex
    checkSelection(selected.id, '#student_select')
    checkSelectedText(selected.name, '#student_select')


  module 'screenreader_gradebook student/assignment navigation: on page load',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
    teardown: ->
      Ember.run App, 'destroy'

  test 'Previous Student button is disabled', ->
    buttonDisabled('#prev_student', true)

  test 'Previous Assignment button is disabled', ->
    buttonDisabled('#prev_assignment', true)

  test 'Next Student button is active', ->
    buttonDisabled('#next_student', false)

  test 'Next Assignment button is active', ->
    buttonDisabled('#next_assignment', false)

  test 'no student or assignment is loaded', ->
    checkText('.student_selection', 'Select a student to view additional information here.')
    checkText('.assignment_selection', 'Select an assignment to view additional information here.')


  module 'screenreader_gradebook student/assignment navigation: with first item selected',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students.firstObject'))
          @controller.set('selectedAssignment', @controller.get('assignments.firstObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'Previous buttons are disabled', ->
    buttonDisabled('#prev_student', true)
    buttonDisabled('#prev_assignment', true)
    checkText('.student_selection', 'Bob')
    checkText('.assignment_selection', 'Z Eats Soup')

  # compares & checks before/after objects
  test 'clicking Next Student button displays next student', ->
    before = @controller.get('selectedStudent')
    checkSelection(before.id, '#student_select')
    click('#next_student').then =>
      after = @controller.get('selectedStudent')
      checkSelection(after.id, '#student_select')
      notEqual(before.id, after.id)
      next = @controller.get('students').indexOf(before) + 1
      equal(next, @controller.get('students').indexOf(after))

  # compares & checks before/after objects
  test 'clicking Next Assignment button displays next assignment', ->
    before = @controller.get('selectedAssignment')
    checkSelection(before.id, '#assignment_select')
    click('#next_assignment').then =>
      after = @controller.get('selectedAssignment')
      checkSelection(after.id, '#assignment_select')
      notEqual(before, after)
      next = @controller.get('assignments').indexOf(before) + 1
      equal(next, @controller.get('assignments').indexOf(after))

  test 'clicking next then previous will refocus on next student', ->
    click('#next_student').then =>
      click('#prev_student').then =>
        equal($("#next_student")[0],document.activeElement)

  test 'clicking next then previous will refocus on next assignment', ->
    click('#next_assignment').then =>
      click('#prev_assignment').then =>
        equal($("#next_assignment")[0],document.activeElement)

  module 'screenreader_gradebook student/assignment navigation: with second item selected',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students').objectAt(1))
          @controller.set('selectedAssignment', @controller.get('assignments').objectAt(1))
    teardown: ->
      Ember.run App, 'destroy'

  test 'Previous/Next Student buttons are both active', ->
    buttonDisabled('#prev_student', false)
    buttonDisabled('#next_student', false)

  test 'Previous/Next Assignment buttons are both active', ->
    buttonDisabled('#prev_assignment', false)
    buttonDisabled('#next_assignment', false)


  module 'screenreader_gradebook student/assignment navigation: with last item selected',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students.lastObject'))
          @controller.set('selectedAssignment', @controller.get('assignments.lastObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'Previous Student button is active', ->
    buttonDisabled('#prev_student', false)

  test 'Previous Assignment button is active', ->
    buttonDisabled('#prev_assignment', false)

  test 'Next Student button is disabled', ->
    buttonDisabled('#next_student', true)

  test 'Next Assignment button is disabled', ->
    buttonDisabled('#next_assignment', true)

  # compares & checks before/after objects
  test 'clicking Previous Student button displays previous student', ->
    before = @controller.get('selectedStudent')
    checkSelection(before.id, '#student_select')
    click('#prev_student').then =>
      after = @controller.get('selectedStudent')
      checkSelection(after.id, '#student_select')
      notEqual(before.id, after.id)
      previous = @controller.get('students').indexOf(before) - 1
      equal(previous, @controller.get('students').indexOf(after))

  # compares & checks before/after objects
  test 'clicking Previous Assignment button displays previous student', ->
    before = @controller.get('selectedAssignment')
    checkSelection(before.id, '#assignment_select')
    click('#prev_assignment').then =>
      after = @controller.get('selectedAssignment')
      checkSelection(after.id, '#assignment_select')
      notEqual(before.id, after.id)
      previous = @controller.get('assignments').indexOf(before) - 1
      equal(previous, @controller.get('assignments').indexOf(after))

  test 'clicking previous then next will reset the focus for students', ->
    click('#prev_student').then =>
      click('#next_student').then =>
        equal($("#prev_student")[0],document.activeElement)

  test 'clicking previous then next will reset the focus for assignments', ->
    click('#prev_assignment').then =>
      click('#next_assignment').then =>
        equal($("#prev_assignment")[0],document.activeElement)

  module 'screenreader_gradebook assignment navigation: assignment sorting',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
    teardown: ->
      # resetting userSettings to default
      Ember.run =>
        @controller.set('assignmentSort', @controller.get('assignmentSortOptions').findBy('value', 'assignment_group'))
      Ember.run App, 'destroy'

  test 'alphabetical', ->
    before = @controller.get('assignments.firstObject')
    Ember.run =>
      @controller.set('assignmentSort', @controller.get('assignmentSortOptions').findBy('value', 'alpha'))
    buttonDisabled('#next_assignment', false)
    buttonDisabled('#prev_assignment', true)
    first = @controller.get('assignments.firstObject')
    notEqual(before, first)
    click('#next_assignment').then =>
      checkSelection(first.id, '#assignment_select')

  test 'due date', ->
    before = @controller.get('assignments.firstObject')
    Ember.run =>
      @controller.set('assignmentSort', @controller.get('assignmentSortOptions').findBy('value', 'due_date'))
    buttonDisabled('#next_assignment', false)
    buttonDisabled('#prev_assignment', true)
    first = @controller.get('assignments.firstObject')
    notEqual(before, first)
    click('#next_assignment').then =>
      checkSelection(first.id, '#assignment_select')

  test 'changing sorting option with selectedAssignment', ->
    # SORT BY: alphabetical
    Ember.run =>
      @controller.set('assignmentSort', @controller.get('assignmentSortOptions').findBy('value', 'alpha'))

    # check first assignment
    click('#next_assignment').then =>
      first = @controller.get('selectedAssignment')
      checkSelection(first.id, '#assignment_select')
      equal(first.name, "Apples are good")
      second = @controller.get('assignments').objectAt(@controller.get('assignmentIndex') + 1)

      # check Next
      click('#next_assignment').then =>
        checkSelection(second.id, '#assignment_select')
        notEqual(first.id, second.id)
        equal(second.name, "Big Bowl of Nachos")

        # check Previous
        click('#prev_assignment').then =>
          selected = @controller.get('selectedAssignment')
          equal(selected.id, first.id)
          checkSelection(selected.id, '#assignment_select')
          oldIndex = @controller.get('assignmentIndex')

          # SORT BY: due date
          Ember.run =>
            @controller.set('assignmentSort', @controller.get('assignmentSortOptions').findBy('value', 'due_date'))

          # check selectedAssignment identity and index
          equal(selected.id, @controller.get('selectedAssignment.id'))
          notEqual(oldIndex, @controller.get('assignmentIndex'))

          # check Next
          next = @controller.get('assignments').objectAt(@controller.get('assignmentIndex') + 1)
          click('#next_assignment').then =>
            checkSelection(next.id, '#assignment_select')

  module 'screenreader_gradebook student navigation: section selection',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedSection', @controller.get('sections.lastObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'prev/next still work', ->
    buttonDisabled('#prev_student', true)
    buttonDisabled('#next_student', false)

    # first in section
    click('#next_student').then =>
      first = @controller.get('selectedStudent')
      index = @controller.get('studentIndex')
      buttonDisabled('#prev_student', true)
      studentSectionAssertions(first, index, 0)

      # second in section
      click('#next_student').then =>
        second = @controller.get('selectedStudent')
        index = @controller.get('studentIndex')
        buttonDisabled('#prev_student', false)
        studentSectionAssertions(second, index, 1)
        notEqual(first, second)

      click('#prev_student').then =>
        buttonDisabled('#prev_student', true)
        buttonDisabled('#next_student', false)

  test 'resets selectedStudent when student is not in both sections', ->
    click('#next_student').then =>
      firstStudent = @controller.get('selectedStudent')

      Ember.run =>
        @controller.set('selectedSection', @controller.get('sections.firstObject'))
      resetStudent = @controller.get('selectedStudent')
      notEqual(firstStudent, resetStudent)
      equal(resetStudent, null)

      click('#next_student').then =>
        current = @controller.get('selectedStudent')
        notEqual(current, firstStudent)
        notEqual(current, resetStudent)

  test 'maintains selectedStudent when student is in both sections and updates navigation points', ->
    Ember.run =>
      # requires a fixture for a student with enrollment in 2 sections
      # and a previous/next option for all sections
      @controller.set('selectedStudent', @controller.get('students').objectAt(4))

    visit('/').then =>
      buttonDisabled('#prev_student', false)
      buttonDisabled('#next_student', false)

      selected = @controller.get('selectedStudent')
      checkSelectedText(selected.name, '#student_select')
      checkSelectedText(@controller.get('selectedSection.name'), '#section_select')

      # position in selected dropdown
      position = @controller.get('studentsInSelectedSection').indexOf(selected)
      equal(position, 1)
      equal(@controller.get('studentIndex'), position)

      # change section
      Ember.run =>
        @controller.set('selectedSection', @controller.get('sections.firstObject'))
      buttonDisabled('#prev_student', false)
      buttonDisabled('#next_student', false)

      newSelected = @controller.get('selectedStudent')
      checkSelectedText(newSelected.name, '#student_select')
      checkSelectedText(@controller.get('selectedSection.name'), '#section_select')
      equal(selected, newSelected)

      # position in selected dropdown
      position = @controller.get('studentsInSelectedSection').indexOf(selected)
      equal(position, 3)
      equal(@controller.get('studentIndex'), position)


  module 'screenreader_gradebook student/assignment navigation: announcing selection with aria-live',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students.firstObject'))
          @controller.set('selectedAssignment', @controller.get('assignments.firstObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'aria-announcer', ->
    checkText '.aria-announcer', ''

    click('#next_student').then =>
      expected = @controller.get('selectedStudent.name')
      checkText '.aria-announcer', expected


    click('#next_assignment').then =>
      expected = @controller.get('selectedAssignment.name')
      checkText '.aria-announcer', expected

    click('#hide_names_checkbox').then =>
      Ember.run ->
        checkText '.aria-announcer', ''
