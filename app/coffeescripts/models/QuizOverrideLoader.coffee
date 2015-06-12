define [
  'jquery'
  'underscore'
  'compiled/collections/PaginatedCollection'
], ($, _, PaginatedCollection) ->

  QuizOverrideLoader = {
    _setQuizOverrides: (pool, quizId, overrides) ->
      quiz = pool.filter((quiz) -> quiz.get('id') == quizId).pop()

      unless quiz
        console.warn("""
          Unable to set assignment overrides;
          quiz with id %s could not be found
        """, ''+quizId)

        return false

      quiz.set({
        base: @_chooseLatest(overrides.due_dates, "base"),
        due_at: @_chooseLatest(overrides.due_dates, "due_at"),
        lock_at: @_chooseLatest(overrides.due_dates, "lock_at"),
        unlock_at: @_chooseEarliest(overrides.due_dates, "unlock_at"),
        all_dates: overrides.all_dates,
      }, { silent: true })
      quiz.initAllDates()
      quiz.set('loadingOverrides', false)

    _chooseLatest: (dates, type) ->
      sortedDates = @_sortedDatesOfType(dates, type)
      if _.any(sortedDates)
        _.last(sortedDates)

    _chooseEarliest: (dates, type) ->
      sortedDates = @_sortedDatesOfType(dates, type)
      if _.any(sortedDates)
        _.first(sortedDates)

    _sortedDatesOfType: (dates, type) ->
      _.chain(dates)
        .map((d) -> d[type])
        .compact()
        .sortBy((date) -> new Date(date).getTime())
        .value()

    # Load assignment overridden due/unlock/available dates for a bunch of quizzes.
    #
    # The property "loadingOverrides" will be toggled to true on every quiz model
    # for which overrides will be loaded. The property will be set to false as
    # soon as the overrides for that particular model have been loaded. You can
    # hook into the "change" event for that property to show loading status.
    #
    # @param {Backbone.Model[]} quizModels
    #   What you'd usually find in a Backbone collection's "models" property;
    #   objects must respond to #get().
    #
    # @param {String} fetchEndpoint
    #   API endpoint for retrieving quiz assignment overrides. Usually this is
    #   exposed in ENV.URLS.assignment_overrides. Pagination supported.
    #
    # @param {Number} [perPage=20]
    #   Number of overrides to request per API call.
    #
    # @return {$.Deferred}
    #   A promise that resolves when all overrides for all quizzes have been
    #   loaded.
    loadQuizOverrides: (quizModels, fetchEndpoint, perPage = 20) ->
      overrideCollection = new PaginatedCollection()
      overrideCollection._defaultUrl = -> fetchEndpoint
      overrideCollection.parse = (resp) ->
        resp.quiz_assignment_overrides

      process = @_setQuizOverrides.bind(@, quizModels)

      fetchAll = (page = undefined, service = $.Deferred()) ->
        overrideCollection.fetch({
          page: page,
          reset: true,
          data: {
            per_page: perPage
          }
        }).then (resp) ->
          overrideCollection.forEach (override) ->
            process(override.get('quiz_id'), {
              due_dates: override.get('due_dates'),
              all_dates: override.get('all_dates')
            })

          if overrideCollection.canFetch('next')
            fetchAll('next', service)
          else
            service.resolve()

        return service

      # mark all quizzes as loading overrides so the views can show loading status
      quizModels.forEach (quiz) ->
        quiz.set('loadingOverrides', true)

      fetchAll().then ->
        overrideCollection.reset([], { silent: true })
        overrideCollection = null
  }
