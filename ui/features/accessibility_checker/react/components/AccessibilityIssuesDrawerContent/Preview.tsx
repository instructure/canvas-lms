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

import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'

import {AccessibilityIssue, ContentItemType, FormValue, PreviewResponse} from '../../types'
import {stripQueryString} from '../../utils'

const SELECTOR_STYLE = 'outline:2px solid #273540; outline-offset:2px;'
const A11Y_ISSUE_ATTR_NAME = 'data-a11y-issue-scroll-target'

export interface PreviewHandle {
  update: (formValue: FormValue, onSuccess?: () => void, onError?: (error?: string) => void) => void
  reload: (onSuccess?: () => void, onError?: (error?: string) => void) => void
}

interface PreviewProps {
  issue: AccessibilityIssue
  itemId: number
  itemType: ContentItemType
}

const applyHighlight = (previewResponse: PreviewResponse | null, issue: AccessibilityIssue) => {
  if (!previewResponse) return ''

  const parser = new DOMParser()
  const doc = parser.parseFromString(previewResponse.content, 'text/html')

  try {
    const target = doc.evaluate(
      previewResponse.path || issue.path || '',
      doc.body,
      null,
      XPathResult.FIRST_ORDERED_NODE_TYPE,
      null,
    ).singleNodeValue

    if (target instanceof Element) {
      const newStyle = `${target.getAttribute('style') || ''}; ${SELECTOR_STYLE}`
      target.setAttribute('style', newStyle)
      target.setAttribute(A11Y_ISSUE_ATTR_NAME, encodeURIComponent(issue.path))
      setTimeout(() => {
        document
          .querySelector(`[${A11Y_ISSUE_ATTR_NAME}="${encodeURIComponent(issue.path)}"]`)
          ?.scrollIntoView({
            behavior: 'smooth',
            block: 'center',
            inline: 'nearest',
          })
      }, 0)
    }
  } catch (err) {
    console.log('Failed to evaluate XPath:', previewResponse.path, err)
  }

  return doc.body.innerHTML
}

const I18n = createI18nScope('accessibility_checker')

const Preview: React.FC<PreviewProps & React.RefAttributes<PreviewHandle>> = forwardRef<
  PreviewHandle,
  PreviewProps
>(({issue, itemId, itemType}: PreviewProps, ref) => {
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
            responseError = await error.response.text()
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
      const params = new URLSearchParams({
        content_type: itemType,
        content_id: String(itemId),
      })

      await handleApiRequest(
        () =>
          doFetchApi<PreviewResponse>({
            path: `${stripQueryString(window.location.href)}/preview?${params.toString()}`,
            method: 'GET',
          }),
        I18n.t('Error loading preview for accessibility issue'),
        onSuccess,
        onError,
      )
    },
    [handleApiRequest, itemId, itemType],
  )

  const performPostRequest = useCallback(
    async (formValue: FormValue, onSuccess?: () => void, onError?: (error?: string) => void) => {
      await handleApiRequest(
        () =>
          doFetchApi<PreviewResponse>({
            path: `${stripQueryString(window.location.href)}/preview`,
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
              content_id: itemId,
              content_type: itemType,
              rule: issue.ruleId,
              path: issue.path,
              value: formValue,
            }),
          }),
        I18n.t('Error updating preview for accessibility issue'),
        onSuccess,
        onError,
      )
    },
    [handleApiRequest, itemId, itemType, issue.path, issue.ruleId],
  )

  useImperativeHandle(ref, () => ({
    reload: performGetRequest,
    update: performPostRequest,
  }))

  useEffect(() => {
    performGetRequest()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [itemId])

  if (isLoading) {
    return (
      <View as="div" textAlign="center" width="100%">
        <Spinner
          data-testid="spinner-loader"
          renderTitle={I18n.t('Loading preview...')}
          size="small"
        />
      </View>
    )
  }

  if (error) {
    return (
      <Alert
        variant="error"
        renderCloseButtonLabel={I18n.t('Close alert')}
        variantScreenReaderLabel={I18n.t('Error, ')}
      >
        {error}
      </Alert>
    )
  }

  return (
    <View
      as="div"
      id="a11y-issue-preview"
      borderWidth="small"
      height="15rem"
      overflowY="auto"
      padding="x-small x-small x-small x-small"
      dangerouslySetInnerHTML={{__html: applyHighlight(contentResponse, issue)}}
    />
  )
})

export default Preview
