/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {IconCertifiedSolid, IconExternalLinkLine} from '@instructure/ui-icons'
import {Tag} from '@instructure/ui-tag'
import {Flex} from '@instructure/ui-flex'
import type {Spacing} from '@instructure/emotion'
import type {ViewProps} from '@instructure/ui-view'
import type {SkillData} from './types'

interface SkillTagProps {
  id: string
  dismissable: boolean
  skill: SkillData
  margin: Spacing
  onClick: (e: React.MouseEvent<ViewProps, MouseEvent>, id: string) => void
}

const SkillTag = ({id, dismissable, skill, margin, onClick}: SkillTagProps) => {
  return (
    <Tag
      id={id}
      dismissible={dismissable}
      title={`Remove ${skill.name}`}
      text={
        <Flex gap="xx-small">
          <Flex.Item shouldGrow={false} padding="0 0 xxx-small 0">
            {skill.verified ? <IconCertifiedSolid color="success" title="certified" /> : null}
          </Flex.Item>
          <Flex.Item shouldGrow={true}>{skill.name}</Flex.Item>
          {skill.url ? (
            <Flex.Item shouldGrow={false}>
              <IconExternalLinkLine title="external link" />
            </Flex.Item>
          ) : null}
        </Flex>
      }
      margin={margin}
      onClick={e => onClick(e, id)}
    />
  )
}

export default SkillTag
