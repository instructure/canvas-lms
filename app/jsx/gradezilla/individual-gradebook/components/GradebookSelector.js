/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import { head, tail } from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import Select from '@instructure/ui-core/lib/components/Select'
import Text from '@instructure/ui-core/lib/components/Text'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import I18n from 'i18n!gradebook'

  const INDIVIDUAL_GRADEBOOK = 'IndividualGradebook';
  const LEARNING_MASTERY = 'LearningMastery';

  function isLearningMastery (state) {
    return state.value === LEARNING_MASTERY;
  }

  class GradebookSelector extends React.Component {
    static propTypes = {
      courseUrl: PropTypes.string.isRequired,
      learningMasteryEnabled: PropTypes.bool.isRequired
    };

    constructor (props) {
      super(props);

      this.state = { value: INDIVIDUAL_GRADEBOOK };

      this.handleOnChange = this.handleOnChange.bind(this);
    }

    setLocation (url) {
      window.location = url;
    }

    selectIndividualGradebook () {
      this.setState({ value: INDIVIDUAL_GRADEBOOK }, () => {
        // hacky way to avoid needing to crack open Ember code
        document.querySelectorAll('ic-tab')[0].click();
      });
    }

    selectLearningMastery () {
      this.setState({ value: LEARNING_MASTERY }, () => {
        // hacky way to avoid needing to crack open Ember code
        document.querySelectorAll('ic-tab')[1].click();
      });
    }

    selectGradebookHistory () { this.setLocation(`${this.props.courseUrl}/gradebook/history`); }

    selectDefaultGradebook () {
      this.setLocation(`${this.props.courseUrl}/gradebook/change_gradebook_version?version=default`);
    }

    handleOnChange (e) {
      const valueFunctionMap = {
        'individual-gradebook': this.selectIndividualGradebook.bind(this),
        'learning-mastery': this.selectLearningMastery.bind(this),
        'default-gradebook': this.selectDefaultGradebook.bind(this),
        'gradebook-history': this.selectGradebookHistory.bind(this)
      };
      valueFunctionMap[e.target.value]();
    }

    renderOptions () {
      let modifiedVariant = 'IndividualGradebook';
      if (this.props.learningMasteryEnabled && isLearningMastery(this.state)) {
        modifiedVariant = `${modifiedVariant}LearningMastery`;
      }
      const optionsForGradebook = {
        IndividualGradebook: ['IndividualGradebook', 'LearningMastery', 'DefaultGradebook', 'GradebookHistory'],
        IndividualGradebookLearningMastery: ['LearningMastery', 'IndividualGradebook', 'DefaultGradebook', 'GradebookHistory'],
      };
      const options = optionsForGradebook[modifiedVariant];
      return [
        this[`render${head(options)}Option`](true),
        ...(tail(options)).map(option => this[`render${option}Option`]())
      ];
    }

    renderIndividualGradebookOption (selected = false) {
      const key = 'individual-gradebook';
      const label = selected ? I18n.t('Individual View') : I18n.t('Individual View…');
      return <option value={key} key={key}>{label}</option>;
    }

    renderLearningMasteryOption (selected = false) {
      if (!this.props.learningMasteryEnabled) return null;
      const key = 'learning-mastery';
      const label = selected ? I18n.t('Learning Mastery') : I18n.t('Learning Mastery…');
      return <option value={key} key={key}>{label}</option>;
    }

    renderDefaultGradebookOption () {
      const key = 'default-gradebook';
      return <option value={key} key={key}>{I18n.t('Gradebook…')}</option>;
    }

    renderGradebookHistoryOption () {
      const key = 'gradebook-history';
      return <option value={key} key={key}>{I18n.t('Gradebook History…')}</option>;
    }

    render () {
      return (
        <div style={{display: 'flex', alignItems: 'center'}}>
          <Text>{I18n.t('Gradebook')}</Text>
          &nbsp;
          <Select
            onChange={this.handleOnChange}
            label={
              <ScreenReaderContent>{I18n.t('Gradebook')}</ScreenReaderContent>
            }
            value={this.state.value}
          >
            {this.renderOptions()}
          </Select>
        </div>
      );
    }
  }

export default GradebookSelector;
