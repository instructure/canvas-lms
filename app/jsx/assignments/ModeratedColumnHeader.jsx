/** @jsx React.DOM */

define([
  'react',
  './constants',
  'i18n!moderated_grading'
], function (React, Constants, I18n) {
  var ModeratedColumnHeader = React.createClass({
    displayName: 'ModeratedColumnHeader',

    propTypes: {
      markColumn: React.PropTypes.string,
      sortDirection: React.PropTypes.string,
      includeModerationSetHeaders: React.PropTypes.bool,
      handleSortMark1: React.PropTypes.func.isRequired,
      handleSortMark2: React.PropTypes.func.isRequired,
      handleSortMark3: React.PropTypes.func.isRequired,
      handleSelectAll: React.PropTypes.func.isRequired
    },

    renderLinkArrow (mark) {
      if (mark === this.props.markColumn){
        if (this.props.sortDirection === Constants.sortDirections.DESCENDING){
          return (<i className='icon-mini-arrow-down'></i>);
        } else {
          return (<i className='icon-mini-arrow-up'></i>);
        }
      }
    },
    render () {
      if (this.props.includeModerationSetHeaders) {
        return (
          <div className='grid-row ModeratedColumnHeader'>
            <div className='col-xs-4'>
              <div className='ModeratedColumnHeader__StudentName ColumnHeader__Item'>
                <input type='checkbox' onChange={this.handleSelectAll} />
                <span>{I18n.t('Student')}</span>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ModeratedColumnHeader__Mark ColumnHeader__Item'>
                <a href='#' onClick={this.props.handleSortMark1}>{I18n.t('1st Reviewer')} {this.renderLinkArrow(Constants.markColumnNames.MARK_ONE)}</a>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__Mark ColumnHeader__Item'>
                <a href='#' onClick={this.props.handleSortMark2}>{I18n.t('2nd Reviewer')} {this.renderLinkArrow(Constants.markColumnNames.MARK_TWO)}</a>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__Mark ColumnHeader__Item'>
                <a href='#' onClick={this.props.handleSortMark3}>{I18n.t('Moderator')} {this.renderLinkArrow(Constants.markColumnNames.MARK_THREE)}</a>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__FinalGrade ColumnHeader__Item'>
                <span>{I18n.t('Grade')}</span>
              </div>
            </div>
          </div>
        );
      } else {
        return (
          <div className='grid-row ColumnHeader'>
            <div className='col-xs-4'>
              <div className='ColumnHeader__StudentName ColumnHeader__Item'>
                <input type='checkbox' onChange={this.handleSelectAll} />
                <span>{I18n.t('Student')}</span>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__Mark ColumnHeader__Item'>
                <a href='#' onClick={this.props.handleSortMark1}>{I18n.t('1st Reviewer')} {this.renderLinkArrow(Constants.markColumnNames.MARK_ONE)}</a>
              </div>
            </div>
          </div>
        );
      }
    }
  });

  return ModeratedColumnHeader;
});
