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
import {func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import theme from '@instructure/canvas-theme'

const I18n = useI18nScope('assignments_2')

TeacherFooter.propTypes = {
  onCancel: func.isRequired,
  onSave: func.isRequired,
  onPublish: func.isRequired,
}
export default function TeacherFooter(props) {
  let padding
  try {
    // assuming some knowledge about canvas' DOM here, but
    // is necessary to make the footer justify itself on the page
    // the way we want
    padding = window
      .getComputedStyle(document.getElementById('content'))
      .getPropertyValue('padding-right')
  } catch (_ignore) {
    padding = '24px' // because I know that's what it is :)
  }

  const style = {
    backgroundColor: theme.variables.colors.white,
    borderColor: theme.variables.colors.borderMedium,
    paddingRight: padding,
    paddingLeft: padding,
  }

  return (
    <div className="assignments-teacher-footer" style={style} data-testid="TeacherFooter">
      <Button color="primary-inverse" margin="0 x-small 0 0" onClick={props.onCancel}>
        {I18n.t('Cancel')}
      </Button>
      <Button color="primary" margin="0 x-small 0 0" onClick={props.onSave}>
        {I18n.t('Save')}
      </Button>
      <Button color="primary" margin="0 x-small 0 0" onClick={props.onPublish}>
        {I18n.t('Publish')}
      </Button>
    </div>
  )
}
