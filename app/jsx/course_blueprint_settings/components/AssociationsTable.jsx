define([
  'i18n!blueprint_config',
  'jquery',
  'react',
  'instructure-ui/Typography',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/PresentationContent',
  'instructure-ui/Table',
  'instructure-ui/Button',
  'instructure-ui/Spinner',
  'instructure-icons/react/Solid/IconXSolid',
  '../propTypes',
  'compiled/jquery.rails_flash_notifications',
], (I18n, $, React, {default: Typography}, {default: ScreenReaderContent}, {default: PresentationContent},
  {default: Table}, {default: Button}, {default: Spinner}, {default: RemoveIcon}, propTypes) => {
  const { func, arrayOf, string, bool } = React.PropTypes

  return class CoursePickerTable extends React.Component {
    static propTypes = {
      existingAssociations: propTypes.courseList.isRequired,
      addedAssociations: propTypes.courseList.isRequired,
      removedAssociations: arrayOf(string).isRequired,
      onRemoveAssociations: func.isRequired,
      isLoadingAssociations: bool.isRequired,
    }

    constructor (props) {
      super(props)
      this.state = {
        visibleExisting: this.props.existingAssociations,
      }
    }

    componentWillReceiveProps (nextProps) {
      this.setState({
        visibleExisting: nextProps.existingAssociations.filter(assoc => !nextProps.removedAssociations.includes(assoc.id)),
      })

      if (!this.props.isLoadingAssociations && nextProps.isLoadingAssociations) {
        $.screenReaderFlashMessage(I18n.t('Loading associations started'))
      }

      if (this.props.isLoadingAssociations && !nextProps.isLoadingAssociations) {
        $.screenReaderFlashMessageExclusive(I18n.t('Loading associations complete'))
      }
    }

    onRemove = (e) => {
      e.preventDefault()
      this.props.onRemoveAssociations([e.target.querySelector('input[name=course_id]').value])
    }

    renderColGroup () {
      return (
        <colgroup>
          <col span="1" style={{width: '32%'}} />
          <col span="1" style={{width: '15%'}} />
          <col span="1" style={{width: '15%'}} />
          <col span="1" style={{width: '10%'}} />
          <col span="1" style={{width: '25%'}} />
          <col span="1" style={{width: '3%'}} />
        </colgroup>
      )
    }

    renderHeaders () {
      return (
        <tr>
          <th scope="col">{I18n.t('Title')}</th>
          <th scope="col">{I18n.t('Short Name')}</th>
          <th scope="col">{I18n.t('Term')}</th>
          <th scope="col">{I18n.t('SIS ID')}</th>
          <th scope="col">{I18n.t('Teacher(s)')}</th>
          <th scope="col">
            <ScreenReaderContent>{I18n.t('Remove Association')}</ScreenReaderContent>
          </th>
        </tr>
      )
    }

    renderCellText (text) {
      return <Typography color="secondary" size="small">{text}</Typography>
    }

    renderRows (associations) {
      return associations.map(course =>
        <tr key={course.id} className="bps-associations__course-row">
          <td>{this.renderCellText(course.name)}</td>
          <td>{this.renderCellText(course.course_code)}</td>
          <td>{this.renderCellText(course.term.name)}</td>
          <td>{this.renderCellText(course.sis_course_id)}</td>
          <td>
            {this.renderCellText(course.teachers.map(teacher => teacher.display_name).join(', '))}
          </td>
          <td>
            <form onSubmit={this.onRemove}>
              <input type="hidden" name="course_id" value={course.id} />
              <Button size="small" type="submit" variant="icon">
                <RemoveIcon title={I18n.t('Remove course association %{name}', { name: course.name })} />
              </Button>
            </form>
          </td>
        </tr>
      )
    }

    renderExistingAssociations () {
      if (this.state.visibleExisting.length) {
        return [(
          <tr key="existing-heading">
            <td colSpan={6}><Typography weight="bold" size="small">{I18n.t('Current')}</Typography></td>
          </tr>
        )].concat(this.renderRows(this.state.visibleExisting))
      }

      return null
    }

    renderAddedAssociations () {
      if (this.props.addedAssociations.length) {
        return [(
          <tr key="added-heading">
            <td colSpan={6}><Typography weight="bold" size="small">{I18n.t('To be Added')}</Typography></td>
          </tr>
        )].concat(this.renderRows(this.props.addedAssociations))
      }

      return null
    }

    renderTable () {
      return (
        <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Course Associations')}</ScreenReaderContent>}>
          {this.renderColGroup()}
          <thead>
            {this.renderHeaders()}
          </thead>
          <tbody>
            {this.renderExistingAssociations()}
            {this.renderAddedAssociations()}
          </tbody>
        </Table>
      )
    }

    renderLoadingOverlay () {
      const { isLoadingAssociations } = this.props
      if (isLoadingAssociations) {
        const title = I18n.t('Loading Associations')
        return (
          <div className="bps__overlay">
            <Spinner title={title} />
            <Typography tag="p">{title}</Typography>
          </div>
        )
      }

      return null
    }

    render () {
      const { addedAssociations } = this.props
      return (
        <div className="bps-associations-table">
          {this.renderLoadingOverlay()}
          { this.state.visibleExisting.length || addedAssociations.length
            ? this.renderTable()
            : <Typography color="secondary" tag="p">{I18n.t('There are currently no associated courses.')}</Typography>
          }
        </div>
      )
    }
  }
})
