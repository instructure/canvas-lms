define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

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


  QUnit.module 'screenreader_gradebook student/assignment navigation: on page load',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
    teardown: ->
      Ember.run App, 'destroy'

  test 'Previous Student button is disabled', ->
    buttonDisabled('.student_navigation .previous_object:first', true)

  test 'Previous Assignment button is disabled', ->
    buttonDisabled('.assignment_navigation .previous_object', true)

  test 'Next Student button is active', ->
    buttonDisabled('.student_navigation .next_object:first', false)

  test 'Next Assignment button is active', ->
    buttonDisabled('.assignment_navigation .next_object', false)

  test 'no student or assignment is loaded', ->
    checkText('.student_selection', 'Select a student to view additional information here.')
    checkText('.assignment_selection', 'Select an assignment to view additional information here.')


  QUnit.module 'screenreader_gradebook student/assignment navigation: with first item selected',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students.firstObject'))
          @controller.set('selectedAssignment', @controller.get('assignments.firstObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'Previous buttons are disabled', ->
    buttonDisabled('.student_navigation .previous_object:first', true)
    buttonDisabled('.assignment_navigation .previous_object', true)
    checkText('.student_selection', 'Bob')
    checkText('.assignment_selection', 'Z Eats Soup')

  # compares & checks before/after objects
  test 'clicking Next Student button displays next student', ->
    before = @controller.get('selectedStudent')
    checkSelection(before.id, '#student_select')
    click('.student_navigation .next_object:first').then =>
      after = @controller.get('selectedStudent')
      checkSelection(after.id, '#student_select')
      notEqual(before.id, after.id)
      next = @controller.get('students').indexOf(before) + 1
      equal(next, @controller.get('students').indexOf(after))

  # compares & checks before/after objects
  test 'clicking Next Assignment button displays next assignment', ->
    before = @controller.get('selectedAssignment')
    checkSelection(before.id, '#assignment_select')
    click('.assignment_navigation .next_object').then =>
      after = @controller.get('selectedAssignment')
      checkSelection(after.id, '#assignment_select')
      notEqual(before, after)
      next = @controller.get('assignments').indexOf(before) + 1
      equal(next, @controller.get('assignments').indexOf(after))

  test 'clicking next then previous will refocus on next student', ->
    click('.student_navigation .next_object:first').then =>
      click('.student_navigation .previous_object:first').then =>
        equal($(".student_navigation .next_object:first")[0],document.activeElement)

  test 'clicking next then previous will refocus on next assignment', ->
    click('.assignment_navigation .next_object').then =>
      click('.assignment_navigation .previous_object').then =>
        equal($(".assignment_navigation .next_object")[0],document.activeElement)

  QUnit.module 'screenreader_gradebook student/assignment navigation: with second item selected',
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
    buttonDisabled('.student_navigation .previous_object:first', false)
    buttonDisabled('.student_navigation .next_object:first', false)

  test 'Previous/Next Assignment buttons are both active', ->
    buttonDisabled('.assignment_navigation .previous_object', false)
    buttonDisabled('.assignment_navigation .next_object', false)


  QUnit.module 'screenreader_gradebook student/assignment navigation: with last item selected',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students.lastObject'))
          @controller.set('selectedAssignment', @controller.get('assignments.lastObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'Previous Student button is active', ->
    buttonDisabled('.student_navigation .previous_object:first', false)

  test 'Previous Assignment button is active', ->
    buttonDisabled('.assignment_navigation .previous_object', false)

  test 'Next Student button is disabled', ->
    buttonDisabled('.student_navigation .next_object:first', true)

  test 'Next Assignment button is disabled', ->
    buttonDisabled('.assignment_navigation .next_object', true)

  # compares & checks before/after objects
  test 'clicking Previous Student button displays previous student', ->
    before = @controller.get('selectedStudent')
    checkSelection(before.id, '#student_select')
    click('.student_navigation .previous_object:first').then =>
      after = @controller.get('selectedStudent')
      checkSelection(after.id, '#student_select')
      notEqual(before.id, after.id)
      previous = @controller.get('students').indexOf(before) - 1
      equal(previous, @controller.get('students').indexOf(after))

  # compares & checks before/after objects
  test 'clicking Previous Assignment button displays previous assignment', ->
    before = @controller.get('selectedAssignment')
    checkSelection(before.id, '#assignment_select')
    click('.assignment_navigation .previous_object').then =>
      after = @controller.get('selectedAssignment')
      checkSelection(after.id, '#assignment_select')
      notEqual(before.id, after.id)
      previous = @controller.get('assignments').indexOf(before) - 1
      equal(previous, @controller.get('assignments').indexOf(after))

  test 'clicking previous then next will reset the focus for students', ->
    click('.student_navigation .previous_object:first').then =>
      click('.student_navigation .next_object:first').then =>
        equal($(".student_navigation .previous_object:first")[0],document.activeElement)

  test 'clicking previous then next will reset the focus for assignments', ->
    click('.assignment_navigation .previous_object').then =>
      click('.assignment_navigation .next_object').then =>
        equal($(".assignment_navigation .previous_object")[0],document.activeElement)

  QUnit.module 'screenreader_gradebook assignment navigation: display update',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students.firstObject'))
          @controller.set('selectedAssignment', @controller.get('assignments.firstObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'screenreader_gradebook assignment selection: grade for field updates', ->
    assignment_name_selector = "label[for='student_and_assignment_grade']"

    selectedAssigName = @controller.get('selectedAssignment.name')
    checkText(assignment_name_selector, "Grade for: #{selectedAssigName}")

    Ember.run =>
      @controller.set('selectedAssignment', @controller.get('assignments').objectAt(2))

    newSelectedAssigName = @controller.get('selectedAssignment.name')
    checkText(assignment_name_selector, "Grade for: #{newSelectedAssigName}")

  QUnit.module 'screenreader_gradebook assignment navigation: assignment sorting',
    setup: ->
      fixtures.create()
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
    buttonDisabled('.assignment_navigation .next_object', false)
    buttonDisabled('.assignment_navigation .previous_object', true)
    first = @controller.get('assignments.firstObject')
    notEqual(before, first)
    click('.assignment_navigation .next_object').then =>
      checkSelection(first.id, '#assignment_select')

  test 'due date', ->
    before = @controller.get('assignments.firstObject')
    Ember.run =>
      @controller.set('assignmentSort', @controller.get('assignmentSortOptions').findBy('value', 'due_date'))
    buttonDisabled('.assignment_navigation .next_object', false)
    buttonDisabled('.assignment_navigation .previous_object', true)
    first = @controller.get('assignments.firstObject')
    notEqual(before, first)
    click('.assignment_navigation .next_object').then =>
      checkSelection(first.id, '#assignment_select')

  test 'changing sorting option with selectedAssignment', ->
    # SORT BY: alphabetical
    Ember.run =>
      @controller.set('assignmentSort', @controller.get('assignmentSortOptions').findBy('value', 'alpha'))

    # check first assignment
    click('.assignment_navigation .next_object').then =>
      first = @controller.get('selectedAssignment')
      checkSelection(first.id, '#assignment_select')
      equal(first.name, "Apples are good")
      second = @controller.get('assignments').objectAt( @controller.get('assignmentIndex') + 1)

      # check Next
      click('.assignment_navigation .next_object').then =>
        checkSelection(second.id, '#assignment_select')
        notEqual(first.id, second.id)
        equal(second.name, "Big Bowl of Nachos")

        # check Previous
        click('.assignment_navigation .previous_object').then =>
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
          selectedIndex = @controller.get('assignmentIndex')
          next = @controller.get('assignments').objectAt(selectedIndex + 1)
          click('.assignment_navigation .next_object').then =>
            checkSelection(next.id, '#assignment_select')

  QUnit.module 'screenreader_gradebook student navigation: section selection',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedSection', @controller.get('sections.lastObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'prev/next still work', ->
    buttonDisabled('.student_navigation .previous_object:first', true)
    buttonDisabled('.student_navigation .next_object:first', false)

    # first in section
    click('.student_navigation .next_object:first').then =>
      first = @controller.get('selectedStudent')
      index = @controller.get('studentIndex')
      buttonDisabled('.student_navigation .previous_object:first', true)
      studentSectionAssertions(first, index, 0)

      # second in section
      click('.student_navigation .next_object:first').then =>
        second = @controller.get('selectedStudent')
        index = @controller.get('studentIndex')
        buttonDisabled('.student_navigation .previous_object:first', false)
        studentSectionAssertions(second, index, 1)
        notEqual(first, second)

      click('.student_navigation .previous_object:first').then =>
        buttonDisabled('.student_navigation .previous_object:first', true)
        buttonDisabled('.student_navigation .next_object:first', false)

  test 'resets selectedStudent when student is not in both sections', ->
    click('.student_navigation .next_object:first').then =>
      firstStudent = @controller.get('selectedStudent')

      Ember.run =>
        @controller.set('selectedSection', @controller.get('sections.firstObject'))
      resetStudent = @controller.get('selectedStudent')
      notEqual(firstStudent, resetStudent)
      equal(resetStudent, null)

      click('.student_navigation .next_object:first').then =>
        current = @controller.get('selectedStudent')
        notEqual(current, firstStudent)
        notEqual(current, resetStudent)

  test 'maintains selectedStudent when student is in both sections and updates navigation points', ->
    Ember.run =>
      # requires a fixture for a student with enrollment in 2 sections
      # and a previous/next option for all sections
      @controller.set('selectedStudent', @controller.get('students').objectAt(4))

    visit('/').then =>
      buttonDisabled('.student_navigation .previous_object:first', false)
      buttonDisabled('.student_navigation .next_object:first', false)

      selected = @controller.get('selectedStudent')
      checkSelectedText(selected.name, '#student_select')
      checkSelectedText(@controller.get('selectedSection.name'), '#section_select')

      # position in selected dropdown
      position = @controller.get('studentsInSelectedSection').indexOf(selected)
      equal(position, 1)
      equal(@controller.get("studentIndex"), position)

      # change section
      Ember.run =>
        @controller.set('selectedSection', @controller.get('sections.firstObject'))
      buttonDisabled('.student_navigation .previous_object:first', false)
      buttonDisabled('.student_navigation .next_object:first', false)

      newSelected = @controller.get('selectedStudent')
      checkSelectedText(newSelected.name, '#student_select')
      checkSelectedText(@controller.get('selectedSection.name'), '#section_select')
      equal(selected, newSelected)

      # position in selected dropdown
      position = @controller.get('studentsInSelectedSection').indexOf(selected)
      equal(position, 3)
      equal(@controller.get("studentIndex"), position)

  QUnit.module 'screenreader_gradebook student/assignment navigation: announcing selection with aria-live',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @controller.set('selectedStudent', @controller.get('students.firstObject'))
          @controller.set('selectedAssignment', @controller.get('assignments.firstObject'))
    teardown: ->
      Ember.run App, 'destroy'

  test 'aria-announcer', ->
    equal Ember.$.trim(find(".aria-announcer").text()), ""

    click('.student_navigation .next_object:first').then =>
      expected = @controller.get('selectedStudent.name')
      equal Ember.$.trim(find(".aria-announcer").text()), expected


    click('.assignment_navigation .next_object').then =>
      expected = @controller.get('selectedAssignment.name')
      equal Ember.$.trim(find(".aria-announcer").text()), expected

    click('#hide_names_checkbox').then =>
      Ember.run ->
        equal Ember.$.trim(find(".aria-announcer").text()), ""
