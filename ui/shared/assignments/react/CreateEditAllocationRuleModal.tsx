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

import React, {useState, useRef, useEffect, useMemo} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Button, CloseButton, CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormMessage} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconTrashLine, IconInfoLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {canvasHighContrast, canvas} from '@instructure/ui-themes'
import {View} from '@instructure/ui-view'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import StudentSelect from './StudentSelect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  CourseStudent,
  CreateAllocationRuleResponse,
  UpdateAllocationRuleResponse,
  AllocationRuleType,
} from '../graphql/teacher/AssignmentTeacherTypes'
import {useCreateAllocationRule} from '../graphql/hooks/useCreateAllocationRule'
import {useEditAllocationRule} from '../graphql/hooks/useEditAllocationRule'
import {formatFullRuleDescription} from './utils/formatRuleDescription'

const I18n = createI18nScope('peer_review_allocation_rule_card')
const baseTheme = ENV.use_high_contrast ? canvasHighContrast : canvas
const {colors: instui10Colors} = baseTheme

const TARGET_TYPES = {
  REVIEWER: 'reviewer',
  REVIEWEE: 'reviewee',
  RECIPROCAL: 'reciprocal',
}
const REQUIRED_REVIEW_TYPE = ['permit', 'prohibit']
const SUGGESTED_REVIEW_TYPE = ['should', 'should_not']

