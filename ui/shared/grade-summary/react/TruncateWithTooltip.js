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
import PropTypes from 'prop-types'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {pickProps} from '@instructure/ui-react-utils'

export default class TruncateWithTooltip extends React.Component {
  static propTypes = {
    children: PropTypes.node.isRequired,
  }

  state = {
    isTruncated: false,
  }

  onTruncationUpdate = isTruncated => {
    if (isTruncated !== this.state.isTruncated) {
      this.setState({isTruncated})
    }
  }

  render() {
    const {children: text, ...remainingProps} = this.props
    // eslint-disable-next-line react/forbid-foreign-prop-types
    const tooltipProps = pickProps(remainingProps, Tooltip.propTypes)
    // eslint-disable-next-line react/forbid-foreign-prop-types
    const truncateProps = pickProps(remainingProps, TruncateText.propTypes)

    const truncatedText = (
      <TruncateText onUpdate={this.onTruncationUpdate} {...truncateProps}>
        {text}
      </TruncateText>
    )
    if (this.state.isTruncated) {
      return (
        <Tooltip {...tooltipProps} renderTip={text}>
          <span>{truncatedText}</span>
        </Tooltip>
      )
    } else {
      return truncatedText
    }
  }
}
