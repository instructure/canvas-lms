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
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('differentiation_tags')

interface ConversionFailureProps {
  conversionError: string | null
}

const ConversionFailure = ({conversionError}: ConversionFailureProps) => {
  const message = I18n.t('Tag conversion failed: %{error}', {
    error: conversionError || I18n.t('An error occurred during tag conversion'),
  })

  return (
    <Alert
      variant="error"
      hasShadow={false}
      margin="0 0 medium 0"
      renderCloseButtonLabel={() => I18n.t('Close differentiation tag message')}
      data-testid="course-differentiation-tag-conversion-error"
    >
      <Flex direction="column">
        <Text>{message}</Text>
      </Flex>
    </Alert>
  )
}

export default ConversionFailure
