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

import PropTypes from 'prop-types'
import React from 'react'

import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'

function AssignmentGroupModuleNav(props) {
  return (
    <Flex margin="0 0 xx-large 0" direction="column">
      {props.module && (
        <FlexItem>
          <Link data-test-id="module-link" href={props.module.link} theme={{color: '#8B969E'}}>
            <Text size="medium">{props.module.name}</Text>
          </Link>
        </FlexItem>
      )}

      {props.assignmentGroup && (
        <FlexItem>
          <Link
            data-test-id="assignmentgroup-link"
            href={props.assignmentGroup.link}
            theme={{color: '#8B969E'}}
          >
            <Text size="medium">{props.assignmentGroup.name}</Text>
          </Link>
        </FlexItem>
      )}
    </Flex>
  )
}

AssignmentGroupModuleNav.propTypes = {
  module: PropTypes.shape({
    name: PropTypes.string,
    link: PropTypes.string
  }),
  assignmentGroup: PropTypes.shape({
    name: PropTypes.string,
    link: PropTypes.string
  })
}

export default React.memo(AssignmentGroupModuleNav)
