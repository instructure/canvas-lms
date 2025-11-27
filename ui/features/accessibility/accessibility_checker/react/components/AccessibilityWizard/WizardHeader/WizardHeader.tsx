/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import type {ViewProps} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'

const I18n = createI18nScope('accessibility_checker')

interface WizardProps {
  title: string
  padding?: ViewProps['padding']
  onDismiss: () => void
}

export const WizardHeader: React.FC<WizardProps> = ({title, onDismiss, padding}) => {
  const [isHeaderTruncated, setIsHeaderTruncated] = React.useState(false)

  return (
    <Flex as="div" gap="small" justifyItems="space-between" padding={padding ?? 'small'}>
      <div style={{display: 'flex', maxWidth: '90%'}}>
        <Tooltip on={isHeaderTruncated ? ['hover'] : []} placement="start center" renderTip={title}>
          <Heading level="h2" variant="titleCardRegular">
            <TruncateText onUpdate={isTruncated => setIsHeaderTruncated(isTruncated)}>
              {title}
            </TruncateText>
          </Heading>
        </Tooltip>
      </div>
      <Flex.Item>
        <CloseButton onClick={onDismiss} size="small" screenReaderLabel={I18n.t('Close')} />
      </Flex.Item>
    </Flex>
  )
}
