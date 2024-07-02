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

type ResourceCardProps = {
  id?: string
  title?: string
  description?: string
  iconName?: string
  linkText?: string
  linkUrl?: string
}

const ResourceCard = ({id, title, description, iconName, linkText, linkUrl}: ResourceCardProps) => {
  const [myId] = useState(id)
  const [myTitle] = useState(title || 'Title')
  const [myDescription] = useState(description || 'Description')
  const [myIcon] = useState(iconName || 'apple')
  const [myLinkText] = useState(linkText || 'Link')
  const [myLinkUrl] = useState(linkUrl || '')

  return (
    <Container className="resource-card" id={myId} background="#fff">
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
          custom={{displayName: 'Icon'}}
        />
        <Element
          id={`${myId}__title`}
          is={HeadingBlock}
          text={myTitle}
          level="h3"
          custom={{displayName: 'Title'}}
        />
        <Element
          id={`${myId}__desc`}
          is={TextBlock}
          text={myDescription}
          textAlign="center"
          custom={{displayName: 'Description'}}
        />
        <Element
          id={`${myId}__link`}
          is={ButtonBlock}
          href={myLinkUrl}
          color="#fff"
          text={myLinkText}
          custom={{displayName: 'Link'}}
        />
      </Flex>
    </Container>
  )
}

ResourceCard.craft = {
  displayName: 'Resource Card',
  defaultProps: {
    id: uid('resource-card', 2),
  },
  custom: {
    isDeletable: (myId: Node, query: any) => {
      const target = query.node(myId).get()
      const ancestors = query.node(myId).ancestors()
      const parent = query.node(ancestors[0])
      if (parent.get().rules?.canMoveOut) {
        return parent.get().rules.canMoveOut([target], parent.get())
      }
      return true
    },
  },
}

export {ResourceCard}
