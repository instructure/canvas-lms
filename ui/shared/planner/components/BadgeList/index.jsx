/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Children} from '@instructure/ui-prop-types'
import {Pill} from '@instructure/ui-pill'
import buildStyle from './style'

export default class BadgeList extends Component {
  constructor(props) {
    super(props)
    this.style = buildStyle()
  }

  renderChildren = () =>
    React.Children.map(this.props.children, child => (
      <li key={child.key} className={this.style.classNames.item}>
        {child}
      </li>
    ))

  render = () => (
    <>
      <style>{this.style.css}</style>
      <ul className={this.style.classNames.root}>{this.renderChildren()}</ul>
    </>
  )
}

BadgeList.propTypes = {
  children: Children.oneOf([Pill]),
}
