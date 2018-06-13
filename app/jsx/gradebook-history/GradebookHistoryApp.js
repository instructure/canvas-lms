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

import React from 'react';
import { Provider } from 'react-redux';
import I18n from 'i18n!gradebook_history';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import SearchForm from '../gradebook-history/SearchForm';
import SearchResults from '../gradebook-history/SearchResults';

import GradebookHistoryStore from '../gradebook-history/store/GradebookHistoryStore';

const GradebookHistoryApp = () => (
  (
    <Provider store={GradebookHistoryStore}>
      <div>
        <h1>{I18n.t('Gradebook History')}</h1>
        <SearchForm />
        <SearchResults caption={<ScreenReaderContent>{I18n.t('Grade Changes')}</ScreenReaderContent>} />
      </div>
    </Provider>
  )
);

export default GradebookHistoryApp;
