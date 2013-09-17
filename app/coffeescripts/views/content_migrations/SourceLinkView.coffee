define [
  'Backbone'
  'jst/content_migrations/SourceLink'
], (Backbone, template) ->
  class SourceLinkView extends Backbone.View
    template: template

    toJSON: ->
      json = super
      json.attachment = @model.get('attachment')
      json.settings = @model.get('settings')
      json