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

import {forwardRef, useCallback, useEffect, useImperativeHandle, useState} from 'react'

import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import {Mask} from '@instructure/ui-overlays'

import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'

import {AccessibilityIssue, FormValue, PreviewResponse, ResourceType} from '../../types'
import {getAsContentItemType} from '../../utils/apiData'
import {getCourseBasedPath} from '../../utils/query'

export interface PreviewHandle {
  update: (formValue: FormValue, onSuccess?: () => void, onError?: (error?: string) => void) => void
  reload: (onSuccess?: () => void, onError?: (error?: string) => void) => void
}

interface PreviewProps {
  issue: AccessibilityIssue
  resourceId: number
  itemType: ResourceType
}

interface PreviewOverlayProps {
  isLoading: boolean
  error: string | null
}

const I18n = createI18nScope('accessibility_checker')

const PreviewOverlay = ({isLoading, error}: PreviewOverlayProps) => {
  if (error) {
    return (
      <Mask id="a11y-issue-preview-overlay">
        <Alert
          variant="error"
          renderCloseButtonLabel={I18n.t('Close alert')}
          variantScreenReaderLabel={I18n.t('Error, ')}
        >
          {error}
        </Alert>
      </Mask>
    )
  }

  if (isLoading) {
    return (
      <Mask id="a11y-issue-preview-overlay">
        <Spinner renderTitle={I18n.t('Loading preview...')} size="large" />
      </Mask>
    )
  }

  return null
}

const Preview: React.FC<PreviewProps & React.RefAttributes<PreviewHandle>> = forwardRef<
  PreviewHandle,
  PreviewProps
>(({issue, resourceId, itemType}: PreviewProps, ref) => {
  const [contentResponse, setContentResponse] = useState<PreviewResponse | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleApiRequest = useCallback(
    async (
      apiCall: () => Promise<{json?: PreviewResponse}>,
      errorMessage: string,
      onSuccess?: () => void,
      onError?: (error?: string) => void,
    ) => {
      setIsLoading(true)
      try {
        const result = await apiCall()
        setContentResponse(result.json || null)
        setError(null)
        onSuccess?.()
      } catch (error: any) {
        let responseError = error?.message || error?.toString()
        if (error?.response?.json) {
          try {
            const json = await error.response.json()
            responseError = json.error || json.message || responseError
          } catch {
            responseError = await error.response.statusText
          }
        }
        onError?.(responseError)
        setError(errorMessage)
      } finally {
        setIsLoading(false)
      }
    },
    [],
  )

  const performGetRequest = useCallback(
    async (onSuccess?: () => void, onError?: (error?: string) => void) => {
      const base = getCourseBasedPath(`/accessibility`)
      const params = new URLSearchParams({
        issue_id: issue.id,
      })

      await handleApiRequest(
        () =>
          doFetchApi<PreviewResponse>({
            path: `${base}/preview?${params.toString()}`,
            method: 'GET',
          }),
        I18n.t('Error previewing fixed accessibility issue.'),
        onSuccess,
        onError,
      )
    },
    [handleApiRequest, issue.id],
  )

  const performPostRequest = useCallback(
    async (formValue: FormValue, onSuccess?: () => void, onError?: (error?: string) => void) => {
      const base = getCourseBasedPath(`/accessibility`)
      await handleApiRequest(
        () =>
          doFetchApi<PreviewResponse>({
            path: `${base}/preview`,
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
              content_id: resourceId,
              content_type: getAsContentItemType(itemType),
              rule: issue.ruleId,
              path: issue.path,
              value: formValue,
            }),
          }),
        I18n.t('Error previewing fixed accessibility issue.'),
        onSuccess,
        onError,
      )
    },
    [handleApiRequest, resourceId, itemType, issue.path, issue.ruleId],
  )

  useImperativeHandle(ref, () => ({
    reload: performGetRequest,
    update: performPostRequest,
  }))

  useEffect(() => {
    performGetRequest()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resourceId, issue.id])

  return (
    <View as="div" position="relative" id="a11y-issue-preview-container">
      <PreviewOverlay isLoading={isLoading} error={error} />
      <View
        as="div"
        id="a11y-issue-preview"
        borderWidth="small"
        height="15rem"
        overflowY="auto"
        padding="x-small x-small x-small x-small"
        dangerouslySetInnerHTML={{__html: contentResponse?.content || ''}}
      />
    </View>
  )
})

export default Preview
