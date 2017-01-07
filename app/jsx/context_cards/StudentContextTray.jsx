define([
  'react',
  'i18n!student_context_tray',
  'jsx/shared/FriendlyDatetime',
  './Avatar',
  './LastActivity',
  './MetricsList',
  './SectionInfo',
  './SubmissionProgressBars',
  'jsx/shared/MessageStudents',
  'instructure-ui/Heading',
  'instructure-ui/Button',
  'instructure-ui/Link',
  'instructure-ui/Overlay',
  'instructure-ui/Typography',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/Spinner',
  'instructure-ui/Tray'
], function(React, I18n, FriendlyDatetime,
   Avatar,
   LastActivity,
   MetricsList,
   SectionInfo,
   SubmissionProgressBars,
   MessageStudents,
   { default: Heading },
   { default: Button },
   { default: Link },
   { default: Overlay },
   { default: Typography },
   { default: ScreenReaderContent },
   { default: Spinner },
   { default: Tray }) {

  class StudentContextTray extends React.Component {

    static propTypes = {
      courseId: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.number
      ]),
      studentId: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.number
      ]),
      isOpen: React.PropTypes.bool,
      store: React.PropTypes.object.isRequired,
      onClose: React.PropTypes.func
    }

    static defaultProps = {
      isOpen: false
    }

    constructor (props) {
      super(props)
      this.state = {
        analytics: {},
        course: {},
        isLoading: this.props.isLoading,
        isOpen: this.props.isOpen,
        messageFormOpen: false,
        submissions: [],
        user: {}
      }
    }

    /**
     * Lifecycle
     */

    componentDidMount () {
      this.props.store.onChange = () => {
        this.setState({
          analytics: this.props.store.state.analytics,
          course: this.props.store.state.course,
          isLoading: this.props.store.state.loading,
          submissions: this.props.store.state.submissions,
          user: this.props.store.state.user
        })
      }
      this.setState({isLoading: true})
      this.props.store.loadDataForStudent()
    }

    /**
     * Handlers
     */

    handleRequestClose = (e) => {
      e.preventDefault()
      this.setState({
        isOpen: false
      })
    }

    handleMessageButtonClick = (e) => {
      e.preventDefault()
      this.setState({
        messageFormOpen: true
      })
    }

    handleMessageFormClose = (e) => {
      e.preventDefault()
      this.setState({
        messageFormOpen: false
      })
    }

    /**
     * Renderers
     */

    render () {
      return (
        <div>
          {this.state.messageFormOpen ? (
            <MessageStudents
              contextCode={`course_${this.state.course.id}`}
              onRequestClose={this.handleMessageFormClose}
              open={this.state.messageFormOpen}
              recipients={[{
                id: this.state.user.id,
                displayName: this.state.user.short_name
              }]}
              title='Send a message'
            />
          ) : null}

          <Tray isDismissable
            closeButtonLabel={I18n.t('Close')}
            isOpen={this.state.isOpen}
            onRequestClose={this.handleRequestClose}
            placement='right'
            zIndex='1000'
            onClose={this.props.onClose}
          >
            <aside
              className={(Object.keys(this.state.user).includes('avatar_url'))
                ? 'StudentContextTray StudentContextTray--withAvatar'
                : 'StudentContextTray'
              }
            >
              {this.state.isLoading ? (
                <div className='StudentContextTray__Spinner'>
                  <Spinner title={I18n.t('Loading')}
                    size='large'
                  />
                </div>
              ) : (
                <div>
                  <header className="StudentContextTray-Header">
                    <Avatar user={this.state.user} />

                    <div className="StudentContextTray-Header__Layout">
                      <div className="StudentContextTray-Header__Content">
                        {this.state.user.short_name ? (
                          <div className="StudentContextTray-Header__Name">
                            <Heading level="h3" tag="h2">
                              <Link
                                href={`/courses/${this.props.courseId}/users/${this.props.studentId}`}
                              >
                                <span className="StudentContextTray-Header__NameLink">
                                  {this.state.user.short_name}
                                </span>
                              </Link>
                            </Heading>
                          </div>
                        ) : null}
                        <div className="StudentContextTray-Header__CourseName">
                          <Typography size="medium" tag="div" lineHeight="condensed">
                            {this.state.course.name}
                          </Typography>
                        </div>
                        <Typography size="x-small" color="secondary" tag="div">
                          <SectionInfo course={this.state.course} user={this.state.user} />
                        </Typography>
                        <Typography size="x-small" color="secondary" tag="div">
                          <LastActivity user={this.state.user} />
                        </Typography>
                      </div>
                      <div className="StudentContextTray-Header__Actions">
                        <Button variant="link" size="small"
                          onClick={this.handleMessageButtonClick}>
                          <ScreenReaderContent>
                            {I18n.t("Send a message to this student")}
                          </ScreenReaderContent>

                          {/* Note: replace with instructure-icon */}
                          <i className="icon-email" aria-hidden="true" />

                        </Button>
                      </div>
                    </div>
                  </header>
                  {this.state.user.short_name ? (
                    <section
                      className="StudentContextTray__Section StudentContextTray-QuickLinks">
                      <div className="StudentContextTray-QuickLinks__Link">
                        <Button
                          href={`/courses/${this.props.courseId}/grades/${this.props.studentId}`}
                          variant="ghost" size="small" isBlock
                        >
                          {I18n.t('Grades')}
                        </Button>
                      </div>
                      <div className="StudentContextTray-QuickLinks__Link">
                        <Button
                          href={`/courses/${this.props.courseId}/analytics/users/${this.props.studentId}`}
                          variant="ghost" size="small" isBlock
                        >
                          {I18n.t('Analytics')}
                        </Button>
                      </div>
                    </section>
                  ) : null}
                  <MetricsList user={this.state.user} analytics={this.state.analytics} />
                  <SubmissionProgressBars submissions={this.state.submissions} />
                </div>
              )}
            </aside>
          </Tray>
        </div>
      )
    }
  }

  return StudentContextTray
})
