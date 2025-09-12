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

import React, {useEffect, useContext} from 'react'
import {View} from '@instructure/ui-view'
import {Transition} from '@instructure/ui-motion'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconArrowOpenStartLine, IconArrowOpenEndLine} from '@instructure/ui-icons'
import useModuleSequence from '../hooks/useModuleSequence'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const I18n = createI18nScope('assignment_footer')

interface AssignmentFooterProps {
  moduleItemId: string | number
}

export default function AssignmentFooter({moduleItemId}: AssignmentFooterProps) {
  const {isLoading, error, sequence} = useModuleSequence(moduleItemId)
  const {setOnFailure} = useContext(AlertManagerContext)
  const displayFooter = !isLoading && !error

  useEffect(() => {
    if (error) {
      setOnFailure(I18n.t('An error occurred while loading sequential module items.'))
    }
  }, [error])

  return (
    <Transition in={displayFooter} type="slide-down">
      {displayFooter && (
        <View as="div" width="100%" padding="small" borderWidth="small none none none">
          <Flex width="100%" justifyItems={sequence.previous ? 'space-between' : 'end'}>
            {sequence.previous && (
              <Tooltip renderTip={sequence.previous.title}>
                <Button href={sequence.previous.url} data-testid="previous-assignment-button">
                  <Flex alignItems="center" gap="x-small">
                    <IconArrowOpenStartLine size="x-small" themeOverride={{sizeXSmall: '.75rem'}} />
                    <Text>{I18n.t('Previous')}</Text>
                  </Flex>
                </Button>
              </Tooltip>
            )}
            {sequence.next && (
              <Tooltip renderTip={sequence.next.title}>
                <Button href={sequence.next.url} data-testid="next-assignment-button">
                  <Flex alignItems="center" gap="x-small">
                    <Text>{I18n.t('Next')}</Text>
                    <IconArrowOpenEndLine size="x-small" themeOverride={{sizeXSmall: '.75rem'}} />
                  </Flex>
                </Button>
              </Tooltip>
            )}
          </Flex>
        </View>
      )}
    </Transition>
  )
}
