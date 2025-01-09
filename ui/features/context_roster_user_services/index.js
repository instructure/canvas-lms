//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'

import '@canvas/jquery/jquery.ajaxJSON'
import {initializeTopNavPortalWithDefaults} from '@canvas/top-navigation/react/TopNavPortalWithDefaults'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('RegisteredServices')
$(document).ready(() => {
  const handleBreadCrumbSetter = ({getCrumbs, setCrumbs}) => {
    const crumbs = getCrumbs()
    crumbs.push({name: I18n.t('People'), url: document.referrer})
    crumbs.push({name: I18n.t('Registered services'), url: ''})
    setCrumbs(crumbs)
  }

  initializeTopNavPortalWithDefaults({
    getBreadCrumbSetter: handleBreadCrumbSetter,
    useStudentView: true,
  })

  return $('.show_user_services_checkbox').change(function () {
    $.ajaxJSON(
      $('.profile_url').attr('href'),
      'PUT',
      {'user[show_user_services]': $(this).prop('checked')},
      _data => {},
      _data => {},
    )
  })
})
