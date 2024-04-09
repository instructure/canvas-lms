/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import React, {useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GradingScheme} from '@canvas/grading_scheme/gradingSchemeApiModel'
import {useGradingSchemeUsedLocations} from '../hooks/useGradingSchemeUsedLocations'
import {ApiCallStatus} from '../hooks/ApiCallStatus'
import {UsedLocationsModal} from './UsedLocationsModal'

const I18n = useI18nScope('GradingSchemeViewModal')

export type GradingSchemeUsedLocationsModalProps = {
  open: boolean
  gradingScheme?: GradingScheme
  handleClose: () => void
}
const GradingSchemeUsedLocationsModal = ({
  open,
  gradingScheme,
  handleClose,
}: GradingSchemeUsedLocationsModalProps) => {
  const path = useRef<string | undefined>(undefined)

  const {getGradingSchemeUsedLocations, gradingSchemeUsedLocationsStatus} =
    useGradingSchemeUsedLocations()

  const onClose = () => {
    path.current = undefined
    handleClose()
  }

  return (
    <UsedLocationsModal
      isLoading={gradingSchemeUsedLocationsStatus === ApiCallStatus.PENDING}
      isOpen={open}
      itemId={gradingScheme?.id}
      fetchUsedLocations={async () => {
        if (!gradingScheme) {
          return {
            usedLocations: [],
            isLastPage: true,
            nextPage: '',
          }
        }

        const usedLocations = await getGradingSchemeUsedLocations(
          gradingScheme.context_type,
          gradingScheme.context_id,
          gradingScheme.id,
          path.current
        )

        path.current = usedLocations.nextPage
        return usedLocations
      }}
      onClose={onClose}
    />
  )
}

export default GradingSchemeUsedLocationsModal
