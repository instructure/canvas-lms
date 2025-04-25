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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'

const I18n = createI18nScope('files_v2')

type PermissionsModalFooterProps = {
  isRequestInFlight: boolean
  onDismiss: () => void
  onSave: () => void
}

export const PermissionsModalFooter = ({
  isRequestInFlight,
  onDismiss,
  onSave,
}: PermissionsModalFooterProps) => (
  <>
    <Button
      data-testid="permissions-cancel-button"
      margin="0 x-small 0 0"
      disabled={isRequestInFlight}
      onClick={onDismiss}
    >
      {I18n.t('Cancel')}
    </Button>
    <Button
      data-testid="permissions-save-button"
      color="primary"
      disabled={isRequestInFlight}
      onClick={onSave}
    >
      {I18n.t('Save')}
    </Button>
  </>
)
