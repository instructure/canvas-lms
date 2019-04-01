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

import React, {Fragment} from 'react'
import {bool, func, shape} from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!hide_assignment_grades_tray'

import Description from './Description'

export default function Layout(props) {
  const {assignment, dismiss, hidingGrades, onHideClick} = props
  const {gradesPublished} = assignment

  return (
    <Fragment>
      <View as="div" padding="0 medium">
        <Heading as="h3" level="h4">
          {I18n.t('Hide Grades')}
        </Heading>
      </View>

      <View as="div" margin="0 medium" className="hr" />

      <View as="div" margin="medium 0" padding="0 medium">
        <Description />
      </View>

      <View as="div" margin="0 medium" className="hr" />

      {!gradesPublished && (
        <View as="p" margin="small 0 small" padding="0 medium">
          <Text>
            {I18n.t(
              'Hiding grades is not allowed because no grades have been posted for this assignment.'
            )}
          </Text>
        </View>
      )}

      <View as="div" margin="medium 0 0" padding="0 medium">
        <Flex justifyItems="end">
          <FlexItem margin="0 small 0 0">
            <Button onClick={dismiss}>{I18n.t('Close')}</Button>
          </FlexItem>

          <FlexItem>
            <Button
              disabled={hidingGrades || !gradesPublished}
              onClick={onHideClick}
              variant="primary"
            >
              {I18n.t('Hide')}
            </Button>
          </FlexItem>
        </Flex>
      </View>
    </Fragment>
  )
}

Layout.propTypes = {
  assignment: shape({
    gradesPublished: bool.isRequired
  }).isRequired,
  dismiss: func.isRequired,
  hidingGrades: bool.isRequired,
  onHideClick: func.isRequired
}
