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

import React, {useState} from 'react'
import PropTypes from 'prop-types'

import {Tabs} from '@instructure/ui-tabs'
import {IconButton} from '@instructure/ui-buttons'
import buttons from './buttons'
import MathIcon from '../MathIcon'

const buttonContainerStyle = {
  display: 'inline-block',
  marginBottom: '5px',
  paddingRight: '5px',
}

function EquationEditorToolbar(props) {
  const [selectedTab, setSelectedTab] = useState('Basic')

  const handleTabChange = (event, {index}) => {
    setSelectedTab(buttons[index].name)
  }

  const renderTabPanel = section => (
    <Tabs.Panel
      id={section.name}
      key={section.name}
      padding="small small"
      renderTitle={section.name}
      isSelected={selectedTab === section.name}
    >
      {section.commands.map(({displayName, command, advancedCommand, label}) => {
        const name = displayName || command
        const icon = <MathIcon command={command} />

        // I'm inlining styles here because for some reason the RCE plugin plays
        // poorly with the way webpack is compiling styles, causing rules from a
        // styles.css file to not show up. It would be nice to figure out how to
        // fix this, though.
        return (
          <div style={buttonContainerStyle} key={name}>
            <IconButton
              onClick={() => props.executeCommand(command, advancedCommand)}
              renderIcon={icon}
              screenReaderLabel={`${label}, LaTeX: ${name}`}
            />
          </div>
        )
      })}
    </Tabs.Panel>
  )

  return (
    <Tabs
      variant="secondary"
      onRequestTabChange={handleTabChange}
      minHeight="10rem"
      maxHeight="10rem"
      maxWidth="42rem"
    >
      {buttons.map(renderTabPanel)}
    </Tabs>
  )
}

EquationEditorToolbar.propTypes = {
  executeCommand: PropTypes.func.isRequired,
}

const MemoizedEquationEditorToolbar = React.memo(EquationEditorToolbar)
export default MemoizedEquationEditorToolbar
