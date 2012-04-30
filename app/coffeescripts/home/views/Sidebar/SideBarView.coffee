define ['Backbone'], ({View}) ->

  class DashboardAsideView extends View

    render: ->
      @$el.html """
        <div class=todo></div>
        <div class=comingUp></div>
      """
      super

