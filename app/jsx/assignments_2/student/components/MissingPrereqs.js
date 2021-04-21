/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import I18n from 'i18n!assignments_2'
import React from 'react'
import {string} from 'prop-types'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

import locked1SVG from '../SVG/Locked1.svg'

export default function MissingPrereqs(props) {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <Flex.Item>
        <img alt={I18n.t('Assignment Locked with Prerequisite')} src={locked1SVG} />
      </Flex.Item>
      <Flex.Item>
        <Flex margin="small" direction="column" alignItems="center" justifyContent="center">
          <Flex.Item>
            <Heading size="large" data-test-id="assignments-2-pre-req-title" margin="small">
              {I18n.t('Prerequisite Completion Period')}
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <Text size="medium">{props.preReqTitle}</Text>
          </Flex.Item>
          <Flex.Item>
            <Button variant="primary" margin="small" href={props.preReqLink}>
              {I18n.t('Go to Prerequisite')}
            </Button>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

MissingPrereqs.propTypes = {
  preReqTitle: string.isRequired,
  preReqLink: string.isRequired
}
