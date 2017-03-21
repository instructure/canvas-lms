import React from 'react'
import CourseHomeDialog from 'jsx/courses/CourseHomeDialog'
import I18n from 'i18n!home_page_prompt'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'

class HomePagePromptContainer extends React.Component {
  static propTypes = {
    store: React.PropTypes.object.isRequired,
    onSubmit: React.PropTypes.func.isRequired,
    wikiFrontPageTitle: React.PropTypes.string,
    wikiUrl: React.PropTypes.string.isRequired,
    courseId: React.PropTypes.string.isRequired,
    forceOpen: React.PropTypes.bool.isRequired,
    returnFocusTo: React.PropTypes.instanceOf(Element).isRequired,
  }

  state = {
    dialogOpen: true
  }

  componentDidMount () {
    this.flashScreenReaderAlert()
  }

  componentWillReceiveProps (nextProps) {
    if (nextProps.forceOpen) {
      this.setState({dialogOpen: true})
      this.flashScreenReaderAlert()
    }
  }

  flashScreenReaderAlert () {
    $.screenReaderFlashMessage(I18n.t('Before publishing your course, you must either publish a module or choose a different home page.'))
  }

  render () {
    return (
      <CourseHomeDialog
        store={this.props.store}
        open={this.state.dialogOpen}
        onRequestClose={this.onClose}
        courseId={this.props.courseId}
        wikiFrontPageTitle={this.props.wikiFrontPageTitle}
        wikiUrl={this.props.wikiUrl}
        onSubmit={this.props.onSubmit}
        returnFocusTo={this.props.returnFocusTo}
        isPublishing
      />
    )
  }

  onClose = () => {
    this.setState({dialogOpen: false})
  }
}

export default HomePagePromptContainer
