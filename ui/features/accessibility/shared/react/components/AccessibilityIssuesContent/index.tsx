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
import {canvasThemeLocal} from '@instructure/ui-themes'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Tray} from '@instructure/ui-tray'
import {FormFieldMessage} from '@instructure/ui-form-field'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

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
import {PreviewHandle} from './Preview'
import SuccessView from './SuccessView'
import CloseRemediationView from './CloseRemediationView'
import WhyMattersPopover from './WhyMattersPopover'
import {ProblemArea} from './ProblemArea/ProblemArea'
import {useA11yTracking} from '../../hooks/useA11yTracking'
import UnsavedChangesModal from './UnsavedChangesModal'
import {WizardHeader} from './WizardHeader/WizardHeader'
import {WizardErrorBoundary} from './WizardErrorBoundary/WizardErrorBoundary'

const I18n = createI18nScope('accessibility_checker')

function renderSpinner() {
  return (
    <Flex as="div" height="100%" justifyItems="center" alignItems="center" width="100%">
      <Flex.Item>
        <Spinner renderTitle={I18n.t('Loading...')} size="large" margin="auto" />
      </Flex.Item>
    </Flex>
  )
}

export const AccessibilityWizard = () => {
  const [
    accessibilityScans,
    nextResource,
    filters,
    isCloseIssuesEnabled,
    issuesSummary,
    isGA2FeaturesEnabled,
    selectedScan,
    setSelectedScan,
    selectedIssue,
    selectedIssueIndex,
    setSelectedIssue,
    isTrayOpen,
    setIsTrayOpen,
  ] = useAccessibilityScansStore(
    useShallow(state => [
      state.accessibilityScans,
      state.nextResource,
      state.filters,
      state.isCloseIssuesEnabled,
      state.issuesSummary,
      state.isGA2FeaturesEnabled,
      state.selectedScan,
      state.setSelectedScan,
      state.selectedIssue,
      state.selectedIssueIndex,
      state.setSelectedIssue,
      state.isTrayOpen,
      state.setIsTrayOpen,
    ]),
  )

  // All other state hooks
  const [isRequestInFlight, setIsRequestInFlight] = useState(false)
  const [isRemediated, setIsRemediated] = useState<boolean>(false)
  const [isFormLocked, setIsFormLocked] = useState<boolean>(false)
  const [isGenerateLoading, setIsGenerateLoading] = useState<boolean>(false)
  const [assertiveAlertMessage, setAssertiveAlertMessage] = useState<string | null>(null)
  const [formError, setFormError] = useState<string | null>()
  const [isSaveButtonEnabled, setIsSaveButtonEnabled] = useState<boolean>(true)
  const issues = selectedScan?.issues || []
  const [allIssuesSkipped, setAllIssuesSkipped] = useState<boolean>(false)
  const [pendingModalAction, setPendingModalAction] = useState<(() => void) | null>(null)
  const previousActiveRef = useRef<number | undefined>()

  const {doFetchAccessibilityIssuesSummary} = useAccessibilityScansFetchUtils()
  const {trackA11yIssueEvent, trackA11yEvent} = useA11yTracking()

  // Helper to wrap actions with unsaved changes check
  const useModalCheck = (action: () => void) =>
    useCallback(() => {
      if (isGA2FeaturesEnabled && isRemediated) {
        setPendingModalAction(() => action)
      } else {
        action()
      }
    }, [action, isGA2FeaturesEnabled, isRemediated])

  const onClose = useCallback(() => {
    setSelectedScan(null)
    setIsTrayOpen(false)
  }, [setSelectedScan, setIsTrayOpen])

  const onDismiss = useModalCheck(onClose)

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

  // Executor functions (without unsaved check)
  const executeSkip = useCallback(() => {
    if (selectedIssue && selectedScan) {
      trackA11yIssueEvent('IssueSkipped', selectedScan.resourceType, selectedIssue.ruleId)
    }

    if (isCloseIssuesEnabled && selectedIssueIndex === issues.length - 1) {
      setAllIssuesSkipped(true)
    } else {
      setSelectedIssue(issues[Math.min(selectedIssueIndex + 1, issues.length - 1)])
    }
    setIsRemediated(false)
  }, [
    isCloseIssuesEnabled,
    selectedIssueIndex,
    issues.length,
    selectedIssue,
    selectedScan,
    trackA11yIssueEvent,
  ])

  const executeBack = useCallback(() => {
    setSelectedIssue(issues[Math.max(selectedIssueIndex - 1, 0)])
    setIsRemediated(false)
  }, [selectedIssueIndex, issues])

  const executeBackToStart = useCallback(() => {
    setAllIssuesSkipped(false)
    setSelectedIssue(issues[0])
    setIsRemediated(false)
  }, [issues])

  const handleSkip = useModalCheck(executeSkip)
  const handlePrevious = useModalCheck(executeBack)
  const handleBackToStart = useModalCheck(executeBackToStart)

  const handleNextResource = useCallback(() => {
    if (!nextResource) return
    const nextItem = nextResource.item
    if (!nextItem) return

    setSelectedScan(nextItem)
    setAllIssuesSkipped(false)

    if (accessibilityScans) {
      const newNextResource = getNextResource(accessibilityScans, nextItem)
      if (newNextResource) {
        setNextResource(newNextResource)
      }
    }
  }, [accessibilityScans, nextResource, setSelectedScan, setNextResource, getNextResource])

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
      if (!selectedScan) return

      const target = findById(accessibilityScans, selectedScan.id)

      if (!target) return

      const updated: AccessibilityResourceScan[] = replaceById(accessibilityScans, {
        ...target,
        issues: updatedIssues,
        issueCount: updatedIssues.length,
      })

      setAccessibilityScans(updated)
    },
    [accessibilityScans, selectedScan, setAccessibilityScans],
  )

  const handleSaveAndNext = useCallback(
    async (formValue: any) => {
      if (!selectedIssue) return
      if (!selectedScan) return

      trackA11yIssueEvent('IssueFixed', selectedScan.resourceType, selectedIssue.ruleId)

      try {
        setIsRequestInFlight(true)

        await doFetchApi({
          path: getCourseBasedPath(`/accessibility_issues/${selectedIssue.id}`),
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
          path: getResourceScanPath(selectedScan),
          method: 'POST',
        })

        const newScan = convertKeysToCamelCase(newScanResponse.json!) as AccessibilityResourceScan
        const newScanIssues = newScan.issues ?? []
        const hadIssuesBefore = issues.length > 0

        if (hadIssuesBefore && newScanIssues.length === 0) {
          const courseId = window.ENV.current_context?.id

          trackA11yEvent('ResourceRemediated', {
            resourceId: selectedScan.resourceId,
            courseId,
          })
        }

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
        setSelectedScan(newScan)
        setSelectedIssue(
          newScanIssues[Math.min(selectedIssueIndex, Math.max(0, newScanIssues.length - 1))],
        )
        doFetchAccessibilityIssuesSummary({filters})
      } catch (err: any) {
        console.error('Error saving accessibility issue. Error is: ' + err.message)
      } finally {
        setIsRequestInFlight(false)
      }
    },
    [
      selectedScan,
      formRef,
      selectedIssue,
      updateAccessibilityIssues,
      accessibilityScans,
      nextResource,
      getAccessibilityIssuesByItem,
      setAccessibilityScans,
      setNextResource,
      updateCountPropertyForItem,
      doFetchAccessibilityIssuesSummary,
      filters,
      trackA11yIssueEvent,
      trackA11yEvent,
    ],
  )

  const handleApplyAndSaveAndNext = useCallback(async () => {
    setIsFormLocked(true)
    const formValue = formRef.current?.getValue()

    return new Promise<void>((resolve, reject) => {
      previewRef.current?.update(
        formValue,
        async () => {
          setFormError(null)
          setIsRemediated(true)
          setIsFormLocked(false)
          await handleSaveAndNext(formValue)
          resolve()
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
          reject(error)
        },
      )
    })
  }, [handleSaveAndNext, formRef, previewRef])

  const handleModalConfirm = useCallback(async () => {
    setPendingModalAction(null) // Close modal

    if (pendingModalAction) {
      await handleApplyAndSaveAndNext()

      pendingModalAction()
    }
  }, [pendingModalAction, handleApplyAndSaveAndNext])

  const handleModalCancel = useCallback(() => {
    setPendingModalAction(null) // Close modal
    pendingModalAction?.() // Execute without saving
  }, [pendingModalAction])

  const handleModalClose = useCallback(() => {
    setPendingModalAction(null) // Just close, no execution
  }, [])

  const applyButtonText = useMemo(() => {
    const defaultApplyText = I18n.t('Apply')

    if (!selectedIssue) {
      return null
    }

    if (selectedIssue.form.type === FormType.Button) {
      return selectedIssue.form.label || defaultApplyText
    }

    return selectedIssue.form.action || defaultApplyText
  }, [selectedIssue])

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

      if (['small-text-contrast', 'large-text-contrast'].includes(selectedIssue?.ruleId ?? '')) {
        // Reset remediation state when color changes after being applied
        if (isRemediated) {
          setIsRemediated(false)
        }
      }
    },
    [selectedIssue, isRemediated],
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
    setIsRemediated(false)
    setIsFormLocked(false)
    setFormError(null)
    setIsSaveButtonEnabled(true)
  }, [selectedIssue])

  useEffect(() => {
    const previousActive = previousActiveRef.current
    const currentActive = issuesSummary?.active

    if (previousActive !== undefined && previousActive > 0 && currentActive === 0) {
      const courseId = window.ENV.current_context?.id
      trackA11yEvent('CourseRemediated', {courseId: courseId || 'unknown'})
    }

    previousActiveRef.current = currentActive
  }, [issuesSummary?.active, trackA11yEvent])

  const trayTitle = selectedScan?.resourceName ?? ''
  const isUnsavedModalOpen = pendingModalAction !== null

  const renderTrayContent = () => {
    if (!selectedScan) {
      return <Spinner renderTitle={I18n.t('Loading accessibility issues...')} />
    }

    if (allIssuesSkipped && isCloseIssuesEnabled) {
      return (
        <CloseRemediationView
          scan={selectedScan}
          onBack={handleBackToStart}
          nextResource={nextResource || defaultNextResource}
          onClose={onClose}
          handleNextResource={handleNextResource}
        />
      )
    }

    if (!selectedIssue) {
      return (
        <>
          <SuccessView
            title={selectedScan.resourceName}
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
        undoMessage={selectedIssue.form.undoText}
        isApplied={isRemediated}
        isLoading={isFormLocked}
        isDisabled={isGenerateLoading}
      >
        {applyButtonText}
      </ApplyButton>
    )

    return (
      <Flex as="div" direction="column" height="100%">
        <Flex.Item shouldGrow overflowY="auto" padding="0 small">
          <Flex direction="column" gap="large">
            <Flex direction="column" gap="mediumSmall">
              <Flex
                as="header"
                elementRef={(el: Element | null) => {
                  regionRef.current = el as HTMLDivElement | null
                }}
              >
                <Text
                  size="large"
                  variant="descriptionPage"
                  as="h3"
                  elementRef={(el: Element | null) => {
                    if (el instanceof HTMLElement) {
                      el.style.margin = '0'
                    }
                  }}
                >
                  {I18n.t('Issue %{current}/%{total}: %{message}', {
                    current: selectedIssueIndex + 1,
                    total: issues.length,
                    message: selectedIssue.displayName,
                  })}
                  <WhyMattersPopover issue={selectedIssue} />
                </Text>
              </Flex>

              <Flex gap="x-small" direction="column">
                <Flex justifyItems="space-between">
                  <Heading level="h4" variant="titleCardMini">
                    {I18n.t('Problem area')}
                  </Heading>
                  <Flex gap="small">
                    <Link
                      href={selectedScan?.resourceUrl}
                      variant="standalone"
                      target="_blank"
                      iconPlacement="end"
                      renderIcon={<IconExternalLinkLine size="x-small" />}
                      onClick={() =>
                        trackA11yIssueEvent(
                          'PageViewOpened',
                          selectedScan.resourceType,
                          selectedIssue.ruleId,
                        )
                      }
                    >
                      {I18n.t('Open Page')}
                      <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
                    </Link>
                    <Link
                      href={
                        selectedScan?.resourceType === 'Syllabus'
                          ? selectedScan.resourceUrl // Syllabus is edited inline, no separate edit page
                          : `${selectedScan.resourceUrl}/edit`
                      }
                      variant="standalone"
                      target="_blank"
                      iconPlacement="end"
                      renderIcon={<IconExternalLinkLine size="x-small" />}
                      onClick={() =>
                        trackA11yIssueEvent(
                          'PageEditorOpened',
                          selectedScan.resourceType,
                          selectedIssue.ruleId,
                        )
                      }
                    >
                      {I18n.t('Edit Page')}
                      <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
                    </Link>
                  </Flex>
                </Flex>

                <ProblemArea previewRef={previewRef} item={selectedScan} issue={selectedIssue} />
              </Flex>

              <Flex gap="x-small" direction="column">
                <Heading level="h4" variant="titleCardMini">
                  {I18n.t('Issue description')}
                </Heading>
                <Text weight="weightRegular">{selectedIssue.message}</Text>
              </Flex>
            </Flex>

            <Flex direction="column">
              <Form
                key={selectedIssue.id}
                ref={formRef}
                issue={selectedIssue}
                error={formError}
                onReload={updatePreview}
                onClearError={handleClearError}
                onValidationChange={handleValidationChange}
                isDisabled={isRemediated || isFormLocked}
                previewRef={previewRef}
                onGenerateLoadingChange={setIsGenerateLoading}
              />
              {selectedIssue.form.canGenerateFix &&
                formError &&
                selectedIssue.form.type === FormType.Button && (
                  <View as="div" margin="x-small 0">
                    <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
                  </View>
                )}
            </Flex>

            <View>
              {previewActionButton}
              {formError && selectedIssue.form.type === FormType.Button && (
                <View as="div" margin="x-small 0">
                  <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
                </View>
              )}
            </View>

            {/* Spacer for sticky footer */}
            <View></View>
          </Flex>
        </Flex.Item>

        <View as="div" position="sticky" insetBlockEnd="0" style={{zIndex: 10}}>
          <AccessibilityIssuesDrawerFooter
            nextButtonName={I18n.t('Save & Next')}
            onSkip={handleSkip}
            onBack={handlePrevious}
            onSaveAndNext={handleApplyAndSaveAndNext}
            onBackToStart={handleBackToStart}
            showBackToStart={
              !isCloseIssuesEnabled && selectedIssueIndex === issues.length - 1 && issues.length > 1
            }
            isBackToStartDisabled={isFormLocked}
            isBackDisabled={selectedIssueIndex === 0 || isFormLocked}
            isSkipDisabled={
              isFormLocked ||
              (issues.length === 1 && !isCloseIssuesEnabled && selectedIssueIndex === 0)
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
        {isGA2FeaturesEnabled && (
          <UnsavedChangesModal
            isOpen={isUnsavedModalOpen}
            onConfirm={handleModalConfirm}
            onCancel={handleModalCancel}
            onClose={handleModalClose}
          />
        )}
      </Flex>
    )
  }

  return (
    <Tray label={trayTitle} open={isTrayOpen} onDismiss={onDismiss} placement="end" size="regular">
      <View
        as="div"
        padding="0"
        position="absolute"
        insetBlockStart="0"
        insetBlockEnd="0"
        insetInlineStart="0"
        insetInlineEnd="0"
      >
        <Flex direction="column" width="100%" height="100%">
          <View
            as="div"
            position="sticky"
            insetBlockStart="0"
            padding="medium small mediumSmall small"
            elementRef={(el: Element | null) => {
              if (el instanceof HTMLElement) {
                el.style.zIndex = '10'
                el.style.background = canvasThemeLocal.colors.contrasts.white1010
                el.style.borderBottom = `1px solid ${canvasThemeLocal.colors.contrasts.grey1214}`
              }
            }}
          >
            <WizardHeader title={trayTitle} onDismiss={onDismiss} />
          </View>
          <View as="div" width="100%" height="100%">
            <WizardErrorBoundary>{renderTrayContent()}</WizardErrorBoundary>
          </View>
        </Flex>
      </View>
    </Tray>
  )
}

export default AccessibilityWizard
