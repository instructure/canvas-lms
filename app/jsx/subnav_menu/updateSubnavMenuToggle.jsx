define([
  'i18n!subnav_menu_toggle'
], (I18n) => {
  const updateSubnavMenuToggle = function (pathname = window.location.pathname) {
    // update subnav menu toggle for accessibility
    const subnavMenuTranslations = {
      hide: {
        default: I18n.t('Hide Navigation Menu'),
        account: I18n.t('Hide Account Navigation Menu'),
        admin: I18n.t('Hide Admin Navigation Menu'),
        courses: I18n.t('Hide Courses Navigation Menu'),
        groups: I18n.t('Hide Groups Navigation Menu')
      },
      show: {
        default: I18n.t('Show Navigation Menu'),
        account: I18n.t('Show Account Navigation Menu'),
        admin: I18n.t('Show Admin Navigation Menu'),
        courses: I18n.t('Show Courses Navigation Menu'),
        groups: I18n.t('Show Groups Navigation Menu')
      }
    }

    const subnavMenuExpanded = document.body.classList.contains('course-menu-expanded')
    const subnavMenuAction = subnavMenuExpanded ? 'hide' : 'show'
    let subnavMenuToggleText = subnavMenuTranslations[subnavMenuAction].default

    if (pathname.match(/^\/profile/)) {
      subnavMenuToggleText = subnavMenuTranslations[subnavMenuAction].account
    } else if (pathname.match(/^\/accounts/)) {
      subnavMenuToggleText = subnavMenuTranslations[subnavMenuAction].admin
    } else if (pathname.match(/^\/courses/)) {
      subnavMenuToggleText = subnavMenuTranslations[subnavMenuAction].courses
    } else if (pathname.match(/^\/groups/)) {
      subnavMenuToggleText = subnavMenuTranslations[subnavMenuAction].groups
    }

    const subnavMenuToggle = document.getElementById('courseMenuToggle')
    subnavMenuToggle.setAttribute('aria-label', subnavMenuToggleText)
    subnavMenuToggle.setAttribute('title', subnavMenuToggleText)
  }

  return updateSubnavMenuToggle
})

