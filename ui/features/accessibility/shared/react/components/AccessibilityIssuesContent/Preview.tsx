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
import {Text} from '@instructure/ui-text'
import {CondensedButton} from '@instructure/ui-buttons'

import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'

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
  onPreviewChange?: (response: PreviewResponse | null) => void
  onStaleConflict: () => void
  onRescan: () => void
}

interface PreviewOverlayProps {
  isLoading: boolean
  error: string | null
  isStale: boolean
  onRescan: () => void
}

const I18n = createI18nScope('accessibility_checker')

const PreviewOverlay = ({isLoading, error, isStale, onRescan}: PreviewOverlayProps) => {
  if (isStale) {
    return (
      <Mask id="a11y-issue-preview-overlay">
        <Alert
          variant="warning"
          renderCloseButtonLabel={I18n.t('Close alert')}
          variantScreenReaderLabel={I18n.t('Warning, ')}
        >
          <Text>
            {I18n.t(
              'This issue may be outdated. The resource has been updated since this issue was detected.',
            )}
          </Text>
          <CondensedButton onClick={onRescan}>{I18n.t('Rescan this resource')}</CondensedButton>
        </Alert>
      </Mask>
    )
  }

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
>(
  (
    {issue, resourceId, itemType, onPreviewChange, onStaleConflict, onRescan}: PreviewProps,
    ref,
  ) => {
    const [contentResponse, setContentResponse] = useState<PreviewResponse | null>(null)
    const [isLoading, setIsLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [isStale, setIsStale] = useState(false)

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
          setIsStale(false)
          onSuccess?.()
          onPreviewChange?.(result.json || null)
        } catch (err: unknown) {
          const error = err as FetchApiError
          let responseError: string = error?.message || error?.toString()
          let parsedJson: any = null

          if (error?.response?.json) {
            try {
              parsedJson = await error.response.json()
              responseError = parsedJson.error || parsedJson.message || responseError
            } catch {
              responseError = await error.response.statusText
            }
          }

          if (error?.response?.status === 409) {
            setIsStale(true)
            setError(null)
            onStaleConflict()
          } else if (parsedJson?.content) {
            setContentResponse(parsedJson)
            setError(null)
            onPreviewChange?.(parsedJson)
          } else {
            setError(errorMessage)
          }

          onError?.(responseError)
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
                // TODO: Refactor to pass issue_id instead of content_type/content_id/rule/path
                // This would allow the backend to use the same resource resolution as the fix
                // action, ensuring consistency and eliminating dependency on dead code.
                // Should be: { issue_id: issue.id, value: formValue }
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
        <PreviewOverlay isLoading={isLoading} error={error} isStale={isStale} onRescan={onRescan} />
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
  },
)

export default Preview
