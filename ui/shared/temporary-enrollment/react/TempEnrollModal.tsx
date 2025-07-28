/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {cloneElement, useEffect, useState} from 'react'
import type {MouseEvent, MouseEventHandler, ReactElement} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TempEnrollSearch} from './TempEnrollSearch'
import {TempEnrollView} from './TempEnrollView'
import {TempEnrollAssign} from './TempEnrollAssign'
import {Flex} from '@instructure/ui-flex'
import type {
  Enrollment,
  EnrollmentType,
  Role,
  ModifyPermissions,
  User,
  RolePermissions,
} from './types'
import {MODULE_NAME, RECIPIENT} from './types'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {createAnalyticPropsGenerator, setAnalyticPropsOnRef} from './util/analytics'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

const I18n = createI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props {
  enrollmentType: EnrollmentType
  children: ReactElement
  user: User
  canReadSIS: boolean
  rolePermissions: RolePermissions
  roles: Role[]
  isEditMode: boolean
  onToggleEditMode?: (mode?: boolean) => void
  modifyPermissions: ModifyPermissions
}

export const generateModalTitle = (
  user: User,
  enrollmentType: EnrollmentType,
  isEditMode: boolean,
  page: number,
  enrollments: User[],
): string => {
  const userName = user.name
  const enrollmentName = enrollments[0]?.name
  if (page >= 2) {
    // if user is RECIPIENT, recipient is the userName; otherwise, use first enrollment
    const recipient = enrollmentType === RECIPIENT && userName ? userName : enrollmentName
    if (recipient) {
      /** if an enrollment array has multiple users, we show the number of recipients (count).
      enrollment.length can be 0 when clicking Edit in TempEnrollView and will still have a valid
       recipient, so we should still show recipient. */
      return I18n.t(
        {
          zero: `Assign temporary enrollments to %{recipient}`,
          one: `Assign temporary enrollments to %{recipient}`,
          other: `Assign temporary enrollments to %{count} users`,
        },
        {count: enrollments.length, recipient},
      )
    } else {
      return I18n.t('Assign temporary enrollments')
    }
  }
  if (isEditMode && userName) {
    return I18n.t(`Temporary Enrollment %{enrollmentType} for %{userName}`, {
      enrollmentType: enrollmentType === RECIPIENT ? 'Providers' : 'Recipients',
      userName,
    })
  }
  return I18n.t('Find recipients of Temporary Enrollments')
}

