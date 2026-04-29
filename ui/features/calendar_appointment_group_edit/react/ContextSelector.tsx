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
import PropTypes from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconMiniArrowEndSolid, IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Grid} from '@instructure/ui-grid'

const I18n = createI18nScope('appointment_groups')

class ContextSelector extends React.Component {
  static propTypes = {
    appointmentGroup: PropTypes.object,
    contexts: PropTypes.array,
    className: PropTypes.string,
    selectedContexts: PropTypes.instanceOf(Set).isRequired,
    selectedSubContexts: PropTypes.instanceOf(Set).isRequired,
    setSelectedContexts: PropTypes.func.isRequired,
    setSelectedSubContexts: PropTypes.func.isRequired,
  }

  constructor() {
    // @ts-expect-error TS2554 (typescriptify)
    super()
    // @ts-expect-error TS2339 (typescriptify)
    this.contextCheckboxes = {}
    // @ts-expect-error TS2339 (typescriptify)
    this.sectionsCheckboxes = {}
    this.state = {
      showDropdown: false,
      expandedContexts: new Set(),
    }
  }

  componentDidMount() {
    this.setIndeterminates()
  }

  // @ts-expect-error TS7006 (typescriptify)
  componentDidUpdate(_previousProps) {
    this.setIndeterminates()
  }

