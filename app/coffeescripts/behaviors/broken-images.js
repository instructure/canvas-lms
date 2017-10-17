//
// Copyright (C) 2017 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from  'jquery';

export default function attachErrorHandler (imgElement) {
  $(imgElement).on('error', (e) => $(e.currentTarget).addClass('broken-image'));
}

// this behavior will set up all broken images on the page with an error handler that
// can apply the broken-image class if there is an error loading the image.
$(document).ready(() => $('img').toArray().forEach(attachErrorHandler));
