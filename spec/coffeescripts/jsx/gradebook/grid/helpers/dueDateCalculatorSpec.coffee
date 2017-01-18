define [
  'jsx/gradebook/grid/helpers/dueDateCalculator'
], (DueDateCalculator) ->
  module 'DueDateCalculator'

  test 'returns due_at if no due dates in all_dates', ->
    assignment =
      due_at: 'dueDate'

    calculator = new DueDateCalculator(assignment)
    equal(calculator.dueDate(), 'dueDate')

  test 'returns due_at even if there are entries in all_dates', ->
    assignment =
      due_at: 'dueDate'
      all_dates: [
        'date1'
        'date2'
      ]

    calculator = new DueDateCalculator(assignment)
    equal(calculator.dueDate(), 'dueDate')

  test 'returns first entry of all_dates if no due_at', ->
    date = new Date(1987, 5, 22)

    assignment =
      all_dates: [
        {
          due_at: date
        }
      ]

    calculator = new DueDateCalculator(assignment)
    equal(calculator.dueDate(), date.toISOString())
