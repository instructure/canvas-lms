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

import page from 'page'
import TabActions from './actions/TabActions'


  const router = {
    start: (store) => {
      const tabList = store.getState().tabList;

      page.base(tabList.basePath);

      tabList.tabs.forEach((tab, i) => {
        page(tab.path, (ctx) => {
          store.dispatch(TabActions.selectTab( i ));
        });
      });

      if (tabList.tabs.length)
        page('/', tabList.tabs[0].path);

      page.start();
    }
  };


export default router
