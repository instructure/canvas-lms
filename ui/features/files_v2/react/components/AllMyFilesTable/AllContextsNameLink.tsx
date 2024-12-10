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
import {Flex} from '@instructure/ui-flex'
import {IconFolderSolid} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'
import {Link} from 'react-router-dom'

interface NameLinkProps {
  name: string
  contextType: string
  contextId: string
}

const AllContextsNameLink = ({name, contextType, contextId}: NameLinkProps) => {
  const icon = getIcon()

  const renderIconComponent = () => {
    return <span style={{fontSize: '2em'}}>{icon}</span>
  }

  const renderTextComponent = () => {
    return (
      <TruncateText>
        <Text>{name}</Text>
      </TruncateText>
    )
  }

  const urlPath = () => {
    return `/folder/${contextType}_${contextId}`
  }

  return (
    <Link to={urlPath()} data-testid={name}>
      <Flex>
        <Flex.Item margin="0 0 x-small 0">{renderIconComponent()}</Flex.Item>
        <Flex.Item margin="0 0 0 small" shouldShrink={true}>
          {renderTextComponent()}
        </Flex.Item>
      </Flex>
    </Link>
  )
}

const getIcon = () => {
  return <IconFolderSolid data-testid="folder-icon" color="primary" />
}

export default AllContextsNameLink
