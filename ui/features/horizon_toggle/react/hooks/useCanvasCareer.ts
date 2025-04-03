/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useState, useEffect, useMemo, useCallback} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {CanvasCareerValidationResponse, CompletionProgressResponse} from '../types'
import {useScope as createI18nScope} from '@canvas/i18n'

export interface UseCanvasCareerResult {
  data: CanvasCareerValidationResponse
  loading: boolean
  hasUnsupportedContent: boolean
  hasChangesNeededContent: boolean
  loadingText: string
  isTermsAccepted: boolean
  setTermsAccepted: (accepted: boolean) => void
  progress: Partial<CompletionProgressResponse>
  onSubmit: () => Promise<void>
}

const I18n = createI18nScope('horizon_toggle_page')

const timeout = (delay: number) => {
  return new Promise(resolve => setTimeout(resolve, delay))
}

export const useCanvasCareer = ({
  onConversionCompleted,
}: {onConversionCompleted: () => void}): UseCanvasCareerResult => {
  const [data, setData] = useState<CanvasCareerValidationResponse>({errors: {}})
  const [loading, setLoading] = useState<boolean>(true)
  const [loadingText, setLoadingText] = useState<string>('')
  const [progress, setProgress] = useState<Partial<CompletionProgressResponse>>({url: ''})
  const [isTermsAccepted, setTermsAccepted] = useState(false)

  useEffect(() => {
    setLoading(true)
    doFetchApi<CanvasCareerValidationResponse>({
      path: `/courses/${ENV.COURSE_ID}/canvas_career_validation`,
    })
      .then(response => setData(response.json!))
      .catch(err => {
        showFlashAlert({message: err.message})
      })
      .finally(() => setLoading(false))
  }, [])

  const hasUnsupportedContent = useMemo(() => {
    return Boolean(
      data?.errors?.discussions ||
        data?.errors?.groups ||
        data?.errors?.outcomes ||
        data?.errors?.collaborations ||
        data?.errors?.quizzes,
    )
  }, [data])

  const hasChangesNeededContent = useMemo(() => {
    return !!data?.errors?.assignments
  }, [data])

  const fetchProgress = useCallback(async () => {
    if (!progress?.url) return
    try {
      const response = await doFetchApi<CompletionProgressResponse>({
        path: progress?.url!,
        method: 'GET',
      })
      const json = response.json!
      await timeout(1000)
      if (json.workflow_state === 'completed' || json.workflow_state === 'failed') {
        onConversionCompleted()
      } else {
        await fetchProgress()
      }
      setProgress(json)
    } catch (e: any) {
      showFlashAlert({
        message: I18n.t('Could not convert course to Canvas Career. Please try again.'),
        type: 'error',
      })
    }
  }, [progress])

  const onSubmit = useCallback(async () => {
    setLoadingText(I18n.t('Converting course to Canvas Career...'))
    try {
      const response = await doFetchApi<CompletionProgressResponse>({
        path: `/courses/${ENV.COURSE_ID}/canvas_career_conversion`,
        method: 'POST',
      })
      const json = response.json!
      if (json.success) {
        onConversionCompleted()
      }
      if (json.errors) {
        showFlashAlert({
          message: json.errors,
          type: 'error',
        })
        setLoadingText('')
      }
      if (json.workflow_state) {
        setProgress(json)
      }
    } catch (e: any) {
      showFlashAlert({
        message: I18n.t('Could not convert course to Canvas Career. Please try again.'),
        type: 'error',
      })
      setLoadingText('')
    }
  }, [])

  useEffect(() => {
    if (
      progress &&
      progress?.workflow_state !== 'completed' &&
      progress?.workflow_state !== 'failed'
    ) {
      fetchProgress()
    } else if (
      (progress && progress?.workflow_state === 'completed') ||
      progress?.workflow_state === 'failed'
    ) {
      onConversionCompleted()
    }
  }, [progress, fetchProgress])

  return {
    data,
    loading,
    hasUnsupportedContent,
    hasChangesNeededContent,
    loadingText,
    isTermsAccepted,
    setTermsAccepted,
    progress,
    onSubmit,
  }
}
