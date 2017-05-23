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

import CourseHomeDialog from 'jsx/courses/CourseHomeDialog'
import HomePagePromptContainer from 'jsx/courses/HomePagePromptContainer'
import createStore from 'jsx/shared/helpers/createStore'
import $ from 'jquery'
import I18n from 'i18n!courses_show'
import axios from 'axios'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import Checkbox from 'instructure-ui/lib/components/Checkbox'
import Tooltip from 'instructure-ui/lib/components/Tooltip'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import PresentationContent from 'instructure-ui/lib/components/PresentationContent'

const defaultViewStore = createStore({
  selectedDefaultView: ENV.COURSE.default_view,
  savedDefaultView: ENV.COURSE.default_view,
})

const publishCourse = () => {
  axios.put(`/api/v1/courses/${ENV.COURSE.id}`, {
    course: {event: 'offer'}
  }).then(() => {
    window.location.reload()
  })
}


$('#course_status_form').submit((e) => {
  const input = e.target.elements.namedItem('course[event]')
  const value = input && input.value
  if (value === 'offer') {
    e.preventDefault()

    const defaultView = defaultViewStore.getState().savedDefaultView
    axios.get(`/api/v1/courses/${ENV.COURSE.id}/modules`)
    .then(({data: modules}) => {
      if (defaultView === 'modules' && modules.length === 0) {
        ReactDOM.render(
          <HomePagePromptContainer
            forceOpen
            store={defaultViewStore}
            courseId={ENV.COURSE.id}
            wikiFrontPageTitle={ENV.COURSE.front_page_title}
            wikiUrl={ENV.COURSE.pages_url}
            returnFocusTo={$(".btn-publish").get(0)}
            onSubmit={() => {
              if (defaultViewStore.getState().savedDefaultView !== 'modules') {
                publishCourse()
              }
            }}
          />,
          document.getElementById('choose_home_page_not_modules')
        )
      } else {
        publishCourse()
      }
    })
  }
})

class ChooseHomePageButton extends React.Component {
  state = {
    dialogOpen: false
  }

  static propTypes = {
    store: PropTypes.object.isRequired,
  }

  render() {
    return (
      <div>
        <button
          type="button"
          className="Button button-sidebar-wide choose_home_page_link"
          ref={(b) => this.chooseButton = b }
          onClick={this.onClick}
        >
          <i className="icon-target" aria-hidden="true" />
          &nbsp;{I18n.t('Choose Home Page')}
        </button>
        <CourseHomeDialog
          store={this.props.store}
          open={this.state.dialogOpen}
          onRequestClose={this.onClose}
          courseId={ENV.COURSE.id}
          wikiFrontPageTitle={ENV.COURSE.front_page_title}
          wikiUrl={ENV.COURSE.pages_url}
          returnFocusTo={this.chooseButton}
          isPublishing={false}
        />
      </div>
    )
  }

  onClick = () => {
    this.setState({dialogOpen: true})
  }

  onClose = () => {
    this.setState({dialogOpen: false})
  }
}

// This wraps the instui Checkbox variant=toggle
// to submit the enclosing form when checked or unchecked.
class PubUnpubToggle extends React.Component {  // eslint-disable-line react/no-multi-comp
  static modes = {
    PUBLISHED: {
      label: I18n.t('Published'),
      tip: I18n.t('Click to unpublish.'),
    },
    UNPUBLISHED: {
      label: I18n.t('Unpublished'),
      tip: I18n.t('Click to publish.'),
    },
    PUBLISHING: {
      label: I18n.t('Publishing…'),
      tip: I18n.t('Please wait.'),
    },
    UNPUBLISHING: {
      label: I18n.t('Unpublishing…'),
      tip: I18n.t('Please wait.'),
    }
  }
  static propTypes = {
    op: PropTypes.string.isRequired
  }

  constructor (props) {
    super(props)
    this.state = {
      mode: PubUnpubToggle.modes[props.op]
    }
  }

  onChange = (event) => {
    // if pub/unpub is in-flight, effectively disable clicking the button
    if (this.state.mode !== PubUnpubToggle.modes.PUBLISHING && this.state.mode !== PubUnpubToggle.modes.UNPUBLISHING) {
      this.setState({
        mode: this.props.op === 'PUBLISHED' ? PubUnpubToggle.modes.UNPUBLISHING : PubUnpubToggle.modes.PUBLISHING
      })
      const form = document.getElementById('course_status_form')
      form.submit()
    } else {
      event.preventDefault()
    }
  }

  render () {
    const label = this.state.mode.label
    const srlabel = this.state.mode.tip
    const checked = this.props.op === 'PUBLISHED' || this.props.op === 'PUBLISHING'
    const placement = 'top start'

    // ideally, we'd let the tooltip provide the additional tip information, but NVDA doesn't read it unless
    // you tab into the Checkbox to give it focus.  What I wound up doing was hiding the tooltip from the screenreader
    // and including the tip as screenreder only content w/in the checkbox's label.
    return (
      <Tooltip tip={<PresentationContent>{srlabel}</PresentationContent>} on={['hover', 'focus']} variant="inverse" placement={placement}>
        <Checkbox
          variant="toggle"
          checked={checked}
          onChange={this.onChange}
          label={<span>{label}<ScreenReaderContent>{srlabel}</ScreenReaderContent></span>}
        />
      </Tooltip>
    )
  }
}

const container = document.getElementById('choose_home_page')
if (container) {
  ReactDOM.render(<ChooseHomePageButton store={defaultViewStore} />, container)
}
const pubunpubcontainer = document.getElementById('pubunpub_btn_container')
if (pubunpubcontainer) {
  const op = pubunpubcontainer.getAttribute('data-op')
  ReactDOM.render(<PubUnpubToggle op={op} />, pubunpubcontainer)
}
