define ['Backbone'], (Backbone) ->

  class DiscussionsSettings extends Backbone.Model

    ##
    # tricks backbone into sending a PUT request when saving instead of
    # POST (no ID on a model in this method's super)
    isNew: -> false

    url: ENV.SETTINGS_URL