  setIndeterminates() {
    // @ts-expect-error TS2339 (typescriptify)
    for (const context in this.contextCheckboxes) {
      // @ts-expect-error TS2339 (typescriptify)
      if (this.contextCheckboxes[context]) {
        // @ts-expect-error TS2339 (typescriptify)
        this.contextCheckboxes[context].indeterminate = this.isContextIndeterminate(context)
      }
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleContextSelectorButtonClick = e => {
    e.preventDefault()
    this.setState({
      // @ts-expect-error TS2339 (typescriptify)
      showDropdown: !this.state.showDropdown,
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleDoneClick = e => {
    e.preventDefault()
    // @ts-expect-error TS2339 (typescriptify)
    this.dropdownButton.focus()
    this.setState({
      showDropdown: false,
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  isSubContextChecked = (context, subContext) => {
    return (
      // @ts-expect-error TS2339 (typescriptify)
      this.props.selectedSubContexts.has(subContext) ||
      (this.isContextChecked(context) && !this.isContextIndeterminate(context))
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  isSubContextDisabled = (context, subContext) => {
    return (
      this.isContextDisabled(context) ||
      // @ts-expect-error TS2339,TS7006 (typescriptify)
      !!this.props.appointmentGroup.sub_context_codes.find(scc => scc === subContext)
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  isContextChecked = context => {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.selectedContexts.has(context)
  }

  // @ts-expect-error TS7006 (typescriptify)
  isContextIndeterminate = context => {
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.selectedContexts.has(context)) {
      return false
    }
    const subContexts = this.subContextsForContext(context)
    // @ts-expect-error TS2339,TS7006 (typescriptify)
    return subContexts.some(subContext => this.props.selectedSubContexts.has(subContext))
  }

  // @ts-expect-error TS7006 (typescriptify)
  isContextDisabled = context => {
    // @ts-expect-error TS2339,TS7006 (typescriptify)
    return !!this.props.appointmentGroup.context_codes.find(c => c === context)
  }

  // @ts-expect-error TS7006 (typescriptify)
  subContextsForContext = context => {
    return (
      // @ts-expect-error TS2339 (typescriptify)
      this.props.contexts
        // @ts-expect-error TS7006 (typescriptify)
        .find(c => c.asset_string === context)
        // @ts-expect-error TS7006 (typescriptify)
        .sections.map(s => s.asset_string)
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  toggleCourse = (course, select) => {
    // set course, unset sections
    // @ts-expect-error TS2339 (typescriptify)
    const contexts = new Set(this.props.selectedContexts)
    // @ts-expect-error TS2339 (typescriptify)
    const subContexts = new Set(this.props.selectedSubContexts)
    const subContextsToRemove = this.subContextsForContext(course)
    if (select) {
      contexts.add(course)
    } else {
      contexts.delete(course)
    }
    for (const subContext of subContextsToRemove) {
      subContexts.delete(subContext)
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.props.setSelectedContexts(contexts)
    // @ts-expect-error TS2339 (typescriptify)
    this.props.setSelectedSubContexts(subContexts)
  }

  // @ts-expect-error TS7006 (typescriptify)
  toggleSection = (context, section, select) => {
    // appointment groups do this thing where if all of the sub contexts in a contexts are
    // included, we don't store them in sub_context_codes. we make an intermediate subContexts
    // set that reflects which subcontexts are checked.
    // @ts-expect-error TS2339 (typescriptify)
    const contexts = new Set(this.props.selectedContexts)
    // @ts-expect-error TS2339 (typescriptify)
    const subContexts = new Set(this.props.selectedSubContexts)
    const siblingSubContexts = new Set(this.subContextsForContext(context))
    let checkedSubContexts = new Set()
    for (const subContext of subContexts) {
      if (siblingSubContexts.has(subContext)) {
        checkedSubContexts.add(subContext)
      }
    }

    // make implicit checked status explicit
    if (checkedSubContexts.size === 0 && contexts.has(context)) {
      checkedSubContexts = new Set(siblingSubContexts)
    }

    if (select) {
      checkedSubContexts.add(section)
    } else {
      checkedSubContexts.delete(section)
    }

    // start with no sub contexts selected and then add the ones that are checked
    for (const subContext of siblingSubContexts) {
      subContexts.delete(subContext)
    }
    if ([...siblingSubContexts].every(ssc => checkedSubContexts.has(ssc))) {
      // if they're all checked, we don't actually store them as selected
      contexts.add(context)
    } else if (checkedSubContexts.size > 0) {
      for (const subContext of checkedSubContexts) {
        subContexts.add(subContext)
      }
      contexts.add(context)
    } else {
      // no sub contexts were checked
      contexts.delete(context)
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.props.setSelectedContexts(contexts)
    // @ts-expect-error TS2339 (typescriptify)
    this.props.setSelectedSubContexts(subContexts)
  }

  // @ts-expect-error TS7006 (typescriptify)
  toggleCourseExpanded = course => {
    // @ts-expect-error TS2339 (typescriptify)
    const contexts = new Set(this.state.expandedContexts)
    if (contexts.has(course)) {
      contexts.delete(course)
    } else {
      contexts.add(course)
    }
    this.setState({expandedContexts: contexts})
  }

  // @ts-expect-error TS7006 (typescriptify)
  contextName = assetString => {
    // @ts-expect-error TS2339 (typescriptify)
    for (const context of this.props.contexts) {
      if (context.asset_string === assetString) {
        return context.name
      }
      for (const subContext of context.sections) {
        if (subContext.asset_string === assetString) {
          return subContext.name
        }
      }
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  contextAndCountText = contextSet => {
    const contextName = this.contextName(contextSet.values().next().value) || ''
    if (contextSet.size > 1) {
      return I18n.t(
        {one: '%{contextName} and %{count} other', other: '%{contextName} and %{count} others'},
        {contextName, count: contextSet.size - 1},
      )
    }
    return contextName
  }

  buttonText = () => {
    let text = ''
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.selectedSubContexts.size > 0) {
      // @ts-expect-error TS2339 (typescriptify)
      text = this.contextAndCountText(this.props.selectedSubContexts)
      // @ts-expect-error TS2339 (typescriptify)
    } else if (this.props.selectedContexts.size > 0) {
      // @ts-expect-error TS2339 (typescriptify)
      text = this.contextAndCountText(this.props.selectedContexts)
    }
    return text || I18n.t('Select Calendars')
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderSections(context) {
    const filteredSections =
      // @ts-expect-error TS7006 (typescriptify)
      context.sections?.filter(section => section.can_create_appointment_groups) ?? []
    return (
      <div
        id={`${context.asset_string}_sections`}
        className={
          // @ts-expect-error TS2339 (typescriptify)
          this.state.expandedContexts.has(context) ? 'CourseListItem-sections' : 'hiddenSection'
        }
      >
        {/* @ts-expect-error TS7006 (typescriptify) */}
        {filteredSections.map(section => {
          return (
            <div className="sectionItem" key={section.asset_string}>
              <input
                id={`${section.asset_string}_checkbox`}
                key={`${section.asset_string}_checkbox`}
                type="checkbox"
                className="CourseListItem-section-item CourseListItem-item-checkbox"
                onChange={() =>
                  this.toggleSection(
                    context.asset_string,
                    section.asset_string,
                    !this.isSubContextChecked(context.asset_string, section.asset_string),
                  )
                }
                ref={checkbox => {
                  // @ts-expect-error TS2339 (typescriptify)
                  this.sectionsCheckboxes[section.asset_string] = checkbox
                }}
                value={section.asset_string}
                checked={this.isSubContextChecked(context.asset_string, section.asset_string)}
                disabled={this.isSubContextDisabled(context.asset_string, section.asset_string)}
              />
              {}
              <label
                className="ContextLabel CourseListItem-section-item"
                htmlFor={`${section.asset_string}_checkbox`}
              >
                {section.name}
              </label>
            </div>
          )
        })}
      </div>
    )
  }

  renderListItems() {
    // @ts-expect-error TS2339 (typescriptify)
    const filteredContexts = this.props.contexts.filter(
      // @ts-expect-error TS7006 (typescriptify)
      context =>
        context.can_create_appointment_groups ||
        // @ts-expect-error TS7006 (typescriptify)
        context.sections?.some(section => section.can_create_appointment_groups),
    )
    return (
      <div>
        {/* @ts-expect-error TS7006 (typescriptify) */}
        {filteredContexts.map(context => {
          // @ts-expect-error TS2339 (typescriptify)
          const expanded = this.state.expandedContexts.has(context)
          const inputId = `${context.asset_string}_checkbox`
          return (
            <div key={context.asset_string} className="CourseListItem">
              <div className="CourseListItem-horizontal">
                <IconButton
                  data-testid={`expand-course-${context.id}`}
                  screenReaderLabel={
                    expanded
                      ? I18n.t('Collapse %{name}', {name: context.name})
                      : I18n.t('Expand %{name}', {name: context.name})
                  }
                  renderIcon={expanded ? <IconMiniArrowDownSolid /> : <IconMiniArrowEndSolid />}
                  onClick={() => this.toggleCourseExpanded(context)}
                  withBorder={false}
                  withBackground={false}
                  margin="0 x-small 0 0"
                />
                <input
                  className="CourseListItem-item CourseListItem-item-checkbox"
                  ref={checkbox => {
                    // @ts-expect-error TS2339 (typescriptify)
                    this.contextCheckboxes[context.asset_string] = checkbox
                  }}
                  id={inputId}
                  type="checkbox"
                  onChange={() =>
                    this.toggleCourse(
                      context.asset_string,
                      !this.isContextChecked(context.asset_string),
                    )
                  }
                  value={context.asset_string}
                  checked={this.isContextChecked(context.asset_string)}
                  disabled={this.isContextDisabled(context.asset_string)}
                />
                {}
                <label className="ContextLabel CourseListItem-item" htmlFor={inputId}>
                  {context.name}
                </label>
              </div>
              {this.renderSections(context)}
            </div>
          )
        })}
      </div>
    )
  }

  render() {
    // @ts-expect-error TS2339 (typescriptify)
    const classes = this.props.className
      ? // @ts-expect-error TS2339 (typescriptify)
        `ContextSelector ${this.props.className}`
      : 'ContextSelector'

    return (
      <div className={classes}>
        <Button
          ref={c => {
            // @ts-expect-error TS2339 (typescriptify)
            this.dropdownButton = c
          }}
          data-testid="select-calendars-button"
          // @ts-expect-error TS2339 (typescriptify)
          aria-expanded={this.state.showDropdown}
          aria-controls="context-selector-dropdown"
          onClick={this.handleContextSelectorButtonClick}
        >
          {this.buttonText()}
        </Button>
        <div
          id="context-selector-dropdown"
          data-testid="context-selector-dropdown"
          // @ts-expect-error TS2339 (typescriptify)
          className={`ContextSelector__Dropdown ${this.state.showDropdown ? 'show' : 'hidden'}`}
        >
          <Grid>
            <Grid.Row hAlign="start">
              <Grid.Col>{this.renderListItems()}</Grid.Col>
            </Grid.Row>
            <Grid.Row hAlign="end">
              <Grid.Col width="auto">
                <Button onClick={this.handleDoneClick} size="small">
                  {I18n.t('Done')}
                </Button>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </div>
      </div>
    )
  }
}

export default ContextSelector
