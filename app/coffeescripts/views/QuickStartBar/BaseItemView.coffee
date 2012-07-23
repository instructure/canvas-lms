define [
  'Backbone'
  'underscore'
  'jquery'
  'compiled/widget/ContextSearch'
  'jquery.instructure_date_and_time'
  'jquery.disableWhileLoading'
], ({View}, _, $, ContextSearch) ->

  ##
  # Base class for all quickstart bar form views.
  # Emits 'save' and 'saveFail' events when the underlying model is saved.
  class BaseItemView extends View

    ##
    # The form submit event is handled in this base class.
    # Remember when extending with coffeescript the `events` will get
    # overwritten, so you need to do something like this to not blow
    # this event away:
    #
    #    class Sub extends BaseItemView
    #      events: _.extend
    #        'click .something': 'someHandler'
    #      , BaseItemView::events
    events:
      'submit form': 'onFormSubmit'

    ##
    # Sub-classes should define a template function that returns
    # a string. Typically this will be a pre-compiled handlebars template.
    template: -> ''

    ##
    # ContextSearch has a lengthy api, each sub-class should define
    # the contextSearchOptions in its entirety, and it will be automatically
    # created
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

    ##
    # Renders the template and sets the @$el html
    render: ->
      @$el.html @template()
      super

    ##
    # Creates date pickers and context search instances after render
    filter: ->
      @$('.dateField').datetime_field()
      @contextSearch = new ContextSearch @$('.contextSearch'), @contextSearchOptions

    teardown: ->
      @contextSearch.teardown()

    ##
    # Form submit handler, converts the form into a JavaScript object and calls
    # the `@save` method. Also handles some shared display concerns.
    onFormSubmit: (event) ->
      event.preventDefault()
      $form = $ event.target
      json = $(event.target).toJSON()
      dfd = @save json
      @$('form').disableWhileLoading dfd
      dfd.done => @trigger 'save'
      dfd.fail => @trigger 'saveFail'

    ##
    # Sub-classes should implement their own save method
    # that returns a deferred object, used in `@onFormSubmit`
    save: -> @model.save()

    @title: (scope, text) ->
      title = ""
      I18n.scoped('dashboard', (i) -> title = i.t scope, text)
      title
