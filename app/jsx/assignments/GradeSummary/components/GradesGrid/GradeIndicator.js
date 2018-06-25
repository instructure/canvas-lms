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

import React, {Component} from 'react'
import {bool, number, shape, string} from 'prop-types'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!assignment_grade_summary'

export default class GradeIndicator extends Component {
  static propTypes = {
    gradeInfo: shape({
      grade: string,
      graderId: string.isRequired,
      id: string.isRequired,
      score: number,
      selected: bool.isRequired,
      studentId: string.isRequired
    })
  }

  static defaultProps = {
    gradeInfo: null
  }

  shouldComponentUpdate(nextProps) {
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  render() {
    const {gradeInfo} = this.props
    const selected = gradeInfo && gradeInfo.selected
    let textColor = selected ? 'primary-inverse' : 'primary'
    textColor = gradeInfo ? textColor : 'secondary'

    return (
      <View
        background={selected ? 'inverse' : 'default'}
        borderRadius="small"
        borderWidth={selected ? 'small' : '0'}
        padding="xx-small small"
      >
        <Text color={textColor}>
          {gradeInfo && gradeInfo.score != null ? I18n.n(gradeInfo.score) : '–'}
        </Text>

        {selected && <ScreenReaderContent>{I18n.t('Selected Grade')}</ScreenReaderContent>}
      </View>
    )
  }
}
