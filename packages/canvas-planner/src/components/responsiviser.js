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

import React from 'react';

// Watches for changes in the match state of a media-query
class MediaQueryWatcher {
  size = 'large';
  interestedParties = [];

  // initialize the mediaQueryList with our media-query of interest
  setup () {
    if (!window.matchMedia) return; // or unit tests fail
    this.mediaQueryList = window.matchMedia('(max-width: 56em)'); // ==896px. hard-code query for now
    this.size = this.mediaQueryList.matches ? 'medium' : 'large';

    // some browsers support mediaQueryList.onchange. Use it if we can
    if ('onchange' in this.mediaQueryList) {
      this.mediaQueryList.onchange = (event) => {
        this.onChangeSize(event);
      };
    } else {
      // add a window.resize event handler. When the user stops
      // resizing for 100ms, check the state of the mediaQueryList's
      // match state.
      this.handleResize = () => {
        window.clearTimeout(this.resizeTimer);
        this.resizeTimer = window.setTimeout(() => {
          this.resizeTimer = 0;
          this.onChangeSize(this.mediaQueryList);
        }, 100);
      };
      this.elementResizeListener = window.addEventListener('resize', this.handleResize);
    }
  }
  teardown () {
    if ('onchange' in this.mediaQueryList) {
      this.mediaQueryList.onchange = null;
    } else {
      window.clearTimeout(this.resizeTimer);
      window.removeEventListener('resize', this.handleResize);
    }
  }
  // add a component that's interested in being notified when the media-query
  // match state changes
  add (interestedParty) {
    if (!this.mediaQueryList) {
      this.setup();
    }
    this.interestedParties.push(interestedParty);
    return this.size;
  }
  // remove a component that's no longer interested
  remove (interestedParty) {
    const i = this.interestedParties.indexOf(interestedParty);
    this.interestedParties.splice(i, 1);
    if (this.mediaQueryList && this.interestedParties.length === 0) {
      this.teardown();
      this.mediaQueryList = null;
    }
  }
  // tell everyone that's interested something has changed
  notifyAll () {
    this.interestedParties.forEach((g) => {
      g.onChangeSize({size: this.size});
    });
  }
  // we just noticed a change in media-query match state
  onChangeSize (event) {
    const newSize = event.matches ? 'medium' : 'large';
    if (newSize !== this.size) {
      this.size = newSize;
      this.notifyAll();
    }
  }
}

// take any react component have it respond to media query state
// e.g.  const ResponsiveFoo = responsiviser()(Foo)
// The media query is currently hard-coded to deal with medium v. large
// rendering of Grouping, but could be extended to have a map of
// MediaQueryWatchers for each one. We'll add that complication if it
// ever becomes necessary.
// This has the advantage over instui Responsive in that it only requires
// one listener and has interested parties register to be notified of
// a change in state.
function responsiviser () {
  return function (ComposedComponent) {
    class ResponsiveComponent extends React.Component {
      static propTypes = {
        ...ComposedComponent.propTypes
      }
      static defaultProps = ComposedComponent.defaultProps ? {...ComposedComponent.defaultProps} : null;
      static name() {
        return `Responsive${ComposedComponent.displayName}`;
      }

      constructor (props) {
        super(props);

        const size = responsiviser.mqwatcher.add(this);
        this.state = {
          size,
        };
      }

      componentWillUnmount () {
        responsiviser.mqwatcher.remove(this);
      }

      onChangeSize (event) {
        this.setState({size: event.size});
      }

      render () {
        return <ComposedComponent {...this.props} responsiveSize={this.state.size} />;
      }
    }
    ResponsiveComponent.displayName = ResponsiveComponent.name();
    return ResponsiveComponent;
  };
}
responsiviser.mqwatcher = new MediaQueryWatcher();  // create the one and only one (for now)


export default responsiviser;
