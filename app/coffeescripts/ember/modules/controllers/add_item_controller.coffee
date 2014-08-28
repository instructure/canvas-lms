define [
  'ember'
  'ic-ajax'
  '../models/item'
], (Ember, {request}, Item) ->

  adders =
    assignment: (assignments, moduleId) ->
      assignments.map (assignment) ->
        item = Item.createRecord
          module_id: moduleId
          content_id: assignment.id
          title: assignment.name
          type: 'Assignment'
        item.save()
        item

    quiz: (quizzes, moduleId) ->
      quizzes.map (quiz) ->
        item = Item.createRecord
          module_id: moduleId
          content_id: quiz.id
          title: quiz.title
          type: 'Quiz'
        item.save()
        item

    file: (files, moduleId) ->
      files.map (file) ->
        item = Item.createRecord
          module_id: moduleId
          content_id: file.id
          title: file.display_name
          type: 'File'
        item.save()
        item

    page: (pages, moduleId) ->
      pages.map (page) ->
        item = Item.createRecord
          module_id: moduleId
          page_url: page.url
          title: page.title
          type: 'Page'
        item.save()
        item

    discussion: (topics, moduleId) ->
      topics.map (topic) ->
        item = Item.createRecord
          module_id: moduleId
          content_id: topic.id
          title: topic.title
          type: 'Discussion'
        item.save()
        item

    tool: ->
      console.log 'tool'

  {equal, bool} = Ember.computed

  cid = -1

  NewModuleItemController = Ember.ObjectController.extend

    returnFocus: false

    # this silliness can go away when ember lands
    # https://github.com/emberjs/ember.js/pull/2409
    createAssignment: equal('createType', 'assignment')
    createDiscussion: equal('createType', 'discussion')
    createFile:       equal('createType', 'file')
    createHeader:     equal('createType', 'header')
    createLink:       equal('createType', 'link')
    createPage:       equal('createType', 'page')
    createQuiz:       equal('createType', 'quiz')
    createTool:       equal('createType', 'tool')
    # same here ...
    addAssignment: equal('addType', 'assignment')
    addDiscussion: equal('addType', 'discussion')
    addFile:       equal('addType', 'file')
    addHeader:     equal('addType', 'header')
    addPage:       equal('addType', 'page')
    addQuiz:       equal('addType', 'quiz')
    addTool:       equal('addType', 'tool')


    editing: bool('createType')

    modalId: (->
      cid++
      "add-item-modal-#{cid}"
    ).property()

    addListId: (->
      cid++
      "add-list-#{cid}"
    ).property()

    actions:

      quitEditing: ->
        @setProperties
          returnFocus: true
          createType: off

      beginCreate: (item) ->
        @set('newThing', {})
        @set('createType', item.get('type'))

      beginAdd: (item) ->
        @set('newThing', {})
        @set('addType', item.get('type'))
        # yehuda doesn't like this next line
        modal = Ember.View.views[@get('modalId')]
        modal.open()

      addExistingItems: ->
        stuffToAdd = @get('newThing.selected')
        items = adders[@get('addType')](stuffToAdd, @get('model.id'))
        # hard to see them get added w/o the delay
        Ember.run.later this, ->
          @get('items').addObjects(items)
        , 300

