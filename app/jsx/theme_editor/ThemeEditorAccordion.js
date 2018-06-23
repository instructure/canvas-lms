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
import PropTypes from 'prop-types'
import I18n from 'i18nObj'
import $ from 'jquery'
import 'jqueryui/accordion'
import Text from '@instructure/ui-elements/lib/components/Text'
import ThemeEditorColorRow from './ThemeEditorColorRow'
import ThemeEditorImageRow from './ThemeEditorImageRow'
import ThemeEditorVariableGroup from './ThemeEditorVariableGroup'
import RangeInput from './RangeInput'
import customTypes from './PropTypes'

const activeIndexKey = 'Theme__editor-accordion-index'

export default class ThemeEditorAccordion extends React.Component {
  static propTypes = {
    variableSchema: customTypes.variableSchema,
    brandConfigVariables: PropTypes.object.isRequired,
    changedValues: PropTypes.object.isRequired,
    changeSomething: PropTypes.func.isRequired,
    getDisplayValue: PropTypes.func.isRequired,
    themeState: PropTypes.object,
    handleThemeStateChange: PropTypes.func
  }

  state = {
    expandedIndex: Number(window.sessionStorage.getItem(activeIndexKey))
  }

  setStoredAccordionIndex(index) {
    window.sessionStorage.setItem(activeIndexKey, index)
  }

  handleToggle = (event, expanded, index) => {
    this.setState(
      {
        expandedIndex: index
      },
      () => {
        this.setStoredAccordionIndex(index)
      }
    )
  }

  renderRow = varDef => {
    const props = {
      key: varDef.variable_name,
      currentValue: this.props.brandConfigVariables[varDef.variable_name],
      userInput: this.props.changedValues[varDef.variable_name],
      onChange: this.props.changeSomething.bind(null, varDef.variable_name),
      placeholder: this.props.getDisplayValue(varDef.variable_name),
      themeState: this.props.themeState,
      handleThemeStateChange: this.props.handleThemeStateChange,
      varDef
    }

    switch (varDef.type) {
      case 'color':
        return <ThemeEditorColorRow {...props} />
      case 'image':
        return <ThemeEditorImageRow {...props} />
      case 'percentage':
        const defaultValue = props.currentValue || props.placeholder
        return (
          <RangeInput
            key={varDef.variable_name}
            labelText={varDef.human_name}
            min={0}
            max={1}
            step={0.1}
            defaultValue={defaultValue ? parseFloat(defaultValue) : 0.5}
            name={`brand_config[variables][${varDef.variable_name}]`}
            variableKey={varDef.variable_name}
            onChange={value => props.onChange(value)}
            themeState={props.themeState}
            handleThemeStateChange={props.handleThemeStateChange}
            formatValue={value => I18n.toPercentage(value * 100, {precision: 0})}
          />
        )
      default:
        return null
    }
  }

  render() {
    return (
      <div>
        {this.props.variableSchema.map((variableGroup, index) => (
          <ThemeEditorVariableGroup
            key={variableGroup.group_name}
            summary={
              <Text as="h3" weight="bold">
                {variableGroup.group_name}
              </Text>
            }
            index={index}
            expanded={index === this.state.expandedIndex}
            onToggle={this.handleToggle}
          >
            {variableGroup.variables.map(this.renderRow)}
          </ThemeEditorVariableGroup>
        ))}
      </div>
    )
  }
}
