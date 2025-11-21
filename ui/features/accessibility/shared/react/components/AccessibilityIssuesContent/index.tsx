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

import {Ref, useCallback, useEffect, useRef, useState, useContext, useMemo} from 'react'
import {useDebouncedCallback} from 'use-debounce'
import {useShallow} from 'zustand/react/shallow'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {FormFieldMessage} from '@instructure/ui-form-field'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {AccessibilityCheckerContext} from '../../contexts/AccessibilityCheckerContext'
import {useNextResource} from '../../hooks/useNextResource'
import {useAccessibilityScansFetchUtils} from '../../hooks/useAccessibilityScansFetchUtils'
import {
  useAccessibilityScansStore,
  defaultNextResource,
  NextResource,
} from '../../stores/AccessibilityScansStore'
import {
  AccessibilityIssue,
  AccessibilityResourceScan,
  FormType,
  FormValue,
  IssueWorkflowState,
} from '../../types'
import {convertKeysToCamelCase, findById, replaceById} from '../../utils/apiData'
import {getCourseBasedPath, getResourceScanPath} from '../../utils/query'
import ApplyButton from './ApplyButton'
import AccessibilityIssuesDrawerFooter from './Footer'
import Form, {FormHandle} from './Form'
import Preview, {PreviewHandle} from './Preview'
import SuccessView from './SuccessView'
import WhyMattersPopover from './WhyMattersPopover'

const I18n = createI18nScope('accessibility_checker')

