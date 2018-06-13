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
import I18n from 'i18n!appointment_groups'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconMiniArrowRight from '@instructure/ui-icons/lib/Solid/IconMiniArrowRight'
import IconMiniArrowDown from '@instructure/ui-icons/lib/Solid/IconMiniArrowDown'
import Grid, { GridCol, GridRow } from '@instructure/ui-layout/lib/components/Grid'

  class ContextSelector extends React.Component {
    static propTypes = {
      appointmentGroup: PropTypes.object,
      contexts: PropTypes.array,
      className: PropTypes.string
    }

    constructor () {
      super()
      this.contextCheckboxes = {}
      this.sectionsCheckboxes = {}
      this.state = {
        showDropdown: false,
        selectedContexts: new Set(),
        selectedSubContexts: new Set(),
        expandedContexts: new Set(),
      }
    }

    componentDidMount () {
      this.setIndeterminates()
    }

    componentWillReceiveProps (nextProps) {
      this.setState({
        selectedContexts: new Set(nextProps.appointmentGroup.context_codes),
        selectedSubContexts: new Set(nextProps.appointmentGroup.sub_context_codes),
        expandedContexts: new Set(),
      })
    }

    componentDidUpdate (previousProps) {
      this.setIndeterminates()
    }

    setIndeterminates () {
      for (const context in this.contextCheckboxes) {
        if (this.contextCheckboxes[context]) {
          this.contextCheckboxes[context].indeterminate = this.isContextIndeterminate(context)
        }
      }
    }


    handleContextSelectorButtonClick = (e) => {
      e.preventDefault()
      this.setState({
        showDropdown: !this.state.showDropdown
      })
    }

    handleDoneClick = (e) => {
      e.preventDefault()
      this.dropdownButton.focus()
      this.setState({
        showDropdown: false
      })
    }

    isSubContextChecked = (context, subContext) => {
      return this.state.selectedSubContexts.has(subContext) || (this.isContextChecked(context) && !this.isContextIndeterminate(context))
    }

    isSubContextDisabled = (context, subContext) => {
      return this.isContextDisabled(context) || !!this.props.appointmentGroup.sub_context_codes.find(scc => scc === subContext)
    }

    isContextChecked = (context) => {
      return this.state.selectedContexts.has(context)
    }

    isContextIndeterminate = (context) => {
      if (!this.state.selectedContexts.has(context)) { return false }
      const subContexts = this.subContextsForContext(context)
      return subContexts.some(subContext => this.state.selectedSubContexts.has(subContext))
    }

    isContextDisabled = (context) => {
      return !!this.props.appointmentGroup.context_codes.find(c => c === context)
    }

    subContextsForContext = (context) => {
      return this.props.contexts.find(c => c.asset_string === context).sections.map(s => s.asset_string)
    }

    toggleCourse = (course, select) => {
      // set course, unset sections
      const contexts = new Set(this.state.selectedContexts)
      const subContexts = new Set(this.state.selectedSubContexts)
      const subContextsToRemove = this.subContextsForContext(course)
      if (select) { contexts.add(course) } else { contexts.delete(course) }
      for (const subContext of subContextsToRemove) { subContexts.delete(subContext) }
      this.setState({
        selectedContexts: contexts,
        selectedSubContexts: subContexts
      })
    }

    toggleSection = (context, section, select) => {
      // appointment groups do this thing where if all of the sub contexts in a contexts are
      // included, we don't store them in sub_context_codes. we make an intermediate subContexts
      // set that reflects which subcontexts are checked.
      const contexts = new Set(this.state.selectedContexts)
      const subContexts = new Set(this.state.selectedSubContexts)
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

      if (select) { checkedSubContexts.add(section) } else { checkedSubContexts.delete(section) }

      // start with no sub contexts selected and then add the ones that are checked
      for (const subContext of siblingSubContexts) { subContexts.delete(subContext) }
      if ([...siblingSubContexts].every(ssc => checkedSubContexts.has(ssc))) {
        // if they're all checked, we don't actually store them as selected
        contexts.add(context)
      } else if (checkedSubContexts.size > 0) {
        for (const subContext of checkedSubContexts) { subContexts.add(subContext) }
        contexts.add(context)
      } else {
        // no sub contexts were checked
        contexts.delete(context)
      }
      this.setState({
        selectedContexts: contexts,
        selectedSubContexts: subContexts
      })
    }

    toggleCourseExpanded = (course) => {
      const contexts = new Set(this.state.expandedContexts)
      if (contexts.has(course)) { contexts.delete(course) } else { contexts.add(course) }
      this.setState({ expandedContexts: contexts })
    }

    contextName = (assetString) => {
      for (const context of this.props.contexts) {
        if (context.asset_string === assetString) { return context.name }
        for (const subContext of context.sections) {
          if (subContext.asset_string === assetString) { return subContext.name }
        }
      }
    }

    contextAndCountText = (contextSet) => {
      const contextName = this.contextName(contextSet.values().next().value) || ''
      if (contextSet.size > 1) {
        return I18n.t({ one: '%{contextName} and %{count} other',
          other: '%{contextName} and %{count} others' },
          { contextName,
            count: contextSet.size - 1 })
      }
      return contextName
    }

    buttonText = () => {
      let text = ''
      if (this.state.selectedSubContexts.size > 0) {
        text = this.contextAndCountText(this.state.selectedSubContexts)
      } else if (this.state.selectedContexts.size > 0) {
        text = this.contextAndCountText(this.state.selectedContexts)
      }
      return text || I18n.t('Select Calendars')
    }

    renderSections (context) {
      return (
        <div id={`${context.asset_string}_sections`}
             className={this.state.expandedContexts.has(context)
               ? 'CourseListItem-sections' : 'hiddenSection'}>
          {
            (context.sections || []).map(section => {
              return (
                <div className="sectionItem" key={section.asset_string}>
                  <input
                    id={`${section.asset_string}_checkbox`}
                    key={`${section.asset_string}_checkbox`}
                    type="checkbox"
                    className="CourseListItem-section-item CourseListItem-item-checkbox"
                    onChange={() => this.toggleSection(context.asset_string, section.asset_string, !this.isSubContextChecked(context.asset_string, section.asset_string))}
                    ref={(checkbox) => { this.sectionsCheckboxes[section.asset_string] = checkbox }}
                    value={section.asset_string}
                    defaultChecked={this.isSubContextChecked(context.asset_string, section.asset_string)}
                    checked={this.isSubContextChecked(context.asset_string, section.asset_string)}
                    disabled={this.isSubContextDisabled(context.asset_string, section.asset_string)}
                  />
                  {
                    // eslint-disable-next-line
                  }<label
                    className="ContextLabel CourseListItem-section-item"
                    htmlFor={`${section.asset_string}_checkbox`}>{section.name}</label>
                </div>
              )
            })
          }
        </div>
      )
    }

    renderListItems () {
      return (
        <div>
          {
            this.props.contexts.map(context => {
              const expanded = this.state.expandedContexts.has(context)
              const inputId = `${context.asset_string}_checkbox`
              return (
                <div key={context.asset_string} className="CourseListItem">
                  <div className="CourseListItem-horizontal">
                    <Button onClick={() => this.toggleCourseExpanded(context)} variant="icon">
                      {expanded ? <IconMiniArrowDown /> : <IconMiniArrowRight /> }
                    </Button>
                    <span className="screenreader-only">{context.name}</span>
                    <input
                      className="CourseListItem-item CourseListItem-item-checkbox"
                      ref={(checkbox) => { this.contextCheckboxes[context.asset_string] = checkbox }}
                      id={inputId}
                      type="checkbox"
                      onChange={() => this.toggleCourse(context.asset_string, !this.isContextChecked(context.asset_string))}
                      value={context.asset_string}
                      defaultChecked={this.isContextChecked(context.asset_string)}
                      checked={this.isContextChecked(context.asset_string)}
                      disabled={this.isContextDisabled(context.asset_string)}
                    />
                    {
                      // eslint-disable-next-line
                    }<label className="ContextLabel CourseListItem-item" htmlFor={inputId}>{context.name}</label>
                  </div>
                  {this.renderSections(context)}
                </div>
              )
            })
          }
        </div>
      )
    }

    render () {
      const classes = (this.props.className) ? `ContextSelector ${this.props.className}` :
                                               'ContextSelector'

      return (
        <div className={classes} {...this.props}>
          <Button
            ref={(c) => { this.dropdownButton = c }}
            aria-expanded={this.state.showDropdown}
            aria-controls="context-selector-dropdown"
            onClick={this.handleContextSelectorButtonClick}
          >
            {this.buttonText()}
          </Button>
          <div id="context-selector-dropdown" className={`ContextSelector__Dropdown ${this.state.showDropdown ? 'show' : 'hidden'}`}>
            <Grid>
              <GridRow hAlign="start">
                <GridCol>
                  {this.renderListItems()}
                </GridCol>
              </GridRow>
              <GridRow hAlign="end">
                <GridCol width="auto">
                  <Button onClick={this.handleDoneClick} size="small" >{I18n.t('Done')}</Button>
                </GridCol>
              </GridRow>
            </Grid>
          </div>
        </div>
      )
    }
  }

export default ContextSelector
