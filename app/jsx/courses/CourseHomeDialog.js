import React from 'react'
import axios from 'axios'
import Modal, {ModalHeader, ModalBody, ModalFooter} from 'instructure-ui/lib/components/Modal'
import Heading from 'instructure-ui/lib/components/Heading'
import RadioInputGroup from 'instructure-ui/lib/components/RadioInputGroup'
import RadioInput from 'instructure-ui/lib/components/RadioInput'
import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'
import Link from 'instructure-ui/lib/components/Link'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import AccessibleContent from 'instructure-ui/lib/components/AccessibleContent'
import I18n from 'i18n!course_home_dialog'
import plainStoreShape from 'jsx/shared/proptypes/plainStoreShape'

class CourseHomeDialog extends React.Component {
  static propTypes = {
    store: React.PropTypes.shape(plainStoreShape).isRequired,
    open: React.PropTypes.bool.isRequired,
    onRequestClose: React.PropTypes.func.isRequired,
    wikiFrontPageTitle: React.PropTypes.string,
    wikiUrl: React.PropTypes.string.isRequired,
    courseId: React.PropTypes.string.isRequired,
    isPublishing: React.PropTypes.bool.isRequired,
    onSubmit: React.PropTypes.func,
    returnFocusTo: React.PropTypes.instanceOf(Element),
  }

  static defaultProps = {
    onSubmit: () => { window.location.reload() },
    wikiFrontPageTitle: null,
  }

  constructor (props) {
    super(props)
    this.state = props.store.getState()
    this.appElement = document.getElementById('application')
  }

  renderWikiLabelContent () {
    const {wikiUrl, wikiFrontPageTitle} = this.props
    if (wikiFrontPageTitle) {
      return (
        <span>
          <Typography size="small" color="secondary">
            &nbsp;&nbsp;
            <i>{wikiFrontPageTitle}</i>
            &nbsp;
            [<Link href={wikiUrl}>{I18n.t('Change')}</Link>]
          </Typography>
        </span>
      )
    }
    return (
      <span>
        <AccessibleContent>*</AccessibleContent>
        <ScreenReaderContent>
          <Link href={wikiUrl}>
            {I18n.t('Front page must be set first')}
          </Link>
        </ScreenReaderContent>
      </span>
    )
  }

  renderWikiLabel () {
    return (
      <span>
        {I18n.t('Pages Front Page')}
        {this.renderWikiLabelContent()}
      </span>
    )
  }

  render () {
    const {selectedDefaultView} = this.state
    const {wikiFrontPageTitle, wikiUrl} = this.props

    const inputs = [
      {
        value: 'feed',
        label: I18n.t('Course Activity Stream'),
        checked: selectedDefaultView === 'feed'
      },
      {
        value: 'wiki',
        label: this.renderWikiLabel(),
        checked: selectedDefaultView === 'wiki',
        disabled: !wikiFrontPageTitle
      },
      {
        value: 'modules',
        label: I18n.t('Course Modules'),
        checked: selectedDefaultView === 'modules'
      },
      {
        value: 'assignments',
        label: I18n.t('Assignments List'),
        checked: selectedDefaultView === 'assignments'
      },
      {
        value: 'syllabus',
        label: I18n.t('Syllabus'),
        checked: selectedDefaultView === 'syllabus'
      }
    ]

    const instructions = this.props.isPublishing ?
      I18n.t('Before publishing your course, you must either publish a module in the Modules page, or choose a different home page.') :
      I18n.t("Select what you'd like to display on the home page.")

    return (<Modal
      isOpen={this.props.open}
      transition="fade"
      zIndex={99999}
      label={I18n.t('Choose Course Home Page')}
      closeButtonLabel={I18n.t("Close")}
      onReady={this.onReady}
      onRequestClose={this.props.onRequestClose}
      onClose={this.onClose}
    >
      <ModalHeader>
        <Heading tag="h2" level="h3">{I18n.t('Choose Home Page')}</Heading>
      </ModalHeader>
      <ModalBody>
        <div className="content-box-mini" style={{marginTop: '0'}}>
          <AccessibleContent>
            <Typography weight="bold" size="small" isBlock>
              {instructions}
            </Typography>
          </AccessibleContent>
        </div>
        <RadioInputGroup
          description={<ScreenReaderContent>{instructions}</ScreenReaderContent>}
          name="course[default_view]"
          onChange={this.onChange}
          defaultValue={selectedDefaultView}
        >
          {inputs.map(input =>
            <RadioInput
              key={input.value}
              checked={input.checked}
              value={input.value}
              label={input.label}
              disabled={input.disabled}
            />)
          }
        </RadioInputGroup>

        {
          wikiFrontPageTitle ? (
            null
          ) : (
            <div className="content-box-mini">
            * <Link href={wikiUrl}>{I18n.t('Front page must be set first')}
            </Link></div>
          )
        }

      </ModalBody>

      <ModalFooter>
        <Button onClick={this.props.onRequestClose}>{I18n.t('Cancel')}</Button>&nbsp;
        <Button
          onClick={this.onSubmit}
          disabled={this.props.isPublishing && this.state.selectedDefaultView === 'modules'}
          variant="primary"
        >{
          this.props.isPublishing ? I18n.t('Choose and Publish') : I18n.t('Save')
        }</Button>
      </ModalFooter>
    </Modal>)
  }

  componentDidMount () {
    this.props.store.addChangeListener(this.onStoreChange)
  }

  componentWillUnmount () {
    this.props.store.removeChangeListener(this.onStoreChange)
  }

  onReady = () => {
    this.appElement.setAttribute('aria-hidden', 'true')
  }

  onClose = () => {
    this.appElement.removeAttribute('aria-hidden')

    // this (unnecessary?) setTimeout fixes returning focus in ie11
    window.setTimeout(() => {
      const returnFocusTo = this.props.returnFocusTo
      returnFocusTo && returnFocusTo.focus()
    })
  }

  onStoreChange = () => {
    this.setState(this.props.store.getState())
  }

  onSubmit = () => {
    const {selectedDefaultView, savedDefaultView} = this.state
    let savingPromise
    if (selectedDefaultView !== savedDefaultView) {
      savingPromise = axios.put(`/api/v1/courses/${this.props.courseId}`, {
        course: {default_view: this.state.selectedDefaultView}
      }).then(({data: course}) => course.default_view)
    } else {
      savingPromise = Promise.resolve(savedDefaultView)
    }

    savingPromise.then((newDefaultView) => {
      this.props.store.setState({savedDefaultView: newDefaultView})
      this.props.onSubmit()
    })
  }

  onChange = (value) => {
    this.props.store.setState({selectedDefaultView: value})
  }
}

export default CourseHomeDialog
