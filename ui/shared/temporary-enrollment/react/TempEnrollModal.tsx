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

const I18n = useI18nScope('account_course_user_search')

interface Props {
  readonly children: ReactElement
}

export function TempEnrollModal(props: Props) {
  const [open, setOpen] = useState(false)

  return (
    <>
      <Modal
        open={open}
        onDismiss={() => {
          setOpen(false)
        }}
        size="large"
        label={I18n.t('Create Temporary Enrollment')}
        shouldCloseOnDocumentClick={true}
        theme={{smallMaxWidth: '30em'}}
      >
        <Modal.Header>
          <Heading tabIndex="-1">{I18n.t('Create a Temporary Enrollment')}</Heading>
        </Modal.Header>
        <Modal.Body />
        <Modal.Footer>
          <Button
            onClick={() => {
              setOpen(false)
            }}
          >
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary">{I18n.t('Next')}</Button>
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
