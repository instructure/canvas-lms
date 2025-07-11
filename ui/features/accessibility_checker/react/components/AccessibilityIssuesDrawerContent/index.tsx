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

import React, {createRef, Ref, useCallback, useEffect, useRef, useState} from 'react'

import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {CloseButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'

import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useDebouncedCallback} from 'use-debounce'

import AccessibilityIssuesDrawerFooter from './Footer'
import Form, {FormHandle} from './Form'
import {AccessibilityIssue, ContentItem, FormType, FormValue} from '../../types'
import Preview, {PreviewHandle} from './Preview'
import WhyMattersPopover from './WhyMattersPopover'
import ApplyButton from './ApplyButton'

const I18n = createI18nScope('accessibility_checker')

interface AccessibilityIssuesDrawerContentProps {
  item: ContentItem
  onClose: () => void
}

function renderSpinner() {
  return (
    <Flex as="div" height="100%" justifyItems="center" alignItems="center" width="100%">
      <Flex.Item>
        <Spinner renderTitle={I18n.t('Loading...')} size="large" margin="auto" />
      </Flex.Item>
    </Flex>
  )
}

const AccessibilityIssuesDrawerContent: React.FC<AccessibilityIssuesDrawerContentProps> = ({
  item,
  onClose,
}: AccessibilityIssuesDrawerContentProps) => {
  const [isRequestInFlight, setIsRequestInFlight] = useState(false)
  const [currentIssueIndex, setCurrentIssueIndex] = useState(0)
  const [issues, setIssues] = useState<AccessibilityIssue[]>(item.issues || [])
  const [isRemediated, setIsRemediated] = useState<boolean>(false)
  const [isFormLocked, setIsFormLocked] = useState<boolean>(false)
  const [assertiveAlertMessage, setAssertiveAlertMessage] = useState<string>('')

  const previewRef: Ref<PreviewHandle> = useRef<PreviewHandle>(null)
  const formRef: Ref<FormHandle> = createRef<FormHandle>()
  const regionRef = useRef<HTMLDivElement | null>(null)

  // This debounces the preview update to prevent excessive API calls when the user is typing.
  const updatePreview = useDebouncedCallback((formValue: FormValue) => {
    previewRef.current?.update(formValue)
  }, 1000)
  const currentIssue = issues[currentIssueIndex]

  const handleNext = useCallback(() => {
    setCurrentIssueIndex(prev => Math.min(prev + 1, issues.length - 1))
  }, [issues.length])

  const handlePrevious = useCallback(() => {
    setCurrentIssueIndex(prev => Math.max(prev - 1, 0))
  }, [])

  const handleApply = useCallback(() => {
    setIsFormLocked(true)
    const formValue = formRef.current?.getValue()
    previewRef.current?.update(
      formValue,
      () => {
        setAssertiveAlertMessage(I18n.t('Issue fixed'))
        setIsRemediated(true)
        setIsFormLocked(false)
      },
      () => {
        setAssertiveAlertMessage(I18n.t('Error applying issue'))
        setIsRemediated(false)
        setIsFormLocked(false)
      },
    )
  }, [formRef, previewRef])

  const handleUndo = useCallback(() => {
    setIsFormLocked(true)
    const formValue = currentIssue.form.value
    previewRef.current?.update(
      formValue,
      () => {
        setAssertiveAlertMessage(I18n.t('Issue undone'))
        setIsRemediated(false)
        setIsFormLocked(false)
      },
      () => {
        setAssertiveAlertMessage(I18n.t('Error undoing issue'))
        setIsRemediated(true)
        setIsFormLocked(false)
      },
    )
  }, [currentIssue, previewRef])

  const handleSaveAndNext = useCallback(() => {
    if (!currentIssue) return

    const issueId = currentIssue.id
    const formValue = formRef.current?.getValue()

    setIsRequestInFlight(true)
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
        setCurrentIssueIndex(prev => Math.max(0, Math.min(prev, updatedIssues.length - 1)))
      })
      .catch(err => console.error('Error saving accessibility issue. Error is: ' + err.message))
      .finally(() => setIsRequestInFlight(false))
  }, [currentIssue, formRef, item.id, item.type, issues])

  useEffect(() => {
    setIsRemediated(false)
  }, [currentIssue])

  // TODO: This is a temporary fix to prevent the component from crashing when there are no issues.
  if (!currentIssue) return null

  if (isRequestInFlight) return renderSpinner()

  return (
    <>
      <Flex as="div" direction="column" height="100vh" width="100%">
        <Flex.Item
          as="header"
          padding="medium"
          elementRef={(el: Element | null) => {
            regionRef.current = el as HTMLDivElement | null
          }}
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
                message: currentIssue.displayName,
              })}{' '}
              <WhyMattersPopover issue={currentIssue} />
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item as="main" padding="x-small medium" shouldGrow={true}>
          <Flex justifyItems="space-between">
            <Text weight="weightImportant">{I18n.t('Problem area')}</Text>
            <Flex gap="small">
              <Link href={item.url} variant="standalone">
                {I18n.t('Open Page')}
              </Link>
              <Link href={item.editUrl} variant="standalone">
                {I18n.t('Edit Page')}
              </Link>
            </Flex>
          </Flex>
          <View as="div" margin="medium 0">
            <Preview ref={previewRef} issue={currentIssue} itemId={item.id} itemType={item.type} />
          </View>
          <View as="section" margin="medium 0">
            <Text weight="weightImportant">{I18n.t('Issue description')}</Text>
            <br aria-hidden={true} />
            <Text weight="weightRegular">{currentIssue.message}</Text>
          </View>
          <View as="section" margin="medium 0">
            <Form ref={formRef} issue={currentIssue} onReload={updatePreview} />
          </View>
          <View as="section" margin="medium 0">
            <ApplyButton
              onApply={handleApply}
              onUndo={handleUndo}
              isApplied={isRemediated}
              isLoading={isFormLocked}
            >
              {currentIssue.form.type === FormType.Checkbox ||
              currentIssue.form.type === FormType.Button
                ? currentIssue.form.label
                : I18n.t('Apply')}
            </ApplyButton>
          </View>
        </Flex.Item>
        <Flex.Item as="footer">
          <AccessibilityIssuesDrawerFooter
            onNext={handleNext}
            onBack={handlePrevious}
            onSaveAndNext={handleSaveAndNext || handleApply}
            isBackDisabled={currentIssueIndex === 0 || isFormLocked}
            isNextDisabled={currentIssueIndex === issues.length - 1 || isFormLocked}
            isSaveAndNextDisabled={!isRemediated || isFormLocked}
          />
        </Flex.Item>
      </Flex>
      <Alert screenReaderOnly={true} liveRegionPoliteness="assertive" liveRegion={getLiveRegion}>
        {assertiveAlertMessage}
      </Alert>
    </>
  )
}

export default AccessibilityIssuesDrawerContent
