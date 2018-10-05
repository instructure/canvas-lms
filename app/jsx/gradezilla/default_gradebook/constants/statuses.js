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

import I18n from 'i18n!gradebook';

export const statuses = [
  'late',
  'missing',
  'resubmitted',
  'dropped',
  'excused'
];

export const statusesTitleMap = {
  late: I18n.t('Late'),
  missing: I18n.t('Missing'),
  resubmitted: I18n.t('Resubmitted'),
  dropped: I18n.t('Dropped'),
  excused: I18n.t('Excused')
};

