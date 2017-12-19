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
import ReactDOM from 'react-dom'
import page from 'page'
import Root from '../external_apps/components/Root'
import AppList from '../external_apps/components/AppList'
import AppDetails from '../external_apps/components/AppDetails'
import Configurations from '../external_apps/components/Configurations'
import AppCenterStore from '../external_apps/lib/AppCenterStore'
import regularizePathname from '../external_apps/lib/regularizePathname'

  const currentPath = window.location.pathname;
  const re = /(.*\/settings|.*\/details)/;
  const matches = re.exec(currentPath);
  const baseUrl = matches[0];

  let targetNodeToRenderIn = null;


  /**
   * Route Handlers
   */
  const renderAppList = (ctx) => {
    if (!window.ENV.APP_CENTER.enabled) {
      page.redirect('/configurations');
    } else {
      ReactDOM.render(
        <Root>
          <AppList pathname={ctx.pathname} />
        </Root>
      , targetNodeToRenderIn);
    }
  };

  const renderAppDetails = (ctx) => {
    ReactDOM.render(
      <Root>
        <AppDetails
          shortName={ctx.params.shortName}
          pathname={ctx.pathname}
          baseUrl={baseUrl}
          store={AppCenterStore}
        />
      </Root>
    , targetNodeToRenderIn);
  };

  const renderConfigurations = (ctx) => {
    ReactDOM.render(
      <Root>
        <Configurations
          pathname={ctx.pathname}
          env={window.ENV} />
      </Root>
    , targetNodeToRenderIn);
  }

  /**
   * Route Configuration
   */
  page.base(baseUrl);
  page('*', regularizePathname);
  page('/', renderAppList);
  page('/app/:shortName', renderAppDetails);
  page('/configurations', renderConfigurations);

export default {
    start (targetNode) {
      targetNodeToRenderIn = targetNode;
      page.start();
    },
    stop () {
      page.stop();
    },
    regularizePathname
  };
