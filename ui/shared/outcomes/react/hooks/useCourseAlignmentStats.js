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

import {useEffect} from 'react'
import {useQuery} from 'react-apollo'
import useCanvasContext from './useCanvasContext'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {COURSE_ALIGNMENT_STATS} from '../../graphql/Management'

const I18n = useI18nScope('AlignmentSummary')

const useCourseAlignmentStats = () => {
  const {contextId} = useCanvasContext()
  const variables = {
    id: contextId,
  }

  const {loading, error, data} = useQuery(COURSE_ALIGNMENT_STATS, {
    variables,
    fetchPolicy: 'network-only',
  })

  useEffect(() => {
    if (error) {
      showFlashAlert({
        message: I18n.t('An error occurred while loading course alignment statistics.'),
        type: 'error',
      })
    }
  }, [error])

  return {
    loading,
    error,
    data,
  }
}

export default useCourseAlignmentStats
