define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/Typography',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/PresentationContent',
  'instructure-ui/Table',
  'instructure-ui/Button',
  'instructure-icons/react/Solid/IconXSolid',
  '../propTypes',
], (I18n, React, {default: Typography}, {default: ScreenReaderContent}, {default: PresentationContent},
  {default: Table}, {default: Button}, {default: RemoveIcon}, propTypes) => {
  const { func } = React.PropTypes

  return class CoursePickerTable extends React.Component {
    static propTypes = {
      associations: propTypes.courseList.isRequired,
      onRemoveAssociation: func.isRequired,
    }

    onRemove = (e) => {
      e.preventDefault()
      this.props.onRemoveAssociation(e.target.querySelector('input[name=course_id]').value)
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

    renderRows () {
      return this.props.associations.map(course =>
        <tr key={course.id} className="bps-associations__course-row">
          <td>
            {this.renderCellText(course.name)}
          </td>
          <td>
            {this.renderCellText(course.course_code)}
          </td>
          <td>
            {this.renderCellText(course.term.name)}
          </td>
          <td>
            {this.renderCellText(course.sis_course_id)}
          </td>
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

    render () {
      return (
        <div className="bps-associations-table">
          <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Course Associations')}</ScreenReaderContent>}>
            {this.renderColGroup()}
            <thead>
              {this.renderHeaders()}
            </thead>
            <tbody>
              {this.renderRows()}
            </tbody>
          </Table>
        </div>
      )
    }
  }
})
