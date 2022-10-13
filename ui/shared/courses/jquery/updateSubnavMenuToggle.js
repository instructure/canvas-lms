/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('subnav_menu_toggle')

const subnavMenuTranslations = {
  hide: {
    get default() {
      return I18n.t('Hide Navigation Menu')
    },
    get account() {
      return I18n.t('Hide Account Navigation Menu')
    },
    get admin() {
      return I18n.t('Hide Admin Navigation Menu')
    },
    get courses() {
      return I18n.t('Hide Courses Navigation Menu')
    },
    get groups() {
      return I18n.t('Hide Groups Navigation Menu')
    },
  },
  show: {
    get default() {
      return I18n.t('Show Navigation Menu')
    },
    get account() {
      return I18n.t('Show Account Navigation Menu')
    },
    get admin() {
      return I18n.t('Show Admin Navigation Menu')
    },
    get courses() {
      return I18n.t('Show Courses Navigation Menu')
    },
    get groups() {
      return I18n.t('Show Groups Navigation Menu')
    },
  },
}

const updateSubnavMenuToggle = function (pathname = window.location.pathname) {
  // update subnav menu toggle for accessibility
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

export default updateSubnavMenuToggle
