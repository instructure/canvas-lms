/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, { Component, PropTypes } from "react";
import LinkSet from "./LinkSet";
import formatMessage from "../../format-message";

class NavigationPanel extends Component {
  collection() {
    const { contextId } = this.props;
    switch (this.props.contextType) {
      case "course":
        return {
          links: [
            {
              href: `/courses/${contextId}/assignments`,
              title: formatMessage("Assignments")
            },
            {
              href: `/courses/${contextId}/pages`,
              title: formatMessage("Pages")
            },
            {
              href: `/courses/${contextId}/discussion_topics`,
              title: formatMessage("Discussions")
            },
            {
              href: `/courses/${contextId}/assignments/syllabus`,
              title: formatMessage("Syllabus")
            },
            {
              href: `/courses/${contextId}/announcements`,
              title: formatMessage("Announcements")
            },
            {
              href: `/courses/${contextId}/quizzes`,
              title: formatMessage("Quizzes")
            },
            {
              href: `/courses/${contextId}/files`,
              title: formatMessage("Files")
            },
            {
              href: `/courses/${contextId}/collaborations`,
              title: formatMessage("Collaborations")
            },
            {
              href: `/courses/${contextId}/grades`,
              title: formatMessage("Grades")
            },
            {
              href: `/courses/${contextId}/users`,
              title: formatMessage("People")
            },
            {
              href: `/courses/${contextId}/modules`,
              title: formatMessage("Modules")
            }
          ]
        };
      case "group":
        return {
          links: [
            {
              href: `/groups/${contextId}/pages`,
              title: formatMessage("Wiki Home")
            },
            {
              href: `/groups/${contextId}/discussion_topics`,
              title: formatMessage("Discussions Index")
            },
            {
              href: `/groups/${contextId}/announcements`,
              title: formatMessage("Announcement List")
            },
            {
              href: `/groups/${contextId}/files`,
              title: formatMessage("Files Index")
            },
            {
              href: `/groups/${contextId}/collaborations`,
              title: formatMessage("Collaborations")
            },
            {
              href: `/groups/${contextId}/users`,
              title: formatMessage("People")
            }
          ]
        };
      default:
        // user, TODO
        return {
          links: [
            {
              href: `/users/${contextId}/files`,
              title: formatMessage("Files Index")
            }
          ]
        };
    }
  }

  render() {
    return (
      <LinkSet
        collection={this.collection()}
        onLinkClick={this.props.onLinkClick}
      />
    );
  }
}

NavigationPanel.propTypes = {
  contextType: PropTypes.string.isRequired,
  contextId: PropTypes.string.isRequired,
  onLinkClick: PropTypes.func
};

export default NavigationPanel;
