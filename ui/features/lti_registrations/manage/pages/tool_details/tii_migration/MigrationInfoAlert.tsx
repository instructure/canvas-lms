/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('lti_registrations')

export const MigrationInfoAlert = () => {
  return (
    <View as="div" margin="0 0 medium 0">
      <Alert variant="info" renderCloseButtonLabel={I18n.t('Close')} margin="0 0 medium 0">
        <Flex gap="small" direction="column">
          <Text>
            {I18n.t(
              'We are replacing LTI 2.0 (CPF) with LTI 1.3 (Asset/Document Processor). Below are the migrations that need to occur in order to easily start using LTI 1.3 on all of your assignments.',
            )}
          </Text>
          <Text>
            {I18n.t(
              'Once you click the button to start the migration, reports will not be visible in SpeedGrader until they have been migrated.',
            )}
          </Text>
        </Flex>
      </Alert>
    </View>
  )
}
