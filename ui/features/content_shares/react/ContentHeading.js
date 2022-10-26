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

import React from 'react'
import {string} from 'prop-types'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import SVGWrapper from '@canvas/svg-wrapper'
import {PresentationContent} from '@instructure/ui-a11y-content'

ContentHeading.propTypes = {
  svgUrl: string,
  heading: string,
  description: string,
}

export default function ContentHeading(props) {
  return (
    <Flex margin="0 0 medium">
      <Flex.Item size="3.5em">
        <PresentationContent>
          <SVGWrapper url={props.svgUrl} />
        </PresentationContent>
      </Flex.Item>
      <Flex.Item padding="0 medium">
        <Heading level="h1" as="h2">
          {props.heading}
        </Heading>
        <Text>{props.description}</Text>
      </Flex.Item>
    </Flex>
  )
}
