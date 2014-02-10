define [], () ->

  (models) ->
    class QuizSorter
      quizSort: (x,y) ->
        if x.due_at == y.due_at
          return 0
        if x.due_at < y.due_at then -1 else 1

      sortQuizzes: (quizModels) ->
        @sorted = quizModels.copy().sort(@quizSort)
        @nulls = []
        @overrides = []
        @sorted.forEach (item) =>
          if item.due_at == null
            if item.all_dates && item.all_dates.length > 1
              @overrides.push item
            else
              @nulls.push item
        @shuffleItems()
        @sorted

      shuffleItems: ->
        for oItem in @overrides
          @moveToBack(oItem)
        for nullItem in @nulls
          @moveToBack(nullItem)

      moveToBack: (item) ->
        @sorted.removeObject item
        @sorted.addObject item

    new QuizSorter().sortQuizzes(models)
