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
import React, {useState} from 'react'
import {AccessibilityIssue, ContentItem, FormType, IssueForm} from '../../types'
import {SimpleSelect} from '@instructure/ui-simple-select'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {IconPublishSolid} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'

interface AccessibilityIssuesModalProps {
  isOpen: boolean
  onClose: (shallClose: boolean) => void
  item: ContentItem
}

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityIssuesModal: React.FC<AccessibilityIssuesModalProps> = ({
  isOpen,
  onClose,
  item,
}) => {
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

  const getIssueId = (issue: AccessibilityIssue, index: number): string => {
    return issue.id || `${item.type}-${item.id}-issue-${index}`
  }

  const handleApplyClick = (item: ContentItem, issue: AccessibilityIssue) => {
    const newState = new Map(applying)
    newState.set(issue.id, true)
    setApplying(newState)
    doFetchApi({
      path: window.location.href + '/issues',
      method: 'PUT',
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

  const createForm = (issueId: string, form: IssueForm): React.ReactNode => {
    if (!form) return <></>

    switch (form.type) {
      case FormType.Checkbox:
        return (
          <View as="div" margin="small 0">
            <Checkbox
              label={form.label}
              checked={issueFormState.get(issueId) === 'true'}
              onChange={() => {
                const newState = new Map(issueFormState)
                if (newState.get(issueId) === 'true') {
                  newState.set(issueId, 'false')
                } else {
                  newState.set(issueId, 'true')
                }
                setIssueFormState(newState)
              }}
            />
          </View>
        )

      case FormType.ColorPicker:
        return (
          <View as="div" margin="small 0">
            <Text weight="bold">{form.label}</Text>
          </View>
        )

      case FormType.TextInput:
        return (
          <View as="div" margin="small 0">
            <Text weight="bold">{form.label}</Text>
            <View as="div" margin="x-small 0 0 0">
              <TextInput
                display="inline-block"
                width="15rem"
                value={issueFormState.get(issueId) || ''}
                onChange={(_, value) => {
                  const newState = new Map(issueFormState)
                  newState.set(issueId, value)
                  setIssueFormState(newState)
                }}
              />
            </View>
          </View>
        )

      case FormType.DropDown:
        return (
          <SimpleSelect
            renderLabel={form.label}
            value={issueFormState.get(issueId) || ''}
            onChange={(_, {id, value}) => {
              const newState = new Map(issueFormState)
              if (value && typeof value === 'string') {
                newState.set(issueId, value)
              }
              setIssueFormState(newState)
            }}
          >
            {form.options?.map((option, index) => (
              <SimpleSelect.Option
                id={option}
                key={index}
                value={option}
                selected={form.value === option}
                disabled={form.value !== option}
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

  return (
    <Modal
      open={isOpen}
      onDismiss={() => onClose(shallReload)}
      size="medium"
      label={`${item.title} - ${I18n.t('Accessibility Issues')}`}
    >
      <Modal.Header>
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
      </Modal.Header>

      <Modal.Body>
        <View as="div" maxHeight="500px" overflowY="auto">
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
                    createForm(issue.id, issue.form)
                  )}
                  {issue.issueUrl !== '' ? (
                    <Link href={issue.issueUrl}>More information on this</Link>
                  ) : (
                    <></>
                  )}
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
                        <Button onClick={() => handleApplyClick(item, issue)}>
                          {I18n.t('Apply Fix')}
                        </Button>
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
      </Modal.Body>

      <Modal.Footer>
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
      </Modal.Footer>
    </Modal>
  )
}
