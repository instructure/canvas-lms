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
import themeable from '@instructure/ui-themeable/lib';
import scopeTab from '@instructure/ui-utils/lib/dom/scopeTab';
import keycode from 'keycode';

import Opportunity from '../Opportunity';
import Button from '@instructure/ui-core/lib/components/Button';
import { findDOMNode } from 'react-dom';
import { array, string, func, number, oneOfType} from 'prop-types';
import formatMessage from '../../format-message';

import IconXLine from 'instructure-icons/lib/Line/IconXLine';

import styles from './styles.css';
import theme from './theme.js';

export class Opportunities extends Component {
  static propTypes = {
    opportunities: array.isRequired,
    timeZone: string.isRequired,
    courses: array.isRequired,
    dismiss: func.isRequired,
    togglePopover: func.isRequired,
    maxHeight: oneOfType([number, string])
  }
  static defaultProps = {
    maxHeight: 'none'
  }

  componentDidMount() {
    setTimeout(() =>{
      // eslint-disable-next-line react/no-find-dom-node
      let closeButtonRef = findDOMNode(this.closeButton);
      closeButtonRef.focus();
    }, 200);
  }

  handleKeyDown = (event) => {
    if ((event.keyCode === keycode.codes.tab)) {
      scopeTab(this._content, event);
    }

   if (event.keyCode === keycode.codes.escape) {
      event.preventDefault();
      this.props.togglePopover();
    }
  }

  courseAttr = (id, attr) => {
    const course = this.props.courses.find(c => c.id === id) || {};
    return course[attr];
  }

  renderOpportunity = () => {
    return (
      this.props.opportunities.map(opportunity =>
        <li key={opportunity.id} className={styles.item}>
          <Opportunity
            id={opportunity.id}
            dueAt={opportunity.due_at}
            points={opportunity.points_possible}
            showPill={this.courseAttr(opportunity.course_id, 'informStudentsOfOverdueSubmissions')}
            courseName={this.courseAttr(opportunity.course_id, 'shortName')}
            opportunityTitle={opportunity.name}
            timeZone={this.props.timeZone}
            dismiss={this.props.dismiss}
            plannerOverride={opportunity.planner_override}
            url={opportunity.html_url}
          />
        </li>
      )
    );
  }

  render () {
    return (
      <div
        id="opportunities_parent"
        className={styles.root}
        onKeyDown={this.handleKeyDown}
        ref={(c) => {this._content=c;}}
        style={{maxHeight: this.props.maxHeight}}
      >
        <div className={styles.header}>
          <Button
            variant="link"
            title={formatMessage('Close opportunities popover')}
            ref={(btnRef) =>{this.closeButton = btnRef;}}
            onClick={this.props.togglePopover}
            >
            <IconXLine className={styles.closeButtonIcon} />
            <span className={styles.closeButtonText}>
              {formatMessage('Close')}
            </span>
          </Button>
        </div>
        <ol className={styles.list}>
          {this.props.opportunities.length ? this.renderOpportunity() : formatMessage('Nothing new needs attention.')}
        </ol>
      </div>
    );
  }
}

export default themeable(theme, styles)(Opportunities);
