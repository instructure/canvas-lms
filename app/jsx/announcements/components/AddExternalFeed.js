/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!announcements_v2'
import React from 'react'
import {bool, func} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'

import Button from '@instructure/ui-buttons/lib/components/Button'
import View from '@instructure/ui-layout/lib/components/View'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import Dialog from '@instructure/ui-a11y/lib/components/Dialog'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import RadioInputGroup from '@instructure/ui-forms/lib/components/RadioInputGroup'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails'
import { ConnectedRSSFeedList } from './RSSFeedList'

import actions from '../actions'
import select from '../../shared/select'

const verbosityTypes = [
  {value: 'full', label: I18n.t('Full article')},
  {value: 'truncate', label: I18n.t('Truncated')},
  {value: 'link_only', label: I18n.t('Link only')}
]

export default class AddExternalFeed extends React.Component {
  static propTypes = {
    defaultOpen: bool,
    isSaving: bool.isRequired,
    addExternalFeed: func.isRequired
  }

  static defaultProps = {
    defaultOpen: false
  }

  state = {
    isOpen: this.props.defaultOpen,
    feedURL: null,
    verbosityType: verbosityTypes[0].value,
    phraseChecked: false,
    phrase: null
  }

  focusOnToggleHeader = () => {
    setTimeout(() => {
      this.toggleBtn.focus();
    })
  }

  addRssSelection = () => {
    this.props.addExternalFeed({
      url: this.state.feedURL,
      verbosity: this.state.verbosityType,
      header_match: this.state.phrase
    })
    this.clearAddRSS()
  }

  toggleOpenState = (event, expanded) => {
    $.screenReaderFlashMessage(I18n.t('dropdown changed state to %{expanded}.', {expanded}))
    this.setState({
      isOpen: expanded
    }, this.focusOnToggleHeader)
  }

  clearAddRSS = () => {
    this.setState({
      isOpen: false,
      feedURL: null,
      verbosityType: verbosityTypes[0].value,
      phraseChecked: false,
      phrase: null
    })
  }

  handleCheckboxPhraseChecked = event => {
    this.setState({
      phraseChecked: event.target.checked
    })
  }

  handleTextInputSetPhrase = event => {
    this.setState({
      phrase: event.target.value
    })
  }

  handleTextInputSetFeedURL = event => {
    this.setState({
      feedURL: event.target.value
    })
  }

  handleRadioSelectionSetVerbosity = value => {
    this.setState({
      verbosityType: value
    })
  }

  isDoneSelecting() {
    return !!(
      this.state.feedURL &&
      (!this.state.phraseChecked || (this.state.phraseChecked && this.state.phrase))
    )
  }

  toggleRef = (c) => {
    this.toggleBtn = c && c.querySelector('button')
  }

  renderTextInput(value, text, onTextChange, name) {
    return (
      <View margin="small" display="block">
        <TextInput
          name={name}
          label={<ScreenReaderContent>{text}</ScreenReaderContent>}
          placeholder={text}
          onChange={onTextChange}
          value={value}
        />
      </View>
    )
  }

  renderRssFeedList() {
    return (
      <View
        margin="small 0"
        as="div"
        textAlign="start"
        className="announcements-tray__rss-feed-root"
      >
        <ConnectedRSSFeedList focusLastElement={this.focusOnToggleHeader}/>
      </View>
    )
  }

  renderEmbeddedSelection() {
    return (
      <View margin="small 0" display="block">
        <RadioInputGroup
          name="verbosity-selection"
          onChange={(e, val) => this.handleRadioSelectionSetVerbosity(val)}
          defaultValue={this.state.verbosityType}
          layout="inline"
          description={
            <ScreenReaderContent>{I18n.t('Select embedded content type')}</ScreenReaderContent>
          }
        >
          {verbosityTypes.map(input => (
            <RadioInput key={input.value} value={input.value} label={input.label} />
          ))}
        </RadioInputGroup>
      </View>
    )
  }

  renderSubmitButtons() {
    return (
      <View
        id="external-rss-feed__submit-button-group"
        margin="medium 0 small"
        textAlign="end"
        display="block"
      >
        <Button onClick={this.clearAddRSS} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button
          id="external-rss-feed__submit-button"
          disabled={!this.isDoneSelecting()}
          type="submit"
          variant="primary"
          onClick={this.addRssSelection}
          margin="0 x-small 0 0"
        >
          {I18n.t('Add Feed')}
        </Button>
      </View>
    )
  }

  renderSpecificHeaderPhrase() {
    return (
      <div className="announcements-tray-row">
        <View margin="medium 0" display="block">
          <Checkbox
            checked={this.state.phraseChecked}
            onChange={this.handleCheckboxPhraseChecked}
            label={I18n.t('Only add posts with a specific phrase in the title')}
            name="external-rss-feed__phrase-checkbox"
          />
          {this.state.phraseChecked &&
            this.renderTextInput(
              this.state.phrase,
              I18n.t('Enter specific phrase'),
              this.handleTextInputSetPhrase,
              'external-rss-feed__phrase-input'
            )}
        </View>
      </div>
    )
  }

  render() {
    return (
      <View id="external-rss-feed__header" display="block" textAlign="start">
        <span id="external-rss-feed__toggle-button" ref={this.toggleRef}>
          <ToggleDetails
            id="external-rss-feed__toggle"
            summary={I18n.t('Add External Feed')}
            onToggle={this.toggleOpenState}
            expanded={this.state.isOpen}
            name="external-rss-feed__toggle"
          >
            <Dialog open={this.state.isOpen} shouldReturnFocus defaultFocusElement={() => this.toggleBtn}>
              {this.renderTextInput(
                this.state.feedURL,
                I18n.t('Feed url'),
                this.handleTextInputSetFeedURL,
                'external-rss-feed__url-input'
              )}
              {this.renderEmbeddedSelection()}
              {this.renderSpecificHeaderPhrase()}
              {this.renderSubmitButtons()}
            </Dialog>
          </ToggleDetails>
        </span>
        {this.renderRssFeedList()}
      </View>
    )
  }
}

const connectState = state =>
  Object.assign({
    isSaving: state.externalRssFeed.isSaving
  })
const connectActions = dispatch =>
  bindActionCreators(select(actions, ['addExternalFeed']), dispatch)
export const ConnectedAddExternalFeed = connect(connectState, connectActions)(AddExternalFeed)
