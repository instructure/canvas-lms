define ['Backbone'], ({View}) ->

  class ItemView extends View

    render: ->
      html = @template @present()
      @$el.html html
      super


