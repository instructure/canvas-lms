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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import axios from 'axios'
import React, {useState} from 'react'
import {AccessibilityIssue, ContentItem, FormField} from '../../types'

interface AccessibilityIssuesModalProps {
  isOpen: boolean
  onClose: () => void
  item: ContentItem
  onApplyCorrection?: (
    issueId: string,
    ruleId: string,
    formData: Record<string, any>,
  ) => Promise<void>
}

/**
 * Modal component for displaying accessibility issues for a specific content item
 * Part of the resource isolation approach, ensuring issues from different content types
 * don't cross-contaminate each other
 */
export const AccessibilityIssuesModal: React.FC<AccessibilityIssuesModalProps> = ({
  isOpen,
  onClose,
  item,
  onApplyCorrection,
}) => {
  const I18n = createI18nScope('accessibility_checker')

  const [formData, setFormData] = useState<Record<string, Record<string, any>>>({})
  const [showForms, setShowForms] = useState<Record<string, boolean>>({})
  const [submitting, setSubmitting] = useState<Record<string, boolean>>({})
  const [success, setSuccess] = useState<Record<string, boolean>>({})

  const getResourcePrefix = (type: string, id: string): string => {
    return `${type}-${id}-`
  }

  const getIssueId = (issue: AccessibilityIssue, index: number): string => {
    return issue.id || `${getResourcePrefix(item.type, item.id)}issue-${index}`
  }

  const initializeFormData = (issue: AccessibilityIssue, index: number) => {
    const issueId = getIssueId(issue, index)
    const initialData: Record<string, any> = {}
    const formFields = issue.form || []

    if (formFields.length > 0) {
      formFields.forEach(field => {
        const dataKey = field.data_key
        const prefixPattern = new RegExp(`^(page|assignment|file)-${item.id}-`)
        const strippedKey = dataKey.replace(prefixPattern, '')

        const prefixedKey = `${getResourcePrefix(item.type, item.id)}${strippedKey}`

        if (issue.data && issue.data[strippedKey]) {
          initialData[prefixedKey] = issue.data[strippedKey]
        } else if (field.checkbox) {
          initialData[prefixedKey] = false
        } else {
          initialData[prefixedKey] = ''
        }
      })
    }
    setFormData(prev => {
      return structuredClone({
        ...prev,
        [issueId]: initialData,
      })
    })
  }

  const handleInputChange = (
    issueId: string,
    dataKey: string,
    value: string | boolean | number,
  ) => {
    const resourcePrefix = getResourcePrefix(item.type, item.id)
    const prefixPattern = new RegExp(`^(page|assignment|file)-${item.id}-`)
    const prefixedKey = prefixPattern.test(dataKey) ? dataKey : `${resourcePrefix}${dataKey}`

    setFormData(prev => {
      const newState = structuredClone(prev)
      if (!newState[issueId]) {
        newState[issueId] = {}
      }
      newState[issueId][prefixedKey] = value

      return newState
    })
  }

  const toggleCorrectionForm = (issueId: string) => {
    setShowForms(prev => ({
      ...prev,
      [issueId]: !prev[issueId],
    }))
  }

  const submitCorrection = async (issue: AccessibilityIssue, index: number) => {
    const issueId = getIssueId(issue, index)

    if (!issue.form || !formData[issueId]) return

    try {
      setSubmitting(prev => ({...prev, [issueId]: true}))
      const submissionData = structuredClone(formData[issueId])

      const resourcePrefix = getResourcePrefix(item.type, item.id)
      const prefixPattern = new RegExp(`^(page|assignment|file)-${item.id}-`)
      const finalData: Record<string, any> = {}
      Object.entries(submissionData).forEach(([key, value]) => {
        const prefixedKey = prefixPattern.test(key) ? key : `${resourcePrefix}${key}`
        finalData[prefixedKey] = value
      })

      if (onApplyCorrection) {
        await onApplyCorrection(issueId, issue.rule_id || '', finalData)
      } else {
        await axios.post(
          `/api/v1/courses/${item.id}/accessibility_correction/${item.type}/${item.id}/${issue.rule_id}`,
          {
            form_data: finalData,
          },
        )
      }

      setSuccess(prev =>
        structuredClone({
          ...prev,
          [issueId]: true,
        }),
      )

      setTimeout(() => {
        setShowForms(prev =>
          structuredClone({
            ...prev,
            [issueId]: false,
          }),
        )
        setSuccess(prev =>
          structuredClone({
            ...prev,
            [issueId]: false,
          }),
        )
      }, 2000)
    } catch (error) {
      console.error('Error applying correction:', error)
    } finally {
      setSubmitting(prev =>
        structuredClone({
          ...prev,
          [issueId]: false,
        }),
      )
    }
  }

  const renderFormField = (
    _issue: AccessibilityIssue,
    field: FormField,
    issueId: string,
    disabled: boolean,
  ) => {
    const resourcePrefix = getResourcePrefix(item.type, item.id)
    const prefixPattern = new RegExp(`^(page|assignment|file)-${item.id}-`)
    const dataKey = prefixPattern.test(field.data_key)
      ? field.data_key
      : `${resourcePrefix}${field.data_key}`
    const value = formData[issueId]?.[dataKey]
    const isFieldDisabled = disabled || submitting[issueId] || success[issueId]

    if (field.checkbox) {
      return (
        <View as="div" margin="small 0" key={field.data_key}>
          <Checkbox
            label={field.label}
            checked={!!value}
            onChange={(event: React.ChangeEvent<HTMLInputElement>) => {
              handleInputChange(issueId, field.data_key, event.target.checked)
            }}
            disabled={isFieldDisabled}
          />
        </View>
      )
    } else if (field.options && field.options.length > 0) {
      return (
        <View as="div" margin="small 0" key={field.data_key}>
          <SimpleSelect
            renderLabel={field.label}
            value={value || ''}
            onChange={(_event: any, data: any) => {
              handleInputChange(issueId, field.data_key, data.value)
            }}
            disabled={isFieldDisabled}
          >
            {field.options.map(option => (
              <SimpleSelect.Option key={option[0]} id={option[0]} value={option[0]}>
                {option[1]}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </View>
      )
    } else if (
      field.data_key.includes('color') ||
      field.data_key.includes('foreground') ||
      field.data_key.includes('background')
    ) {
      return (
        <View as="div" margin="small 0" key={field.data_key}>
          <TextInput
            renderLabel={field.label}
            value={value || ''}
            onChange={(_event: any, color: string) => {
              // Simple validation to ensure it's a valid hex color
              const hexColorRegex = /^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/
              if (hexColorRegex.test(color) || color === '') {
                handleInputChange(issueId, field.data_key, color)
              }
            }}
            placeholder={field.placeholder || '#000000'}
            disabled={isFieldDisabled}
            renderAfterInput={
              <View as="div" padding="0 small">
                <View
                  as="div"
                  width="1.5rem"
                  height="1.5rem"
                  background={value || '#FFFFFF'}
                  borderWidth="small"
                  borderColor="secondary"
                  borderRadius="small"
                />
              </View>
            }
          />
          <Text as="p" size="small">
            {I18n.t('Enter a hex color value (e.g., #RRGGBB or #RGB)')}
          </Text>
        </View>
      )
    } else {
      return (
        <View as="div" margin="small 0" key={field.data_key}>
          <TextInput
            renderLabel={field.label}
            value={value || ''}
            onChange={(_event: any, value: string) => {
              handleInputChange(issueId, field.data_key, value)
            }}
            placeholder={field.placeholder}
            disabled={isFieldDisabled}
          />
        </View>
      )
    }
  }

  const _renderCorrectionForm = (issue: AccessibilityIssue, index: number) => {
    const issueId = getIssueId(issue, index)

    if (showForms[issueId] && !formData[issueId] && issue.form) {
      initializeFormData(issue, index)
    }

    if (!issue.form || issue.form.length === 0) {
      return null
    }

    return (
      <ToggleDetails
        summary={I18n.t('Fix this issue')}
        expanded={showForms[issueId]}
        onToggle={() => toggleCorrectionForm(issueId)}
      >
        <View as="div" padding="small" background="secondary">
          <form>
            {issue.form.map(field => renderFormField(issue, field, issueId, !!submitting[issueId]))}

            <View as="div" margin="medium 0 0 0">
              <Button
                color="primary"
                onClick={() => submitCorrection(issue, index)}
                disabled={submitting[issueId]}
              >
                {submitting[issueId] ? (
                  <Spinner renderTitle={I18n.t('Applying fix')} size="x-small" />
                ) : success[issueId] ? (
                  I18n.t('Success!')
                ) : (
                  I18n.t('Apply Fix')
                )}
              </Button>
            </View>
          </form>
        </View>
      </ToggleDetails>
    )
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onClose}
      size="medium"
      label={`${item.name} - ${I18n.t('Accessibility Issues')}`}
    >
      <Modal.Header>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel={I18n.t('Close')} />
        <Heading level="h2">{item.name}</Heading>
        <Flex margin="small 0">
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
            item.issues.map((issue, index) =>
              (issue.severity || item.severity) === 'high' ? (
                <View
                  key={getIssueId(issue, index)}
                  as="div"
                  margin="0 0 medium 0"
                  padding="small"
                  borderWidth="0 0 0 medium"
                  borderColor="danger"
                  background="secondary"
                >
                  <Heading level="h3">{issue.message}</Heading>
                  <Text as="p">{issue.why}</Text>
                  {_renderCorrectionForm(issue, index)}
                </View>
              ) : (issue.severity || item.severity) === 'medium' ? (
                <View
                  key={getIssueId(issue, index)}
                  as="div"
                  margin="0 0 medium 0"
                  padding="small"
                  borderWidth="0 0 0 medium"
                  borderColor="primary"
                  background="secondary"
                >
                  <Heading level="h3">{issue.message}</Heading>
                  <Text as="p">{issue.why}</Text>
                  {_renderCorrectionForm(issue, index)}
                </View>
              ) : (
                <View
                  key={getIssueId(issue, index)}
                  as="div"
                  margin="0 0 medium 0"
                  padding="small"
                  borderWidth="0 0 0 medium"
                  borderColor="success"
                  background="secondary"
                >
                  <Heading level="h3">{issue.message}</Heading>
                  <Text as="p">{issue.why}</Text>
                  {_renderCorrectionForm(issue, index)}
                </View>
              ),
            )
          ) : (
            <Text as="p">{I18n.t('No issues found')}</Text>
          )}
        </View>
      </Modal.Body>

      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button onClick={onClose}>{I18n.t('Close')}</Button>
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
