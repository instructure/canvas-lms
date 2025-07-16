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

import React, {useEffect, useRef, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {CloseButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'

import AccessibilityIssuesDrawerFooter from './AccessibilityIssuesDrawerFooter'
import AccessibilityIssueForm from './AccessibilityIssueForm'
import {AccessibilityIssue, ContentItem, PreviewResponse} from '../../types'
import {ruleIdToLabelMap} from '../../constants'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('AccessibilityIssuesDrawerContent')

interface Props {
  item: ContentItem
  onClose: () => void
}

const SELECTOR_STYLE = 'outline:2px solid #273540; outline-offset:2px;'
const A11Y_ISSUE_ATTR_NAME = 'data-a11y-issue-scroll-target'

function renderLoading() {
  return (
    <Flex as="div" height="100%" justifyItems="center" alignItems="center" width="100%">
      <Spinner renderTitle={I18n.t('Loading...')} size="large" margin="auto" />
    </Flex>
  )
}

const AccessibilityIssuesDrawerContent: React.FC<Props> = ({item, onClose}: Props) => {
  const [isLoading, setIsLoading] = useState(false)
  const [currentIssueIndex, setCurrentIssueIndex] = useState(0)
  const [originalContentLoading, setOriginalContentLoading] = useState(true)
  const [originalContent, setOriginalContent] = useState('')
  const regionRef = useRef<HTMLDivElement | null>(null)
  const [issues, setIssues] = useState<AccessibilityIssue[]>(item.issues || [])
  const currentIssue = issues[currentIssueIndex]
  const [solvedIssue, setSolvedIssue] = useState(
    new Map(item.issues?.map(issue => [issue.id, false]) || []),
  )
  const [applying, setApplying] = useState(
    new Map(item.issues?.map(issue => [issue.id, false]) || []),
  )
  const [previewLoading, setPreviewLoading] = useState(
    new Map(item.issues?.map(issue => [issue.id, false]) || []),
  )
  const [issuesPreview, setIssuesPreview] = useState(
    new Map<string, PreviewResponse>(
      item.issues?.map(issue => [issue.id, {content: originalContent, path: issue.path}]) || [],
    ),
  )
  const [issueFormState, setIssueFormState] = useState<Map<string, string>>(
    new Map(item.issues?.map(issue => [issue.id, issue.form?.value || '']) || []),
  )

  useEffect(() => {
    if (regionRef.current) {
      regionRef.current.focus()
    }
    setCurrentIssueIndex(0)
  }, [item])

  useEffect(() => {
    const params = new URLSearchParams({
      content_type: item.type,
      content_id: String(item.id),
    })

    doFetchApi({
      path: `${window.location.href}/preview?${params.toString()}`,
      method: 'GET',
    })
      .then(result => result.json)
      .then(resultJson => {
        setOriginalContent((resultJson as PreviewResponse).content)
      })
      .catch(err => {
        console.error('Error loading preview for content. Error is:' + err.message)
      })
      .finally(() => {
        setOriginalContentLoading(false)
      })
  }, [item.id, item.type])

  const onNext = () => {
    setCurrentIssueIndex(prev => Math.min(prev + 1, issues.length - 1))
  }

  const onPrevious = () => {
    setCurrentIssueIndex(prev => Math.max(prev - 1, 0))
  }

  const handleFormChange = (issue: AccessibilityIssue, formValue: string) => {
    const newState = new Map(previewLoading)
    newState.set(issue.id, true)
    setPreviewLoading(newState)
    doFetchApi({
      path: window.location.href + '/preview',
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        content_type: item.type,
        content_id: item.id,
        rule: issue.ruleId,
        path: issue.path,
        value: formValue,
      }),
    })
      .then(result => result.json)
      .then(resultJson => {
        const newState = new Map(issuesPreview)
        newState.set(issue.id, resultJson as PreviewResponse)
        setIssuesPreview(newState)
      })
      .catch(err => {
        console.error('Error loading preview for accessibility issue. Error is:' + err.message)
      })
      .finally(() => {
        const newState = new Map(previewLoading)
        newState.set(issue.id, false)
        setPreviewLoading(newState)
      })
  }

  const applyHighlight = (issue: AccessibilityIssue) => {
    if (!issue) return originalContent

    const issuePreview = issuesPreview.get(issue.id) || {
      content: originalContent,
      path: issue.path,
    }

    const parser = new DOMParser()
    const doc = parser.parseFromString(issuePreview.content, 'text/html')

    try {
      const target = doc.evaluate(
        issuePreview.path || '',
        doc.body,
        null,
        XPathResult.FIRST_ORDERED_NODE_TYPE,
        null,
      ).singleNodeValue

      if (target instanceof Element) {
        const newStyle = `${target.getAttribute('style') || ''}; ${SELECTOR_STYLE}`
        target.setAttribute('style', newStyle)
        target.setAttribute(A11Y_ISSUE_ATTR_NAME, encodeURIComponent(issue.path))
      }
    } catch (err) {
      console.log('Failed to evaluate XPath:', issuePreview.path, err)
    }

    return doc.body.innerHTML
  }

  const onSaveAndNext = () => {
    if (!currentIssue) return

    const issueId = currentIssue.id
    const formValue = issueFormState.get(issueId)
    setIsLoading(true)
    const applyingMap = new Map(applying)
    applyingMap.set(issueId, true)
    setApplying(applyingMap)

    doFetchApi({
      path: window.location.href + '/issues',
      method: 'PUT',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        content_type: item.type,
        content_id: item.id,
        rule: currentIssue.ruleId,
        path: currentIssue.path,
        value: formValue,
      }),
    })
      .then(() => {
        const updatedIssues = issues.filter(issue => issue.id !== issueId)
        setIssues(updatedIssues)
        const newFormState = new Map(issueFormState)
        newFormState.delete(issueId)
        setIssueFormState(newFormState)
        const newPreview = new Map(issuesPreview)
        newPreview.delete(issueId)
        setIssuesPreview(newPreview)
        const newSolved = new Map(solvedIssue)
        newSolved.set(issueId, true)
        setSolvedIssue(newSolved)
        const newApplying = new Map(applying)
        newApplying.delete(issueId)
        setApplying(newApplying)
        const newPreviewLoading = new Map(previewLoading)
        newPreviewLoading.delete(issueId)
        setPreviewLoading(newPreviewLoading)
        setCurrentIssueIndex(prev => Math.max(0, Math.min(prev, updatedIssues.length - 1)))
      })
      .catch(err => {
        console.error('Error saving accessibility issue. Error is: ' + err.message)
      })
      .finally(() => {
        const applyingMap = new Map(applying)
        applyingMap.set(issueId, false)
        setApplying(applyingMap)
        setIsLoading(false)
      })
  }

  if (isLoading) return renderLoading()

  return (
    <Flex as="div" direction="column" height="100vh" width="100%">
      <Flex.Item shouldGrow={true} as="main">
        <View
          as="div"
          padding="medium"
          elementRef={(el: Element | null) => {
            regionRef.current = el as HTMLDivElement | null
          }}
          aria-label={I18n.t('Accessibility Issues for %{title}', {title: item.title})}
        >
          <View>
            <Heading level="h2">{item.title}</Heading>
            <CloseButton
              placement="end"
              data-testid="close-button"
              margin="small"
              screenReaderLabel={I18n.t('Close')}
              onClick={onClose}
            />
          </View>
          <View margin="large 0">
            <Text size="large" as="h3">
              {I18n.t('Issue %{current}/%{total}: %{message}', {
                current: currentIssueIndex + 1,
                total: issues.length,
                message: ruleIdToLabelMap[currentIssue?.ruleId ?? ''] || '',
              })}
            </Text>
          </View>
          <Flex justifyItems="space-between">
            <Text weight="bold">{I18n.t('Preview')}</Text>
            <Flex gap="small">
              <Link href={item.url} variant="standalone">
                {I18n.t('Open Page')}
              </Link>
              <Link href={item.editUrl} variant="standalone">
                {I18n.t('Edit Page')}
              </Link>
            </Flex>
          </Flex>
          <View>
            {originalContentLoading ? (
              <Spinner renderTitle={I18n.t('Loading...')} size="small" />
            ) : (
              <View
                as="div"
                margin="x-small 0 medium"
                id="a11y-issue-preview"
                borderWidth="small"
                height="300px"
                overflowY="auto"
                dangerouslySetInnerHTML={{__html: applyHighlight(currentIssue)}}
              />
            )}
          </View>
          {currentIssue && (
            <>
              <View as="section" margin="medium 0">
                {currentIssue.message}
              </View>
              <View as="section" margin="medium 0">
                <AccessibilityIssueForm
                  issue={currentIssue}
                  issueFormState={issueFormState}
                  setIssueFormState={setIssueFormState}
                  handleFormChange={handleFormChange}
                />
              </View>
            </>
          )}
        </View>
      </Flex.Item>
      <Flex.Item as="footer">
        <AccessibilityIssuesDrawerFooter
          onNext={onNext}
          onBack={onPrevious}
          onSaveAndNext={onSaveAndNext}
          isBackDisabled={currentIssueIndex === 0}
          isNextDisabled={currentIssueIndex === issues.length - 1}
        />
      </Flex.Item>
    </Flex>
  )
}

export default AccessibilityIssuesDrawerContent
