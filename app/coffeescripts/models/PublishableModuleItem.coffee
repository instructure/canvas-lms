define [
  'compiled/backbone-ext/DefaultUrlMixin'
  'Backbone'
  'i18n!publishableModuleItem'
], (DefaultUrlMixin, {Model}, I18n) ->


  # A slightly terrible class that branches the urls and json data for the
  # different module types
  class PublishableModuleItem extends Model

    defaults:
      module_type: null
      course_id: null
      module_id: null
      published: true
      publishable: true
      unpublishable: true

    branch: (key) ->
      (@[key][@get('module_type')] or @[key].generic).call(this)

    url:             -> @branch('urls')
    toJSON:          -> @branch('toJSONs')
    disabledMessage: -> @branch('disabledMessages')

    baseUrl: -> "/api/v1/courses/#{@get('course_id')}"

    urls:
      generic:          -> "#{@baseUrl()}/modules/#{@get('module_id')}/items/#{@get('module_item_id') || @get('id')}"
      #attachment:       -> "/api/v1/files/#{@get('id')}"
      wiki_page:        -> "#{@baseUrl()}/pages/#{@get('id')}"
      assignment:       -> "#{@baseUrl()}/assignments/#{@get('id')}"
      discussion_topic: -> "#{@baseUrl()}/discussion_topics/#{@get('id')}"
      module:           -> "#{@baseUrl()}/modules/#{@get('id')}"
      quiz:             -> "#{@baseUrl()}/quizzes/#{@get('id')}"

    toJSONs:
      generic: ->          module_item: @attributes
      #attachment: ->       hidden: !@get('published')
      wiki_page: ->        wiki_page: @attributes
      assignment: ->       assignment: @attributes
      discussion_topic: -> @attributes
      quiz: ->             quiz: @attributes
      module: ->           module: @attributes

    disabledMessages:
      generic:          -> I18n.t('disabled', 'Publishing is disabled for this item')
      assignment:       -> I18n.t('disabled_assignment', "Can't unpublish if there are student submissions")
      quiz:             -> I18n.t('disabled_quiz', "Can't unpublish if there are student submissions")
      discussion_topic: -> I18n.t('disabled_discussion_topic', "Can't unpublish if there are student submissions")

    publish: ->
      @save 'published', yes

    unpublish: ->
      @save 'published', no

