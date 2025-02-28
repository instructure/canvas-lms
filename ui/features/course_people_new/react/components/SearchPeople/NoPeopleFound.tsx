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

import React, {type FC} from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {InlineList} from '@instructure/ui-list'
import NotFoundSVG from '../../../images/NotFound.svg'
import useCoursePeopleContext from '../../hooks/useCoursePeopleContext'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

const NoPeopleFound: FC = () => {
  const {
    canViewLoginIdColumn,
    canViewSisIdColumn
  } = useCoursePeopleContext()

  return (
    <Flex as="div" justifyItems="center">
      <Flex.Item as="div" padding="xx-large" textAlign="center">
        <Img
          src={NotFoundSVG}
          alt={I18n.t('No people found')}
          width="400px"
          height="250px"
          data-testid='no-people-found-img'
        />
      <Heading as="h2" margin="xx-small 0">
        {I18n.t('No people found')}
      </Heading>
      <View as="div" margin="small 0">
        {I18n.t('You can search by:')}
      </View>
      <InlineList>
        <InlineList.Item>
          {I18n.t('Name')}
        </InlineList.Item>
        {canViewLoginIdColumn && (
          <InlineList.Item>
              {I18n.t('Login ID')}
          </InlineList.Item>
        )}
        {canViewSisIdColumn && (
          <InlineList.Item>
              {I18n.t('SIS ID')}
          </InlineList.Item>
        )}
        <InlineList.Item
          delimiter='none'
          themeOverride={{
            noneSpacing: '0px'
          }}
        >
          {I18n.t('Canvas User ID')}
        </InlineList.Item>
      </InlineList>
      </Flex.Item>
    </Flex>
  )
}

export default NoPeopleFound
