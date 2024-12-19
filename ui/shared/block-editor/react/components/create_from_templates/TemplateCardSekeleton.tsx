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
import {Flex} from '@instructure/ui-flex'
import type {BlockTemplate} from '../../types'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {AvailableTags} from './TagSelect'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export default function TemplateCardSkeleton({
  template,
  createAction,
  quickLookAction,
  inLayout,
}: {
  template: BlockTemplate
  createAction: () => void
  quickLookAction?: () => void
  inLayout: 'grid' | 'rows'
}) {
  const renderBlankPageCard = () => {
    return (
      <>
        <div className="curl" />
        <Flex alignItems="center" height="100%" justifyItems="center" width="100%">
          <Button color="primary" size="small" onClick={createAction}>
            {I18n.t('New Blank Page')}
          </Button>
        </Flex>
      </>
    )
  }

  const renderTemplateCard = () => {
    return (
      <div
        className="block-template-preview-card__content"
        style={{
          position: 'absolute',
          height: 'auto',
          right: 0,
          bottom: 0,
          left: 0,
          backgroundColor: '#fff',
        }}
      >
        <Flex direction="column" gap="xx-small" padding="x-small">
          <Heading level="h4" margin="0">
            {template.name}
          </Heading>
          {template.description && (
            <div id={`${template.id}-description`}>
              <TruncateText maxLines={2}>
                <Text as="div" size="x-small" lineHeight="condensed">
                  {template.description}
                </Text>
              </TruncateText>
            </div>
          )}
          <Flex alignItems="end" height="100%" justifyItems="end" width="100%" gap="x-small">
            <Button color="secondary" size="small" onClick={quickLookAction}>
              {I18n.t('Quick Look')}
            </Button>
            <Button color="primary" size="small" onClick={createAction}>
              {I18n.t('Customize')}
            </Button>
          </Flex>
        </Flex>
      </div>
    )
  }

  return (
    <View
      data-testid="template-card-skeleton"
      as="div"
      className={`block-template-preview-card ${inLayout} ${
        template.id === 'blank_page' ? 'blank-card' : ''
      }`}
      position="relative"
      shadow="above"
      tabIndex={0}
      style={{backgroundImage: template?.thumbnail && `url(${template.thumbnail})`}}
      aria-label={I18n.t('%{name} template', {name: template.name})}
      aria-describedby={template.description ? `${template.id}-description` : undefined}
    >
      <Flex as="div" margin="x-small" justifyItems="end" gap="x-small">
        {template.tags?.map((tag: string) => (
          <Pill key={tag} margin="0">
            {AvailableTags[tag] || tag}
          </Pill>
        ))}
      </Flex>
      {template.id === 'blank_page' ? renderBlankPageCard() : renderTemplateCard()}
    </View>
  )
}
