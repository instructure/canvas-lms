/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {shape, string} from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import TruncateText from '@instructure/ui-elements/lib/components/TruncateText'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import View from '@instructure/ui-layout/lib/components/View'

export default class CourseLink extends React.Component {

  static propTypes = {
    course: shape({
      id: string.isRequired,
      name: string.isRequired
    }).isRequired
  }

  static defaultProps = {
    course: {}
  }

  constructor (props) {
    super(props)
    this.state = {
      isTruncated: false
    }
  }

  handleUpdate = (isTruncated) => {
    if (this.state.isTruncated !== isTruncated) {
      this.setState({ isTruncated })
    }
  }

  renderCourseLink () {
    return (
      <Button
        fluidWidth
        variant="link"
        theme={{mediumPadding: '0'}}
        href={`/courses/${this.props.course.id}`}
      >
        <TruncateText
          position="middle"
          onUpdate={this.handleUpdate}
        >
            {this.props.course.name}
        </TruncateText>
      </Button>
    )
  }

  render() {
    return (this.state.isTruncated ? (
        <Tooltip
          variant="inverse"
          tip={<View as="div" maxWidth="20em">{this.props.course.name}</View>}
        >
          { this.renderCourseLink() }
        </Tooltip>
      ) : this.renderCourseLink()
    )
  }
}
