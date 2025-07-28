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

import {CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {ResponsiveWrapper} from './ResponsiveWrapper'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_registrations')

export type HeaderProps = {
  onClose: () => void
  editing?: boolean
}

export const Header = ({onClose, editing = false}: HeaderProps) => {
  return (
    <ResponsiveWrapper
      render={modalProps => (
        <Modal.Header spacing={modalProps?.spacing || 'default'}>
          <CloseButton
            placement="end"
            offset={modalProps?.offset || 'medium'}
            onClick={onClose}
            screenReaderLabel={I18n.t('Close')}
            data-testid="header-close-button"
          />
          <Heading>{editing ? I18n.t('Edit App') : I18n.t('Install App')}</Heading>
        </Modal.Header>
      )}
    />
  )
}