interface AccessibilityIssuesDrawerContentProps {
  item: AccessibilityResourceScan
  onClose: () => void
  pageView?: boolean
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

const AccessibilityIssuesContent: React.FC<AccessibilityIssuesDrawerContentProps> = ({
  item,
  onClose,
  pageView = false,
}: AccessibilityIssuesDrawerContentProps) => {
  const [isRequestInFlight, setIsRequestInFlight] = useState(false)
  const [currentIssueIndex, setCurrentIssueIndex] = useState(0)
  const context = useContext(AccessibilityCheckerContext)
  const {setSelectedItem} = context
  const [issues, setIssues] = useState<AccessibilityIssue[]>(item.issues || [])
  const [isRemediated, setIsRemediated] = useState<boolean>(false)
  const [isFormLocked, setIsFormLocked] = useState<boolean>(false)
  const [assertiveAlertMessage, setAssertiveAlertMessage] = useState<string | null>(null)
  const [formError, setFormError] = useState<string | null>()
  const [isSaveButtonEnabled, setIsSaveButtonEnabled] = useState<boolean>(true)

  const {doFetchAccessibilityIssuesSummary} = useAccessibilityScansFetchUtils()
  const [accessibilityScans, nextResource, filters] = useAccessibilityScansStore(
    useShallow(state => [state.accessibilityScans, state.nextResource, state.filters]),
  )
  const [setAccessibilityScans, setNextResource] = useAccessibilityScansStore(
    useShallow(state => [state.setAccessibilityScans, state.setNextResource]),
  )

  const {getNextResource, updateCountPropertyForItem, getAccessibilityIssuesByItem} =
    useNextResource()

  const previewRef: Ref<PreviewHandle> = useRef<PreviewHandle>(null)
  const formRef: Ref<FormHandle> = useRef<FormHandle>(null)
  const regionRef = useRef<HTMLDivElement | null>(null)

  // This debounces the preview update to prevent excessive API calls when the user is typing.
  const updatePreview = useDebouncedCallback((formValue: FormValue) => {
    previewRef.current?.update(
      formValue,
      () => {
        setFormError(null)
        setAssertiveAlertMessage(null)
        setIsRemediated(true)
      },
      error => {
        if (error) {
          setFormError(error)
          setAssertiveAlertMessage(error)
        }
        setIsRemediated(false)
      },
    )
  }, 1000)
  const current = {resource: item, issues: issues, issue: issues[currentIssueIndex]}

  const isApplyButtonHidden = useMemo(
    () => [FormType.CheckboxTextInput].includes(current.issue?.form?.type),
    [current.issue],
  )

  const handleSkip = useCallback(() => {
    setCurrentIssueIndex(prev => Math.min(prev + 1, issues.length - 1))
  }, [issues.length])

  const handlePrevious = useCallback(() => {
    setCurrentIssueIndex(prev => Math.max(prev - 1, 0))
  }, [])

  const handleNextResource = useCallback(() => {
    if (!nextResource) return
    const nextItem = nextResource.item
    if (!nextItem) return

    setSelectedItem(nextItem)

    if (accessibilityScans) {
      const newNextResource = getNextResource(accessibilityScans, nextItem)
      if (newNextResource) {
        setNextResource(newNextResource)
      }
    }
  }, [accessibilityScans, nextResource, setSelectedItem, setNextResource, getNextResource])

  const handleApply = useCallback(() => {
    setIsFormLocked(true)
    const formValue = formRef.current?.getValue()
    previewRef.current?.update(
      formValue,
      () => {
        setFormError(null)
        setAssertiveAlertMessage(current.issue.form.undoText || I18n.t('Issue fixed'))
        setIsRemediated(true)
        setIsFormLocked(false)
      },
      error => {
        if (error) {
          formRef.current?.focus()
          setFormError(error)
          setAssertiveAlertMessage(error)
        }
        setIsRemediated(false)
        setIsFormLocked(false)
      },
    )
  }, [formRef, previewRef, current.issue])

  const handleUndo = useCallback(() => {
    setIsFormLocked(true)
    previewRef.current?.reload(
      () => {
        setFormError(null)
        setAssertiveAlertMessage(I18n.t('Issue undone'))
        setIsRemediated(false)
        setIsFormLocked(false)
      },
      error => {
        if (error) {
          formRef.current?.focus()
          setFormError(error)
          setAssertiveAlertMessage(error)
        }
        setIsRemediated(true)
        setIsFormLocked(false)
      },
    )
  }, [formRef, previewRef])

  const updateAccessibilityIssues = useCallback(
    (updatedIssues: AccessibilityIssue[]) => {
      if (!accessibilityScans) return

      const target = findById(accessibilityScans, item.id)

      if (!target) return

      const updated: AccessibilityResourceScan[] = replaceById(accessibilityScans, {
        ...target,
        issues: updatedIssues,
        issueCount: updatedIssues.length,
      })

      setAccessibilityScans(updated)
    },
    [accessibilityScans, item.id, setAccessibilityScans],
  )

  const handleSaveAndNext = useCallback(async () => {
    if (!current.issue) return

    try {
      const issueId = current.issue.id
      const formValue = formRef.current?.getValue()

      setIsRequestInFlight(true)

      await doFetchApi({
        path: getCourseBasedPath(`/accessibility_issues/${issueId}`),
        method: 'PATCH',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
          workflow_state: IssueWorkflowState.Resolved,
          value: formValue,
        }),
      })

      const newScanResponse = await doFetchApi({
        path: getResourceScanPath(current.resource),
        method: 'POST',
      })
      const newScan = convertKeysToCamelCase(newScanResponse.json!) as AccessibilityResourceScan
      const newScanIssues = newScan.issues ?? []

      setIssues(newScanIssues)

      if (accessibilityScans) {
        const updatedOrderedTableData = updateCountPropertyForItem(accessibilityScans, newScan)
        setAccessibilityScans(updatedOrderedTableData)
        if (nextResource) {
          const nextItem: AccessibilityResourceScan = accessibilityScans[nextResource.index]
          if (nextItem) {
            nextItem.issues = getAccessibilityIssuesByItem(accessibilityScans, nextItem)

            const updatedNextResource: NextResource = {index: nextResource.index, item: nextItem}
            setNextResource(updatedNextResource)
          }
        }
      }
      updateAccessibilityIssues(newScanIssues)
      setCurrentIssueIndex(prev => Math.min(prev, Math.max(0, newScanIssues.length - 1)))
      doFetchAccessibilityIssuesSummary({filters})
    } catch (err: any) {
      console.error('Error saving accessibility issue. Error is: ' + err.message)
    } finally {
      setIsRequestInFlight(false)
    }
  }, [
    formRef,
    current.issue,
    current.resource,
    updateAccessibilityIssues,
    accessibilityScans,
    nextResource,
    getAccessibilityIssuesByItem,
    setAccessibilityScans,
    setNextResource,
    updateCountPropertyForItem,
    doFetchAccessibilityIssuesSummary,
    filters,
  ])

  const handleApplyAndSaveAndNext = useCallback(() => {
    setIsFormLocked(true)
    const formValue = formRef.current?.getValue()
    previewRef.current?.update(
      formValue,
      () => {
        setFormError(null)
        setAssertiveAlertMessage(null)
        setIsRemediated(true)
        setIsFormLocked(false)
        handleSaveAndNext()
      },
      error => {
        if (error) {
          setFormError(error)
          setAssertiveAlertMessage(error)
        }
        setIsRemediated(false)
        setIsFormLocked(false)
      },
    )
  }, [handleSaveAndNext, formRef, previewRef])

  const applyButtonText = useMemo(() => {
    const defaultApplyText = I18n.t('Apply')

    if (!current.issue) {
      return null
    }

    if (current.issue.form.type === FormType.Button) {
      return current.issue.form.label || defaultApplyText
    }

    return current.issue.form.action || defaultApplyText
  }, [current.issue])

  const handleClearError = useCallback(() => {
    setFormError(null)
  }, [])

  const handleValidationChange = useCallback(
    (isValid: boolean, errorMessage?: string) => {
      setIsSaveButtonEnabled(isValid)
      if (!isValid) {
        setFormError(errorMessage)
      } else {
        setFormError(null)
      }
      if (['small-text-contrast', 'large-text-contrast'].includes(current.issue?.ruleId)) {
        // Reset remediation state when color changes after being applied
        if (isRemediated) {
          setIsRemediated(false)
        }
      }
    },
    [current.issue?.ruleId, isRemediated],
  )

  useEffect(() => {
    setIsRemediated(false)
    setIsFormLocked(false)
    setAssertiveAlertMessage(null)
    setFormError(null)
    setIsSaveButtonEnabled(true)
  }, [current.issue])

  if (!current.issue)
    return (
      <SuccessView
        title={current.resource.resourceName}
        nextResource={nextResource || defaultNextResource}
        onClose={onClose}
        handleSkip={handleSkip}
        handlePrevious={handlePrevious}
        handleNextResource={handleNextResource}
        assertiveAlertMessage={assertiveAlertMessage || ''}
        getLiveRegion={getLiveRegion}
      />
    )

  const applyButton = (
    <ApplyButton
      onApply={handleApply}
      onUndo={handleUndo}
      undoMessage={current.issue.form.undoText}
      isApplied={isRemediated}
      isLoading={isFormLocked}
    >
      {applyButtonText}
    </ApplyButton>
  )

  if (isRequestInFlight) return renderSpinner()

  return (
    <View position={'relative'} width={pageView ? '100%' : 'auto'} overflowY="auto">
      <Flex as="div" direction="column" height={pageView ? 'auto' : '100%'} width="100%">
        <Flex.Item
          as="header"
          padding="small small 0"
          elementRef={(el: Element | null) => {
            regionRef.current = el as HTMLDivElement | null
          }}
        >
          <Flex direction="column" gap="small">
            <Flex.Item>
              <View>
                <Heading level="h2" variant="titleCardRegular">
                  {current.resource.resourceName}
                </Heading>
              </View>
            </Flex.Item>
            <Flex.Item>
              <View>
                <Flex alignItems="center" gap="xx-small">
                  <Flex.Item>
                    <Text size="large" variant="descriptionPage" as="h3">
                      {I18n.t('Issue %{current}/%{total}: %{message}', {
                        current: currentIssueIndex + 1,
                        total: issues.length,
                        message: current.issue.displayName,
                      })}
                    </Text>
                  </Flex.Item>
                  <Flex.Item>
                    <WhyMattersPopover issue={current.issue} />
                  </Flex.Item>
                </Flex>
              </View>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item as="main" padding="x-small small" shouldGrow={true} overflowY="auto">
          <Flex justifyItems="space-between">
            <Text weight="weightImportant">{I18n.t('Problem area')}</Text>
            <Flex gap="small">
              <Link
                href={current.resource.resourceUrl}
                variant="standalone"
                target="_blank"
                iconPlacement="end"
                renderIcon={<IconExternalLinkLine size="x-small" />}
              >
                {I18n.t('Open Page')}
                <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
              </Link>
              <Link
                href={`${current.resource.resourceUrl}/edit`}
                variant="standalone"
                target="_blank"
                iconPlacement="end"
                renderIcon={<IconExternalLinkLine size="x-small" />}
              >
                {I18n.t('Edit Page')}
                <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
              </Link>
            </Flex>
          </Flex>
          <View as="div" margin="medium 0">
            <Preview
              ref={previewRef}
              issue={current.issue}
              resourceId={current.resource.resourceId}
              itemType={current.resource.resourceType}
            />
          </View>
          {current.issue.form.type !== FormType.ColorPicker && (
            <View as="section" margin="medium 0">
              <Text weight="weightImportant">{I18n.t('Issue description')}</Text>
              <br aria-hidden={true} />
              <Text weight="weightRegular">{current.issue.message}</Text>
            </View>
          )}
          <View as="section" margin="large 0 medium 0">
            <Form
              ref={formRef}
              issue={current.issue}
              error={formError}
              onReload={updatePreview}
              onClearError={handleClearError}
              onValidationChange={handleValidationChange}
              isDisabled={isRemediated}
              actionButtons={
                !isApplyButtonHidden && current.issue.form.canGenerateFix ? applyButton : undefined
              }
            />
            {!isApplyButtonHidden &&
              current.issue.form.canGenerateFix &&
              formError &&
              current.issue.form.type === FormType.Button && (
                <View as="div" margin="x-small 0">
                  <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
                </View>
              )}
          </View>
          {!isApplyButtonHidden && !current.issue.form.canGenerateFix && (
            <View as="section" margin="medium 0">
              {applyButton}
              {formError && current.issue.form.type === FormType.Button && (
                <View as="div" margin="x-small 0">
                  <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
                </View>
              )}
            </View>
          )}
        </Flex.Item>
      </Flex>
      <View as="div" position="sticky" insetBlockEnd="0" style={{zIndex: 10}}>
        <AccessibilityIssuesDrawerFooter
          nextButtonName={I18n.t('Save & Next')}
          onSkip={handleSkip}
          onBack={handlePrevious}
          onSaveAndNext={isApplyButtonHidden ? handleApplyAndSaveAndNext : handleSaveAndNext}
          isBackDisabled={currentIssueIndex === 0 || isFormLocked}
          isSkipDisabled={currentIssueIndex === issues.length - 1 || isFormLocked}
          isSaveAndNextDisabled={
            (!isRemediated && !isApplyButtonHidden) ||
            isFormLocked ||
            !!formError ||
            !isSaveButtonEnabled
          }
        />
      </View>
      <Alert screenReaderOnly={true} liveRegionPoliteness="assertive" liveRegion={getLiveRegion}>
        {assertiveAlertMessage || ''}
      </Alert>
    </View>
  )
}

export default AccessibilityIssuesContent
