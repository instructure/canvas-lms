/******************************************************************************
 *
 * IMPORTANT: This file is only used for the "demo"/dev environment that is
 * set up via webpack-dev-server.  It should *NOT* be bundled into the production
 * package.
 *
 ****************************************************************************/

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
import ReactDOM from 'react-dom';
import moment from 'moment-timezone';
import CanvasPlanner, { store as PlannerStore } from './index';
import { addDay, getPlannerItems } from '../src/actions';

import Button from '@instructure/ui-buttons/lib/components/Button';
import Select from '@instructure/ui-core/lib/components/Select';
import Grid, { GridCol, GridRow } from '@instructure/ui-layout/lib/components/Grid';
import Text from '@instructure/ui-elements/lib/components/Text';
import THEMES from '@instructure/ui-themes/lib';

const COURSES = [{
  id: "1",
  longName: "World History I",
  shortName: "World History I",
  href: "https://en.wikipedia.org/wiki/World_history",
  image: "https://c1.staticflickr.com/6/5473/14502036741_b3d9f4f345_n.jpg",
  color: "#BE0EAA"
}, {
  id: "2",
  longName: "English Literature",
  shortName: "English Literature",
  href: "https://en.wikipedia.org/wiki/English_literature",
  image: "https://c1.staticflickr.com/7/6238/6363562459_7399ee3c3e_n.jpg",
  color: "#19C3B4"
}];

const changeDashboardView = () => {
  console.log("Demo: Change to Dashboard Card View Clicked");
};

const flashAlertFunctions = {
  visualSuccessCallback () { console.log('visual alert called'); },
  visualErrorallback () { console.log('visual error called'); },
  srAlertCallback () { console.log('sr alert called'); }
};

const demo_only_mount_point = document.getElementById('demo_only_mount');
const header_mount_point = document.getElementById('header_mount_point');
const mount_point = document.getElementById('mount_point');

const locales = ["en", "ar", "da", "de", "en-AU", "en-GB", "es", "fa", "fr-CA",
                 "fr", "he", "ht", "hy", "ja", "ko", "mi", "nl", "nb", "nn", "pl",
                 "pt", "pt-BR", "ru", "sv", "tr", "zh-Hans", "zh-Hant"];

class DemoArea extends Component {
  constructor (props) {
    super(props);
    this.state = {
      timeZone: 'America/Denver',
      locale: 'en',
      courses: COURSES,
      theme: 'canvas',
      stickyOffset: 0,
      stickyZIndex: 10,
      flashAlertFunctions,
      currentUser: {id: '1', displayName: 'Jane', avatarUrl: '/avatar/is/here'},
      ariaHideElement: document.getElementById('mount_point')
    };
    this.dayCount = 3;
  }

  handleChange = (e) => {
    e.preventDefault();
    this.setState({
      [e.target.name]: e.target.value
    });
  }

  handleAddDay = (e) => {
    e.preventDefault();
    const fakeDay = moment().add(this.dayCount, 'days');
    PlannerStore.dispatch(addDay(fakeDay.format('YYYY-MM-DD')));
    this.dayCount++;
  }

  handleFetchBeforeToday  = (e) => {
    e.preventDefault();
    const fakeDay = moment.tz(this.state.timeZone).startOf('day').subtract(2, 'weeks');
    PlannerStore.dispatch(getPlannerItems(fakeDay));
  }

  componentDidMount () {
    this.renderPlannerHeaderAndBody();
  }

  componentDidUpdate () {
    this.renderPlannerHeaderAndBody();
  }

  renderPlannerHeaderAndBody () {
    // This sucks, but Safari seems to need a little time to correctly calculate the header height.
    window.setTimeout(() => {
      const headerRect = header_mount_point.getBoundingClientRect();
      const stickyOffset = (headerRect.bottom - headerRect.top);
      const opts = {
        ...this.state,
        theme: THEMES[this.state.theme],
        stickyOffset,
        changeDashboardView
      };
      CanvasPlanner.renderHeader(header_mount_point, opts);
      CanvasPlanner.render(mount_point, opts);
    }, 150);
  }

  render () {
    return (
      <div style={{ backgroundColor: 'papayawhip', padding: '10px'}}>
        <Text weight="bold" color="error">
          This area is only shown here, not in production
        </Text>
        <Grid vAlign="middle">
          <GridRow>
            <GridCol>
              <Select
                id="localeSelect"
                label="Locale"
                layout="inline"
                value={this.state.locale}
                onChange={this.handleChange}
                name="locale"
                size="small"
                width="100px"
              >
                {
                  locales.map(l => <option key={l} value={l}>{l}</option>)
                }
              </Select>
            </GridCol>
            <GridCol>
              <Select
                id="tzSelect"
                name="timeZone"
                value={this.state.timeZone}
                onChange={this.handleChange}
                size="small"
                width="200px"
                layout="inline"
                label="Timezone"
              >
                {
                  moment.tz.names().map(tz => <option key={tz} value={tz}>{tz}</option>)
                }
              </Select>
            </GridCol>
            <GridCol width="auto">
              <Button
                onClick={this.handleAddDay}
              >
                Add a day
              </Button>
            </GridCol>
            <GridCol>
              <Button
                onClick={this.handleFetchBeforeToday}
              >
                Fetch previous days
              </Button>
            </GridCol>
          </GridRow>
          <GridRow hAlign="end">
            <GridCol textAlign="end" width={4}>
              <Select
                name="theme"
                label="Theme"
                layout="inline"
                onChange={this.handleChange}
                value={this.state.theme}
              >
                {
                  Object.keys(THEMES).map((key) => {
                    return <option key={key} value={key}>{key}</option>;
                  })
                }
              </Select>
            </GridCol>
          </GridRow>
        </Grid>
      </div>
    );
  }
}

ReactDOM.render(
    <DemoArea />
  , demo_only_mount_point
);
