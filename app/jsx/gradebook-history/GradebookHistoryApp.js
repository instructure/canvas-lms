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
import 'instructure-ui/lib/themes/canvas';
import I18n from 'i18n!gradebook_history';
import Heading from 'instructure-ui/lib/components/Heading';
import SearchForm from 'jsx/gradebook-history/SearchForm';
import SearchResults from 'jsx/gradebook-history/SearchResults';

import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';

/* eslint-disable react/prefer-stateless-function */
class GradebookHistoryApp extends React.Component {
  render () {
    return (
      <Provider store={GradebookHistoryStore}>
        <div>
          <Heading level="h2" as="h1">{I18n.t('Grade History')}</Heading>
          <SearchForm />
          <SearchResults label={I18n.t('Search Results')} />
        </div>
      </Provider>
    );
  }
}

export default GradebookHistoryApp;
