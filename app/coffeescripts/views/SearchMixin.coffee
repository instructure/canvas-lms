define [
  'i18n!course_users'
  'jquery'
  'compiled/util/mixin'
  'compiled/views/ValidatedMixin'
  'jquery.instructure_forms'
  'vendor/jquery.placeholder'
], (I18n, $, mixin, ValidatedMixin) ->

  mixin {}, ValidatedMixin,

    defaults:

      ##
      # Name of the parameter to add to the query string

      paramName: 'search_term'

    initialize: ->
      @collection = @collectionView.collection

    attach: ->
      @inputFilterView.on 'input', @fetchResults, this

    afterRender: ->
      @$el.placeholder()

    fetchResults: (query) ->
      if query is ''
        @collection.deleteParam @options.paramName
      # this might not be general :\
      else if query.length < 3
        return
      else
        @collection.setParam @options.paramName, query
      @lastRequest?.abort()
      @lastRequest = @collection.fetch().fail => @onFail()

    onFail: (xhr) ->
      return if xhr.statusText is 'abort'
      parsed = $.parseJSON xhr.responseText
      message = if parsed?.errors?[0].message is "3 or more characters is required"
        I18n.t('greater_than_three', 'Please enter a search term with three or more characters')
      else
        I18n.t('unknown_error', 'Something went wrong with your search, please try again.')
      @showErrors inputFilter: [{message}]

