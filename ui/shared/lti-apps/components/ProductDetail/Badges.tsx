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

import TruncateWithTooltip from '../common/TruncateWithTooltip'
import useBreakpoints from '../../hooks/useBreakpoints'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Img} from '@instructure/ui-img'
import type {Badges} from '../../models/Product'

interface BadgesProps {
  badges: Badges
}

const Badges = (props: BadgesProps) => {
  const {badges} = props
  const {isDesktop, isMobile} = useBreakpoints()

  const horizontalOffset = () => {
    if (isDesktop) {
      return -90
    } else if (isMobile) {
      return -50
    } else {
      return -20
    }
  }

  return (
    <div>
      {badges && (
        <Flex direction="row">
          <Flex.Item margin="0 small 0 0" align="start">
            <Img src={badges.image_url} height={50} width={'100%'} />
          </Flex.Item>

          <Flex direction="column">
            <Flex.Item margin="0 0 x-small 0">
              <Link href={badges.link} isWithinText={false} target="_blank">
                <Text weight="bold">
                  {badges.name}{' '}
                  <IconExternalLinkLine />
                </Text>
              </Link>
            </Flex.Item>
            <Flex.Item>
              <TruncateWithTooltip
                linesAllowed={3}
                horizontalOffset={horizontalOffset()}
                backgroundColor="primary"
              >
                <Text>{badges.description}</Text>
              </TruncateWithTooltip>
            </Flex.Item>
          </Flex>
        </Flex>
      )}
    </div>
  )
}

export default Badges
