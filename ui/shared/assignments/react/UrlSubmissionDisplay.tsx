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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {IconExternalLinkLine} from '@instructure/ui-icons'

interface UrlSubmissionDisplayProps {
  url: string
}

const UrlSubmissionDisplay: React.FC<UrlSubmissionDisplayProps> = ({url}) => {
  return (
    <Flex direction="column">
      <Flex.Item textAlign="center" margin="small 0 medium 0">
        <Text size="large">
          <Link
            renderIcon={IconExternalLinkLine}
            iconPlacement="end"
            margin="small"
            onClick={() => window.open(url)}
          >
            <span data-testid="url-submission-text">{url}</span>
          </Link>
        </Text>
      </Flex.Item>
    </Flex>
  )
}

export default UrlSubmissionDisplay
