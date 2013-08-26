define [
  'jquery'
  'Backbone'
  'compiled/models/Assignment'
  'compiled/collections/AssignmentOverrideCollection'
  'str/pluralize'
  'i18n!quizzes'
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers' # $.underscore
], ($, Backbone, Assignment, AssignmentOverrideCollection, pluralize, I18n) ->

  class Quiz extends Backbone.Model
    resourceName: 'quizzes'

    defaults:
      due_at: null
      unlock_at: null
      lock_at: null
      publishable: true
      points_possible: null

    initialize: (attributes, options = {}) ->
      super
      @initAssignment()
      @initAssignmentOverrides()
      @initUrls()
      @initTitleLabel()
      @initPublishable()
      @initQuestionsCount()
      @initPointsCount()

    # initialize attributes
    initAssignment: ->
      if @attributes.assignment
        @set 'assignment', new Assignment(@attributes.assignment)

    initAssignmentOverrides: ->
      if @attributes.assignment_overrides
        overrides = new AssignmentOverrideCollection(@attributes.assignment_overrides)
        @set 'assignment_overrides', overrides, silent: true

    initUrls: ->
      if @get 'html_url'
        @set 'base_url', @get('html_url').replace(/quizzes\/\d+/, "quizzes")

        @set 'url',           "#{@get 'base_url'}/#{@get 'id'}"
        @set 'edit_url',      "#{@get 'base_url'}/#{@get 'id'}/edit"
        @set 'publish_url',   "#{@get 'base_url'}/publish"
        @set 'unpublish_url', "#{@get 'base_url'}/unpublish"

    initTitleLabel: ->
      @set 'title_label', @get('title') or @get('readable_type')

    initPublishable: ->
      @set('publishable', false) if @get('can_unpublish') == false and @get('published')

    initQuestionsCount: ->
      cnt = @get 'question_count'
      @set 'question_count_label', I18n.t('question_count', 'Question', count: cnt)

    initPointsCount: ->
      pts = @get 'points_possible'
      text = ''
      text = I18n.t('assignment_points_possible', 'pt', count: pts) if pts isnt null
      @set 'possible_points_label', text

    # publishing

    publish: =>
      if @get 'publishable'
        @set 'published', true
        $.ajaxJSON(@get('publish_url'), 'POST', 'quizzes': [@get 'id'])

    unpublish: =>
      @set 'published', false
      $.ajaxJSON(@get('unpublish_url'), 'POST', 'quizzes': [@get 'id'])

    disabledMessage: ->
      I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")
