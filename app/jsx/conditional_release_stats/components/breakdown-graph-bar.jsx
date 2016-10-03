define([
  'react',
  'i18n!cyoe_assignment_sidebar',
], (React, I18n) => {
  const { string, number, func } = React.PropTypes

  class BreakdownGraph extends React.Component {
    static propTypes = {
      rangeStudents: number.isRequired,
      totalStudents: number.isRequired,
      lowerBound: string.isRequired,
      upperBound: string.isRequired,
      rangeIndex: number.isRequired,
      selectRange: func.isRequired,
    }

    constructor () {
      super()
      this.selectRange = this.selectRange.bind(this)
    }

    selectRange () {
      this.props.selectRange(this.props.rangeIndex)
    }

    renderInnerBar() {
      const width = Math.min((this.props.rangeStudents / this.props.totalStudents) * 100, 100)
      const progressBarStyle = { width: width + '%' }
      if (width > 0) {
        return (
          <div style={progressBarStyle} className='crs-bar__horizontal-inside-fill'></div>
        )
      } else {
        return null
      }
    }

    render () {

      return (
        <div className='crs-bar__container'>
          <div className='crs-bar__horizontal-outside'>
            <div className='crs-bar__horizontal-inside'></div>
            { this.renderInnerBar() }
          </div>
          <div className='crs-bar__bottom'>
            <span className='crs-bar__info'>{I18n.t('%{lowerBound}+ to %{upperBound}', {
              upperBound: this.props.upperBound,
              lowerBound: this.props.lowerBound,
            })}
            </span>
            <button
              className='crs-link-button'
              onClick={this.selectRange}
              aria-label={I18n.t('View range student details')}
            >
              {I18n.t('%{rangeStudents} out of %{totalStudents} students', {
                rangeStudents: this.props.rangeStudents,
                totalStudents: this.props.totalStudents,
              })}
            </button>
          </div>
        </div>
      )
    }
  }

  return BreakdownGraph
})
