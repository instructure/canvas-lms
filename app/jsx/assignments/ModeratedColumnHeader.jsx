/** @jsx React.DOM */

define([
  'react',
  './constants'
], function (React, Constants) {
  var ModeratedColumnHeader = React.createClass({
    displayName: 'ModeratedColumnHeader',
    propTypes:{
      markColumn: React.PropTypes.number,
      currentSortDirection: React.PropTypes.string,
      handleSortByThisColumn: React.PropTypes.func.isRequired,
      includeModerationSetHeaders: React.PropTypes.bool
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
    renderModerationSetColumnHeaders () {
      if(this.props.includeModerationSetHeaders){
        return (
          <div className='ColumnHeader__ModerationSetContainer'>
            <div className='ColumnHeader__ColumnItem'>
              <a href='#' onClick={this.props.handleSortByThisColumn.bind(null, Constants.markColumn.MARK_TWO, this.props)}>2st Mark {this.renderLinkArrow(Constants.markColumn.MARK_TWO)}</a>
            </div>
            <div className='ColumnHeader__ColumnItem'>
              <a href='#' onClick={this.props.handleSortByThisColumn.bind(null, Constants.markColumn.MARK_THREE, this.props)}>3st Mark {this.renderLinkArrow(Constants.markColumn.MARK_THREE)}</a>
            </div>
            <div className='ColumnHeader__ColumnItem'>
              <span>Grade</span>
            </div>
          </div>
        );
      }
    },
    render () {
      return (
        <div className='ColumnHeader'>
          <div className='ColumnHeader__StudentName'>
            <input type='checkbox' />
            <strong>Student</strong>
          </div>
          <div className='ColumnHeader__ColumnItem'>
            <a href='#' onClick={this.props.handleSortByThisColumn.bind(null, Constants.markColumn.MARK_ONE, this.props)}>1st Mark {this.renderLinkArrow(Constants.markColumn.MARK_ONE)}</a>
          </div>
          {this.renderModerationSetColumnHeaders()}
        </div>
      );
    }
  });

  return ModeratedColumnHeader;
});
