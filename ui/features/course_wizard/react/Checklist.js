/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import ChecklistItem from './ChecklistItem'
import ListItems from './ListItems'
import I18n from 'i18n!course_wizard'

class Checklist extends React.Component {
  static displayName = 'Checklist'

  static propTypes = {
    selectedItem: PropTypes.string.isRequired,
    clickHandler: PropTypes.func.isRequired,
    className: PropTypes.string.isRequired
  }

  state = {
    selectedItem: this.props.selectedItem || ''
  }

  componentWillReceiveProps(newProps) {
    this.setState({
      selectedItem: newProps.selectedItem
    })
  }

  renderChecklist = () =>
    ListItems.map(item => {
      const isSelected = this.state.selectedItem === item.key
      const id = `wizard_${item.key}`
      return (
        <ChecklistItem
          complete={item.complete}
          id={id}
          key={item.key}
          stepKey={item.key}
          title={item.title}
          onClick={this.props.clickHandler}
          isSelected={isSelected}
        />
      )
    })

  render() {
    const checklist = this.renderChecklist()
    return (
      <div className={this.props.className}>
        <h2 className="screenreader-only">{I18n.t('Setup Checklist')}</h2>
        <ul className="ic-wizard-box__nav-checklist">{checklist}</ul>
      </div>
    )
  }
}

export default Checklist
