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
import {useScope as useI18nScope} from '@canvas/i18n'
import splitAssetString from '@canvas/util/splitAssetString'

const I18n = useI18nScope('react_collaborations')

// eslint-disable-next-line react/prefer-stateless-function
class NewCollaborationsDropDown extends React.Component {
  render() {
    const [context, contextId] = splitAssetString(ENV.context_asset_string)
    const hasOne = this.props?.ltiCollaborators.length === 1
    return (
      <div
        className="al-dropdown__container create-collaborations-dropdown"
        data-testid="new-collaborations-dropdown"
      >
        {hasOne ? (
          <a
            className="Button Button--primary"
            aria-label={I18n.t('Add Collaboration')}
            href={`/${context}/${contextId}/lti_collaborations/external_tools/${this.props?.ltiCollaborators[0].id}?launch_type=collaboration&display=borderless`}
          >
            {I18n.t('+ Collaboration')}
          </a>
        ) : (
          <div>
            <button
              type="button"
              className="al-trigger Button Button--primary"
              aria-label={I18n.t('Add Collaboration')}
              href="#"
            >
              {I18n.t('+ Collaboration')}
            </button>
            {/* eslint-disable-next-line jsx-a11y/role-supports-aria-props */}
            <ul
              className="al-options"
              role="menu"
              tabIndex="0"
              aria-hidden="true"
              aria-expanded="false"
              aria-activedescendant="new-collaborations-dropdown"
            >
              {this.props.ltiCollaborators.map(ltiCollaborator => {
                const itemUrl = `lti_collaborations/external_tools/${ltiCollaborator.id}?launch_type=collaboration&display=borderless`
                return (
                  <li key={ltiCollaborator.id}>
                    <a href={itemUrl} rel="external" role="menuitem">
                      {ltiCollaborator?.collaboration?.text}
                    </a>
                  </li>
                )
              })}
            </ul>
          </div>
        )}
      </div>
    )
  }
}

export default NewCollaborationsDropDown
