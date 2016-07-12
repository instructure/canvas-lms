define([
  'react',
  'i18n!cyoe_assignment_sidebar'
], function(React, I18n) {

  const { string, number, bool } = React.PropTypes;

  class BarComponent extends React.Component {
    static get propTypes () {
      return {
        studentsPerRangeCount: number.isRequired,
        totalStudentsEnrolled: number.isRequired,
        lowerBound: string,
        upperBound: string,
        isTop: bool,
        isBottom: bool,
        path: string,
      }
    }

    render() {
      const progressBarStyle = {
        width: ((((this.props.studentsPerRangeCount * 1.0) / this.props.totalStudentsEnrolled)) * 100 + '%'),
      }

      return (
        <div className={'crs-bar__container'} >
          <div className='crs-bar__horizontal-outside'>
            <div className='crs-bar__horizontal-inside'></div>
            <div style={progressBarStyle} className='crs-bar__horizontal-inside-fill'></div>
          </div>
          <div className='crs-bar__bottom'>
            <span className='crs-bar__info'>{I18n.t('%{lowerBound}+ to %{upperBound}', {
              upperBound: this.props.upperBound,
              lowerBound: this.props.lowerBound,
            })}
            </span>
            <a href='#' className='crs-bar__link'>{I18n.t('%{studentsPerRangeCount} out of %{totalStudentsEnrolled} students', {
              studentsPerRangeCount: this.props.studentsPerRangeCount,
              totalStudentsEnrolled: this.props.totalStudentsEnrolled,
            })}</a>
          </div>
        </div>
      )
    }
  }

  return BarComponent;
});
