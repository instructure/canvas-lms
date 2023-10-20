/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import StuckList from './StuckList'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('jobs_v2')

export default function StuckModal({shard, isOpen, onClose}) {
  const Footer = () => {
    return <Button onClick={onClose}>{I18n.t('Close')}</Button>
  }

  return (
    <CanvasModal
      footer={<Footer />}
      label={I18n.t('Blocked job details')}
      open={isOpen}
      onDismiss={onClose}
    >
      {isOpen && (
        <>
          <StuckList shard={shard} type="strand" />
          <StuckList shard={shard} type="singleton" />
        </>
      )}
    </CanvasModal>
  )
}
