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
import React, {useCallback, useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GradingScheme, UsedLocation} from '@canvas/grading_scheme/gradingSchemeApiModel'
import {useGradingSchemeUsedLocations} from '../hooks/useGradingSchemeUsedLocations'
import {ApiCallStatus} from '../hooks/ApiCallStatus'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
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
  const [usedLocations, setUsedLocations] = useState<UsedLocation[]>([])
  const path = useRef<string | undefined>(undefined)
  const moreLocationsLeft = useRef(true)
  const sentinelRef = useRef(null)
  const fetchingLocations = useRef(false)

  const {getGradingSchemeUsedLocations, gradingSchemeUsedLocationsStatus} =
    useGradingSchemeUsedLocations()
  const loadMoreItems = useCallback(async () => {
    if (!gradingScheme || fetchingLocations.current) {
      return
    }
    fetchingLocations.current = true
    try {
      const newLocations = await getGradingSchemeUsedLocations(
        gradingScheme.context_type,
        gradingScheme.context_id,
        gradingScheme.id,
        path.current
      )
      setUsedLocations(prevLocations => {
        if (newLocations.usedLocations[0]?.id === prevLocations[prevLocations.length - 1]?.id) {
          prevLocations[prevLocations.length - 1].assignments.push(
            ...newLocations.usedLocations[0].assignments
          )
          newLocations.usedLocations.shift()
        }
        return [...prevLocations, ...newLocations.usedLocations]
      })
      path.current = newLocations.nextPage
      moreLocationsLeft.current = !newLocations.isLastPage
      fetchingLocations.current = false
    } catch (error: any) {
      showFlashError(I18n.t('Failed to load used locations'))(error)
    }
  }, [getGradingSchemeUsedLocations, gradingScheme])

  const reset = () => {
    setUsedLocations([])
    path.current = undefined
    moreLocationsLeft.current = true
  }

  useEffect(() => {
    if (!open) {
      return
    }
    const timer = setTimeout(() => {
      if (!sentinelRef?.current) {
        return
      }
      const observer = new IntersectionObserver(
        entries => {
          if (
            entries[0].isIntersecting &&
            moreLocationsLeft.current &&
            !fetchingLocations.current
          ) {
            loadMoreItems()
          }
        },
        {
          root: null,
          rootMargin: '0px',
          threshold: 0.4,
        }
      )

      observer.observe(sentinelRef.current)
      return () => {
        observer.disconnect()
      }
    }, 0)
    return () => clearTimeout(timer)
  }, [gradingSchemeUsedLocationsStatus, loadMoreItems, moreLocationsLeft, open])
  return (
    <UsedLocationsModal
      isLoading={gradingSchemeUsedLocationsStatus === ApiCallStatus.PENDING}
      isOpen={open}
      onClose={handleClose}
      onDismiss={reset}
      sentinelRef={sentinelRef}
      usedLocations={usedLocations}
    />
  )
}

export default GradingSchemeUsedLocationsModal
