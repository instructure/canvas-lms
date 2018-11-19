/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React, { Component } from 'react';
import classnames from 'classnames';
import themeable from '@instructure/ui-themeable/lib';
import { func, bool, string } from 'prop-types';

import Heading from '@instructure/ui-elements/lib/components/Heading';
import Link from '@instructure/ui-elements/lib/components/Link';
import Button from '@instructure/ui-buttons/lib/components/Button';

import formatMessage from '../../format-message';
import DesertSvg from './empty-desert.svg'; // Currently uses react-svg-loader
import BalloonsSvg from './balloons.svg';

import styles from './styles.css';
import theme from './theme.js';

class PlannerEmptyState extends Component {

  static propTypes = {
    changeDashboardView: func.isRequired,
    onAddToDo: func.isRequired,
    isCompletelyEmpty: bool,
    responsiveSize: string,
  }
  static defaultProps = {
    responsiveSize: 'large',
  }

  handleDashboardCardLinkClick = () => {
    if (this.props.changeDashboardView) {
        this.props.changeDashboardView('cards');
    }
  }

  renderAddToDoButton () {
    return (
      <Button
        id="PlannerEmptyState_AddToDo"
        variant="link"
        onClick={this.props.onAddToDo}>{formatMessage("Add To-Do")}
      </Button>
    );
  }

  renderNothingAtAll () {
    return (
      <div className={classnames(styles.root, 'planner-empty-state', styles[this.props.responsiveSize])}>
        <DesertSvg className={classnames(styles.desert, 'desert')} aria-hidden="true" />
        <div className={styles.title}>
          <Heading>{formatMessage("No Due Dates Assigned")}</Heading>
        </div>
        <div className={styles.subtitlebox}>
          <div className={styles.subtitle}>{formatMessage("Looks like there isn't anything here")}</div>
          <Link id="PlannerEmptyState_CardView" onClick={this.handleDashboardCardLinkClick}>{formatMessage("Go to Card View Dashboard")}</Link> |
          {this.renderAddToDoButton()}
        </div>
      </div>
    );
  }

  renderNothingLeft () {
    return (
      <div className={classnames(styles.root, 'planner-empty-state', styles[this.props.responsiveSize])}>
        <BalloonsSvg className={classnames(styles.balloons, 'balloons')} aria-hidden="true" />
        <div className={styles.title}>
          <Heading>{formatMessage("Nothing More To Do")}</Heading>
        </div>
        <div className={styles.subtitlebox}>
          <div className={styles.subtitle}>{formatMessage("Scroll up to see your history!")}</div>
          {this.renderAddToDoButton()}
        </div>
      </div>
    );
  }

  render () {
    return this.props.isCompletelyEmpty ? this.renderNothingAtAll() : this.renderNothingLeft();
  }
}

export default themeable(theme, styles)(PlannerEmptyState);
