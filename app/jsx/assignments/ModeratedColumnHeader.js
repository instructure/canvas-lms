import React from 'react'
import Constants from './constants'
import I18n from 'i18n!moderated_grading'

const ModeratedColumnHeader = React.createClass({
  displayName: 'ModeratedColumnHeader',

  propTypes: {
    markColumn: React.PropTypes.string.isRequired,
    sortDirection: React.PropTypes.string,
    includeModerationSetHeaders: React.PropTypes.bool.isRequired,
    handleSortMark1: React.PropTypes.func.isRequired,
    handleSortMark2: React.PropTypes.func.isRequired,
    handleSortMark3: React.PropTypes.func.isRequired,
    handleSelectAll: React.PropTypes.func.isRequired,
    permissions: React.PropTypes.shape({
      viewGrades: React.PropTypes.bool.isRequired
    }).isRequired
  },

  onSelectAllBlurred () {
    this.checkbox.setAttribute('aria-label', '');
  },

  onSelectAllFocused () {
    this.checkbox.setAttribute('aria-label', I18n.t('Select all students'));
  },

  labelSortOrder (mark) {
    if (mark !== this.props.markColumn) {
      return '';
    }

    switch (this.props.sortDirection) {
      case Constants.sortDirections.DESCENDING:
        return I18n.t('sorted descending');
      case Constants.sortDirections.ASCENDING:
        return I18n.t('sorted ascending');
      default:
        return '';
    }
  },

  renderLinkArrow (mark) {
    if (mark !== this.props.markColumn) {
      return null;
    }

    if (this.props.sortDirection === Constants.sortDirections.DESCENDING) {
      return (<i className="icon-mini-arrow-down" />);
    }

    return (<i className="icon-mini-arrow-up" />);
  },

  renderCheckbox () {
    if (!this.props.permissions.viewGrades) {
      return (
        <th scope="col" className="ColumnHeader__Selector">&nbsp;</th>
      );
    }

    return (
      <th
        scope="col"
        className="ColumnHeader__Selector"
        onBlur={this.onSelectAllBlurred}
        onFocus={this.onSelectAllFocused}
      >
        <input
          ref={(c) => { this.checkbox = c; }}
          type="checkbox"
          onChange={this.props.handleSelectAll}
        />
      </th>
    );
  },

  renderStudentColumnHeader () {
    return (
      <th scope="col" className="ModeratedColumnHeader__StudentName ColumnHeader__Item">
        <span>{I18n.t('Student')}</span>
      </th>
    );
  },

  renderFirstReviewerColumnHeader () {
    return (
      <th scope="col" className="ModeratedColumnHeader__Mark ColumnHeader__Item">
        <a
          href="#"
          onClick={this.props.handleSortMark1}
        >
          <span aria-label={I18n.t('First reviewer %{sortOrder}', { sortOrder: this.labelSortOrder(Constants.markColumnNames.MARK_ONE) })}>
            {I18n.t('1st Reviewer')}&nbsp;{this.renderLinkArrow(Constants.markColumnNames.MARK_ONE)}
          </span>
        </a>
      </th>
    );
  },

  render () {
    if (this.props.includeModerationSetHeaders) {
      return (
        <thead>
          <tr className="ModeratedColumnHeader">
            {this.renderCheckbox()}
            {this.renderStudentColumnHeader()}
            {this.renderFirstReviewerColumnHeader()}

            <th scope="col" className="ModeratedColumnHeader__Mark ColumnHeader__Item">
              <a
                href="#"
                onClick={this.props.handleSortMark2}
              >
                <span aria-label={`${I18n.t('Second reviewer')} ${this.labelSortOrder(Constants.markColumnNames.MARK_TWO)}`}>
                  {I18n.t('2nd Reviewer')}&nbsp;{this.renderLinkArrow(Constants.markColumnNames.MARK_TWO)}
                </span>
              </a>
            </th>

            <th scope="col" className="ModeratedColumnHeader__Mark ColumnHeader__Item">
              <a
                href="#"
                onClick={this.props.handleSortMark3}
              >
                <span aria-label={I18n.t('Moderator %{sortOrder}', { sortOrder: this.labelSortOrder(Constants.markColumnNames.MARK_THREE) })}>
                  {I18n.t('Moderator')}&nbsp;{this.renderLinkArrow(Constants.markColumnNames.MARK_THREE)}
                </span>
              </a>
            </th>

            <th scope="col" className="ColumnHeader__FinalGrade ColumnHeader__Item">
              {I18n.t('Grade')}
            </th>
          </tr>
        </thead>
      );
    }

    return (
      <thead>
        <tr className="ModeratedColumnHeader">
          {this.renderCheckbox()}
          {this.renderStudentColumnHeader()}
          {this.renderFirstReviewerColumnHeader()}
        </tr>
      </thead>
    );
  }
});

export default ModeratedColumnHeader
