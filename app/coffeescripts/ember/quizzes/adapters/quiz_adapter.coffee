define [
  'ember'
  'ember-data'
  'underscore' # which is really lodash trolololo
  './jsonapi_adapter'
  '../shared/ic-ajax-jsonapi'
  'ic-ajax'
], ({RSVP}, DS, _, JSONAPIAdapter, ajax) ->

  urlTemplate = (template, page) ->
    template.replace /\{page\}/, page

  QuizAdapter = JSONAPIAdapter.extend

    findAll: (type, array) ->
      firstPage = @_super(type, array)

      firstPage.then (json) ->
        json = _.cloneDeep(json)
        {pagination} = json.meta
        {page, page_count, template} = pagination
        return json if page is page_count
        urls = (urlTemplate(template, page) for page in [(page+1)..page_count])
        RSVP.map(urls, ajax).then (pagesOfQuizzes) ->
          pagesOfQuizzes.push json
          pagesOfQuizzes = _.flatten pagesOfQuizzes.mapBy('quizzes')
          json.quizzes = pagesOfQuizzes
          json.meta.page = page_count
          json

