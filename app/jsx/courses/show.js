import CourseHomeDialog from 'jsx/courses/CourseHomeDialog'
import HomePagePromptContainer from 'jsx/courses/HomePagePromptContainer'
import createStore from 'jsx/shared/helpers/createStore'
import $ from 'jquery'
import I18n from 'i18n!courses_show'
import axios from 'axios'
import React from 'react'
import ReactDOM from 'react-dom'

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
    store: React.PropTypes.object.isRequired,
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

const container = document.getElementById('choose_home_page')
if (container) {
  ReactDOM.render(<ChooseHomePageButton store={defaultViewStore} />, container)
}
