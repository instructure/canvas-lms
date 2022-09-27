/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Flex} from '@instructure/ui-flex'
import {IconLtiSolid} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Menu} from '@instructure/ui-menu'
import React from 'react'
import {View} from '@instructure/ui-view'
import SubmissionTypeButton, {MoreOptionsButton} from './SubmissionTypeButton'
import {arrayOf, func, string} from 'prop-types'
import {ExternalTool} from '@canvas/assignments/graphql/student/ExternalTool'

export default function ExternalToolOptions({
  activeSubmissionType,
  externalTools,
  updateActiveSubmissionType,
  selectedExternalTool,
}) {
  if (externalTools.length === 0) {
    return null
  }

  // We want to show a couple tools in line with the rest of the submission
  // types, rather than hiding them behind the "More" button. For lack of a
  // better option, we just check the names directly, ignoring I18n.
  const isFavorite = tool =>
    ['Arc', 'Canvas Studio', 'Studio', 'Google Drive', 'Office 365'].some(
      name => name.toLowerCase() === tool.name.toLowerCase()
    )
  const favoriteTools = externalTools.filter(isFavorite)
  const otherTools = externalTools.filter(tool => !isFavorite(tool))

  const isToolSelected = tool =>
    activeSubmissionType === 'basic_lti_launch' && selectedExternalTool?._id === tool._id
  const isOtherToolSelected = otherTools.some(isToolSelected)

  // Functional components don't work as InstUI Menu triggers, so we have to
  // wrap our button in an invisible view
  const otherToolsTrigger = (
    <View borderWidth="0" background="transparent" padding="0">
      <MoreOptionsButton selected={isOtherToolSelected} />
    </View>
  )

  return (
    <>
      {favoriteTools.map(tool => (
        <Flex.Item as="div" key={tool._id} margin="0 medium 0 0" data-testid={`tool_${tool._id}`}>
          <SubmissionTypeButton
            displayName={tool.name}
            icon={tool.settings.iconUrl || IconLtiSolid}
            selected={isToolSelected(tool)}
            onSelected={() => {
              updateActiveSubmissionType('basic_lti_launch', tool)
            }}
          />
        </Flex.Item>
      ))}

      {otherTools.length > 0 && (
        <Menu trigger={otherToolsTrigger}>
          {otherTools.map(tool => (
            <Menu.Item
              key={tool._id}
              onSelect={() => {
                updateActiveSubmissionType('basic_lti_launch', tool)
              }}
              selected={isToolSelected(tool)}
            >
              <Img alt="" src={tool.settings.iconUrl} height="24px" width="24px" />
              {tool.name}
            </Menu.Item>
          ))}
        </Menu>
      )}
    </>
  )
}

ExternalToolOptions.propTypes = {
  activeSubmissionType: string,
  externalTools: arrayOf(ExternalTool.shape).isRequired,
  updateActiveSubmissionType: func,
  selectedExternalTool: ExternalTool.shape,
}

ExternalToolOptions.defaultProps = {
  updateActiveSubmissionType: () => {},
}
