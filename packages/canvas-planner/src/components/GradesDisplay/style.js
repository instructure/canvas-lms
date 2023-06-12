/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {getThemeVars} from '../../getThemeVars'

export default function buildStyle() {
  /*
   * If the theme variables to be used when generating the styles below
   * are dependent on the actual theme in use, you can also pull out the
   * `key` property from the return from `getThemeVars()` and do a bit of
   * if or switch statement logic to get the result you want.
   */
  const {variables, key} = getThemeVars()

  let themeCourseColor = ''
  switch (key) {
    case 'canvas':
      themeCourseColor = variables['ic-brand-primary']
      break
    case 'canvas-a11y':
    case 'modern-a11y':
      themeCourseColor = variables.colors.licorice
      break
    default:
      themeCourseColor = variables.colors.brand
  }

  const classNames = {
    course: 'GradesDisplay-styles__course',
  }

  const theme = {
    courseColor: themeCourseColor,
  }

  const css = `
  .${classNames.course} {
    border-bottom-color: ${theme.courseColor};
  }
  `

  return {css, classNames, theme}
}
