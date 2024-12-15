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

import React, {useState} from 'react'
import {Element, type Node} from '@craftjs/core'
import {Flex} from '@instructure/ui-flex'
import {uid} from '@instructure/uid'
import {Container} from '../Container'
import {HeadingBlock} from '../HeadingBlock'
import {TextBlock} from '../TextBlock'
import {ButtonBlock} from '../ButtonBlock'
import {IconBlock} from '../IconBlock'
import {type ResourceCardProps} from './types'
import {isLastChild} from '../../../../utils'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const ResourceCard = ({id, title, description, iconName, linkText, linkUrl}: ResourceCardProps) => {
  const [myId] = useState(id)
  const [myTitle] = useState(title || ResourceCard.craft.defaultProps.title)
  const [myDescription] = useState(description || ResourceCard.craft.defaultProps.description)
  const [myIcon] = useState(iconName || ResourceCard.craft.defaultProps.iconName)
  const [myLinkText] = useState(linkText || ResourceCard.craft.defaultProps.linkText)
  const [myLinkUrl] = useState(linkUrl || ResourceCard.craft.defaultProps.linkUrl)

  return (
    <Container className="block resource-card" id={myId} background="#fff">
      <Flex
        direction="column"
        justifyItems="center"
        alignItems="center"
        padding="medium"
        height="100%"
        gap="x-small"
      >
        <Element
          id={`${myId}__icon`}
          is={IconBlock}
          iconName={myIcon}
          custom={{displayName: I18n.t('Icon')}}
        />
        <Element
          id={`${myId}__title`}
          is={HeadingBlock}
          text={myTitle}
          level="h3"
          custom={{displayName: I18n.t('Title')}}
        />
        <Element
          id={`${myId}__desc`}
          is={TextBlock}
          text={myDescription}
          textAlign="center"
          custom={{displayName: I18n.t('Description')}}
        />
        <Element
          id={`${myId}__link`}
          is={ButtonBlock}
          href={myLinkUrl}
          color="#fff"
          text={myLinkText}
          custom={{displayName: I18n.t('Link')}}
        />
      </Flex>
    </Container>
  )
}

ResourceCard.craft = {
  displayName: I18n.t('Resource Card'),
  defaultProps: {
    id: uid('resource-card', 2),
    title: 'Title',
    description: 'Description',
    iconName: 'apple',
    linkText: 'Link',
    linkUrl: '',
  },
  custom: {
    isDeletable: (nodeId: string, query: any) => {
      const parentId = query.node(nodeId).get().data.parent
      const parent = query.node(parentId).get()
      return parent?.data.name === 'ResourcesSectionInner' && !isLastChild(nodeId, query)
    },
  },
}

export {ResourceCard}
