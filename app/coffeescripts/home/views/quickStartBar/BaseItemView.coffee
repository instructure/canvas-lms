define [
  'Backbone'
  'underscore'
  'jquery'
  'compiled/widget/ContextSearch'
  'jquery.instructure_date_and_time'
  'jquery.disableWhileLoading'
], ({View}, _, $, Assignment, template, ContextSearch) ->

  class BaseItemView extends View

    contextSearchOptions:
      fakeInputWidth: '100%'
      contexts: ENV.CONTEXTS
      placeholder: "Type the name of a class to assign this too..."
      selector:
        baseData:
          type: 'course'
        preparer: (postData, data, parent) ->
          for row in data
            row.noExpand = true
        browser: false

    events:
      'submit form': 'onFormSubmit'

    render: ->
      @$el.html @template()
      super

    filter: ->
      @$('.dateField').datetime_field()
      @$('.contextSearch').contextSearch @contextSearchOptions

    onFormSubmit: (event) ->
      event.preventDefault()
      $form = $ event.target
      json = $(event.target).toJSON()
      dfd = @save json
      @$('form').disableWhileLoading dfd
      dfd.done => @trigger 'save'
      dfd.fail => @trigger 'saveFail'

    ##
    # sub classes should implement their own save method
    # that returns a deferred object
    save: -> @model.save()

