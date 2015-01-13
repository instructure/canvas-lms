define [
  'Backbone'
  'jquery'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/accounts/admin_tools/DateRangeSearchView'
  'compiled/views/accounts/admin_tools/AutocompleteView'
  'compiled/views/ValidatedMixin'
  'compiled/views/accounts/admin_tools/CourseLoggingItemView'
  'compiled/collections/CourseLoggingCollection'
  'compiled/collections/CourseCollection'
  'jst/accounts/admin_tools/courseLoggingContent'
  'jst/accounts/admin_tools/courseLoggingResults'
  'jst/accounts/admin_tools/courseLoggingDetails'
  'jqueryui/dialog'
], (
  Backbone,
  $,
  PaginatedCollectionView,
  DateRangeSearchView,
  AutocompleteView,
  ValidatedMixin,
  CourseLoggingItemView,
  CourseLoggingCollection,
  CourseCollection,
  template,
  courseLoggingResultsTemplate,
  detailsTemplate
) ->
  class CourseLoggingContentView extends Backbone.View
    @mixin ValidatedMixin

    @child 'resultsView', '#courseLoggingSearchResults'
    @child 'dateRangeSearch', '#courseDateRangeSearch'
    @child 'courseSearch', '#courseCourseSearch'
 
    fieldSelectors:
      'course_id': "#course_id-autocompleteField"

    els:
      '#courseLoggingForm': '$form'

    template: template
    detailsTemplate: detailsTemplate

    constructor: (@options) ->
      @collection = new CourseLoggingCollection
      super
      @dateRangeSearch = new DateRangeSearchView
        name: "courseLogging"
      @courseSearch = new AutocompleteView
        collection: new Backbone.Collection null, resourceName: 'courses'
        labelProperty: $.proxy(@autoCompleteItemLabel, @)
        fieldName: 'course_id'
        placeholder: 'Course ID'
        sourceParameters:
          "state[]": "all"
      @resultsView = new PaginatedCollectionView
        template: courseLoggingResultsTemplate
        itemView: CourseLoggingItemView
        collection: @collection

    events:
      'submit #courseLoggingForm': 'onSubmit'
      'click #courseLoggingSearchResults .courseLoggingDetails > a': 'showDetails'

    onSubmit: (event) ->
      event.preventDefault()
      json = @$form.toJSON()
      if @validate(json)
        @updateCollection(json)

    showDetails: (event) ->
      event.preventDefault()
      $target = $(event.target)
      id = $target.data("id")

      model = @collection.get(id)
      unless model?
        console.warn("Could not find model for event #{id}.")
        return

      type = model.get("event_type")
      unless type?
        console.warn("Could not find type for event #{id}.")
        return

      @dialog = $('<div class="use-css-transitions-for-show-hide" style="padding:0;"/>')
      @dialog.html(@detailsTemplate(model.present()))
      config =
        title: "Event Details"
        width: 600
        resizable: true
      @dialog.dialog(config)

    updateCollection: (json) ->
      # Update the params (which fetches the collection)
      json ||= @$form.toJSON()

      params =
        id: null
        type: null
        start_time: ''
        end_time: ''

      params.start_time = json.start_time if json.start_time
      params.end_time = json.end_time if json.end_time

      params.id = json.course_id if json.course_id

      @collection.setParams params

    validate: (json) ->
      json ||= @$form.toJSON()
      delete json.course_submit
      errors = @dateRangeSearch.validate(json) || {}

      json.course_id ||= @$el.find("#course_id-autocompleteField").val()
      if !json.course_id
        errors['course_submit'] = [{
          type: 'required'
          message: 'A valid Course is required to search events.'
        }]

      @showErrors errors
      return $.isEmptyObject(errors)

    attach: ->
      @collection.on 'setParams', @fetch

    fetch: =>
      @collection.fetch(error: @onFail)

    onFail: (collection, xhr) =>
      # Received a 404, empty the collection and don't let the paginated
      # view try to fetch more.
      @collection.reset()
      @resultsView.detachScroll()
      @resultsView.$el.find(".paginatedLoadingIndicator").fadeOut()

      if xhr?.status? && xhr.status == 404
        errors = {}
        errors['course_id'] = [{
          type: 'required'
          message: 'A course with that ID could not be found for this account.'
        }]
        @showErrors errors unless $.isEmptyObject(errors)

    autoCompleteItemLabel: (model) ->
      name = model.get("name")
      code = model.get("course_code")
      "#{model.id} - #{name} - #{code}"
