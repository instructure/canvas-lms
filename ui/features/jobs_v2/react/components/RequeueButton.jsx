/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import React, {useState, useEffect} from 'react'
import {Button} from '@instructure/ui-buttons'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = useI18nScope('jobs_v2')

export default function RequeueButton({id, onRequeue}) {
  const [loading, setLoading] = useState(false)

  // don't re-enable the requeue button until a different job is selected
  // (the button will disappear after the job list refreshes anyway, but
  // we don't want it to be temporarily clickable while that happens)
  useEffect(() => {
    setLoading(false)
  }, [id])

  const onClick = () => {
    setLoading(true)
    return doFetchApi({
      method: 'POST',
      path: `/api/v1/jobs2/${id}/requeue`,
    }).then(
      response => {
        onRequeue(response.json)
      },
      _error => {
        setLoading(false)
      }
    )
  }

  return (
    ENV.manage_jobs && (
      <Button onClick={onClick} interaction={loading ? 'disabled' : 'enabled'}>
        {I18n.t('Requeue Job')}
      </Button>
    )
  )
}
