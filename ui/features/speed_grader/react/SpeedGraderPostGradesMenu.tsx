// @ts-nocheck
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
import {IconButton} from '@instructure/ui-buttons'
import {IconEyeLine, IconOffLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('SpeedGraderPostGradesMenu')

const {Item: MenuItem} = Menu as any

type Props = {
  allowHidingGradesOrComments: boolean
  allowPostingGradesOrComments: boolean
  hasGradesOrPostableComments: boolean
  onHideGrades: () => void
  onPostGrades: () => void
}

export default function SpeedGraderPostGradesMenu(props: Props) {
  const {allowHidingGradesOrComments, allowPostingGradesOrComments} = props
  const Icon = allowPostingGradesOrComments ? IconOffLine : IconEyeLine
  const menuTrigger = (
    <IconButton
      withBackground={false}
      withBorder={false}
      focusColor="inverse"
      screenReaderLabel={I18n.t('Post or Hide Grades')}
      data-testid="post-or-hide-grades-button"
      size="small"
    >
      <Icon className="speedgrader-postgradesmenu-icon" />
    </IconButton>
  )

  return (
    <Menu placement="bottom end" trigger={menuTrigger}>
      {allowPostingGradesOrComments ? (
        <MenuItem name="postGrades" onSelect={props.onPostGrades}>
          <Text>{I18n.t('Post Grades')}</Text>
        </MenuItem>
      ) : (
        <MenuItem name="postGrades" disabled={true}>
          <Text>
            {props.hasGradesOrPostableComments
              ? I18n.t('All Grades Posted')
              : I18n.t('No Grades to Post')}
          </Text>
        </MenuItem>
      )}

      {allowHidingGradesOrComments ? (
        <MenuItem name="hideGrades" onSelect={props.onHideGrades}>
          <Text>{I18n.t('Hide Grades')}</Text>
        </MenuItem>
      ) : (
        <MenuItem name="hideGrades" disabled={true}>
          <Text>
            {props.hasGradesOrPostableComments
              ? I18n.t('All Grades Hidden')
              : I18n.t('No Grades to Hide')}
          </Text>
        </MenuItem>
      )}
    </Menu>
  )
}
