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

import React from 'react'
import { object } from 'prop-types'
import I18n from 'i18n!outcomes'
import _ from 'lodash'
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import View from '@instructure/ui-layout/lib/components/View'
import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconAssignment from '@instructure/ui-icons/lib/Line/IconAssignment'
import IconQuiz from '@instructure/ui-icons/lib/Line/IconQuiz'
import { ListItem } from '@instructure/ui-elements/lib/components/List'

const UnassessedAssignment = ({ assignment }) => {
  const { id, url, submission_types, title } = assignment
  return (
    <ListItem key={id}>
      <View padding="small">
        <ApplyTheme theme={{[Link.theme]: {color: '#68777D'}}}>
          <Link href={ url }>
            <Flex alignItems="center">
              <FlexItem padding="0 0 0 small">
                <Text size="medium">{
                  _.includes(submission_types, 'online_quiz') ?
                    <IconQuiz /> : <IconAssignment/>}
                </Text>
              </FlexItem>
              <FlexItem padding="0 x-small">
                <Text weight="bold">{ title } ({ I18n.t('Not yet assessed') })</Text>
              </FlexItem>
            </Flex>
          </Link>
        </ApplyTheme>
      </View>
    </ListItem>
  )
}

UnassessedAssignment.propTypes = {
  assignment: object.isRequired // eslint-disable-line react/forbid-prop-types
}

export default UnassessedAssignment