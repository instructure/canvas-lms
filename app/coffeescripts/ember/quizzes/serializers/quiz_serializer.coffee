define [
  'ember-data'
  'underscore'
], (DS, _) ->

  mungeOverrides = (payload) ->
    {quizzes} = payload
    overrides = (quizzes || []).reduce (memo, quiz) ->
      dates = (quiz.all_dates || []).filter (date) -> !!date.id
      delete quiz.all_dates
      quiz.links ||= {}
      quiz.assignment_override_ids = dates.mapBy 'id'
      memo.concat dates
    , []

    payload.assignment_overrides = overrides

  QuizSerializer = DS.ActiveModelSerializer.extend

    extractArray: (store, primaryType, payload) ->
      mungeOverrides payload
      this._super store, primaryType, payload

    extractSingle: (store, type, payload, id, requestType) ->
      mungeOverrides payload
      this._super store, type, payload, id, requestType

    normalizePayload: (type, hash, prop) ->
      if hash.quizzes
        _(hash.quizzes).each (quiz) ->
          if quiz.links
            if quiz.links.quiz_statistics
              quiz.links.quiz_statistics += '?include=quiz_questions'
            if quiz.links.quiz_reports
              quiz.links.quiz_reports += '?includes_all_versions=true'
            if submitals = quiz.links.submitted_students || quiz.links.unsubmitted_students
              quiz.links.users = submitals.replace(/\?submitted=(true|false)/, '')
              quiz.links.users += '?include[]=quiz_submissions'
              quiz.links.quiz_submissions = quiz.links.users
      hash
