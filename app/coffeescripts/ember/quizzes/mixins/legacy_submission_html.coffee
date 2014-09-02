define [
  'ember'
  '../shared/ic-ajax-jsonapi'
], (Ember, ajax) ->
  {computed} = Ember

  PromiseObject = Ember.ObjectProxy.extend(Ember.PromiseProxyMixin)

  # This mixin adds support for loading up legacy html for submissions/versions
  Ember.Mixin.create

    legacyQuizSubmissionVersionsReady: computed.and('quizSubmissionVersionsHtml', 'didLoadQuizSubmissionVersionsHtml')
    legacyQuizSubmissionReady: computed.and('quizSubmissionHtml', 'didLoadQuizSubmissionHtml')

    # temporary until we ship the show page with quiz submission info in ember
    quizSubmissionHtml: (->
      promise = ajax(
        url: @get 'quizSubmissionHtmlUrl'
        dataType: 'html'
        contentType: 'text/html'
        headers:
          Accept: 'text/html'
        data:
          preview: @get('isPreview')

      ).then (html) =>
        @set 'didLoadQuizSubmissionHtml', true
        { html: html }
      PromiseObject.create promise: promise
    ).property('quizSubmissionHtmlUrl')

    # temporary until we ship the quiz submission versions in ember
    quizSubmissionVersionsHtml: (->
      return unless @get 'quizSubmissionVersionsHtmlUrl'
      promise = ajax(
        url: @get 'quizSubmissionVersionsHtmlUrl'
        dataType: 'html'
        contentType: 'text/html'
        headers:
          Accept: 'text/html'
      ).then (html) =>
        @set 'didLoadQuizSubmissionVersionsHtml', true
        { html: html }
      PromiseObject.create promise: promise
    ).property('quizSubmissionVersionsHtmlUrl')