export function TempEnrollModal(props: Props) {
  const [open, setOpen] = useState(false)
  const [page, setPage] = useState(0)
  const [enrollments, setEnrollments] = useState<User[]>([])
  const [isViewingAssignFromEdit, setIsViewingAssignFromEdit] = useState(false)
  const [buttonsDisabled, setButtonsDisabled] = useState(true)
  const [wasReset, setWasReset] = useState(false)
  const [isModalOpenAnimationComplete, setIsModalOpenAnimationComplete] = useState(false)
  const [tempEnrollmentsPairing, setTempEnrollmentsPairing] = useState<Enrollment[] | null>(null)
  const [title, setTitle] = useState(' ')
  const [duplicateReq, setDuplicateReq] = useState(false)

  useEffect(() => {
    if (isModalOpenAnimationComplete) {
      setButtonsDisabled(false)
    }
  }, [isModalOpenAnimationComplete])

  useEffect(() => {
    const newTitle = generateModalTitle(
      props.user,
      props.enrollmentType,
      props.isEditMode,
      page,
      enrollments,
    )
    setTitle(newTitle)
  }, [props.user, props.enrollmentType, props.isEditMode, page, enrollments])

  const resetCommonState = () => {
    if (props.isEditMode && props.onToggleEditMode) {
      props.onToggleEditMode(false)
    }
  }

  const handleModalReset = () => {
    setPage(0)
    setEnrollments([])
    setWasReset(true)
    setTempEnrollmentsPairing(null)
    setIsViewingAssignFromEdit(false)
    setIsModalOpenAnimationComplete(false)
    resetCommonState()
  }

  const handleGoToAssignPageWithEnrollments = (
    enrollmentUser: User,
    tempEnrollments: Enrollment[],
  ) => {
    setEnrollments([enrollmentUser])
    setTempEnrollmentsPairing(tempEnrollments)
    setPage(2)
    setIsViewingAssignFromEdit(true)
    resetCommonState()
  }

  const handleEnrollmentSubmission = (
    isSuccess: boolean,
    isUpdate: boolean,
    isMultiple: boolean,
  ) => {
    if (isSuccess) {
      setOpen(false)
      if (isUpdate) {
        showFlashSuccess(I18n.t('Temporary enrollment was successfully updated.'))()
      } else if (isMultiple) {
        showFlashSuccess(I18n.t('Temporary enrollments were successfully created.'))()
      } else {
        showFlashSuccess(I18n.t('Temporary enrollment was successfully created.'))()
      }
    } else {
      setPage(2)
    }
  }

  const handleOpenModal = () => {
    if (!open) {
      setOpen(true)
    }
  }

  const handleCloseModal = () => {
    if (open) {
      setOpen(false)
      handleModalReset()
    }
  }

  const handleSetEnrollmentsFromSearch = (enrollmentUsers: User[]) => {
    setEnrollments(enrollmentUsers)
    setDuplicateReq(false)
  }

  const handlePageChange = (change: number) => {
    // don't change page if duplicates are not selected
    if (page !== 1 || enrollments.length !== 0) {
      setPage((currentPage: number) => currentPage + change)
    } else {
      setDuplicateReq(true)
    }
  }

  const isSubmissionPage = () => {
    return page === 3
  }

  const handleModalEntered = () => {
    setIsModalOpenAnimationComplete(true)
  }

  const handleModalExit = () => {
    setButtonsDisabled(true)
  }

  const handleChildClick =
    (originalOnClick?: MouseEventHandler<HTMLElement>) => (event: MouseEvent<HTMLElement>) => {
      event.stopPropagation()
      handleOpenModal()
      // call the original onClick (if it exists)
      if (typeof originalOnClick === 'function') {
        originalOnClick(event)
      }
    }

  const renderCloseButton = () => {
    return (
      <CloseButton
        placement="end"
        offset="small"
        onClick={handleCloseModal}
        screenReaderLabel="Close"
        elementRef={ref => {
          if (ref instanceof HTMLElement) {
            setAnalyticPropsOnRef(ref, analyticProps('Close'))
          }
        }}
      />
    )
  }

  const renderBody = () => {
    if (props.isEditMode) {
      return (
        <QueryClientProvider client={queryClient}>
          <TempEnrollView
            user={props.user}
            onAddNew={handleModalReset}
            onEdit={handleGoToAssignPageWithEnrollments}
            enrollmentType={props.enrollmentType}
            modifyPermissions={props.modifyPermissions}
            disableModal={(isDisabled: boolean) => setButtonsDisabled(isDisabled)}
          />
        </QueryClientProvider>
      )
    } else {
      if (page >= 2) {
        return (
          <TempEnrollAssign
            enrollments={enrollments}
            user={props.user}
            roles={props.roles}
            goBack={() => handlePageChange(-1)}
            rolePermissions={props.rolePermissions}
            doSubmit={isSubmissionPage}
            setEnrollmentStatus={handleEnrollmentSubmission}
            isInAssignEditMode={isViewingAssignFromEdit}
            enrollmentType={props.enrollmentType}
            tempEnrollmentsPairing={tempEnrollmentsPairing}
          />
        )
      }

      return (
        <TempEnrollSearch
          canReadSIS={props.canReadSIS}
          user={props.user}
          page={page}
          searchFail={handleModalReset}
          searchSuccess={handleSetEnrollmentsFromSearch}
          foundUsers={enrollments}
          wasReset={wasReset}
          duplicateReq={duplicateReq}
        />
      )
    }
  }

  const renderButtons = () => {
    if (props.isEditMode) {
      return (
        <Flex.Item>
          <Button disabled={buttonsDisabled} onClick={handleCloseModal} {...analyticProps('Done')}>
            {I18n.t('Done')}
          </Button>
        </Flex.Item>
      )
    } else {
      return [
        <Flex.Item key="cancel">
          <Button
            disabled={buttonsDisabled}
            onClick={handleCloseModal}
            {...analyticProps('Cancel')}
          >
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>,

        page === 1 && (
          <Flex.Item key="startOver">
            <Button
              disabled={buttonsDisabled}
              onClick={handleModalReset}
              {...analyticProps('StartOver')}
            >
              {I18n.t('Start Over')}
            </Button>
          </Flex.Item>
        ),

        !props.isEditMode && (
          <Flex.Item key="nextOrSubmit">
            <Button
              disabled={buttonsDisabled}
              color="primary"
              onClick={() => handlePageChange(1)}
              {...analyticProps(page === 2 ? 'Submit' : 'Next')}
            >
              {page === 2 ? I18n.t('Submit') : I18n.t('Next')}
            </Button>
          </Flex.Item>
        ),
      ]
    }
  }

  return (
    <>
      {open && (
        <Modal
          overflow="scroll"
          open={open}
          size="large"
          label={I18n.t('Create a Temporary Enrollment')}
          shouldCloseOnDocumentClick={false}
          themeOverride={{smallMaxWidth: '30em'}}
          onEntered={handleModalEntered}
          onExit={handleModalExit}
          onDismiss={handleCloseModal}
          onExited={handleModalReset}
        >
          <Modal.Header>
            {renderCloseButton()}
            <Heading tabIndex={-1} level="h2">
              {title}
            </Heading>
          </Modal.Header>

          <Modal.Body>{renderBody()}</Modal.Body>

          <Modal.Footer>
            <Flex gap="small">{renderButtons()}</Flex>
          </Modal.Footer>
        </Modal>
      )}

      {cloneElement(props.children, {
        onClick: handleChildClick(props.children.props.onClick),
      })}
    </>
  )
}
