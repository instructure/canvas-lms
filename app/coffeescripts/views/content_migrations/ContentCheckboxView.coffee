define [
  'Backbone'
  'jst/content_migrations/ContentCheckbox'
  'jst/content_migrations/ContentCheckboxCollection'
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/views/CollectionView'
  'compiled/str/TextHelper'
], (Backbone, template, checkboxCollectionTemplate, CheckboxCollection, CollectionView, TextHelper) ->
  class ContentCheckboxView extends Backbone.View
    template: template

    els: 
      '[data-content=sublevelCheckboxes]' : '$sublevelCheckboxes'
      '.showHide'                         : '$showHide'

    # Bind a change event only to top level checkboxes that are 
    # initially loaded.

    initialize: -> 
      super
      @hasSubItemsUrl = !!@model.get('sub_items_url')
      @hasSubItems = !!@model.get('sub_items')

      @$el.on  "click", "#selectAll-#{@cid}", @checkAllChildren
      @$el.on  "click", "#selectNone-#{@cid}", @uncheckAllChildren

      if @hasSubItemsUrl
        @$el.on "change", "#checkbox-#{@cid}", @toplevelCheckboxEvents

    toJSON: -> 
      json = super
      json.hasSubCheckboxes = @hasSubItems || @hasSubItemsUrl
      json.onlyLabel = @hasSubItems and !@hasSubItemsUrl
      json.checked = @model.collection?.isTopLevel
      json.iconClass = @getIconClass()
      json.count = @model.get('count')
      json.showHide = @model.get('count') || (@hasSubItems and @model.get('sub_items').length > 2)
      json

    # This is a map for icon classes depending on the type of checkbox that is being
    # rendered

    iconClasses:
      course_settings:              "icon-settings"
      syllabus_body:                "icon-syllabus"
      context_modules:              "icon-module"
      assignments:                  "icon-assignment"
      quizzes:                      "icon-quiz"
      assessment_question_banks:    "icon-collection"
      discussion_topics:            "icon-discussion"
      wiki_pages:                   "icon-note-light"
      context_external_tools:       "icon-lti"
      announcements:                "icon-announcement"
      calendar_events:              "icon-calendar-days"
      rubrics:                      "icon-rubric"
      groups:                       "icon-group"
      learning_outcomes:            "icon-standards"
      attachments:                  "icon-document"
      assignment_groups:            "icon-gradebook"
      folders:                      "icon-folder"

    
    # This retreaves the iconClass out of the iconClasses object map
    # @api private

    getIconClass: -> @iconClasses[@model.get('type')]

    # If this checkbox model has sublevel checkboxes, create a new collection view
    # and render the sub-level checkboxes in the collection view. 
    # @api custom backbone override

    afterRender: -> 
      if @hasSubItems
        @sublevelCheckboxes = new CheckboxCollection @model.get('sub_items')
        @renderSublevelCheckboxes()

    # Check/Uncheck all children checkboxes. Slice(1) ensures that we do not
    # uncheck/check the toplevel checkbox. Instead we leave that for the user
    # to do.
    # @api private

    checkAllChildren: (event) => 
      event.preventDefault()
      if @model.collection?.isTopLevel
        @$el.find('[type=checkbox]').slice(1).prop('checked', true)
      else
        @$el.find('[type=checkbox]').prop('checked', true)

    uncheckAllChildren: (event) => 
      event.preventDefault()
      if @model.collection?.isTopLevel
        @$el.find('[type=checkbox]').slice(1).prop('checked', false)
      else
        @$el.find('[type=checkbox]').prop('checked', false)

    # Determins if we should hide the sublevel checkboxes or 
    # fetch new ones. 
    # @returns undefined
    # @api private

    toplevelCheckboxEvents: (event) => 
      return unless @hasSubItemsUrl

      if $(event.target).is(':checked')
        @$sublevelCheckboxes.hide()
        @$showHide.hide()
      else
        @$sublevelCheckboxes.show()
        @$showHide.show()

        unless @sublevelCheckboxes
          @fetchSublevelCheckboxes()
          @renderSublevelCheckboxes()
    
    # Attempt to fetch sublevel in a new checkbox collection. Cache
    # the collection so it doesn't call the server twice.
    # @api private

    fetchSublevelCheckboxes: -> 
      @sublevelCheckboxes = new CheckboxCollection
      @sublevelCheckboxes.url = @model.get('sub_items_url')

      dfd = @sublevelCheckboxes.fetch()
      @$el.disableWhileLoading dfd
    
    # Render all sublevel checkboxes in a collection view. The template
    # should take care of rendering any "sublevel" checkboxes that may
    # be on each of these models. 
    # @api private

    renderSublevelCheckboxes: -> 
      checkboxCollectionView = new CollectionView
                                 collection: @sublevelCheckboxes
                                 itemView: ContentCheckboxView
                                 el: @$sublevelCheckboxes
                                 template: checkboxCollectionTemplate

      checkboxCollectionView.render()
