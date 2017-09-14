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
import { bool, shape, string } from 'prop-types';
import I18n from 'i18n!gradebook_history';
import IconOffLine from 'instructure-icons/lib/Line/IconOffLine';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import Tooltip from 'instructure-ui/lib/components/Tooltip';

const anonymouslyGraded = anonymous => (
  anonymous ? (
    <div>
      <Tooltip tip={I18n.t('Anonymously graded')}>
        <IconOffLine />
      </Tooltip>
      <ScreenReaderContent>{I18n.t('Anonymously graded')}</ScreenReaderContent>
    </div>
  ) : (
    <ScreenReaderContent>{I18n.t('Not anonymously graded')}</ScreenReaderContent>
  )
);

const SearchResultsRow = (props) => {
  const item = props.item;
  return (
    <tr>
      <td>{item.date}</td>
      <td>{anonymouslyGraded(item.anonymous)}</td>
      <td>{item.student}</td>
      <td>{item.grader}</td>
      <td>{item.assignment}</td>
      <td>{item.before}</td>
      <td>{item.after}</td>
    </tr>
  );
};

SearchResultsRow.propTypes = {
  item: shape({
    after: string.isRequired,
    anonymous: bool.isRequired,
    assignment: string.isRequired,
    before: string.isRequired,
    date: string.isRequired,
    grader: string.isRequired,
    student: string.isRequired,
  }).isRequired
};

export default SearchResultsRow;
