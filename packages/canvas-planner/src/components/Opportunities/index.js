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
import {animatable} from '../../dynamic-ui';
import {specialFallbackFocusId} from '../../dynamic-ui/util';
import scopeTab from '@instructure/ui-a11y/lib/utils/scopeTab';
import keycode from 'keycode';

import Opportunity from '../Opportunity';
import Button from '@instructure/ui-buttons/lib/components/Button';
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList';
import AccessibleContent from   '@instructure/ui-a11y/lib/components/AccessibleContent';
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton';
import { findDOMNode } from 'react-dom';
import { array, string, func, number, oneOfType} from 'prop-types';
import formatMessage from '../../format-message';

import IconXLine from '@instructure/ui-icons/lib/Line/IconX';

import styles from './styles.css';
import theme from './theme.js';

export const OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID = specialFallbackFocusId('opportunity');

export class Opportunities extends Component {
  static propTypes = {
    newOpportunities: array.isRequired,
    dismissedOpportunities: array.isRequired,
    timeZone: string.isRequired,
    courses: array.isRequired,
    dismiss: func.isRequired,
    togglePopover: func.isRequired,
    maxHeight: oneOfType([number, string]),
    registerAnimatable: func,
    deregisterAnimatable: func,
  }

  static defaultProps = {
    maxHeight: 'none',
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
  }

  constructor (props) {
    super(props);

    this.state = {
      innerMaxHeight: "auto"
    }
    this.closeButtonRef = null;
    this.tabPanelContentDiv = null;
  }

  componentDidMount () {
    this.props.registerAnimatable('opportunity', this, -1, [OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID]);
    this.setMaxHeight(this.props);
    this.closeButtonRef.focus();
  }

  componentWillReceiveProps (nextProps) {
    this.setMaxHeight(nextProps);
  }

  componentWillUnmount () {
    this.props.deregisterAnimatable('opportunity', this, [OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID]);
  }

  getFocusable () {
    return this.newTabRef;
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

  // the only place on the TabList heirarchy where we can set a maxHeight is on 
  // TabPanel, which puts the style on it's child content-holding div.
  // To keep the scrolling area w/in the TabPanel's content so that
  // the TabList doesn't outgrow its parent and the user winds up scrolling the tabs
  // out of view, we need to subtract out how much space the TabList's boilerplate takes
  // up to set the TabPanel's maxHeight appropriately.
  // Unfortunately TabPanel's tabRef returns a ref to the Tab, and TabPanel's ref returns
  // a ref to the TabPanel component. Even if we get it's div, it doesn't have it's padding
  // at the time when the component mounts and our calculation is off.
  setMaxHeight (props) {
    let mxht = 'auto';
    if (this.tabPanelContentDiv) {
      const style = window.getComputedStyle(this.tabPanelContentDiv);
      const padding = parseInt(style['padding-top']) + parseInt(style['padding-bottom']);
      const border =  parseInt(style['border-top-width']) + parseInt(style['border-bottom-width']);
      mxht = `${props.maxHeight - this.tabPanelContentDiv.offsetTop - padding - border}px`;
    }
    this.setState({innerMaxHeight: mxht});
  }

  // the parent of the <ol> holding the opportunities is the div TabPanel will assign 
  // TabPanel's maxHeight prop to.
   getTabPanelContentDivRefFromList = (ol) => {
    this.tabPanelContentDiv = ol && ol.parentElement;
  }

  renderOpportunities (opportunities, dismissed) {
    return (
      <ol className={styles.list} ref={this.getTabPanelContentDivRefFromList}>
        {opportunities.map((opportunity, oppIndex) =>
          <li key={opportunity.id} className={styles.item}>
            <Opportunity
              id={opportunity.id}
              dueAt={opportunity.due_at}
              points={opportunity.points_possible}
              courseName={this.courseAttr(opportunity.course_id, 'shortName')}
              opportunityTitle={opportunity.name}
              timeZone={this.props.timeZone}
              dismiss={dismissed ? null : this.props.dismiss}
              plannerOverride={opportunity.planner_override}
              url={opportunity.html_url}
              animatableIndex={oppIndex}
            />
          </li>
        )}
      </ol>
    );
  }

  renderNewOpportunities () {
    return this.props.newOpportunities.length ?
      this.renderOpportunities(this.props.newOpportunities, false) :
      <div>{formatMessage('Nothing new needs attention.')}</div>
  }

  renderDismissedOpportunities () {
    return this.props.dismissedOpportunities.length ?
      this.renderOpportunities(this.props.dismissedOpportunities, true) :
      <div>{formatMessage('Nothing here needs attention.')}</div>
  }

  renderTitle (which) {
    const srtitle = (which === "new") ? formatMessage("New Opportunities") : formatMessage("Dismissed Opportunities");
    const title = (which === "new") ? formatMessage("New") : formatMessage("Dismissed");
    return <AccessibleContent alt={srtitle}>{title}</AccessibleContent>;
  }

  renderCloseButton () {
    return (
      <CloseButton
        placement="end"
        offset="x-small"
        variant="icon"
        onClick={this.props.togglePopover}
        buttonRef={(el) => {this.closeButtonRef = el}}
      >
        {formatMessage('Close Opportunity Center popup')}
      </CloseButton>
    )
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
        {this.renderCloseButton()}
        <TabList variant="minimal" focus={false}>
          <TabPanel title={this.renderTitle("new")} maxHeight={this.state.innerMaxHeight}>
            {this.renderNewOpportunities()}
          </TabPanel>
          <TabPanel title={this.renderTitle("dismissed")} maxHeight={this.state.innerMaxHeight}>
              {this.renderDismissedOpportunities()}
          </TabPanel>
        </TabList>
      </div>
    );
  }
}

export default animatable(themeable(theme, styles)(Opportunities));
