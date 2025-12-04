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
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'

import CanvasMultiSelect from '@canvas/multi-select'
import {capitalizeFirstLetter} from '@instructure/ui-utils'
import {difference, filter} from 'es-toolkit/compat'

import Placement from './Placement'
import {LtiPlacements} from '../../model/LtiPlacements'
import {filterPlacementsByFeatureFlags} from '@canvas/lti/model/LtiPlacementFilter'

const I18n = createI18nScope('react_developer_keys')

export default class Placements extends React.Component {
  constructor(props) {
    super(props)
    const allPlacements = Object.values(LtiPlacements).filter(p => p !== 'default_placements')
    const validPlacements = filterPlacementsByFeatureFlags(allPlacements)
    const validPlacementNames = new Set(validPlacements)
    const filteredPlacements = (props.placements || []).filter(p =>
      validPlacementNames.has(p.placement),
    )
    this.state = {
      placements: filteredPlacements,
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
    if (p === LtiPlacements.ActivityAssetProcessor) {
      return 'Assignment Document Processor'
    }
    if (p === LtiPlacements.ActivityAssetProcessorContribution) {
      return 'Discussions Document Processor'
    }
    return p
      .split('_')
      .map(n => capitalizeFirstLetter(n))
      .join(' ')
  }

  handlePlacementSelect = selected => {
    const {placements} = this.state
    const removed = difference(this.placements(placements), selected)
    const added = difference(selected, this.placements(placements))
    removed.forEach(p => delete this.placementRefs[`${p}Ref`])
    this.setState({
      placements: [
        ...filter(placements, p => !removed.includes(p.placement)),
        ...this.newPlacements(added),
      ],
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
        placement: p,
      }
    })
  }

  render() {
    const {placements} = this.state
    const allPlacements = Object.values(LtiPlacements).filter(p => p !== 'default_placements')
    const validPlacements = filterPlacementsByFeatureFlags(allPlacements)

    return (
      <>
        <CanvasMultiSelect
          label={I18n.t('Placements')}
          assistiveText={I18n.t(
            'Select Placements. Type or use arrow keys to navigate. Multiple selections are allowed.',
          )}
          selectedOptionIds={this.placements(placements)}
          onChange={this.handlePlacementSelect}
        >
          {validPlacements.map(p => {
            return (
              <CanvasMultiSelect.Option id={p} value={p} key={p}>
                {this.placementDisplayName(p)}
              </CanvasMultiSelect.Option>
            )
          })}
        </CanvasMultiSelect>
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
  placements: PropTypes.arrayOf(
    PropTypes.shape({
      placement: PropTypes.string.isRequired,
    }),
  ),
}

Placements.defaultProps = {
  placements: [{placement: 'account_navigation'}, {placement: 'link_selection'}],
}
