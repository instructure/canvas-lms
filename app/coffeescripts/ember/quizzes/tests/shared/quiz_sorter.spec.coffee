define [
  '../../shared/quiz_sorter',
  '../date_string_offset',
  'ember'
], (quizSorter, dateString, Ember) ->

  module 'quiz_sorter',
    setup: ->
      @quizzes = Ember.A [
        {due_at: null, title: 'null due_at no override' },
        {due_at: null, title: 'single_override', all_dates: [{}] },
        {due_at: null, title: 'multi_overrides', all_dates: [{},{}] },
        {due_at: dateString(3), title: '3 days from now' },
        {due_at: dateString(2), title: '2 days from now' },
        {due_at: dateString(0), title: 'today' },
        {due_at: dateString(-1), title: '1 day ago' }
      ]

  test 'sorts due_at first', ->
    sortedQuizzes = quizSorter(@quizzes)
    sortedQuizzes.forEach (item, index, ar) =>
      return if index == 0
      if item.due_at != null
        ok( ar[index - 1].due_at < item.due_at, 'ascending order' )

  test 'puts nulls with multiple assignment overrides next', ->
    sortedQuizzes = quizSorter(@quizzes)
    title = sortedQuizzes[sortedQuizzes.length - 3].title
    equal(title, 'multi_overrides', 'multiple overriddes preceed nulls')

  test 'puts nulls with only default overrides at end', ->
    expect(2)
    sortedQuizzes = quizSorter(@quizzes)
    title = sortedQuizzes[sortedQuizzes.length - 1].title
    equal(title, 'single_override', 'nulls maintain order in back of sort')
    title = sortedQuizzes[sortedQuizzes.length - 2].title
    equal(title, 'null due_at no override', 'nulls maintain order in back of sort')

