define [
  'compiled/models/Course'
  'compiled/views/conversations/CourseSelectionView'
  'compiled/collections/CourseCollection'
  'compiled/collections/FavoriteCourseCollection'
  'compiled/collections/GroupCollection'
  'helpers/fakeENV'
], (Course, CourseSelectionView, CourseCollection, FavoriteCourseCollection, GroupCollection, fakeENV) ->
  courseSelectionView = () ->
    courses =
      favorites: new FavoriteCourseCollection()
      all: new CourseCollection()
      groups: new GroupCollection()

    app = new CourseSelectionView
      courses: courses

  QUnit.module 'CourseSelectionView',
    setup: ->
      @now = $.fudgeDateForProfileTimezone(new Date)
      fakeENV.setup(CONVERSATIONS: {CAN_MESSAGE_ACCOUNT_CONTEXT: false})
    teardown: ->
      fakeENV.teardown()

  test 'does not label an un-favorited course as concluded', ->
    course = new Course
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'labels a concluded course as concluded', ->
    course = new Course
      workflow_state: 'completed'
    view = courseSelectionView()
    ok view.is_complete(course, @now)

  test 'does not label a course with a term with no end_at as concluded', ->
    course = new Course
      term: "foo"
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'labels as completed a course with a term with an end_at date in the past', ->
    course = new Course
      term:
        end_at: Date.today().last().monday().toISOString()
    view = courseSelectionView()
    ok view.is_complete(course, @now)

  test 'does not label as completed a course with a term overriding end_at in the future', ->
    course = new Course
      end_at: Date.today().next().monday().toISOString()
      restrict_enrollments_to_course_dates: true
      term:
        end_at: Date.today().last().monday().toISOString()
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'does not label as completed a course with a term with an end_at date in the future', ->
    course = new Course
      term:
        end_at: Date.today().next().monday().toISOString()
    view = courseSelectionView()
    ok !view.is_complete(course, @now)

  test 'does not label as completed a course with a term with an end_at that is null', ->
    course = new Course
      term: {end_at: null}
    view = courseSelectionView()
    ok !view.is_complete(course, @now)
