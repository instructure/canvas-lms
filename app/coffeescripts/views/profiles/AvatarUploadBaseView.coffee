define ['Backbone'], (Backbone) ->

  class AvatarUploadBaseView extends Backbone.View

    setup: $.noop

    teardown: $.noop

    render: ->
      super
      @$el.data('view', this)
      this
