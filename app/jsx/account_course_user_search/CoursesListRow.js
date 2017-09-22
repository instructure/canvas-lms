/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import CreateUsersView from 'compiled/views/courses/roster/CreateUsersView'
import RosterUserCollection from 'compiled/collections/RosterUserCollection'
import SectionCollection from 'compiled/collections/SectionCollection'
import RolesCollection from 'compiled/collections/RolesCollection'
import Role from 'compiled/models/Role'
import CreateUserList from 'compiled/models/CreateUserList'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import {Model} from 'Backbone'
import I18n from 'i18n!account_course_user_search'
import _ from 'underscore'
import UserLink from './UserLink'

const { number, string, shape, arrayOf } = PropTypes;

class CoursesListRow extends React.Component {
  static propTypes = {
    id: string.isRequired,
    name: string.isRequired,
    workflow_state: string.isRequired,
    total_students: number.isRequired,
    teachers: arrayOf(shape(UserLink.propTypes)).isRequired,
    sis_course_id: string.isRequired,
    subaccount_name: string.isRequired,
    urls: shape({ ENROLL_USERS_URL: string.isRequired, USER_LISTS_URL: string.isRequired }),
    roles: arrayOf(shape({ id: string.isRequired })),
    sections: arrayOf(shape(UserLink.propTypes)),
  };

  static defaultProps = {
    roles: [],
    urls: {ENROLL_USERS_URL: '', USER_LISTS_URL: ''},
    sections: [],
  };

  constructor (props) {
    super(props)

    const teachers = _.uniq(props.teachers, t => t.id);

    this.state = {
      teachersToShow: _.compact([teachers[0], teachers[1]])
    }
  }

  showMoreLink = () => {
    if (this.props.teachers.length > 2 && this.state.teachersToShow.length === 2) {
      return <a className="showMoreLink" href="#" onClick={this.showMoreTeachers}> {I18n.t('Show More')}</a>
    }
  }

  showMoreTeachers = () => {
    this.setState({teachersToShow: _.uniq(this.props.teachers, t => t.id)});
  }

  addUserToCourse = () => {
    const course = new Model({id: this.props.id});

    const userCollection = new RosterUserCollection(null, {
      course_id: this.props.id,
      sections: new SectionCollection(this.props.sections),
      params: {
        include: ['avatar_url', 'enrollments', 'email', 'observed_users', 'can_be_removed'],
        per_page: 50
      }
    });

    userCollection.fetch();
    userCollection.once('reset', () => {
      userCollection.on('reset', () => {
        const numUsers = userCollection.length;
        let msg = '';
        if (numUsers === 0) {
          msg = I18n.t('No matching users found.');
        } else if (numUsers === 1) {
          msg = I18n.t('1 user found.');
        } else {
          msg = I18n.t('%{userCount} users found.', {userCount: numUsers});
        }
        $('#aria_alerts').empty().text(msg);
      });
    });

    const createUsersViewParams = {
      collection: userCollection,
      rolesCollection: new RolesCollection(this.props.roles.map(role => new Role(role))),
      model: new CreateUserList({
        sections: this.props.sections,
        roles: this.props.roles,
        readURL: this.props.urls.USER_LISTS_URL,
        updateURL: this.props.urls.ENROLL_USERS_URL
      }),
      courseModel: course,
      title: I18n.t('Add People'),
      height: 520,
      className: 'form-dialog'

    };

    const createUsersBackboneView = new CreateUsersView(createUsersViewParams);
    createUsersBackboneView.open();
    createUsersBackboneView.on('close', () => {
      createUsersBackboneView.remove()
    });
  }

  render () {
    const { id, name, workflow_state, sis_course_id, total_students, subaccount_name } = this.props;
    const url = `/courses/${id}`;
    const isPublished = workflow_state !== 'unpublished';

    return (
      <div role="row" className="grid-row pad-box-mini border border-b">
        <div className="col-xs-3">
          <div role="gridcell" className="grid-row middle-xs">
            <div className="col-xs-2">{isPublished && (<i className="icon-publish icon-Solid courses-list__published-icon" />)}</div>
            <div className="col-xs-10">
              <div className="courseName">
                <a href={url}>{name}</a>
              </div>
            </div>
          </div>
        </div>

        <div className="col-xs-1" role="gridcell">
          <div className="courseSIS">{sis_course_id}</div>
        </div>

        <div className="col-xs-2" role="gridcell">
          {this.state.teachersToShow && this.state.teachersToShow.map(teacher => <UserLink key={teacher.id} {...teacher} />)}
          { this.showMoreLink() }
        </div>

        <div className="col-xs-2" role="gridcell">
          <div className="courseSubaccount">{subaccount_name}</div>
        </div>

        <div className="col-xs-1" role="gridcell">
          <div className="totalStudents">{I18n.n(total_students)}</div>
        </div>
        <div className="col-xs-2" role="gridcell">
          <div className="courses-user-list-actions">
            <button className="Button Button--icon-action addUserButton" onClick={this.addUserToCourse} type="button">
              <span className="screenreader-only">{I18n.t('Add Users to %{name}', {name: this.props.name})}</span>
              <i className="icon-plus" aria-hidden="true" />
            </button>
            <a className="Button Button--icon-action" href={`/courses/${this.props.id}/statistics`}>
              <span className="screenreader-only">{I18n.t('Go to statistics for %{name}', {name: this.props.name})}</span>
              <i className="icon-stats" aria-hidden="true" />
            </a>
            <a className="Button Button--icon-action" href={`/courses/${this.props.id}/settings`}>
              <span className="screenreader-only">{I18n.t('Go to settings for %{name}', {name: this.props.name})}</span>
              <i className="icon-settings" aria-hidden="true" />
            </a>
          </div>
        </div>
      </div>
    );
  }
}

export default CoursesListRow
