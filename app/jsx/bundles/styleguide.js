/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import _ from 'underscore'
import React from 'react'
import ReactDOM from 'react-dom'
import preventDefault from 'compiled/fn/preventDefault'
import PublishButtonView from 'compiled/views/PublishButtonView'
import PublishIconView from 'compiled/views/PublishIconView'
import ReactModalExample from '../styleguide/ReactModalExample'
import Backbone from 'Backbone'
import 'jqueryui/accordion'
import 'jqueryui/tabs'
import 'jqueryui/button'
import 'jqueryui/tooltip'
import 'jquery.instructure_date_and_time'

const dialog = $('#dialog-buttons-dialog').dialog({
  autoOpen: false,
  height: 200
}).data('dialog')
$('#show-dialog-buttons-dialog').click(() => dialog.open())

// React Modal
ReactDOM.render(
  <ReactModalExample
    className="ReactModal__Content--canvas"
    overlayClassName="ReactModal__Overlay--canvas"
  />,
  document.getElementById('react-modal-example')
)

ReactDOM.render(
  <ReactModalExample
    label="Trigger Confirm Dialog"
    className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
    overlayClassName="ReactModal__Overlay--canvas"
  />,
  document.getElementById('react-modal-confirm-example')
)

// # OLD STYLEGUIDE ##

const iconEventsMap = {
  mouseover () { $(this).addClass('hover') },
  click () { $(this).addClass('active') },
  mouseout () { $(this).removeClass('hover active') }
}

$('#content').on(iconEventsMap, '.demo-icons')

// Tabs
$('#styleguide-tabs-demo-regular').tabs()
$('#styleguide-tabs-demo-minimal').tabs()

// Datepicker
// $("#datepicker").datepicker().children().show()


// hover states on the static widgets
$('ul#icons li').hover(function () {
  $(this).addClass('ui-state-hover')
}, function () {
  $(this).removeClass('ui-state-hover')
})

// Button
$('.styleguide-turnIntoUiButton, .styleguide-turnAllIntoUiButton > *').button()

// Icon Buttons
$('#leftIconButton').button({
  icons: {primary: 'ui-icon-wrench'}
})

$('#bothIconButton').button({
  icons: {
    primary: 'ui-icon-wrench',
    secondary: 'ui-icon-triangle-1-s'
  }
})

// Button Set
$('#radio1').buttonset()


// Publish Button
// --
// Hooks into a 'publishable' Backbone model. The backbone model requires
// the 'published' and 'publishable' attributes to determine initial state,
// and the  publish() and unpublish() methods that return a deferred objects.
//
const Publishable = Backbone.Model.extend({
  defaults: {
    published: false,
    publishable: true
  },

  publish () {
    this.set('published', true)
    const deferred = $.Deferred()
    setTimeout(deferred.resolve, 1000)
    return deferred
  },

  unpublish () {
    this.set('published', false)
    const deferred = $.Deferred()
    setTimeout(deferred.resolve, 1000)
    return deferred
  },

  disabledMessage () {
    return "Can't unpublish"
  }
})

// PublishButtonView doesn't require an element to initialize. It is
// passed in here for the style-guide demonstration purposes

// publish
let model = new Publishable({published: false, publishable: true})
let btnView = new PublishButtonView({model, el: '#publish'}).render()

// published
model = new Publishable({published: true, publishable: true})
btnView = new PublishButtonView({model, el: '#published'}).render()

// published & disables
model = new Publishable({published: true, publishable: false})
btnView = new PublishButtonView({model, el: '#published-disabled'}).render()

// publish icon
_.each($('.publish-icon'), ($el) => {
  model = new Publishable({published: false, publishable: true})
  btnView = new PublishIconView({model, el: $el}).render()
})


// Element Toggler
$('.element_toggler').click(e =>
  $(e.currentTarget).find('i')
    .toggleClass('icon-mini-arrow-down')
    .toggleClass('icon-mini-arrow-right')
)


// Progressbar
$('#progressbar').progressbar({value: 37}).width(500)
$('#animateProgress').click(preventDefault(() => {
  const randNum = Math.random() * 90
  $('#progressbar div').animate({width: `${randNum}%`})
}))


// Combinations
$('#tabs2').tabs()
$('#accordion2').accordion({header: 'h4'})


// Toolbar
$('#play, #shuffle').button()
$('#repeat').buttonset()

$('.styleguide-datetime_field-example').datetime_field()

// Global Navigation Hide/Show Subnav
function selectCategory (event) {
  event.preventDefault()
  const SgNavType = $(this).data('sg-category')
  $('.Sg-header__Subnavigation section').addClass('isHidden')
  $(`.Sg-header__Subnavigation section.${SgNavType}`).removeClass('isHidden')
  $('.Sg-header__Navigation a').removeClass('active')
  $(this).addClass('active')
}

$('.Sg-header__Navigation a').on('click', selectCategory)
