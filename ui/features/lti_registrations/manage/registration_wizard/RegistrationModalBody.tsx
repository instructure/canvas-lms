/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Modal} from '@instructure/ui-modal'

export const MODAL_BODY_HEIGHT = '50vh'

export type RegistrationModalProps = {
  padding?: 'medium' | 'none'
  children: React.ReactNode
}

const paddingMapping = {
  medium: '1.5rem',
  none: '0px',
}

export const RegistrationModalBody = ({
  padding,
  children,
}: React.PropsWithChildren<RegistrationModalProps>) => {
  return (
    <Modal.Body padding={padding ?? 'medium'}>
      <View height={`calc(${MODAL_BODY_HEIGHT} - ${paddingMapping[padding ?? 'medium']})`} as="div">
        {children}
      </View>
    </Modal.Body>
  )
}
