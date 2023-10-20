/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {bool, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'

import EmptyGroups from '../images/empty-groups.svg'

const I18n = useI18nScope('teacher_groups_page')

const TeacherGroupsPage = props => (
  <Flex
    as="div"
    direction="column"
    alignItems="center"
    justifyItems="center"
    textAlign="center"
    margin="x-large large"
    height="50vh"
  >
    <Img data-testid="empty-groups-image" src={EmptyGroups} />
    <View width="25rem" margin="x-large none small none">
      <Text size="large">{I18n.t('This is where students can see their groups.')}</Text>
    </View>
    <Button id="k5-manage-groups-btn" href={props.groupsPath}>
      {props.canManageGroups ? I18n.t('Manage Groups') : I18n.t('View Groups')}
    </Button>
  </Flex>
)

TeacherGroupsPage.propTypes = {
  groupsPath: string.isRequired,
  canManageGroups: bool,
}

export default TeacherGroupsPage
