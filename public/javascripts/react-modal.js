/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(['node_modules-version-of-react-modal'], function(ReactModal) {
  var appElement = document.getElementById('application');

  // In general this will be present, but in the case that it's not present,
  // you'll need to set your own which most likely occurs during tests.

  if (appElement) {
    ReactModal.setAppElement(document.getElementById('application'));
  }

  return ReactModal;
});