/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'

export type AchievementCardProps = {
  isNew: boolean
  title: string
  issuer: string
  imageUrl?: string | null
}

const cardStyle = {
  position: 'relative',
  width: '265px',
  height: '130px',
  padding: '16px',
  border: '1px solid #f5f5f5',
  boxShadow: '0px 1px 3px 0px rgba(0, 0, 0, 0.10), 0px 1px 2px 0px rgba(0, 0, 0, 0.20)',
}

const AchievementCard = ({isNew, title, issuer, imageUrl}: AchievementCardProps) => {
  return (
    <>
      {/*
    // @ts-ignore-error */}
      <div style={cardStyle}>
        {isNew && (
          <div style={{position: 'absolute', top: '1rem', left: '1rem'}}>
            <Pill color="info">New</Pill>
          </div>
        )}
        <Flex justifyItems="space-between" alignItems="center" direction="column" gap="x-small">
          <Flex.Item size="64px">
            <img
              src={imageUrl || undefined}
              alt=""
              style={{
                flexBasis: '64px',
                height: '64px',
                minWidth: '64px',
                background: imageUrl
                  ? 'none'
                  : 'repeating-linear-gradient(45deg, #cecece, #cecece 10px, #aeaeae 10px, #aeaeae 20px)',
              }}
            />
          </Flex.Item>
          <Flex.Item>
            <Text weight="bold">{title}</Text>
          </Flex.Item>
          <Flex.Item>
            <Text>{issuer}</Text>
          </Flex.Item>
        </Flex>
      </div>
    </>
  )
}

export default AchievementCard
