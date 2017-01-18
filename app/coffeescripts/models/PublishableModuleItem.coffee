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
      module_item_name: null

    branch: (key) ->
      (@[key][@get('module_type')] or @[key].generic).call(this)

    url:             -> @branch('urls')
    toJSON:          -> @branch('toJSONs')
    disabledMessage: -> @branch('disabledMessages')

    baseUrl: -> "/api/v1/courses/#{@get('course_id')}"

    urls:
      generic:          -> "#{@baseUrl()}/modules/#{@get('module_id')}/items/#{@get('module_item_id')}"
      module:           -> "#{@baseUrl()}/modules/#{@get('id')}"

    toJSONs:
      generic: ->          module_item: { published: @get('published') }
      module: ->           module: { published: @get('published') }

    disabledMessages:
      generic:          -> if @get('module_item_name')
                             I18n.t('Publishing %{item_name} is disabled', {item_name: @get('module_item_name')})
                           else
                             I18n.t('Publishing is disabled for this item')

      assignment:       -> if @get('module_item_name')
                             I18n.t("Can't unpublish %{item_name} if there are student submissions", {item_name: @get('module_item_name')})
                           else
                             I18n.t("Can't unpublish if there are student submissions")

      quiz:             -> if @get('module_item_name')
                             I18n.t("Can't unpublish %{item_name} if there are student submissions", {item_name: @get('module_item_name')})
                           else
                             I18n.t("Can't unpublish if there are student submissions")
      discussion_topic: -> if @get('module_item_name')
                             I18n.t("Can't unpublish %{item_name} if there are student submissions", {item_name: @get('module_item_name')})
                           else
                             I18n.t("Can't unpublish if there are student submissions")

    publish: ->
      @save 'published', yes

    unpublish: ->
      @save 'published', no

