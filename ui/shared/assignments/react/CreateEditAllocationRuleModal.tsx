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

import React, {useState, useRef, useEffect} from 'react'
import {AllocationRuleType, PeerReviewStudentType} from './AllocationRuleCard'
import {Button, CloseButton, CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormMessage} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconTrashLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Select} from '@instructure/ui-select'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('peer_review_allocation_rule_card')
const TARGET_TYPES = {
  REVIEWER: 'reviewer',
  REVIEWEE: 'reviewee',
  RECIPROCAL: 'reciprocal',
}
const REQUIRED_REVIEW_TYPE = ['permit', 'prohibit']
const SUGGESTED_REVIEW_TYPE = ['should', 'should_not']

const CreateEditAllocationRuleModal = ({
  setIsOpen,
  rule,
  isOpen = false,
  isEdit = false,
}: {
  isOpen: boolean
  setIsOpen: (isOpen: boolean) => void
  isEdit?: boolean
  rule?: AllocationRuleType
}): React.ReactElement => {
  const [assignedStudents, setAssignedStudents] = useState<PeerReviewStudentType[]>([])
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
  const [targetSearch, setTargetSearch] = useState(
    (targetType === TARGET_TYPES.REVIEWEE ? rule?.reviewee?.name : rule?.reviewer?.name) || '',
  )
  const [showTargetOptions, setShowTargetOptions] = useState(false)
  const [targetErrors, setTargetErrors] = useState<FormMessage[]>([])
  const [subject, setSubject] = useState(rule?.reviewee)
  const [additionalSubjects, setAdditionalSubjects] = useState<{
    [key: string]: PeerReviewStudentType
  }>({})
  const [subjectErrors, setSubjectErrors] = useState<FormMessage[]>([])
  const [additionalSubjectsErrors, setAdditionalSubjectsErrors] = useState<{
    [key: string]: FormMessage[]
  }>({})
  const [subjectSearch, setSubjectSearch] = useState(
    (targetType === TARGET_TYPES.REVIEWEE ? rule?.reviewer?.name : rule?.reviewee?.name) || '',
  )
  const [additionalSubjectSearch, setAdditionalSubjectSearch] = useState<{[key: string]: string}>(
    {},
  )
  const [showSubjectOptions, setShowSubjectOptions] = useState(false)
  const [showAdditionalSubjectOptions, setShowAdditionalSubjectOptions] = useState<{
    [key: string]: boolean
  }>({})
  const [additionalSubjectCount, setAdditionalSubjectCount] = useState(0)

  const targetSelectRef = useRef<HTMLElement | null>(null)
  const subjectSelectRef = useRef<HTMLElement | null>(null)
  const [additionalSubjectSelectRefs, setAdditionalSubjectSelectRefs] = useState<{
    [key: string]: HTMLElement | null
  }>({})

  useEffect(() => {
    // TODO: [EGG-1386] Replace with actual data fetching logic
    const fetchAssignedStudents = async () => {
      const students: PeerReviewStudentType[] = [
        {id: '1', name: 'Student 1'},
        {id: '2', name: 'Student 2'},
        {id: '3', name: 'Student 3'},
      ]
      setAssignedStudents(students)
    }
    fetchAssignedStudents()
  }, [])

  const renderStudentOption = (
    student: PeerReviewStudentType,
    isTargetOption: boolean,
    subjectKey?: string,
  ) => {
    const filterStudents = []
    if (isTargetOption) {
      filterStudents.push(subject)
    } else if (subjectKey) {
      filterStudents.push(target)
      filterStudents.push(subject)
    } else {
      filterStudents.push(target)
    }

    Object.keys(additionalSubjects).forEach(addSubjectKey => {
      if (addSubjectKey !== subjectKey) {
        filterStudents.push(additionalSubjects[addSubjectKey])
      }
    })

    filterStudents.push(...Object.values(additionalSubjects))
    if (!filterStudents.some(s => s?.id === student.id)) {
      const id = `${isTargetOption ? 'target' : 'subject'}-${student.id}`
      return (
        <Select.Option id={id} key={id}>
          {student.name}
        </Select.Option>
      )
    }
  }

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
        if (!additionalSubjects[subjectKey].id) {
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

  const clearErrors = () => {
    setTargetErrors([])
    setSubjectErrors([])
  }

  const handleClose = () => {
    // TODO: [EGG-1387] Handle opening and reopening the modal after submitting is implemented
    clearErrors()
    setIsOpen(false)
  }

  const handleInputChange = (value: string, isTarget: boolean, subjectKey?: string) => {
    if (isTarget) {
      setTarget(undefined)
      setTargetSearch(value.trim())
      setShowTargetOptions(true)
      setTargetErrors([])
    } else {
      if (subjectKey) {
        setAdditionalSubjects({...additionalSubjects, [subjectKey]: {id: '', name: ''}})
        setAdditionalSubjectSearch({...additionalSubjectSearch, [subjectKey]: value.trim()})
        setShowAdditionalSubjectOptions({...showAdditionalSubjectOptions, [subjectKey]: true})
      } else {
        setSubject(undefined)
        setSubjectSearch(value.trim())
        setShowSubjectOptions(true)
      }
      setSubjectErrors([])
    }
  }

  const handleInputBlur = (isTarget: boolean, subjectKey?: string) => {
    isTarget
      ? setShowTargetOptions(false)
      : subjectKey
        ? setShowAdditionalSubjectOptions(prev => ({
            ...prev,
            [subjectKey]: false,
          }))
        : setShowSubjectOptions(false)
  }

  const handleSelection = (id: string, isTarget: boolean, subjectKey?: string) => {
    if (id) {
      const studentId = id.split('-')[1]
      const student = assignedStudents.find(student => student.id === studentId)
      if (!student) return

      if (isTarget) {
        setTarget(student)
        setTargetSearch(student?.name || '')
        setShowTargetOptions(false)
        setTargetErrors([])
      } else {
        if (subjectKey) {
          setAdditionalSubjects(prev => ({
            ...prev,
            [subjectKey]: student,
          }))
          setAdditionalSubjectSearch(prev => ({
            ...prev,
            [subjectKey]: student?.name || '',
          }))
          setShowAdditionalSubjectOptions(prev => ({
            ...prev,
            [subjectKey]: false,
          }))
          setAdditionalSubjectsErrors(prev => {
            const newErrors = {...prev}
            delete newErrors[subjectKey]
            return newErrors
          })
        } else {
          setSubject(student)
          setSubjectSearch(student?.name || '')
          setShowSubjectOptions(false)
          setSubjectErrors([])
        }
      }
    }
  }

  const handleTargetSelection = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    clearErrors()
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

  const reviewType = getReviewType()

  // index = -1 for the main subject select, otherwise it will be the index of additional subjects
  const renderSubjectSelect = (index = -1, subjectKey: string | undefined = undefined) => {
    const numericKey = subjectKey ? parseInt(subjectKey) : -1

    return (
      <Select
        renderLabel={
          targetType === TARGET_TYPES.REVIEWEE ? I18n.t('Reviewer Name') : I18n.t('Recipient Name')
        }
        messages={index === -1 ? subjectErrors : (additionalSubjectsErrors[subjectKey || ''] ?? [])}
        inputRef={ref => {
          if (index === -1) {
            if (subjectSelectRef) subjectSelectRef.current = ref
          } else if (subjectKey) {
            setAdditionalSubjectSelectRefs(prev => ({
              ...prev,
              [subjectKey]: ref,
            }))
          }
        }}
        inputValue={
          index === -1 ? subjectSearch : (additionalSubjectSearch[subjectKey || ''] ?? '')
        }
        onInputChange={(_event: React.ChangeEvent<HTMLInputElement>, value: string) =>
          handleInputChange(value, false, subjectKey)
        }
        onBlur={() => handleInputBlur(false, subjectKey)}
        isShowingOptions={
          index === -1 ? showSubjectOptions : (showAdditionalSubjectOptions[numericKey] ?? false)
        }
        onRequestSelectOption={(_event: React.SyntheticEvent, {id}) => {
          if (id) handleSelection(id, false, subjectKey)
        }}
        isRequired
        data-testid={index === -1 ? 'subject-select' : `additional-subject-select-${subjectKey}`}
      >
        {assignedStudents.map(student => renderStudentOption(student, false, subjectKey))}
      </Select>
    )
  }

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
            <Select
              renderLabel={
                targetType === TARGET_TYPES.REVIEWEE
                  ? I18n.t('Recipient Name')
                  : I18n.t('Reviewer Name')
              }
              messages={targetErrors}
              inputRef={ref => {
                if (targetSelectRef) targetSelectRef.current = ref
              }}
              inputValue={targetSearch}
              onInputChange={(_event: React.ChangeEvent<HTMLInputElement>, value: string) =>
                handleInputChange(value, true)
              }
              onBlur={() => handleInputBlur(true)}
              isShowingOptions={showTargetOptions}
              onRequestSelectOption={(_event: React.SyntheticEvent, {id}) => {
                if (id) {
                  handleSelection(id, true)
                }
              }}
              isRequired
              data-testid="target-select"
            >
              {assignedStudents.map(student => renderStudentOption(student, true))}
            </Select>
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
