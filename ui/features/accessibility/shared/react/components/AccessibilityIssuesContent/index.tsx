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

import {Ref, useCallback, useEffect, useRef, useState, useMemo} from 'react'
import {useDebouncedCallback} from 'use-debounce'
import {useShallow} from 'zustand/react/shallow'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {FormFieldMessage} from '@instructure/ui-form-field'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {useNextResource} from '../../hooks/useNextResource'
import {useAccessibilityCheckerContext} from '../../hooks/useAccessibilityCheckerContext'
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
import {PreviewHandle} from './Preview'
import SuccessView from './SuccessView'
import CloseRemediationView from './CloseRemediationView'
import WhyMattersPopover from './WhyMattersPopover'
import {ProblemArea} from './ProblemArea/ProblemArea'

const I18n = createI18nScope('accessibility_checker')

interface AccessibilityIssuesDrawerContentProps {
  item: AccessibilityResourceScan
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

const AccessibilityIssuesContent: React.FC<AccessibilityIssuesDrawerContentProps> = ({
  item,
  onClose,
}: AccessibilityIssuesDrawerContentProps) => {
  const [isRequestInFlight, setIsRequestInFlight] = useState(false)
  const [currentIssueIndex, setCurrentIssueIndex] = useState(0)
  const [isRemediated, setIsRemediated] = useState<boolean>(false)
  const [isFormLocked, setIsFormLocked] = useState<boolean>(false)
  const [isGenerateLoading, setIsGenerateLoading] = useState<boolean>(false)
  const [assertiveAlertMessage, setAssertiveAlertMessage] = useState<string | null>(null)
  const [formError, setFormError] = useState<string | null>()
  const [isSaveButtonEnabled, setIsSaveButtonEnabled] = useState<boolean>(true)
  const [issues, setIssues] = useState<AccessibilityIssue[]>(item.issues || [])
  const [allIssuesSkipped, setAllIssuesSkipped] = useState<boolean>(false)

  const {setSelectedItem} = useAccessibilityCheckerContext()
  const {doFetchAccessibilityIssuesSummary} = useAccessibilityScansFetchUtils()

  const [accessibilityScans, nextResource, filters, isCloseIssuesEnabled] =
    useAccessibilityScansStore(
      useShallow(state => [
        state.accessibilityScans,
        state.nextResource,
        state.filters,
        state.isCloseIssuesEnabled,
      ]),
    )

  const [setAccessibilityScans, setNextResource] = useAccessibilityScansStore(
    useShallow(state => [state.setAccessibilityScans, state.setNextResource]),
  )

  const {getNextResource, updateCountPropertyForItem, getAccessibilityIssuesByItem} =
    useNextResource()

  const previewRef: Ref<PreviewHandle> = useRef<PreviewHandle>(null)
  const formRef: Ref<FormHandle> = useRef<FormHandle>(null)
  const regionRef = useRef<HTMLDivElement | null>(null)

  const {currentIssue} = useMemo(
    () => ({
      currentIssue: issues.find((_, idx) => idx === currentIssueIndex),
    }),
    [currentIssueIndex, issues],
  )

  // This debounces the preview update to prevent excessive API calls when the user is typing.
  const updatePreview = useDebouncedCallback((formValue: FormValue) => {
    previewRef.current?.update(
      formValue,
      () => {
        setFormError(null)
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

  const handleSkip = useCallback(() => {
    if (isCloseIssuesEnabled && currentIssueIndex === issues.length - 1) {
      setAllIssuesSkipped(true)
    } else {
      setCurrentIssueIndex(prev => Math.min(prev + 1, issues.length - 1))
    }
  }, [isCloseIssuesEnabled, currentIssueIndex, issues.length])

  const handlePrevious = useCallback(() => {
    setCurrentIssueIndex(prev => Math.max(prev - 1, 0))
  }, [])

  const handleBackToStart = useCallback(() => {
    setAllIssuesSkipped(false)
    setCurrentIssueIndex(0)
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

  const handlePreviewApply = useCallback(() => {
    if (formError) {
      formRef.current?.focus()
      return
    }

    setIsFormLocked(true)
    const formValue = formRef.current?.getValue()
    previewRef.current?.update(
      formValue,
      () => {
        setFormError(null)
        setIsRemediated(true)
        setIsFormLocked(false)

        setTimeout(
          () => setAssertiveAlertMessage(I18n.t('Problem area updated with fixed version')),
          1500,
        )
      },
      error => {
        if (error) {
          setFormError(error)
          setAssertiveAlertMessage(error)
          // Needed avoid form disabled state + focus issue
          setTimeout(() => {
            formRef.current?.focus()
          }, 0)
        }
        setIsRemediated(false)
        setIsFormLocked(false)
      },
    )
  }, [formRef, previewRef])

  const handlePreviewUndo = useCallback(() => {
    setIsFormLocked(true)
    previewRef.current?.reload(
      () => {
        setFormError(null)
        setIsRemediated(false)
        setIsFormLocked(false)

        setTimeout(() => setAssertiveAlertMessage(I18n.t('Problem area fix undone')), 1500)
      },
      error => {
        if (error) {
          setFormError(error)
          setAssertiveAlertMessage(error)
        }
        setIsRemediated(true)
        setIsFormLocked(false)

        // Focus after state updates to ensure form is enabled
        if (error) {
          setTimeout(() => {
            formRef.current?.focus()
          }, 150)
        }
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
    if (!currentIssue) return

    try {
      const formValue = formRef.current?.getValue()

      setIsRequestInFlight(true)

      await doFetchApi({
        path: getCourseBasedPath(`/accessibility_issues/${currentIssue.id}`),
        method: 'PATCH',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
          workflow_state: IssueWorkflowState.Resolved,
          value: formValue,
        }),
      })

      setTimeout(() => {
        setAssertiveAlertMessage(I18n.t('Issue fix applied successfully'))
      }, 1500)

      const newScanResponse = await doFetchApi({
        path: getResourceScanPath(item),
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
    item,
    formRef,
    currentIssue,
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

        // Focus after state updates to ensure form is enabled
        if (error) {
          setTimeout(() => {
            formRef.current?.focus()
          }, 150)
        }
      },
    )
  }, [handleSaveAndNext, formRef, previewRef])

  const applyButtonText = useMemo(() => {
    const defaultApplyText = I18n.t('Apply')

    if (!currentIssue) {
      return null
    }

    if (currentIssue.form.type === FormType.Button) {
      return currentIssue.form.label || defaultApplyText
    }

    return currentIssue.form.action || defaultApplyText
  }, [currentIssue])

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

      if (['small-text-contrast', 'large-text-contrast'].includes(currentIssue?.ruleId ?? '')) {
        // Reset remediation state when color changes after being applied
        if (isRemediated) {
          setIsRemediated(false)
        }
      }
    },
    [currentIssue, isRemediated],
  )

  useEffect(() => {
    const timeout = setTimeout(() => {
      if (assertiveAlertMessage !== null) {
        setAssertiveAlertMessage(null)
      }
    }, 3000)

    return () => clearTimeout(timeout)
  }, [assertiveAlertMessage, setAssertiveAlertMessage])

  useEffect(() => {
    // issues are saved into local state, so the state does not update when "item" changes.
    // this effect ensures that issues state is updated on external "item" prop change.
    setIssues(item.issues || [])
    setCurrentIssueIndex(0)
  }, [item, setIssues, setCurrentIssueIndex])

  useEffect(() => {
    setIsRemediated(false)
    setIsFormLocked(false)
    setFormError(null)
    setIsSaveButtonEnabled(true)
  }, [currentIssue])

  if (allIssuesSkipped && isCloseIssuesEnabled) {
    return (
      <CloseRemediationView
        scan={item}
        onBack={handleBackToStart}
        nextResource={nextResource || defaultNextResource}
        onClose={onClose}
        handleNextResource={handleNextResource}
      />
    )
  }

  if (!currentIssue) {
    return (
      <>
        <SuccessView
          title={item.resourceName}
          nextResource={nextResource || defaultNextResource}
          onClose={onClose}
          handleSkip={handleSkip}
          handlePrevious={handlePrevious}
          handleNextResource={handleNextResource}
        />
        {assertiveAlertMessage && (
          <Alert
            screenReaderOnly={true}
            liveRegionPoliteness="assertive"
            liveRegion={getLiveRegion}
          >
            {assertiveAlertMessage}
          </Alert>
        )}
      </>
    )
  }

  if (isRequestInFlight) {
    return renderSpinner()
  }

  const previewActionButton = (
    <ApplyButton
      onApply={handlePreviewApply}
      onUndo={handlePreviewUndo}
      undoMessage={currentIssue.form.undoText}
      isApplied={isRemediated}
      isLoading={isFormLocked}
      isDisabled={isGenerateLoading}
    >
      {applyButtonText}
    </ApplyButton>
  )

  return (
    <Flex as="div" direction="column" height="100%" width="auto">
      <Flex.Item shouldGrow={true} overflowY="auto">
        <View position={'relative'} width="100%">
          <Flex as="div" direction="column" width="100%" margin="0 0 medium 0">
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
                    <Text size="large" variant="descriptionPage" as="h3">
                      {I18n.t('Issue %{current}/%{total}: %{message}', {
                        current: currentIssueIndex + 1,
                        total: issues.length,
                        message: currentIssue.displayName,
                      })}
                      <WhyMattersPopover issue={currentIssue} />
                    </Text>
                  </View>
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item padding="x-small small">
              <Flex padding="0 medium 0 0" gap="x-small" direction="column">
                <Flex justifyItems="space-between">
                  <Heading level="h4" variant="titleCardMini">
                    {I18n.t('Problem area')}
                  </Heading>
                  <Flex gap="small">
                    <Link
                      href={item.resourceUrl}
                      variant="standalone"
                      target="_blank"
                      iconPlacement="end"
                      renderIcon={<IconExternalLinkLine size="x-small" />}
                    >
                      {I18n.t('Open Page')}
                      <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
                    </Link>
                    <Link
                      href={`${item.resourceUrl}/edit`}
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

                <ProblemArea previewRef={previewRef} item={item} issue={currentIssue} />
              </Flex>

              <View as="section" margin="medium 0">
                <Heading level="h4" variant="titleCardMini">
                  {I18n.t('Issue description')}
                </Heading>
                <br aria-hidden={true} />
                <Text weight="weightRegular">{currentIssue.message}</Text>
              </View>

              <View as="section" margin="medium 0">
                <Form
                  key={currentIssue.id}
                  ref={formRef}
                  issue={currentIssue}
                  error={formError}
                  onReload={updatePreview}
                  onClearError={handleClearError}
                  onValidationChange={handleValidationChange}
                  isDisabled={isRemediated || isFormLocked}
                  actionButtons={currentIssue.form.canGenerateFix ? previewActionButton : undefined}
                  previewRef={previewRef}
                  onGenerateLoadingChange={setIsGenerateLoading}
                />
                {currentIssue.form.canGenerateFix &&
                  formError &&
                  currentIssue.form.type === FormType.Button && (
                    <View as="div" margin="x-small 0">
                      <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
                    </View>
                  )}
              </View>
              {!currentIssue.form.canGenerateFix && (
                <View as="section" margin="medium 0">
                  {previewActionButton}
                  {formError && currentIssue.form.type === FormType.Button && (
                    <View as="div" margin="x-small 0">
                      <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
                    </View>
                  )}
                </View>
              )}
            </Flex.Item>
          </Flex>
        </View>
      </Flex.Item>
      <View as="div" position="sticky" insetBlockEnd="0" style={{zIndex: 10}}>
        <AccessibilityIssuesDrawerFooter
          nextButtonName={I18n.t('Save & Next')}
          onSkip={handleSkip}
          onBack={handlePrevious}
          onSaveAndNext={handleApplyAndSaveAndNext}
          isBackDisabled={currentIssueIndex === 0 || isFormLocked}
          isSkipDisabled={
            isFormLocked || (!isCloseIssuesEnabled && currentIssueIndex === issues.length - 1)
          }
          isSaveAndNextDisabled={
            !isRemediated || isFormLocked || !!formError || !isSaveButtonEnabled
          }
        />
      </View>
      {assertiveAlertMessage && (
        <Alert
          isLiveRegionAtomic
          liveRegionPoliteness="assertive"
          liveRegion={getLiveRegion}
          screenReaderOnly={true}
        >
          {assertiveAlertMessage}
        </Alert>
      )}
    </Flex>
  )
}

export default AccessibilityIssuesContent
