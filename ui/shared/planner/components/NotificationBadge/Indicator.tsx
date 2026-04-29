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
import {string, func} from 'prop-types'
import {Badge} from '@instructure/ui-badge'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export default class Indicator extends Component {
  static propTypes = {
    title: string.isRequired,
    variant: string.isRequired,
    indicatorRef: func,
    testId: string,
  }

  static defaultProps = {
    indicatorRef: () => {},
  }

  render() {
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <div ref={this.props.indicatorRef} data-testid={this.props.testId}>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.variant !== 'invisible' && (
          // @ts-expect-error TS2339 (typescriptify)
          <Badge standalone={true} type="notification" variant={this.props.variant} />
        )}
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <ScreenReaderContent>{this.props.title}</ScreenReaderContent>
      </div>
    )
  }
}
