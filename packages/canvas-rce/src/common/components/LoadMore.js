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

import PropTypes from "prop-types";

import React, { Component } from "react";
import Loading from "./Loading";
import formatMessage from "../../format-message";
import Button from "@instructure/ui-buttons/lib/components/Button";
import { StyleSheet, css } from "aphrodite";

class LoadMore extends Component {
  constructor(props) {
    super(props);
    this.state = {
      nextFocus: Infinity
    };
  }

  componentDidUpdate() {
    const focusable = this.focusableElements();
    if (focusable.length > this.state.nextFocus) {
      const next = focusable[this.state.nextFocus];
      if (next) {
        next.focus();
      }
    }
  }

  focusableElements() {
    if (!this.props.focusSelector) {
      return [];
    }
    return this.refs.parent.querySelectorAll(this.props.focusSelector);
  }

  loadMore = ev => {
    this.setState({ nextFocus: this.focusableElements().length });
    this.props.loadMore(ev);
  };

  render() {
    const hasChildren = React.Children.count(this.props.children) > 0;
    const opacity = this.props.isLoading ? 1 : 0;

    return (
      <div ref="parent">
        {this.props.children}

        {this.props.hasMore &&
          !this.props.isLoading && (
            <div className={css(styles.button)}>
              <Button variant="link" onClick={this.loadMore} fluidWidth={true}>
                {formatMessage("Load more results")}
              </Button>
            </div>
          )}

        {hasChildren &&
          this.props.hasMore && (
            <div
              aria-hidden={!this.props.isLoading}
              className={css(styles.loader)}
              style={{ opacity }}
            >
              <Loading />
            </div>
          )}
      </div>
    );
  }
}

LoadMore.propTypes = {
  hasMore: PropTypes.bool.isRequired,
  loadMore: PropTypes.func.isRequired,
  isLoading: PropTypes.bool,
  focusSelector: PropTypes.string,
  children: PropTypes.any /* Immutable.List is not a valid 'node' */
};

export const styles = StyleSheet.create({
  loader: {
    display: "block",
    margin: "20px 0 40px 0",
    clear: "both",
    paddingRight: "30px" /* needed for centering */,
    textAlign: "center",
    fontSize: "13px",
    height: "15px",
    color: "#666"
  },
  button: {
    textAlign: "center",
    marginTop: "1em",
    clear: "both"
  }
});

export default LoadMore;
