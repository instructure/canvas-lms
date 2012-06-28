define [
  'i18n!dashboard'
  'compiled/fn/preventDefault'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
], (I18n, preventDefault) ->

  dashboardToggle = (action) ->
    $a = $('<a />')
    $a.text(if action is 'enable'
      I18n.t('enable_dashboard', "Try out the new dashboard")
    else
      I18n.t('disable_dashboard', "Go back to the old dashboard")
    )
    clicked = false
    $a.click preventDefault ->
      return if clicked
      clicked = true
      $a.css(opacity: 0.5)
      $.ajaxJSON '/toggle_dashboard', 'POST', {}, ->
        location.reload()
    $('<span class="dashboard-toggle" />').append($a)
