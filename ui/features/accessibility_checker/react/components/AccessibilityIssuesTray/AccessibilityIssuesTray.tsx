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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import React, {useEffect, useState} from 'react'
import {AccessibilityIssue, ContentItem, FormType, PreviewResponse} from '../../types'
import {SimpleSelect} from '@instructure/ui-simple-select'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {IconPublishSolid} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import {ToggleDetails} from '@instructure/ui-toggle-details'

interface AccessibilityIssuesTrayProps {
  onClose: (shallClose: boolean) => void
  item: ContentItem
}

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityIssuesTray: React.FC<AccessibilityIssuesTrayProps> = ({
  onClose,
  item,
}) => {
  const [originalContentLoading, setOriginalContentLoading] = useState(true)
  const [originalContent, setOriginalContent] = useState(I18n.t('Loading content...'))
  useEffect(() => {
    const params = new URLSearchParams({
      content_type: item.type,
      content_id: String(item.id),
    })

    doFetchApi({
      path: `${window.location.href}/preview?${params.toString()}`,
      method: 'GET',
    })
      .then(result => {
        return result.json
      })
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

  useEffect(() => {
    setIssuesPreview(
      new Map<string, PreviewResponse>(
        item.issues?.map(issue => {
          return [issue.id, {content: originalContent, path: issue.path}]
        }) || [],
      ),
    )
  }, [originalContent, item.issues])

  const [shallReload, setShallReload] = useState(false)

  const [solvedIssue, setSolvedIssue] = useState(
    new Map(
      item.issues?.map(issue => {
        return [issue.id, false]
      }),
    ),
  )
  const [issueFormState, setIssueFormState] = useState(
    new Map(
      item.issues?.map(issue => {
        return [issue.id, issue.form?.value]
      }) || [],
    ),
  )
  const [applying, setApplying] = useState(
    new Map(
      item.issues?.map(issue => {
        return [issue.id, false]
      }) || [],
    ),
  )
  const [previewLoading, setPreviewLoading] = useState(
    new Map(
      item.issues?.map(issue => {
        return [issue.id, false]
      }) || [],
    ),
  )
  const [issuesPreview, setIssuesPreview] = useState(
    new Map<string, PreviewResponse>(
      item.issues?.map(issue => {
        return [issue.id, {content: originalContent, path: issue.path}]
      }) || [],
    ),
  )

  const getIssueId = (issue: AccessibilityIssue, index: number): string => {
    return issue.id || `${item.type}-${item.id}-issue-${index}`
  }

  const handleApplyClick = (issue: AccessibilityIssue) => {
    const newState = new Map(applying)
    newState.set(issue.id, true)
    setApplying(newState)
    doFetchApi({
      path: window.location.href + '/issues',
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        content_type: item.type,
        content_id: item.id,
        rule: issue.ruleId,
        path: issue.path,
        value: issueFormState.get(issue.id),
      }),
    })
      .then(_ => {
        const newState = new Map(solvedIssue)
        newState.set(issue.id, true)
        setSolvedIssue(newState)
      })
      .catch(err => {
        console.error('Error applying accessibility issues. Error is:' + err.message)
      })
      .finally(() => {
        const newState = new Map(applying)
        newState.set(issue.id, false)
        setApplying(newState)
        setShallReload(true)
      })
  }

  const handleFormChange = (issue: AccessibilityIssue, formValue: string) => {
    const newState = new Map(previewLoading)
    newState.set(issue.id, true)
    setPreviewLoading(newState)
    doFetchApi({
      path: window.location.href + '/preview',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
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

  const createForm = (issue: AccessibilityIssue): React.ReactNode => {
    if (!issue || !issue.form) return <></>

    switch (issue.form.type) {
      case FormType.Checkbox:
        return (
          <View as="div" margin="small 0">
            <Checkbox
              label={issue.form.label}
              checked={issueFormState.get(issue.id) === 'true'}
              onChange={() => {
                const newState = new Map(issueFormState)
                if (newState.get(issue.id) === 'true') {
                  newState.set(issue.id, 'false')
                } else {
                  newState.set(issue.id, 'true')
                }
                setIssueFormState(newState)
                handleFormChange(issue, newState.get(issue.id) || 'false')
              }}
            />
          </View>
        )

      case FormType.ColorPicker:
        return (
          <View as="div" margin="small 0">
            <Text weight="bold">{issue.form.label}</Text>
          </View>
        )

      case FormType.TextInput:
        return (
          <View as="div" margin="small 0">
            <Text weight="bold">{issue.form.label}</Text>
            <View as="div" margin="x-small 0 0 0">
              <TextInput
                display="inline-block"
                width="15rem"
                value={issueFormState.get(issue.id) || ''}
                onChange={(_, value) => {
                  const newState = new Map(issueFormState)
                  newState.set(issue.id, value)
                  setIssueFormState(newState)
                  handleFormChange(issue, value)
                }}
              />
            </View>
          </View>
        )

      case FormType.DropDown:
        return (
          <SimpleSelect
            renderLabel={issue.form.label}
            value={issueFormState.get(issue.id) || ''}
            onChange={(_, {id, value}) => {
              const newState = new Map(issueFormState)
              if (value && typeof value === 'string') {
                newState.set(issue.id, value)
              }
              setIssueFormState(newState)
              handleFormChange(issue, value as string)
            }}
          >
            {issue.form.options?.map((option, index) => (
              <SimpleSelect.Option
                id={option}
                key={index}
                value={option}
                selected={issue.form.value === option}
                disabled={issue.form.value !== option}
              >
                {option}
              </SimpleSelect.Option>
            )) || <></>}
          </SimpleSelect>
        )

      default:
        return <></>
    }
  }

  const SELECTOR_STYLE = 'outline:2px solid #273540; outline-offset:2px;'
  const A11Y_ISSUE_ATTR_NAME = 'data-a11y-issue-scroll-target'

  const applyHighlight = (issue: AccessibilityIssue) => {
    const issuePreview = issuesPreview.get(issue.id) || {content: originalContent, path: issue.path}
    const parser = new DOMParser()
    const doc = parser.parseFromString(issuePreview.content, 'text/html')
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

    return doc.body.innerHTML
  }

  const scrollIssueIntoView = (selector: string) => {
    return (_: React.MouseEvent, expanded: boolean) => {
      if (expanded) {
        setTimeout(() => {
          document
            .querySelector(`[${A11Y_ISSUE_ATTR_NAME}="${encodeURIComponent(selector)}"]`)
            ?.scrollIntoView({
              behavior: 'smooth',
              block: 'center',
              inline: 'nearest',
            })
        }, 0)
      }
    }
  }

  return (
    <View as="div" padding="medium">
      <View>
        <CloseButton
          placement="end"
          onClick={() => onClose(shallReload)}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading level="h2">{item.title}</Heading>
        <Flex margin="small 0" direction="column">
          <Flex.Item shouldGrow>
            <Alert variant="warning" margin="small">
              {I18n.t(
                'Pressing "Apply Fix" for any issue below will modify the content instantly.',
              )}
            </Alert>
          </Flex.Item>
          <Flex.Item padding="0 small 0 0">
            <Text weight="bold">
              {I18n.t(
                {
                  one: '1 accessibility issue found',
                  other: '%{count} accessibility issues found',
                },
                {count: item.count},
              )}
            </Text>
          </Flex.Item>
        </Flex>
      </View>

      <View>
        {item.issues && item.issues.length > 0 ? (
          item.issues.map((issue, index) => {
            return (
              <View
                key={getIssueId(issue, index)}
                as="div"
                margin="0 0 medium 0"
                padding="small"
                borderWidth="0 0 0 medium"
                borderColor={solvedIssue.get(issue.id) ? 'success' : 'danger'}
                background="secondary"
              >
                <Heading level="h3">{issue.message}</Heading>
                <Text as="p">{issue.why}</Text>
                {solvedIssue.get(issue.id) ? (
                  <Flex direction="row" justifyItems="end">
                    <Flex.Item margin="small">
                      <IconPublishSolid color="success" />
                    </Flex.Item>
                    <Flex.Item>
                      <Text>{I18n.t('Applied')}</Text>
                    </Flex.Item>
                  </Flex>
                ) : (
                  createForm(issue)
                )}
                {issue.issueUrl !== '' ? (
                  <Link href={issue.issueUrl}>More information on this</Link>
                ) : (
                  <></>
                )}

                <Flex.Item padding="x-small 0 x-small x-small">
                  {solvedIssue.get(issue.id) ? (
                    <></>
                  ) : (
                    <ToggleDetails summary="Preview fix" onToggle={scrollIssueIntoView(issue.path)}>
                      {originalContentLoading && previewLoading.get(issue.id) ? (
                        <Spinner renderTitle="Loading..." size="small" />
                      ) : (
                        <View
                          as="div"
                          padding="0 x-small 0 x-small"
                          id={`a11y-issue-preview-${index}`}
                          borderColor="neutral"
                          maxHeight="300px"
                          overflowY="auto"
                          dangerouslySetInnerHTML={{__html: applyHighlight(issue)}}
                        />
                      )}
                    </ToggleDetails>
                  )}
                </Flex.Item>

                <Flex direction="row" justifyItems="end">
                  {applying.get(issue.id) === true ? (
                    <Flex.Item>
                      <Spinner renderTitle="Loading" size="x-small" />
                    </Flex.Item>
                  ) : (
                    <></>
                  )}
                  <Flex.Item margin="0 small 0 0">
                    {solvedIssue.get(issue.id) ? (
                      <></>
                    ) : (
                      <Button onClick={() => handleApplyClick(issue)}>{I18n.t('Apply Fix')}</Button>
                    )}
                  </Flex.Item>
                </Flex>
              </View>
            )
          })
        ) : (
          <Text as="p">{I18n.t('No issues found')}</Text>
        )}
      </View>
      <View margin="0 medium">
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button onClick={() => onClose(shallReload)}>{I18n.t('Close')}</Button>
          </Flex.Item>
          <Flex.Item>
            <Button color="primary" href={item.editUrl}>
              {I18n.t('Edit content')}
            </Button>
          </Flex.Item>
        </Flex>
      </View>
    </View>
  )
}
