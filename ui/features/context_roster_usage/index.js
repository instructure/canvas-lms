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

import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/datetime/jquery'
import '@canvas/util/templateData'
import 'jquery-pageless'

const I18n = useI18nScope('context.roster_user_usage')

$(() => {
  const url = ENV.context_url
  $('#usage_report').pageless({
    totalPages: ENV.accesses_total_pages,
    url,
    loaderMsg: I18n.t('loading_more_results', 'Loading more results'),
    scrape(data) {
      if (typeof data === 'string') {
        try {
          data = JSON.parse(data)
        } catch (e) {
          data = []
        }
      }
      for (const idx in data) {
        const $access = $('#usage_report .access.blank:first').clone(true).removeClass('blank')
        const access = data[idx].asset_user_access
        $access.addClass(access.asset_class_name)
        $access.find('.icon').addClass(access.icon)
        delete access.icon
        access.readable_name = access.readable_name || access.display_name || access.asset_code
        access.last_viewed = $.datetimeString(access.last_access)
        $access.fillTemplateData({data: access})
        $('#usage_report table tbody').append($access.show())
      }
      return ''
    },
  })
})
