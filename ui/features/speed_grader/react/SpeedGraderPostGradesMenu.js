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
import {bool, func} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {IconEyeLine, IconOffLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import I18n from 'i18n!SpeedGraderPostGradesMenu'

export default function SpeedGraderPostGradesMenu(props) {
  const {allowHidingGradesOrComments, allowPostingGradesOrComments} = props
  const Icon = allowPostingGradesOrComments ? IconOffLine : IconEyeLine
  const menuTrigger = (
    <Button
      icon={<Icon className="speedgrader-postgradesmenu-icon" />}
      title={I18n.t('Post or Hide Grades')}
      variant="icon"
    />
  )

  return (
    <Menu placement="bottom end" trigger={menuTrigger}>
      {allowPostingGradesOrComments ? (
        <Menu.Item name="postGrades" onSelect={props.onPostGrades}>
          <Text>{I18n.t('Post Grades')}</Text>
        </Menu.Item>
      ) : (
        <Menu.Item name="postGrades" disabled>
          <Text>
            {props.hasGradesOrPostableComments
              ? I18n.t('All Grades Posted')
              : I18n.t('No Grades to Post')}
          </Text>
        </Menu.Item>
      )}

      {allowHidingGradesOrComments ? (
        <Menu.Item name="hideGrades" onSelect={props.onHideGrades}>
          <Text>{I18n.t('Hide Grades')}</Text>
        </Menu.Item>
      ) : (
        <Menu.Item name="hideGrades" disabled>
          <Text>
            {props.hasGradesOrPostableComments
              ? I18n.t('All Grades Hidden')
              : I18n.t('No Grades to Hide')}
          </Text>
        </Menu.Item>
      )}
    </Menu>
  )
}

SpeedGraderPostGradesMenu.propTypes = {
  allowHidingGradesOrComments: bool.isRequired,
  allowPostingGradesOrComments: bool.isRequired,
  hasGradesOrPostableComments: bool.isRequired,
  onHideGrades: func.isRequired,
  onPostGrades: func.isRequired
}
