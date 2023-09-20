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

import React, {ReactElement, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
// @ts-ignore
import {Modal} from '@instructure/ui-modal'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TempEnrollSearch} from './TempEnrollSearch'
import {TempEnrollAssign} from './TempEnrollAssign'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('temporary_enrollment')

interface Props {
  readonly children: ReactElement
  readonly user: {
    id: string
    name: string
    avatar_url?: string
  }
  readonly canReadSIS?: boolean
  readonly permissions: {
    teacher: boolean
    ta: boolean
    student: boolean
    observer: boolean
    designer: boolean
  }
  readonly accountId: string
  readonly roles: {id: string; label: string; base_role_name: string}[]
  readonly onOpen?: () => void
  readonly onClose?: () => void
  readonly defaultOpen?: boolean
  readonly isOpen?: boolean
}

export function TempEnrollModal(props: Props) {
  const [open, setOpen] = useState(props.defaultOpen || false)
  const [page, setPage] = useState(0)
  const [enrollment, setEnrollment] = useState(null)

  const submitEnroll = (isSuccess: boolean) => {
    if (isSuccess) {
      setPage(0)
      setEnrollment(null)
      setOpen(false)
      showFlashSuccess(I18n.t('Temporary enrollment was successfully created.'))()
    } else {
      setPage(2)
    }
  }

  const resetState = () => {
    setPage(0)
    setEnrollment(null)
  }

  const handleOpen = () => {
    if (props.isOpen !== undefined) {
      props.onOpen && props.onOpen()
    } else if (!open) {
      setOpen(true)
    }
  }

  const handleClose = () => {
    if (props.isOpen !== undefined) {
      props.onClose && props.onClose()
    } else if (open) {
      resetState()
      setOpen(false)
    }
  }

  const handleSearchFail = () => {
    setPage(0)
    setEnrollment(null)
  }

  const handleSearchSuccess = (e: any) => {
    setEnrollment(e)
  }

  const handleCancel = () => {
    setPage(0)
    setOpen(false)
  }

  const handleGoBack = () => {
    setPage((p: number) => p - 1)
  }

  const handleStartOver = () => {
    setPage((p: number) => p - 1)
    setEnrollment(null)
  }

  const handleNextOrSubmit = () => {
    setPage(p => p + 1)
  }

  const handleChildClick =
    (childOnClick: any) =>
    (...args: any) => {
      if (childOnClick) childOnClick(...args)
      handleOpen()
    }

  const shouldSubmit = () => {
    return page === 3
  }

  const renderScreen = () => {
    if (page >= 2) {
      return (
        <TempEnrollAssign
          user={props.user}
          enrollment={enrollment}
          roles={props.roles}
          goBack={handleGoBack}
          permissions={props.permissions}
          doSubmit={shouldSubmit}
          setEnrollmentStatus={submitEnroll}
        />
      )
    } else if (enrollment === null) {
      return (
        <TempEnrollSearch
          accountId={props.accountId}
          canReadSIS={props.canReadSIS}
          user={props.user}
          page={page}
          searchFail={handleSearchFail}
          searchSuccess={handleSearchSuccess}
        />
      )
    } else {
      return (
        <TempEnrollSearch
          accountId={props.accountId}
          canReadSIS={props.canReadSIS}
          user={props.user}
          page={page}
          searchFail={handleSearchFail}
          searchSuccess={handleSearchSuccess}
          foundEnroll={enrollment}
        />
      )
    }
  }

  return (
    <>
      <Modal
        overflow="scroll"
        open={props.isOpen !== undefined ? props.isOpen : open}
        onDismiss={handleClose}
        size="large"
        label={I18n.t('Create a Temporary Enrollment')}
        shouldCloseOnDocumentClick={true}
        theme={{smallMaxWidth: '30em'}}
      >
        <Modal.Header>
          <Heading tabIndex={-1} level="h2">
            {I18n.t('Create a temporary enrollment')}
          </Heading>
        </Modal.Header>
        <Modal.Body>{renderScreen()}</Modal.Body>
        <Modal.Footer>
          <Button onClick={handleCancel}>{I18n.t('Cancel')}</Button>
          &nbsp;
          {page === 1 ? (
            <>
              <Button onClick={handleStartOver}>{I18n.t('Start Over')}</Button>
              &nbsp;
            </>
          ) : null}
          <Button color="primary" onClick={handleNextOrSubmit}>
            {page === 2 ? I18n.t('Submit') : I18n.t('Next')}
          </Button>
        </Modal.Footer>
      </Modal>
      {React.Children.map(props.children, (child: any) =>
        // any child will open the modal on click
        React.cloneElement(child, {
          onClick: handleChildClick(child.props.onClick),
        })
      )}
    </>
  )
}
