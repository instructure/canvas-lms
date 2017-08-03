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

import I18n from 'i18n!gradebook_history';
import splitAssetString from 'coffeescripts/str/splitAssetString';

const colHeaders = [
  I18n.t('Date'),
  I18n.t('Time'),
  I18n.t('From'),
  I18n.t('To'),
  I18n.t('Grader'),
  I18n.t('Student'),
  I18n.t('Assignment'),
  I18n.t('Anonymous')
];

function courseId () {
  return ENV.context_asset_string ? splitAssetString(ENV.context_asset_string)[1] : '';
}

function timezone () {
  return ENV.TIMEZONE;
}

export default {
  colHeaders,
  courseId,
  timezone
}
