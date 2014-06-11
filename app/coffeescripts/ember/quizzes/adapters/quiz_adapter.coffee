define [
  'ember'
  'ember-data'
  'underscore'
  './jsonapi_adapter'
  '../shared/ic-ajax-jsonapi'
  'ic-ajax'
], ({RSVP}, DS, _, JSONAPIAdapter, ajax) ->

  urlTemplate = (template, page) ->
    template.replace /\{page\}/, page

  QuizAdapter = JSONAPIAdapter.extend

    loadRemainingPages: (store) ->
      new Ember.RSVP.Promise (resolve, reject) ->
        pagination = store.metadataFor('quiz').pagination
        {page, page_count, template} = pagination
        if page is page_count
          resolve()
          return
        urls = (urlTemplate(template, page) for page in [(page+1)..page_count])
        RSVP.map(urls, ajax).then (pagesOfQuizzes) ->
          store.pushPayload('quiz', {quizzes: pagesOfQuizzes[0].quizzes})
          resolve()
