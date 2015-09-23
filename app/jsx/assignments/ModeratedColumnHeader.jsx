/** @jsx React.DOM */

define([
  'react',
  './constants',
  './actions/ModerationActions'
], function (React, Constants, ModerationActions) {
  var ModeratedColumnHeader = React.createClass({
    displayName: 'ModeratedColumnHeader',
    propTypes:{
      markColumn: React.PropTypes.number,
      currentSortDirection: React.PropTypes.string,
      handleSortByThisColumn: React.PropTypes.func.isRequired,
      includeModerationSetHeaders: React.PropTypes.bool
    },

    handleSelectAll (event) {
      if (event.target.checked) {
        var allStudents = this.props.store.getState().students;
        this.props.store.dispatch(ModerationActions.selectAllStudents(allStudents));
      } else {
        this.props.store.dispatch(ModerationActions.unselectAllStudents());
      }
    },

    renderLinkArrow (mark) {
      if (mark === this.props.markColumn){
        if (this.props.currentSortDirection === Constants.sortDirections.HIGHEST){
          return(<i className='icon-mini-arrow-down'></i>);
        }else{
          return(<i className='icon-mini-arrow-up'></i>);
        }
      }
    },
    render () {
      if(this.props.includeModerationSetHeaders){
        return(
          <div className='ModeratedColumnHeader'>
            <div className='ModeratedColumnHeader__StudentName ColumnHeader__Item'>
              <input type='checkbox' onChange={this.handleSelectAll} />
              <span>Student</span>
            </div>

            <div className='ModeratedColumnHeader__Mark ColumnHeader__Item'>
              <a href='#' onClick={this.props.handleSortByThisColumn.bind(null, Constants.markColumn.MARK_ONE, this.props)}>1st Mark {this.renderLinkArrow(Constants.markColumn.MARK_ONE)}</a>
            </div>

            <div className='ColumnHeader__Mark ColumnHeader__Item'>
              <a href='#' onClick={this.props.handleSortByThisColumn.bind(null, Constants.markColumn.MARK_TWO, this.props)}>2st Mark {this.renderLinkArrow(Constants.markColumn.MARK_TWO)}</a>
            </div>

            <div className='ColumnHeader__Mark ColumnHeader__Item'>
              <a href='#' onClick={this.props.handleSortByThisColumn.bind(null, Constants.markColumn.MARK_THREE, this.props)}>3st Mark {this.renderLinkArrow(Constants.markColumn.MARK_THREE)}</a>
            </div>

            <div className='ColumnHeader__FinalGrade ColumnHeader__Item'>
              <span>Grade</span>
            </div>
          </div>
        );
      }else{
        return(
          <div className='ColumnHeader'>
            <div className='ColumnHeader__StudentName ColumnHeader__Item'>
              <input type='checkbox' onChange={this.handleSelectAll} />
              <span>Student</span>
            </div>

            <div className='ColumnHeader__Mark ColumnHeader__Item'>
              <a href='#' onClick={this.props.handleSortByThisColumn.bind(null, Constants.markColumn.MARK_ONE, this.props)}>1st Mark {this.renderLinkArrow(Constants.markColumn.MARK_ONE)}</a>
            </div>
          </div>
        );
      }
    }
  });

  return ModeratedColumnHeader;
});
