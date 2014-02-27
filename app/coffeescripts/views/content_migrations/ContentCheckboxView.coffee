define [
  'jquery'
  'Backbone'
  'jst/content_migrations/ContentCheckbox'
  'jst/content_migrations/ContentCheckboxCollection'
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/views/CollectionView'
  'compiled/str/TextHelper'
], ($, Backbone, template, checkboxCollectionTemplate, CheckboxCollection, CollectionView, TextHelper) ->
  class ContentCheckboxView extends Backbone.View
    template: template
    tagName: 'li'
    attributes: -> 
      attr = {}
      attr.role = "treeitem"

      if @model.collection?.isTopLevel
        attr.class = "top-level-treeitem"
      else if !(@hasSubItems || @hasSubItemsUrl)
        attr.class = "small-spacing"

      attr

    els: 
      '[data-content=sublevelCheckboxes]' : '$sublevelCheckboxes'

    # Bind a change event only to top level checkboxes that are 
    # initially loaded.

    initialize: -> 
      super
      @hasSubItemsUrl = !!@model.get('sub_items_url')
      @hasSubItems = !!@model.get('sub_items')
      @linkedTarget = @model.collection?.linkedTarget

      if @hasSubItemsUrl || @hasSubItems
        @$el.on "fetchCheckboxes", "#carrot-#{@cid}", @toplevelCarrotEvents

      if @model.get('linked_resource')
        @$el.on "click", "#checkbox-#{@cid}", @syncWithLinkedResource

    toJSON: -> 
      json = super
      json.hasSubCheckboxes = @hasSubItems || @hasSubItemsUrl
      json.isTopLevel = @model.collection?.isTopLevel
      json.iconClass = @getIconClass()
      json.type = @model.get('type')
      json.count = @model.get('count')
      linkedItem = @model.get('linked_resource')

      if linkedItem && linkedItem.message
        json.linkedMessage = linkedItem.message

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
      assignment_groups:            "icon-folder"
      folders:                      "icon-folder"
    
    # This retrieves the iconClass out of the iconClasses object map
    # @api private

    getIconClass: -> @iconClasses[@model.get('type')]

    # If this checkbox model has sublevel checkboxes, create a new collection view
    # and render the sub-level checkboxes in the collection view. 
    # @api custom backbone override

    afterRender: ->
      if @hasSubItems
        @sublevelCheckboxes = new CheckboxCollection @model.get('sub_items')
        @sublevelCheckboxes.linkedTarget = @linkedTarget if @linkedTarget
        @renderSublevelCheckboxes()

    # Determins if we should hide the sublevel checkboxes or 
    # fetch new ones based on clicking the carrot next to it.
    # @returns undefined
    # @api private

    toplevelCarrotEvents: (event) =>
      return unless @hasSubItemsUrl
      event.preventDefault()

      $target = $(event.currentTarget)

      unless @sublevelCheckboxes
          @linkedTarget = $target.data('linkedTarget')

          @fetchSublevelCheckboxes()
          @renderSublevelCheckboxes()

    # Attempt to fetch sublevel in a new checkbox collection. Cache
    # the collection so it doesn't call the server twice.
    # @api private

    fetchSublevelCheckboxes: -> 
      @sublevelCheckboxes = new CheckboxCollection
      @sublevelCheckboxes.url = @model.get('sub_items_url')
      @sublevelCheckboxes.linkedTarget = @linkedTarget if @linkedTarget

      dfd = @sublevelCheckboxes.fetch()
      dfd.done => 
        @$el.find("#carrot-#{@cid}").trigger 'doneFetchingCheckboxes', @$el.find("#checkbox-#{@cid}")
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

    # Items such as Quizzes and Discussions can be duplicated as an item in an Assignment. Since
    # it wouldn't make sense to just check one of those items we ensure that they are synced together.
    # If There are duplicate times there will be a 'linked_resource' object that has a migration_id and
    # type assoicated with it. We are building our own custom 'property' based on these two attributes
    # so we can ensure they are synced. Whenever we change a checkbox we ensure that a change event
    # is triggered so indeterminate states of high level checkboxes can be calculated.
    # returns nada

    syncWithLinkedResource: =>
      linkedItem = @model.get('linked_resource')
      checked = @$el.find("#checkbox-#{@cid}").is(':checked')

      linkedProperty = "copy[#{linkedItem.type}][id_#{linkedItem.migration_id}]"

      $collection_box = $("[name=\"copy[all_#{linkedItem.type}]\"]")
      if !checked && $collection_box.is(':checked')
        $collection_box.data('linkedTarget', linkedProperty)
                       .prop
                         'indeterminate': false, 'checked': false
                       .trigger('change')

      if $linked_el = $("[name=\"#{linkedProperty}\"]")
        $linked_el.prop
                    'indeterminate': false
                    'checked': checked
                 .trigger('change')
