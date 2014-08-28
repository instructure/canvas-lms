define [
  './base_controller'
  'i18n!create_module_item_quiz'
  '../../models/item'
  'ic-ajax'
], (Base, I18n, Item, {request}) ->

  CreateDiscussionController = Base.extend

    text:
      discussionName: I18n.t('discussion_name', 'Discussion Name')

    createItem: ->
      discussion = @get('model')
      item = Item.createRecord(title: discussion.title, type: 'Discussion')
      request(
        url: "/api/v1/courses/#{ENV.course_id}/discussion_topics"
        type: 'post'
        data: discussion
      ).then(((savedDiscussion) =>
        item.set('content_id', savedDiscussion.id)
        item.save()
      ), (=>
        item.set('error', true)
      ))
      item


