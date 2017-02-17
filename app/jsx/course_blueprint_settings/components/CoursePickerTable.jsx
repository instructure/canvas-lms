define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/Typography',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/PresentationContent',
  'instructure-ui/Table',
  'instructure-ui/Checkbox',
  '../propTypes',
], (I18n, React, {default: Typography}, {default: ScreenReaderContent}, {default: PresentationContent},
  {default: Table}, {default: Checkbox}, propTypes) => {
  const { func } = React.PropTypes

  return class CoursePickerTable extends React.Component {
    static propTypes = {
      courses: propTypes.courseList.isRequired,
      onCourseSelect: func.isRequired,
    }

    renderColGroup () {
      return (
        <colgroup>
          <col span="1" style={{width: '3%'}} />
          <col span="1" style={{width: '32%'}} />
          <col span="1" style={{width: '15%'}} />
          <col span="1" style={{width: '15%'}} />
          <col span="1" style={{width: '10%'}} />
          <col span="1" style={{width: '25%'}} />
        </colgroup>
      )
    }

    renderHeaders () {
      return (
        <tr>
          <th scope="col">
            <ScreenReaderContent>{I18n.t('Course Selection')}</ScreenReaderContent>
          </th>
          <th scope="col">{I18n.t('Title')}</th>
          <th scope="col">{I18n.t('Short Name')}</th>
          <th scope="col">{I18n.t('Term')}</th>
          <th scope="col">{I18n.t('SIS ID')}</th>
          <th scope="col">{I18n.t('Teacher(s)')}</th>
        </tr>
      )
    }

    renderCellText (text) {
      return <Typography color="secondary" size="small">{text}</Typography>
    }

    renderRows () {
      return this.props.courses.map(course =>
        <tr key={course.id} className="bps-table__course-row">
          <td key="select">
            <Checkbox
              onChange={this.props.onCourseSelect}
              value={course.id}
              label={
                <ScreenReaderContent>
                  {I18n.t('Toggle select course %{name}', { name: course.name })}
                </ScreenReaderContent>
              }
            />
          </td>
          <td key="title">
            {this.renderCellText(course.name)}
          </td>
          <td key="short_name">
            {this.renderCellText(course.course_code)}
          </td>
          <td key="term">
            {this.renderCellText(course.term.name)}
          </td>
          <td key="sis_id">
            {this.renderCellText(course.sis_course_id)}
          </td>
          <td key="teachers">
            {this.renderCellText(course.teachers.map(teacher => teacher.display_name).join(', '))}
          </td>
        </tr>
      )
    }

    renderBodyContent () {
      if (this.props.courses.length > 0) {
        return [(
          <ScreenReaderContent key="select-all" tag="tr">
            <td>
              <Checkbox
                onChange={this.props.onCourseSelect}
                value="all"
                label={I18n.t({ one: 'Select (%{count}) Course', other: 'Select All (%{count}) Courses' },
                { count: this.props.courses.length })}
              />
            </td>
          </ScreenReaderContent>
        )].concat(this.renderRows())
      }

      return (
        <tr key="no-results" className="bps-table__no-results">
          <td>{this.renderCellText(I18n.t('No results'))}</td>
        </tr>
      )
    }

    renderStickyHeaders () {
      // in order to create a sticky table header, we'll create a separate table with
      // just the visual sticky headers, that will be hidden from screen readers
      return (
        <PresentationContent tagName="div">
          <div className="btps-table__header-wrapper">
            <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Courses')}</ScreenReaderContent>}>
              {this.renderColGroup()}
              <thead className="bps-table__head">
                {this.renderHeaders()}
              </thead>
              <tbody>
                <tr>
                  <td key="select">
                    <Checkbox
                      onChange={this.props.onCourseSelect}
                      value="all"
                      label={
                        <ScreenReaderContent>
                          {I18n.t({ one: 'Select (%{count}) Course', other: 'Select All (%{count}) Courses' },
                          { count: this.props.courses.length })}
                        </ScreenReaderContent>
                      }
                    />
                  </td>
                  <td colSpan="5" key="label">{I18n.t('Select All (%{count})', { count: this.props.courses.length })}</td>
                </tr>
              </tbody>
            </Table>
          </div>
        </PresentationContent>
      )
    }

    render () {
      return (
        <div className="bps-table__wrapper">
          {this.renderStickyHeaders()}
          <div className="bps-table__content-wrapper">
            <Table caption={<ScreenReaderContent>{I18n.t('Blueprint Courses')}</ScreenReaderContent>}>
              {this.renderColGroup()}
              {/* on the real table, we'll include the headers again, but make them screen reader only */}
              <ScreenReaderContent tag="thead">
                {this.renderHeaders()}
              </ScreenReaderContent>
              <tbody className="bps-table__body">
                {this.renderBodyContent()}
              </tbody>
            </Table>
          </div>
        </div>
      )
    }
  }
})
