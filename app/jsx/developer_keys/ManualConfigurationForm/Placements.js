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
import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'

import {Select} from '@instructure/ui-forms'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {capitalizeFirstLetter} from '@instructure/ui-utils'
import difference from 'lodash/difference'
import filter from 'lodash/filter'

import Placement from './Placement'

export default class Placements extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      placements: this.props.placements
    }
    this.placementRefs = {}
  }

  generateToolConfigurationPart = () => {
    return Object.values(this.placementRefs).map(p => p.generateToolConfigurationPart())
  }

  valid = () => Object.values(this.placementRefs).every(p => p.valid())

  placements(obj) {
    return obj.map(o => o.placement)
  }

  placementDisplayName(p) {
    return p
      .split('_')
      .map(n => capitalizeFirstLetter(n))
      .join(' ')
  }

  handlePlacementSelect = (_, opts) => {
    const {placements} = this.state
    const selected = opts.map(o => o.id)
    const removed = difference(this.placements(placements), selected)
    const added = difference(selected, this.placements(placements))
    removed.forEach(p => delete this.placementRefs[`${p}Ref`])
    this.setState({
      placements: [
        ...filter(placements, p => !removed.includes(p.placement)),
        ...this.newPlacements(added)
      ]
    })
  }

  setPlacementRef = placement => node => {
    const ref = `${placement}Ref`
    if (node) {
      this.placementRefs[ref] = node
    }
    this[ref] = node
  }

  newPlacements(placements) {
    return placements.map(p => {
      return {
        placement: p
      }
    })
  }

  render() {
    const {placements} = this.state
    const {validPlacements} = this.props

    return (
      <>
        <Select
          label={I18n.t('Placements')}
          editable
          formatSelectedOption={tag => (
            <AccessibleContent alt={I18n.t('Remove %{placement}', {placement: tag.label})}>
              {tag.label}
            </AccessibleContent>
          )}
          multiple
          selectedOption={this.placements(placements)}
          onChange={this.handlePlacementSelect}
        >
          {validPlacements.map(p => {
            return (
              <option value={p} key={p}>
                {this.placementDisplayName(p)}
              </option>
            )
          })}
        </Select>
        {placements.map(p => (
          <Placement
            ref={this.setPlacementRef(p.placement)}
            placementName={p.placement}
            displayName={this.placementDisplayName(p.placement)}
            placement={p}
            key={p.placement}
          />
        ))}
      </>
    )
  }
}

Placements.propTypes = {
  validPlacements: PropTypes.arrayOf(PropTypes.string),
  placements: PropTypes.arrayOf(
    PropTypes.shape({
      placement: PropTypes.string.isRequired
    })
  )
}

Placements.defaultProps = {
  placements: [{placement: 'account_navigation'}, {placement: 'link_selection'}],
  validPlacements: []
}
