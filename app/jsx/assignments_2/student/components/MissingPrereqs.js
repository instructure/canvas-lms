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

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import Button from '@instructure/ui-buttons/lib/components/Button'

import locked1SVG from '../../../../../public/images/assignments_2/Locked1.svg'

function MissingPrereqs(props) {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <FlexItem>
        <img alt={I18n.t('Assignment Locked with Prerequisite')} src={locked1SVG} />
      </FlexItem>
      <FlexItem>
        <Flex margin="small" direction="column" alignItems="center" justifyContent="center">
          <FlexItem>
            <Heading size="large" data-test-id="assignments-2-pre-req-title" margin="small">
              {I18n.t('Prerequisite Completion Period')}
            </Heading>
          </FlexItem>
          <FlexItem>
            <Text size="medium">{props.preReqTitle}</Text>
          </FlexItem>
          <FlexItem>
            <Button variant="primary" margin="small" href={props.preReqLink}>
              {I18n.t('Go to Prerequisite')}
            </Button>
          </FlexItem>
        </Flex>
      </FlexItem>
    </Flex>
  )
}

MissingPrereqs.propTypes = {
  preReqTitle: string.isRequired,
  preReqLink: string.isRequired
}

export default React.memo(MissingPrereqs)
