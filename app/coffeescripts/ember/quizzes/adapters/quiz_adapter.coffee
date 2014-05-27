define [
  'ember'
  '../shared/ic-ajax-jsonapi'
  'ember-data'
  'underscore' # which is really lodash trolololo
  './jsonapi_adapter'
], ({RSVP}, ajax, DS, _, JSONAPIAdapter) ->

  urlTemplate = (template, page) ->
    template.replace /\{page\}/, page

  QuizAdapter = JSONAPIAdapter.extend

    ajax: (url, type, options) ->
      options = @ajaxOptions url, type, options
      ajax(options)

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

