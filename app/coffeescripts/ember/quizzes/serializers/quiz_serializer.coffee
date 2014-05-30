define [ 'ember-data', 'underscore' ], (DS, _) ->
  DS.ActiveModelSerializer.extend
    normalizePayload: (type, hash, prop) ->
      # how can we add query parameters to model.find('quiz_statistics') ??
      if hash.quizzes
        _(hash.quizzes).each (quiz) ->
          if quiz.links
            if quiz.links.quiz_statistics
              quiz.links.quiz_statistics += '?include=quiz_questions'
            if quiz.links.quiz_reports
              quiz.links.quiz_reports += '?includes_all_versions=true'
      hash