define [
  'Backbone'
  'compiled/views/DiscussionTopic/EntryView'
  'jst/discussions/results_entry'
], ({View}, EntryView, template) ->

  class FilterEntryView extends View

    events:
      'click': 'click'

    tagName: 'li'

    className: 'entry'

    template: template

    toJSON: ->
      @model.attributes

    click: ->
      @trigger 'click', this

