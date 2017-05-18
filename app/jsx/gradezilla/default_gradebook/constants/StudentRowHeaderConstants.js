/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import I18n from 'i18n!gradebook'

const primaryInfoLabels = {
  first_last: I18n.t('First, Last Name'),
  last_first: I18n.t('Last, First Name'),
  anonymous: I18n.t('Anonymous')
};

const primaryInfoKeys = ['first_last', 'last_first', 'anonymous'];
const defaultPrimaryInfo = 'first_last';

const secondaryInfoLabels = {
  section: I18n.t('Section'),
  sis_id: I18n.t('SIS ID'),
  login_id: I18n.t('Login ID'),
  none: I18n.t('None')
};

const secondaryInfoKeys = ['section', 'sis_id', 'login_id', 'none'];
const defaultSecondaryInfo = 'none';
const sectionSecondaryInfo = 'section';

const enrollmentFilterLabels = {
  inactive: I18n.t('Inactive enrollments'),
  concluded: I18n.t('Concluded enrollments')
};

const enrollmentFilterKeys = ['inactive', 'concluded'];

export default {
  primaryInfoKeys,
  primaryInfoLabels,
  defaultPrimaryInfo,

  secondaryInfoKeys,
  secondaryInfoLabels,
  defaultSecondaryInfo,
  sectionSecondaryInfo,
  enrollmentFilterKeys,
  enrollmentFilterLabels
};
