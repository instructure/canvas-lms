/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState} from 'react'

import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'

import formatMessage from '../../../../../../format-message'
import {UploadModal} from './UploadModal'

export const MyImages = () => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  return (
    <View as="div" padding="small 0">
      <Button onClick={() => setIsModalOpen(true)} renderIcon={IconAddLine}>
        {formatMessage('Add Image')}
      </Button>
      <UploadModal onDismiss={() => setIsModalOpen(false)} open={isModalOpen} />
    </View>
  )
}
