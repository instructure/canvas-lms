/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import I18n from 'i18n!student_context_trayRating'
import classnames from 'classnames'
import {Text} from '@instructure/ui-text'
import {Rating as InstUIRating} from '@instructure/ui-rating'
import {Heading} from '@instructure/ui-heading'

class Rating extends React.Component {
  static propTypes = {
    metric: PropTypes.shape({
      level: PropTypes.number
    }).isRequired,
    label: PropTypes.string.isRequired
  }

  formatValueText(currentRating, maxRating) {
    const valueText = {}
    valueText[I18n.t('High')] = currentRating === maxRating
    valueText[I18n.t('Moderate')] = currentRating === 2
    valueText[I18n.t('Low')] = currentRating === 1
    valueText[I18n.t('None')] = currentRating === 0
    return classnames(valueText)
  }

  render() {
    const {label, metric} = this.props
    return (
      <div className="StudentContextTray-Rating">
        <Heading level="h5" as="h4">
          {label}
        </Heading>
        <div className="StudentContextTray-Rating__Stars">
          <InstUIRating
            formatValueText={this.formatValueText}
            label={this.props.label}
            valueNow={metric.level}
            valueMax={3}
          />
          <div>
            <Text size="small" color="brand">
              {this.formatValueText(metric.level, 3)}
            </Text>
          </div>
        </div>
      </div>
    )
  }
}

export default Rating