const CreateEditAllocationRuleModal = ({
  assignmentId,
  requiredPeerReviewsCount,
  setIsOpen,
  rule,
  refetchRules,
  isOpen = false,
  isEdit = false,
}: {
  assignmentId: string
  requiredPeerReviewsCount: number
  isOpen: boolean
  setIsOpen: (isOpen: boolean) => void
  refetchRules: (ruleId: string, isNewRule?: boolean, ruleDescription?: string) => void
  isEdit?: boolean
  rule?: AllocationRuleType
}): React.ReactElement => {
  const [targetType, setTargetType] = useState(
    rule
      ? rule.appliesToAssessor
        ? TARGET_TYPES.REVIEWER
        : TARGET_TYPES.REVIEWEE
      : TARGET_TYPES.REVIEWER,
  )
  const [permitReview, setPermitReview] = useState(rule?.reviewPermitted ?? true)
  const [mustReview, setMustReview] = useState(rule?.mustReview ?? true)

  const [target, setTarget] = useState(rule?.appliesToAssessor ? rule?.assessor : rule?.assessee)
  const [targetErrors, setTargetErrors] = useState<FormMessage[]>([])
  const targetSelectRef = useRef<HTMLElement | null>(null)

  const [subject, setSubject] = useState(rule?.appliesToAssessor ? rule?.assessee : rule?.assessor)
  const [subjectErrors, setSubjectErrors] = useState<FormMessage[]>([])
  const subjectSelectRef = useRef<HTMLElement | null>(null)

  const [additionalSubjects, setAdditionalSubjects] = useState<{[key: string]: CourseStudent}>({})
  const [additionalSubjectsErrors, setAdditionalSubjectsErrors] = useState<{
    [key: string]: FormMessage[]
  }>({})
  const [additionalSubjectSelectRefs, setAdditionalSubjectSelectRefs] = useState<{
    [key: string]: HTMLElement | null
  }>({})
  const [additionalSubjectCount, setAdditionalSubjectCount] = useState(0)
  const [showErrorAlert, setShowErrorAlert] = useState(false)
  const [shouldFocusNewField, setShouldFocusNewField] = useState(false)

  const createAllocationRuleMutation = useCreateAllocationRule(
    (data: CreateAllocationRuleResponse) => {
      const newRule = data.createAllocationRule.allocationRules[0]
      refetchRules(newRule._id, true, formatFullRuleDescription(newRule))
      handleClose()
    },
    (allocationErrors: any[]) => {
      let shouldFocus = true
      allocationErrors.forEach(error => {
        if (error.attributeId === target?._id) {
          setTargetErrors([{text: error.message, type: 'newError'}])
          if (shouldFocus) {
            targetSelectRef.current?.focus()
            shouldFocus = false
          }
        } else if (error.attributeId === subject?._id) {
          setSubjectErrors([{text: error.message, type: 'newError'}])
          if (shouldFocus) {
            subjectSelectRef.current?.focus()
            shouldFocus = false
          }
        } else if (error.attributeId) {
          const additionalSubjectKeys = Object.keys(additionalSubjects)
          additionalSubjectKeys.forEach(subjectKey => {
            if (error.attributeId === additionalSubjects[subjectKey]?._id) {
              setAdditionalSubjectsErrors(prev => ({
                ...prev,
                [subjectKey]: [{text: error.message, type: 'newError'}],
              }))
              if (shouldFocus) {
                additionalSubjectSelectRefs[subjectKey]?.focus()
                shouldFocus = false
              }
            }
          })
        } else {
          setShowErrorAlert(true)
        }
      })
    },
  )

  const editAllocationRuleMutation = useEditAllocationRule(
    (data: UpdateAllocationRuleResponse) => {
      const editedRule = data.updateAllocationRule.allocationRules.find(r => r._id === rule?._id)
      if (editedRule) {
        refetchRules(editedRule._id, false, formatFullRuleDescription(editedRule))
        handleClose(editedRule)
      }
    },
    (allocationErrors: any[]) => {
      let shouldFocus = true
      allocationErrors.forEach(error => {
        if (error.attributeId === target?._id) {
          setTargetErrors([{text: error.message, type: 'newError'}])
          if (shouldFocus) {
            targetSelectRef.current?.focus()
            shouldFocus = false
          }
        } else if (error.attributeId === subject?._id) {
          setSubjectErrors([{text: error.message, type: 'newError'}])
          if (shouldFocus) {
            subjectSelectRef.current?.focus()
            shouldFocus = false
          }
        } else if (error.attributeId) {
          const additionalSubjectKeys = Object.keys(additionalSubjects)
          additionalSubjectKeys.forEach(subjectKey => {
            if (error.attributeId === additionalSubjects[subjectKey]?._id) {
              setAdditionalSubjectsErrors(prev => ({
                ...prev,
                [subjectKey]: [{text: error.message, type: 'newError'}],
              }))
              if (shouldFocus) {
                additionalSubjectSelectRefs[subjectKey]?.focus()
                shouldFocus = false
              }
            }
          })
        } else {
          setShowErrorAlert(true)
        }
      })
    },
  )

  // Store original values for change detection in edit mode
  const originalValues = React.useMemo(() => {
    if (isEdit && rule) {
      return {
        targetType: rule.appliesToAssessor ? TARGET_TYPES.REVIEWER : TARGET_TYPES.REVIEWEE,
        permitReview: rule.reviewPermitted,
        mustReview: rule.mustReview,
        target: rule.appliesToAssessor ? rule.assessor : rule.assessee,
        subject: rule.appliesToAssessor ? rule.assessee : rule.assessor,
      }
    }
    return null
  }, [isEdit, rule])

  const hasChanges = () => {
    if (!isEdit || !originalValues) return true

    return (
      targetType !== originalValues.targetType ||
      permitReview !== originalValues.permitReview ||
      mustReview !== originalValues.mustReview ||
      target?._id !== originalValues.target?._id ||
      subject?._id !== originalValues.subject?._id ||
      Object.keys(additionalSubjects).length > 0
    )
  }

  const handleSave = () => {
    if (isEdit && !hasChanges()) {
      handleClose()
      return
    }

    let shouldFocus = true
    if (!target) {
      setTargetErrors([
        {
          type: 'newError',
          text:
            targetType === TARGET_TYPES.REVIEWEE
              ? I18n.t('Recipient is required')
              : I18n.t('Reviewer is required'),
        },
      ])
      if (shouldFocus) {
        targetSelectRef.current?.focus()
        shouldFocus = false
      }
    }

    if (!subject) {
      setSubjectErrors([
        {
          type: 'newError',
          text:
            targetType === TARGET_TYPES.REVIEWEE
              ? I18n.t('Reviewer is required')
              : I18n.t('Recipient is required'),
        },
      ])
      if (shouldFocus) {
        subjectSelectRef.current?.focus()
        shouldFocus = false
      }
    }
    const additionalSubjectKeys = Object.keys(additionalSubjects)
    if (additionalSubjectKeys.length > 0) {
      additionalSubjectKeys.forEach(subjectKey => {
        if (!additionalSubjects[subjectKey]._id) {
          setAdditionalSubjectsErrors(prev => ({
            ...prev,
            [subjectKey]: [
              {
                type: 'newError',
                text:
                  targetType === TARGET_TYPES.REVIEWEE
                    ? I18n.t('Reviewer is required')
                    : I18n.t('Recipient is required'),
              },
            ],
          }))
          if (shouldFocus) {
            additionalSubjectSelectRefs[subjectKey]?.focus()
            shouldFocus = false
          }
        }
      })
    }

    // shouldFocus is still true if no errors were found
    if (shouldFocus) {
      submitRule()
    }
  }

  const submitRule = () => {
    if (!assignmentId || !target || !subject) {
      return
    }

    const allSubjects = [subject, ...Object.values(additionalSubjects).filter(s => s._id)]
    const isReciprocal = targetType === TARGET_TYPES.RECIPROCAL
    const appliesToAssessor = targetType === TARGET_TYPES.REVIEWER

    let assessorIds: string[]
    let assesseeIds: string[]

    if (isReciprocal) {
      assessorIds = [target._id]
      assesseeIds = [subject._id]
    } else if (appliesToAssessor) {
      assessorIds = [target._id]
      assesseeIds = allSubjects.map(s => s._id)
    } else {
      assessorIds = allSubjects.map(s => s._id)
      assesseeIds = [target._id]
    }

    if (isEdit && rule) {
      const editInput = {
        ruleId: rule._id,
        assessorIds,
        assesseeIds,
        mustReview,
        reviewPermitted: permitReview,
        appliesToAssessor: isReciprocal ? true : appliesToAssessor,
        reciprocal: isReciprocal,
      }
      editAllocationRuleMutation.mutate(editInput)
    } else {
      const createInput = {
        assignmentId,
        assessorIds,
        assesseeIds,
        mustReview,
        reviewPermitted: permitReview,
        appliesToAssessor: isReciprocal ? true : appliesToAssessor,
        reciprocal: isReciprocal,
      }
      createAllocationRuleMutation.mutate(createInput)
    }
  }

  const clearErrors = (isSubject: boolean, subjectKey?: string) => {
    if (isSubject) {
      if (subjectKey) {
        setAdditionalSubjectsErrors(prev => ({
          ...prev,
          [subjectKey]: [],
        }))
      } else {
        setSubjectErrors([])
      }
    } else {
      setTargetErrors([])
    }
  }

  const clearAllErrors = (resetSubjectErrors = false) => {
    setTargetErrors([])
    setSubjectErrors([])
    if (resetSubjectErrors) {
      setAdditionalSubjectsErrors(prev => {
        const cleared: {[key: string]: FormMessage[]} = {}
        Object.keys(prev).forEach(key => {
          cleared[key] = []
        })
        return cleared
      })
    } else {
      setAdditionalSubjectsErrors({})
    }
  }

  const clearAdditionalSubjects = () => {
    setAdditionalSubjects({})
    setAdditionalSubjectSelectRefs({})
    setAdditionalSubjectCount(0)
  }

  const clearContents = () => {
    setTarget(undefined)
    setSubject(undefined)
    clearAdditionalSubjects()
  }

  const resetContents = (newRule?: AllocationRuleType) => {
    const ruleToUse = newRule ? newRule : rule
    if (ruleToUse) {
      setTarget(ruleToUse.appliesToAssessor ? ruleToUse.assessor : ruleToUse.assessee)
      setSubject(ruleToUse.appliesToAssessor ? ruleToUse.assessee : ruleToUse.assessor)
      clearAdditionalSubjects()
      setTargetType(ruleToUse.appliesToAssessor ? TARGET_TYPES.REVIEWER : TARGET_TYPES.REVIEWEE)
      setMustReview(ruleToUse.mustReview)
      setPermitReview(ruleToUse.reviewPermitted)
    }
  }

  const handleClose = (newRule?: AllocationRuleType) => {
    isEdit ? resetContents(newRule) : clearContents()
    clearAllErrors()
    setIsOpen(false)
  }

  const handleTargetSelection = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    clearAllErrors(true)
    if (value === TARGET_TYPES.RECIPROCAL) {
      if (additionalSubjectCount > 0) clearAdditionalSubjects()
    }
    setTargetType(value)
  }

  const getReviewType = () => {
    if (permitReview && mustReview) return 'permit'
    if (!permitReview && mustReview) return 'prohibit'
    if (permitReview && !mustReview) return 'should'
    return 'should_not'
  }

  const handleReviewTypeChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    clearAllErrors(true)
    switch (value) {
      case 'permit':
        setPermitReview(true)
        setMustReview(true)
        break
      case 'prohibit':
        setPermitReview(false)
        setMustReview(true)
        break
      case 'should':
        setMustReview(false)
        setPermitReview(true)
        break
      case 'should_not':
        setMustReview(false)
        setPermitReview(false)
        break
      default:
        break
    }
  }

  useEffect(() => {
    if (shouldFocusNewField && additionalSubjectSelectRefs[additionalSubjectCount]) {
      additionalSubjectSelectRefs[additionalSubjectCount]?.focus()
      setShouldFocusNewField(false)
    }
  }, [additionalSubjectSelectRefs, additionalSubjectCount, shouldFocusNewField])

  const additionalSubjectsKeys = useMemo(
    () =>
      Object.keys(additionalSubjects)
        .sort()
        .map(key => additionalSubjects[key]?._id || '')
        .join(','),
    [additionalSubjects],
  )

  useEffect(() => {
    if (target && targetType !== TARGET_TYPES.REVIEWEE) checkPeerReviewStatus(target)
  }, [target, targetType, mustReview, permitReview])

  useEffect(() => {
    if (targetType === TARGET_TYPES.REVIEWEE && subject) {
      checkPeerReviewStatus(subject, false)
    }
  }, [targetType, subject, mustReview, permitReview])

  useEffect(() => {
    if (targetType === TARGET_TYPES.REVIEWEE) {
      Object.keys(additionalSubjects).forEach(subjectKey => {
        if (additionalSubjects[subjectKey])
          checkPeerReviewStatus(additionalSubjects[subjectKey], false, subjectKey)
      })
    }
  }, [targetType, additionalSubjectsKeys, mustReview, permitReview])

  const handleAddSubjectField = () => {
    const newCount = additionalSubjectCount + 1
    setAdditionalSubjects(prev => ({
      ...prev,
      [newCount]: {
        id: '',
        name: '',
        peerReviewStatus: {mustReviewCount: 0, completedReviewsCount: 0},
      },
    }))
    setAdditionalSubjectCount(newCount)
    setShouldFocusNewField(true)
  }

  const handleRemoveSubjectField = (key: string, index: number) => {
    setAdditionalSubjects(prev => {
      const newSubjects = {...prev}
      delete newSubjects[key]
      return newSubjects
    })
    if (index === 0) {
      subjectSelectRef.current?.focus()
    } else {
      const keys = Object.keys(additionalSubjects)[index - 1]
      additionalSubjectSelectRefs[keys]?.focus()
    }
  }

  const deleteAdditionalSubjectLabel = (key: string) => {
    const name = additionalSubjects[key]?.name || ''
    if (name) {
      return I18n.t('Delete additional subject field: %{name}', {name: name})
    } else {
      return I18n.t('Delete additional empty subject field')
    }
  }

  const hintText = (hint: string, useIconMargin: boolean = false) => {
    return (
      <View
        as="div"
        width="100%"
        background="primary"
        borderRadius="medium"
        padding="small"
        margin="x-small 0 0 0"
        themeOverride={{
          backgroundPrimary: instui10Colors.dataVisualization.ocean12Primary,
        }}
        data-testid="peer-review-status-hint"
      >
        <Flex as="div" alignItems="center">
          <Flex
            as="div"
            alignItems="center"
            margin={useIconMargin ? 'xx-small xx-small x-large 0' : '0 xx-small 0 0'}
            themeOverride={{gapXLarge: '2.5rem'}}
          >
            <IconInfoLine />
          </Flex>
          <Text size="small">{hint}</Text>
        </Flex>
      </View>
    )
  }

  const getPeerReviewStatusMessages = (student: CourseStudent): FormMessage[] => {
    if (!student.peerReviewStatus) return []
    const {mustReviewCount, completedReviewsCount} = student.peerReviewStatus
    if (completedReviewsCount >= requiredPeerReviewsCount) {
      return [
        {
          type: 'hint',
          text: hintText(
            I18n.t('%{name} has already completed the required peer reviews.', {
              name: student.name,
            }),
          ),
        },
      ]
    } else if (
      mustReview &&
      (mustReviewCount >= requiredPeerReviewsCount ||
        completedReviewsCount + mustReviewCount >= requiredPeerReviewsCount)
    ) {
      return [
        {
          type: 'hint',
          text: hintText(
            I18n.t(
              '%{name} already has enough “must review” allocations to meet required peer reviews. Additional allocations will follow available submissions and precedence.',
              {name: student.name},
            ),
            true,
          ),
        },
      ]
    } else {
      return []
    }
  }

  const checkPeerReviewStatus = (
    student: CourseStudent,
    isTarget: boolean = true,
    subjectKey?: string,
  ) => {
    const peerReviewStatusErrors = getPeerReviewStatusMessages(student)
    if (peerReviewStatusErrors.length > 0) {
      if (isTarget) {
        setTargetErrors(peerReviewStatusErrors)
      } else if (subjectKey) {
        setAdditionalSubjectsErrors(prev => ({
          ...prev,
          [subjectKey]: peerReviewStatusErrors,
        }))
      } else {
        setSubjectErrors(peerReviewStatusErrors)
      }
    }
  }

  const handleSetSubject = (student?: CourseStudent, subjectKey?: string) => {
    if (!subjectKey) {
      setSubject(student)
    } else {
      if (student) {
        setAdditionalSubjects(prev => ({
          ...prev,
          [subjectKey]: student ?? ({} as CourseStudent),
        }))
      }
    }
  }

  const handleSetTarget = (student?: CourseStudent) => {
    setTarget(student)
  }

  const getFilterStudents = (isSubject: boolean, subjectKey?: string) => {
    const filterStudents = []
    if (target && isSubject) filterStudents.push(target)
    if (subject && (subjectKey || !isSubject)) filterStudents.push(subject)
    Object.keys(additionalSubjects).forEach(addSubjectKey => {
      if (addSubjectKey !== subjectKey) {
        if (additionalSubjects[addSubjectKey])
          filterStudents.push(additionalSubjects[addSubjectKey])
      }
    })
    return filterStudents
  }

  // index = -1 for the main subject select, otherwise it will be the index of additional subjects
  const renderSubjectSelect = (index = -1, subjectKey: string | undefined = undefined) => (
    <StudentSelect
      inputId={index === -1 ? 'subject-select-main' : `subject-select-${subjectKey}`}
      label={
        targetType === TARGET_TYPES.REVIEWEE ? I18n.t('Reviewer Name') : I18n.t('Recipient Name')
      }
      errors={index === -1 ? subjectErrors : (additionalSubjectsErrors[subjectKey || ''] ?? [])}
      selectedStudent={index === -1 ? subject : additionalSubjects[subjectKey || '']}
      assignmentId={assignmentId}
      filteredStudents={getFilterStudents(true, subjectKey)}
      onOptionSelect={student => handleSetSubject(student, subjectKey)}
      handleInputRef={ref => {
        if (index === -1) {
          if (subjectSelectRef) subjectSelectRef.current = ref
        } else if (subjectKey) {
          setAdditionalSubjectSelectRefs(prev => ({
            ...prev,
            [subjectKey]: ref,
          }))
        }
      }}
      clearErrors={() => clearErrors(true, subjectKey)}
    />
  )

  const reviewType = getReviewType()

  return (
    <Modal
      label={isEdit ? I18n.t('Edit Rule Modal') : I18n.t('Create Rule Modal')}
      open={isOpen}
      size="small"
      data-testid={isEdit ? 'edit-rule-modal' : 'create-rule-modal'}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          onClick={() => handleClose()}
          screenReaderLabel={I18n.t('Close')}
          data-testid="allocation-rule-modal-close-button"
        />
        <Heading level="h2">{isEdit ? I18n.t('Edit Rule') : I18n.t('Create Rule')}</Heading>
      </Modal.Header>
      <Modal.Body padding="medium small">
        <Flex direction="column">
          {showErrorAlert && (
            <Flex.Item padding="small">
              <Alert
                variant="error"
                renderCloseButtonLabel={
                  isEdit
                    ? I18n.t('Close error alert for edit allocation rule modal')
                    : I18n.t('Close error alert for create allocation rule modal')
                }
                variantScreenReaderLabel={I18n.t('Error, ')}
              >
                {isEdit
                  ? I18n.t('An error occurred while editing the rule')
                  : I18n.t('An error occurred while creating the rule')}
              </Alert>
            </Flex.Item>
          )}
          <Flex.Item padding="small">
            <RadioInputGroup
              onChange={handleTargetSelection}
              name="target"
              defaultValue={targetType ?? TARGET_TYPES.REVIEWER}
              description=""
              data-testid="target-type-radio-group"
            >
              <RadioInput
                key={TARGET_TYPES.REVIEWER}
                value={TARGET_TYPES.REVIEWER}
                label={I18n.t('Rule for a reviewer')}
                data-testid="target-type-reviewer"
              />
              <RadioInput
                key={TARGET_TYPES.REVIEWEE}
                value={TARGET_TYPES.REVIEWEE}
                label={I18n.t('Rule for recipient of a review')}
                data-testid="target-type-reviewee"
              />
              <RadioInput
                key={TARGET_TYPES.RECIPROCAL}
                value={TARGET_TYPES.RECIPROCAL}
                label={I18n.t('Reciprocal review')}
                data-testid="target-type-reciprocal"
              />
            </RadioInputGroup>
          </Flex.Item>
          <Flex.Item padding="small">
            <StudentSelect
              inputId={`target-select`}
              label={
                targetType === TARGET_TYPES.REVIEWEE
                  ? I18n.t('Recipient Name')
                  : I18n.t('Reviewer Name')
              }
              handleInputRef={ref => {
                if (targetSelectRef) targetSelectRef.current = ref
              }}
              errors={targetErrors}
              selectedStudent={target}
              assignmentId={assignmentId}
              filteredStudents={getFilterStudents(false)}
              onOptionSelect={handleSetTarget}
              clearErrors={() => clearErrors(false)}
            />
          </Flex.Item>
          <Flex.Item padding="small">
            <Flex direction="row">
              <Flex.Item
                margin={targetType !== TARGET_TYPES.REVIEWEE ? '0 medium 0 0' : '0 small 0 0'}
              >
                <RadioInputGroup
                  onChange={handleReviewTypeChange}
                  name="reviewPermitted"
                  value={REQUIRED_REVIEW_TYPE.includes(reviewType) ? reviewType : ''}
                  description=""
                  data-testid="required-review-type-group"
                >
                  <RadioInput
                    key={'permit'}
                    value={'permit'}
                    label={
                      targetType !== TARGET_TYPES.REVIEWEE
                        ? I18n.t('Must review')
                        : I18n.t('Must be reviewed by')
                    }
                    data-testid="review-type-must-review"
                  />
                  <RadioInput
                    key={'prohibit'}
                    value={'prohibit'}
                    label={
                      targetType !== TARGET_TYPES.REVIEWEE
                        ? I18n.t('Must not review')
                        : I18n.t('Must not be reviewed by')
                    }
                    data-testid="review-type-must-not-review"
                  />
                </RadioInputGroup>
              </Flex.Item>
              <Flex.Item>
                <RadioInputGroup
                  onChange={handleReviewTypeChange}
                  name="shouldReview"
                  value={SUGGESTED_REVIEW_TYPE.includes(reviewType) ? reviewType : ''}
                  description=""
                  data-testid="suggested-review-type-group"
                >
                  <RadioInput
                    key={'should'}
                    value={'should'}
                    label={
                      targetType !== TARGET_TYPES.REVIEWEE
                        ? I18n.t('Should review')
                        : I18n.t('Should be reviewed by')
                    }
                    data-testid="review-type-should-review"
                  />
                  <RadioInput
                    key={'should_not'}
                    value={'should_not'}
                    label={
                      targetType !== TARGET_TYPES.REVIEWEE
                        ? I18n.t('Should not review')
                        : I18n.t('Should not be reviewed by')
                    }
                    data-testid="review-type-should-not-review"
                  />
                </RadioInputGroup>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item padding="small">{renderSubjectSelect()}</Flex.Item>
          {Object.keys(additionalSubjects).length > 0 && (
            <Flex.Item padding="small">
              {Object.keys(additionalSubjects).map((key, index) => (
                <Flex
                  as="div"
                  direction="row"
                  justifyItems="space-between"
                  margin={index === 0 ? '0 0 small 0' : 'small 0'}
                  key={key}
                >
                  <Flex.Item key={key} margin="0 small 0 0" shouldGrow>
                    {renderSubjectSelect(index, key)}
                  </Flex.Item>
                  <Flex.Item
                    margin={additionalSubjectsErrors[key]?.length > 0 ? '0' : 'medium 0 0 0'}
                  >
                    <IconButton
                      data-testid={`delete-additional-subject-field-${key}-button`}
                      renderIcon={<IconTrashLine color="brand" />}
                      withBackground={false}
                      withBorder={false}
                      size="small"
                      screenReaderLabel={deleteAdditionalSubjectLabel(key)}
                      onClick={_event => handleRemoveSubjectField(key, index)}
                    />
                  </Flex.Item>
                </Flex>
              ))}
            </Flex.Item>
          )}
          {targetType !== TARGET_TYPES.RECIPROCAL &&
            Object.keys(additionalSubjectSelectRefs).length < 49 && (
              <Flex.Item padding="small">
                <CondensedButton
                  onClick={handleAddSubjectField}
                  aria-label={
                    targetType === TARGET_TYPES.REVIEWEE
                      ? I18n.t('Add another reviewer name')
                      : I18n.t('Add another recipient name')
                  }
                  data-testid="add-subject-button"
                >
                  {targetType === TARGET_TYPES.REVIEWEE
                    ? I18n.t('+ Add another reviewer name')
                    : I18n.t('+ Add another recipient name')}
                </CondensedButton>
              </Flex.Item>
            )}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button onClick={() => handleClose()} data-testid="cancel-button">
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button color="primary" onClick={handleSave} data-testid="save-button">
              {I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default CreateEditAllocationRuleModal
