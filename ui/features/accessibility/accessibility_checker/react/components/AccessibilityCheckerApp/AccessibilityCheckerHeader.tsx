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
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {LIMIT_EXCEEDED_MESSAGE} from '../../constants'

export const AccessibilityCheckerHeader: React.FC = () => {
  const accessibilityScanDisabled = window.ENV.SCAN_DISABLED
  return (
    <Flex direction="column">
      {accessibilityScanDisabled && (
        <Alert
          variant="info"
          renderCloseButtonLabel="Close"
          onDismiss={() => {}}
          margin="small 0"
          data-testid="accessibility-scan-disabled-alert"
        >
          {LIMIT_EXCEEDED_MESSAGE}
        </Alert>
      )}
    </Flex>
  )
}
