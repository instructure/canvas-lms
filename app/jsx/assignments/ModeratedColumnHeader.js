import React from 'react'
import Constants from './constants'
import I18n from 'i18n!moderated_grading'

  var ModeratedColumnHeader = React.createClass({
    displayName: 'ModeratedColumnHeader',

    propTypes: {
      markColumn: React.PropTypes.string,
      sortDirection: React.PropTypes.string,
      includeModerationSetHeaders: React.PropTypes.bool,
      handleSortMark1: React.PropTypes.func.isRequired,
      handleSortMark2: React.PropTypes.func.isRequired,
      handleSortMark3: React.PropTypes.func.isRequired,
      handleSelectAll: React.PropTypes.func.isRequired,
      permissions: React.PropTypes.shape({
        viewGrades: React.PropTypes.bool.isRequired
      }).isRequired
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

    labelSortOrder(mark) {
      if (mark === this.props.markColumn){
        if (this.props.sortDirection === Constants.sortDirections.DESCENDING){
          return I18n.t('Sorted descending.');
        } else {
          return I18n.t('Sorted ascending.');
        }
      }
    },

    renderCheckbox () {
      return this.props.permissions.viewGrades && (
        <input
          ref={(c) => { this.checkbox = c; }}
          type="checkbox"
          aria-label={I18n.t('Select all students')}
          onChange={this.props.handleSelectAll}
        />
      );
    },

    render () {
      if (this.props.includeModerationSetHeaders) {
        return (
          <div className='grid-row ModeratedColumnHeader' role="row">
            <div className='col-xs-4'>
              <div className='ModeratedColumnHeader__StudentName ColumnHeader__Item' role="columnheader">
                {this.renderCheckbox()}
                <span>{I18n.t('Student')}</span>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ModeratedColumnHeader__Mark ColumnHeader__Item' role="columnheader">
                <a href='#' onClick={this.props.handleSortMark1}>
                  <span className='screenreader-only'>{I18n.t('First reviewer')} {this.labelSortOrder(Constants.markColumnNames.MARK_ONE)}</span>
                  <span aria-hidden='true'>{I18n.t('1st Reviewer')} {this.renderLinkArrow(Constants.markColumnNames.MARK_ONE)}</span>
                </a>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__Mark ColumnHeader__Item' role="columnheader">
                <a href='#' onClick={this.props.handleSortMark2}>
                  <span className='screenreader-only'>{I18n.t('Second reviewer')} {this.labelSortOrder(Constants.markColumnNames.MARK_TWO)}</span>
                  <span aria-hidden='true'>{I18n.t('2nd Reviewer')} {this.renderLinkArrow(Constants.markColumnNames.MARK_TWO)}</span>
                </a>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__Mark ColumnHeader__Item' role="columnheader">
                <a href='#' onClick={this.props.handleSortMark3}>
                  <span className='screenreader-only'>{I18n.t('Moderator')} {this.labelSortOrder(Constants.markColumnNames.MARK_THREE)}</span>
                  <span aria-hidden='true'>{I18n.t('Moderator')} {this.renderLinkArrow(Constants.markColumnNames.MARK_THREE)}</span>
                </a>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__FinalGrade ColumnHeader__Item' role="columnheader">
                <span>{I18n.t('Grade')}</span>
              </div>
            </div>
          </div>
        );
      } else {
        return (
          <div className='grid-row ColumnHeader' role="row">
            <div className='col-xs-4'>
              <div className='ColumnHeader__StudentName ColumnHeader__Item' role="columnheader">
                {this.renderCheckbox()}
                <span>{I18n.t('Student')}</span>
              </div>
            </div>

            <div className='col-xs-2'>
              <div className='ColumnHeader__Mark ColumnHeader__Item' role="columnheader">
                <a href='#' onClick={this.props.handleSortMark1}>
                  <span className='screenreader-only'>{I18n.t('First reviewer')} {this.labelSortOrder(Constants.markColumnNames.MARK_ONE)}</span>
                  <span aria-hidden='true'>{I18n.t('1st Reviewer')} {this.renderLinkArrow(Constants.markColumnNames.MARK_ONE)}</span>
                </a>
              </div>
            </div>
          </div>
        );
      }
    }
  });

export default ModeratedColumnHeader
