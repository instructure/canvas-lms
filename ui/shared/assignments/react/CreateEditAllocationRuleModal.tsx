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

import React, {useState, useRef} from 'react'
import {AllocationRuleType} from './AllocationRuleCard'
import {Button, CloseButton, CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormMessage} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconTrashLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import StudentSelect from './StudentSelect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CourseStudent} from '../graphql/hooks/useAssignedStudents'

const I18n = createI18nScope('peer_review_allocation_rule_card')
const TARGET_TYPES = {
  REVIEWER: 'reviewer',
  REVIEWEE: 'reviewee',
  RECIPROCAL: 'reciprocal',
}
const REQUIRED_REVIEW_TYPE = ['permit', 'prohibit']
const SUGGESTED_REVIEW_TYPE = ['should', 'should_not']

const CreateEditAllocationRuleModal = ({
  assignmentId,
  courseId,
  setIsOpen,
  rule,
  isOpen = false,
  isEdit = false,
}: {
  assignmentId?: string
  courseId?: string
  isOpen: boolean
  setIsOpen: (isOpen: boolean) => void
  isEdit?: boolean
  rule?: AllocationRuleType
}): React.ReactElement => {
  const [targetType, setTargetType] = useState(
    rule
      ? rule.appliesToReviewer
        ? TARGET_TYPES.REVIEWER
        : TARGET_TYPES.REVIEWEE
      : TARGET_TYPES.REVIEWER,
  )
  const [permitReview, setPermitReview] = useState(rule?.reviewPermitted ?? true)
  const [mustReview, setMustReview] = useState(rule?.mustReview ?? true)

  const [target, setTarget] = useState(rule?.appliesToReviewer ? rule?.reviewer : rule?.reviewee)
  const [targetErrors, setTargetErrors] = useState<FormMessage[]>([])
  const targetSelectRef = useRef<HTMLElement | null>(null)

  const [subject, setSubject] = useState(rule?.reviewee)
  const [subjectErrors, setSubjectErrors] = useState<FormMessage[]>([])
  const subjectSelectRef = useRef<HTMLElement | null>(null)

  const [additionalSubjects, setAdditionalSubjects] = useState<{
    [key: string]: CourseStudent
  }>({})
  const [additionalSubjectsErrors, setAdditionalSubjectsErrors] = useState<{
    [key: string]: FormMessage[]
  }>({})
  const [additionalSubjectSelectRefs, setAdditionalSubjectSelectRefs] = useState<{
    [key: string]: HTMLElement | null
  }>({})
  const [additionalSubjectCount, setAdditionalSubjectCount] = useState(0)

  const handleSave = () => {
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
    // TODO: [EGG-1387] Implement submitting the rule to be saved
    handleClose()
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

  const clearAllErrors = () => {
    setTargetErrors([])
    setSubjectErrors([])
    setAdditionalSubjectsErrors(prev => {
      const cleared: {[key: string]: FormMessage[]} = {}
      Object.keys(prev).forEach(key => {
        cleared[key] = []
      })
      return cleared
    })
  }

  const clearContents = () => {
    setTarget(undefined)
    setSubject(undefined)
    setAdditionalSubjects({})
    setAdditionalSubjectSelectRefs({})
    setAdditionalSubjectCount(0)
  }

  const handleClose = () => {
    // TODO: [EGG-1387] Handle opening and reopening the modal after submitting is implemented
    clearContents()
    clearAllErrors()
    setIsOpen(false)
  }

  const handleTargetSelection = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    clearAllErrors()
    setTargetType(value)
  }

  const getReviewType = () => {
    if (permitReview && mustReview) return 'permit'
    if (!permitReview && mustReview) return 'prohibit'
    if (permitReview && !mustReview) return 'should'
    return 'should_not'
  }

  const handleReviewTypeChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
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

  const handleAddSubjectField = () => {
    const newCount = additionalSubjectCount + 1
    setAdditionalSubjects(prev => ({...prev, [newCount]: {id: '', name: ''}}))
    setAdditionalSubjectCount(newCount)
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

  const handleAddSubjectFieldClick = () => {
    handleAddSubjectField()
  }

  const getFilterStudents = (isSubject: boolean, subjectKey?: string) => {
    const filterStudents = new Set<CourseStudent>()
    if (target && isSubject) filterStudents.add(target)
    if (subject && (subjectKey || !isSubject)) filterStudents.add(subject)
    Object.keys(additionalSubjects).forEach(addSubjectKey => {
      if (addSubjectKey !== subjectKey) {
        if (additionalSubjects[addSubjectKey]) filterStudents.add(additionalSubjects[addSubjectKey])
      }
    })
    return filterStudents
  }

  // index = -1 for the main subject select, otherwise it will be the index of additional subjects
  const renderSubjectSelect = (index = -1, subjectKey: string | undefined = undefined) => (
    <StudentSelect
      label={
        targetType === TARGET_TYPES.REVIEWEE ? I18n.t('Reviewer Name') : I18n.t('Recipient Name')
      }
      errors={index === -1 ? subjectErrors : (additionalSubjectsErrors[subjectKey || ''] ?? [])}
      initialSelected={index === -1 ? subject : additionalSubjects[subjectKey || '']}
      assignmentId={assignmentId}
      courseId={courseId}
      filterStudents={getFilterStudents(true, subjectKey)}
      onOptionSelect={
        !subjectKey
          ? setSubject
          : (student: CourseStudent) => {
              setAdditionalSubjects(prev => ({
                ...prev,
                [subjectKey]: student,
              }))
            }
      }
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
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
          data-testid="close-button"
        />
        <Heading level="h2">{isEdit ? I18n.t('Edit Rule') : I18n.t('Create Rule')}</Heading>
      </Modal.Header>
      <Modal.Body padding="medium small">
        <Flex direction="column">
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
              label={
                targetType === TARGET_TYPES.REVIEWEE
                  ? I18n.t('Recipient Name')
                  : I18n.t('Reviewer Name')
              }
              handleInputRef={ref => {
                if (targetSelectRef) targetSelectRef.current = ref
              }}
              errors={targetErrors}
              initialSelected={target}
              assignmentId={assignmentId}
              courseId={courseId}
              filterStudents={getFilterStudents(false)}
              onOptionSelect={setTarget}
              clearErrors={() => clearErrors(false)}
            />
          </Flex.Item>
          <Flex.Item padding="small">
            <Flex direction="row">
              <Flex.Item margin="0 medium 0 0">
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
                    label={I18n.t('Must review')}
                    data-testid="review-type-must-review"
                  />
                  <RadioInput
                    key={'prohibit'}
                    value={'prohibit'}
                    label={I18n.t('Must not review')}
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
                    label={I18n.t('Should review')}
                    data-testid="review-type-should-review"
                  />
                  <RadioInput
                    key={'should_not'}
                    value={'should_not'}
                    label={I18n.t('Should not review')}
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
                  <Flex.Item margin={additionalSubjectsErrors[key] ? '0' : 'medium 0 0 0'}>
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
          <Flex.Item padding="small">
            <CondensedButton
              onClick={handleAddSubjectFieldClick}
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
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button onClick={handleClose} data-testid="cancel-button">
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
