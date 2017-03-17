import $ from 'jquery'
import I18n from 'i18n!common'
import React from 'react'
import ReactDOM from 'react-dom'
import Navigation from 'jsx/navigation_header/Navigation'

// #
// Handle user toggling of nav width
let navCollapsed = window.ENV.SETTINGS.collapse_global_nav

$('body').on('click', '#primaryNavToggle', function () {
  let primaryNavToggleText
  navCollapsed = !navCollapsed
  if (navCollapsed) {
    $('body').removeClass('primary-nav-expanded')
    $.ajaxJSON('/api/v1/users/self/settings', 'PUT',
        {collapse_global_nav: true})
    primaryNavToggleText = I18n.t('Expand global navigation')
    $(this).attr({title: primaryNavToggleText, 'aria-label': primaryNavToggleText})

    // add .primary-nav-transitions a little late to avoid awkward CSS
    // transitions when the nav is changing states
    setTimeout((() => {
      $('body').addClass('primary-nav-transitions')
    }), 300)
  } else {
    $('body').removeClass('primary-nav-transitions').addClass('primary-nav-expanded')
    $.ajaxJSON('/api/v1/users/self/settings', 'PUT',
        {collapse_global_nav: false})
    primaryNavToggleText = I18n.t('Minimize global navigation')
    $(this).attr({title: primaryNavToggleText, 'aria-label': primaryNavToggleText})
  }
})

ReactDOM.render(<Navigation />, document.getElementById('global_nav_tray_container'))
