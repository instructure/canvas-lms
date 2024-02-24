/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import $ from 'jquery'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('quiz_migration_notifications')

$('.close_migration_notification_link').click(function (event) {
  event.preventDefault()
  $(this).prop('disabled', true)
  doFetchApi({
    path: $(this).attr('rel'),
    method: 'POST',
  })
    .then(() => {
      $(this).closest('.quiz_migration_notification').remove()
    })
    .catch(err => {
      showFlashAlert({message: I18n.t('There was an error removing the notification'), err})
      $(this).prop('disabled', false)
    })
})
