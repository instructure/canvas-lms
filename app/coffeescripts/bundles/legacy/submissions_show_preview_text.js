//
// Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'

$(document).ready(() => {
  // this is so iOS devices can scroll submissions in speedgrader
  $('body,html').css({
    height: '100%',
    overflow: 'auto',
    '-webkit-overflow-scrolling': 'touch'
  })

  $('.data_view')
    .change(function() {
      if ($(this).val() === 'paper') {
        $('#submission_preview')
          .removeClass('plain_text')
          .addClass('paper')
      } else {
        $('#submission_preview')
          .removeClass('paper')
          .addClass('plain_text')
      }
    })
    .change()
})
