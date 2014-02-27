define ['jquery', 'Backbone'], ($, {View}) ->

  class NavigationPillView extends View

    events:
      'click a': 'onToggle'

    onToggle: (e) ->
      e.preventDefault()
      @setActiveTab(e.target)

    setActiveTab: (active) ->
      @$('li').removeClass('active')
      $(active).parent().addClass('active')
      @trigger('pillchange', $(active).data('id'))

    setActiveView: (viewName) ->
      @setActiveTab(@$("[data-id=#{viewName}]"))
