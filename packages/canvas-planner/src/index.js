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

// runtimes and polyfills that need to be imported first
import 'regenerator-runtime/runtime';

import React from 'react';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import PlannerApp from './components/PlannerApp';
import PlannerHeader from './components/PlannerHeader';
import ApplyTheme from '@instructure/ui-core/lib/components/ApplyTheme';
import i18n from './i18n';
import configureStore from './store/configureStore';
import { initialOptions, getPlannerItems, scrollIntoPast } from './actions';
import { registerScrollEvents } from './utilities/scrollUtils';
import { initialize as initializeAlerts } from './utilities/alertUtils';
import moment from 'moment-timezone';
import {DynamicUiManager, DynamicUiProvider} from './dynamic-ui';

const defaultOptions = {
  locale: 'en',
  timeZone: moment.tz.guess(),
  theme: 'canvas',
  courses: [],
  groups: [],
  stickyOffset: 0,
  stickyZIndex: 5,
};

const dynamicUiManager = new DynamicUiManager();
export const store = configureStore(dynamicUiManager);

function handleScrollIntoPastAttempt () {
  if (!store.getState().loading.loadingPast && !store.getState().loading.loadingFuture && !store.getState().loading.allPastItemsLoaded) {
    store.dispatch(scrollIntoPast());
  }
}

export default {
  render (element, options) {
    // Using this pattern because default params don't merge objects
    const opts = { ...defaultOptions, ...options };
    i18n.init(opts.locale);
    moment.locale(opts.locale);
    moment.tz.setDefault(opts.timeZone);
    dynamicUiManager.setStickyOffset(opts.stickyOffset);
    registerScrollEvents(handleScrollIntoPastAttempt);
    if (!opts.flashAlertFunctions) {
      throw new Error('You must provide callbacks to handle flash messages');
    }
    initializeAlerts(opts.flashAlertFunctions);

    store.dispatch(initialOptions(opts));
    store.dispatch(getPlannerItems(moment.tz(opts.timeZone).startOf('day')));

    ReactDOM.render(applyTheme(
      <DynamicUiProvider manager={dynamicUiManager} >
        <Provider store={store}>
          <PlannerApp
            stickyOffset={opts.stickyOffset}
            stickyZIndex={opts.stickyZIndex}
            changeToDashboardCardView={opts.changeToDashboardCardView}
          />
        </Provider>
      </DynamicUiProvider>
    , opts.theme), element);
  },

  // This method allows you to render the header items into a separate DOM node
  renderHeader (element, options) {
    // Using this pattern because default params don't merge objects
    const opts = { ...defaultOptions, ...options };

    ReactDOM.render(applyTheme(
      <DynamicUiProvider manager={dynamicUiManager} >
        <Provider store={store}>
          <PlannerHeader
            timeZone={opts.timeZone}
            locale={opts.locale}
            ariaHideElement={opts.ariaHideElement}
          />
        </Provider>
      </DynamicUiProvider>
    , opts.theme), element);
  }
};

function applyTheme (el, theme) {
  return theme ? (
    <ApplyTheme
      theme={ApplyTheme.generateTheme(theme.key)}
      immutable={theme.accessible}
    >
      {el}
    </ApplyTheme>
  ): el;
}
