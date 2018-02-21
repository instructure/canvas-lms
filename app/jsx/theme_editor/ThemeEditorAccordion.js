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
import I18n from 'i18n!theme_editor'
import $ from 'jquery'
import 'jqueryui/accordion'
import Text from '@instructure/ui-core/lib/components/Text'
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
    refactorEnabled: PropTypes.bool,
    accordionContextOverride: PropTypes.object, // Temporary prop that should be removed after removing the refactorEnabled stuff
    themeState: PropTypes.object,
    handleThemeStateChange: PropTypes.func
  }

  static defaultProps = {
    refactorEnabled: false
  }

  state = {
    expandedIndex: Number(window.sessionStorage.getItem(activeIndexKey))
  }

  componentDidMount() {
    if (!this.props.refactorEnabled) {
      this.initAccordion()
    }
  }

  setStoredAccordionIndex(index) {
    window.sessionStorage.setItem(activeIndexKey, index)
  }

  getStoredAccordionIndex = () => {
    if (!this.props.refactorEnabled) {
      // Note that "Number(null)" returns 0
      return Number(window.sessionStorage.getItem(activeIndexKey))
    }
  }

  // Returns the index of the current accordion pane open
  getCurrentIndex = () => {
    if (!this.props.refactorEnabled) {
      return $(this.rootNode).accordion('option', 'active')
    }
  }

  // Remembers which accordion pane is open
  rememberActiveIndex = () => {
    if (!this.props.refactorEnabled) {
      const index = this.getCurrentIndex()
      this.setStoredAccordionIndex(index)
    }
  }

  initAccordion = () => {
    if (!this.props.refactorEnabled) {
      const self = this.props.accordionContextOverride || this
      const index = self.getStoredAccordionIndex()
      $(self.rootNode).accordion({
        active: index,
        header: 'h3',
        heightStyle: 'content',
        beforeActivate(event, ui) {
          const previewIframe = $('#previewIframe')
          if ($.trim(ui.newHeader[0].innerText) === 'Login Screen') {
            const loginPreview = previewIframe.contents().find('#login-preview')
            if (loginPreview) previewIframe.scrollTo(loginPreview)
          } else {
            previewIframe.scrollTo(0)
          }
        },
        activate: self.rememberActiveIndex
      })
    }
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
      refactorEnabled: this.props.refactorEnabled,
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
    if (!this.props.refactorEnabled) {
      return (
        <div
          ref={c => (this.rootNode = c)}
          className="accordion ui-accordion--mini Theme__editor-accordion"
        >
          {this.props.variableSchema.map(variableGroup => [
            <h3>
              <a href="#">
                <div className="te-Flex">
                  <span className="te-Flex__block">{variableGroup.group_name}</span>
                  <i className="Theme__editor-accordion-icon icon-mini-arrow-right" />
                </div>
              </a>
            </h3>,
            <div>{variableGroup.variables.map(this.renderRow)}</div>
          ])}
        </div>
      )
    } else {
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
}
