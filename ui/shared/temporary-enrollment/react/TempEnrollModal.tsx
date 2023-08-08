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
}

export function TempEnrollModal(props: Props) {
  const [open, setOpen] = useState(false)
  const [page, setPage] = useState(0)
  const [enrollment, setEnrollment] = useState(null)

  const renderScreen = () => {
    if (page === 2) {
      return (
        <TempEnrollAssign
          user={props.user}
          enrollment={enrollment}
          roles={props.roles}
          goBack={() => {
            setPage(p => p - 1)
          }}
          permissions={props.permissions}
        />
      )
    } else if (enrollment === null) {
      return (
        <TempEnrollSearch
          accountId={props.accountId}
          canReadSIS={props.canReadSIS}
          user={props.user}
          page={page}
          searchFail={() => {
            setPage(0)
            setEnrollment(null)
          }}
          searchSuccess={(e: any) => {
            setEnrollment(e)
          }}
        />
      )
    } else {
      return (
        <TempEnrollSearch
          accountId={props.accountId}
          canReadSIS={props.canReadSIS}
          user={props.user}
          page={page}
          searchFail={() => {
            setPage(0)
            setEnrollment(null)
          }}
          searchSuccess={(e: any) => {
            setEnrollment(e)
          }}
          foundEnroll={enrollment}
        />
      )
    }
  }

  if (page > 2) {
    setOpen(false)
    setPage(0)
  }

  return (
    <>
      <Modal
        overflow="scroll"
        open={open}
        onDismiss={() => {
          setOpen(false)
        }}
        size="large"
        label={I18n.t('Create a Temporary Enrollment')}
        shouldCloseOnDocumentClick={true}
        theme={{smallMaxWidth: '30em'}}
      >
        <Modal.Header>
          <Heading tabIndex="-1">
            {I18n.t('Create a Temporary Enrollment for %{name}', {name: props.user.name})}
          </Heading>
        </Modal.Header>
        <Modal.Body>{renderScreen()}</Modal.Body>
        <Modal.Footer>
          <Button
            onClick={() => {
              setOpen(false)
              setPage(0)
            }}
          >
            {I18n.t('Cancel')}
          </Button>
          &nbsp;
          {page === 1 ? (
            <Button
              onClick={() => {
                setPage(p => p - 1)
                setEnrollment(null)
              }}
            >
              {I18n.t('Start Over')}
            </Button>
          ) : null}
          &nbsp;
          <Button
            color="primary"
            onClick={() => {
              setPage(p => p + 1)
            }}
          >
            {page === 2 ? I18n.t('Submit') : I18n.t('Next')}
          </Button>
          &nbsp;
        </Modal.Footer>
      </Modal>
      {React.Children.map(props.children, child =>
        // when you click whatever is the child element to this, open the modal
        React.cloneElement(child, {
          onClick: (...args: any) => {
            if (child.props.onClick) child.props.onClick(...args)
            setOpen(true)
          },
        })
      )}
    </>
  )
}
