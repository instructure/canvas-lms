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
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconStarLightLine, IconEducatorsLine, IconStandardsLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import type {PathwayBadgeType} from '../../../types'

type ViewBadgeTrayProps = {
  badge: PathwayBadgeType
  open: boolean
  onClose: () => void
}

const ViewBadgeTray = ({badge, open, onClose}: ViewBadgeTrayProps) => {
  return (
    <Tray
      label="Achievement Details"
      open={open}
      onDismiss={onClose}
      size="regular"
      placement="end"
    >
      <Flex as="div" padding="small small small medium">
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Heading level="h2" margin="0 large 0 0">
            {badge.title}
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton placement="end" offset="small" screenReaderLabel="Close" onClick={onClose} />
        </Flex.Item>
      </Flex>
      <Flex
        as="div"
        margin="0 medium large medium"
        direction="column"
        justifyItems="start"
        alignItems="stretch"
      >
        <Flex.Item align="stretch">
          <View as="div" padding="medium 0" borderWidth="0 0 small 0">
            <div style={{width: '250px', height: '250px', background: 'grey', margin: '0 auto'}} />
          </View>
        </Flex.Item>
        <View as="div" padding="medium 0" borderWidth="0 0 small 0">
          <View as="div">
            <IconStarLightLine />
            <View display="inline-block" margin="0 0 0 small">
              <Text>Award type: </Text>
              <Text weight="bold">{badge.type}</Text>
            </View>
          </View>
          <View as="div">
            <IconEducatorsLine />
            <View display="inline-block" margin="0 0 0 small">
              <Text>Issued by: </Text>
              <Link href={badge.issuer.url} target="_blank">
                {badge.issuer.name}
              </Link>
            </View>
          </View>
        </View>
        <View as="div" padding="medium 0" borderWidth="0 0 small 0">
          <Text weight="bold">Earning creteria</Text>
          <p>
            <Text>{badge.criteria}</Text>
          </p>
        </View>
        <View as="div" padding="medium 0">
          <Text weight="bold">Skills</Text>
          <div>
            <IconStandardsLine />{' '}
            <Text>
              Verified by <Link href="https;//lightcast.io/open-skills">Lightcast</Link>
            </Text>
          </div>
          <View as="div" margin="small 0 0 0">
            {badge.skills.map(skill => (
              <Pill key={skill} margin="0 x-small xx-small 0">
                {skill}
              </Pill>
            ))}
          </View>
        </View>
      </Flex>
    </Tray>
  )
}

export default ViewBadgeTray
