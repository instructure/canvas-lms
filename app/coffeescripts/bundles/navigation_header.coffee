require [
  'jquery',
  'underscore',
  'i18n!common',
  'react',
  'react-dom',
  'jsx/navigation_header/Navigation',
], ($, _, I18n, React, ReactDOM, Navigation) ->

  ##
  # Handle user toggling of nav width
  navCollapsed = window.ENV.SETTINGS.collapse_global_nav

  $('body').on 'click', '#primaryNavToggle', ->
    navCollapsed = !navCollapsed
    if navCollapsed
      $('body').removeClass('primary-nav-expanded')
      $.ajaxJSON '/api/v1/users/self/settings', 'PUT',
        'collapse_global_nav': true
      primaryNavToggleText = I18n.t("Expand global navigation")
      $(this).attr({title: primaryNavToggleText, "aria-label": primaryNavToggleText})
      # add .primary-nav-transitions a little late to avoid awkward CSS
      # transitions when the nav is changing states
      setTimeout (->
        $('body').addClass('primary-nav-transitions')
        return
      ), 300
    else
      $('body').removeClass('primary-nav-transitions').addClass('primary-nav-expanded')
      $.ajaxJSON '/api/v1/users/self/settings', 'PUT',
        'collapse_global_nav': false
      primaryNavToggleText = I18n.t("Minimize global navigation")
      $(this).attr({title: primaryNavToggleText, "aria-label": primaryNavToggleText})

  Nav = React.createElement(Navigation)
  ReactDOM.render(Nav, document.getElementById('global_nav_tray_container'))
