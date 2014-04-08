define [
  './base_controller'
  'i18n!add_module_item'
  '../../../shared/xhr/fetch_all_pages'
  'ic-ajax'
  '../../models/item'
], (Base, I18n, fetch, {request}, Item) ->

  AddTopicController = Base.extend

    topics: (->
      @constructor.topics or= fetch("/api/v1/courses/#{ENV.course_id}/discussion_topics")
    ).property()

    title: (->
      I18n.t('add_topic_to', "Add discussion topics to %{module}", module: @get('moduleController.name'))
    ).property('moduleController.name')

    actions:

      toggleSelected: (topic) ->
        topics = @get('model.selected')
        if topics.contains(topic)
          topics.removeObject(topic)
        else
          topics.addObject(topic)

  AddTopicController.reopenClass

    topics: null

