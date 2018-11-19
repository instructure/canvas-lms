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
  mediaQueries = {}

  // initialize the mediaQueryList with our media-query of interest
  setup () {
    if (!window.matchMedia) return; // or unit tests fail
    // Note: specifying max-widths in ems so planner will adjust its layout
    // even if the browser window is physicallly wide, but the font-size is
    // enlarged. This will make for a better experience.
    this.mediaQueries.small = window.matchMedia('(max-width: 37em)');   // == 592px
    this.mediaQueries.medium = window.matchMedia('(max-width: 56em)');  // == 896px
    if (this.mediaQueries.small.matches) {
      this.size = 'small';
    } else if ( this.mediaQueries.medium.matches) {
      this.size = 'medium';
    } else {
      this.size = 'large';
    }

    // some browsers support mediaQueryList.onchange. Use it if we can
    if ('onchange' in this.mediaQueries.medium) {
      this.mediaQueries.medium.onchange = this.onChangeLayout;
      this.mediaQueries.small.onchange = this.onChangeLayout;

    } else {
      // add a window.resize event handler. When the user stops
      // resizing for 100ms, check the state of the mediaQueryList's
      // match state.
      this.handleResize = () => {
        window.clearTimeout(this.resizeTimer);
        this.resizeTimer = window.setTimeout(() => {
          this.resizeTimer = 0;
          this.onChangeSize();
        }, 100);
      };
      window.addEventListener('resize', this.handleResize);
    }
  }
  teardown () {
    if ('onchange' in this.mediaQueries.medium) {
      this.mediaQueries.medium.onchange = null;
      this.mediaQueries.small.onchange = null;
    } else {
      window.clearTimeout(this.resizeTimer);
      window.removeEventListener('resize', this.handleResize);
    }
  }
  // add a component that's interested in being notified when the media-query
  // match state changes
  add (interestedParty) {
    if (!this.mediaQueries.medium) {
      this.setup();
    }
    this.interestedParties.push(interestedParty);
    return this.size;
  }
  // remove a component that's no longer interested
  remove (interestedParty) {
    const i = this.interestedParties.indexOf(interestedParty);
    this.interestedParties.splice(i, 1);
    if (this.mediaQueries.medium && this.interestedParties.length === 0) {
      this.teardown();
      this.mediaQueries.medium = null;
    }
  }
  // tell everyone that's interested something has changed
  notifyAll () {
    this.interestedParties.forEach((g) => {
      g.onChangeSize({size: this.size});
    });
  }
  // we just noticed a change in media-query match state
  onChangeLayout = (event) => {
    let newSize = 'large';
    if (event.target === this.mediaQueries.small) {
      newSize = event.matches ? 'small' : 'medium';
    } else if (event.target === this.mediaQueries.medium) {
      newSize = event.matches ? 'medium' : 'large';
    }
    if (newSize !== this.size) {
      this.size = newSize;
      this.notifyAll();
    }
  }
  // the window was resized, check the media-query match states
  onChangeSize () {
    let newSize = 'large';
    if (this.mediaQueries.small.matches) {
      newSize = 'small';
    } else if (this.mediaQueries.medium.matches) {
      newSize = 'medium';
    }
    if (newSize !== this.size) {
      this.size = newSize;
      this.notifyAll();
    }
  }
}

// take any react component have it respond to media query state
// e.g.  const ResponsiveFoo = responsiviser()(Foo)
// The media query is currently hard-coded to deal with small v. medium v. large
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
    ResponsiveComponent.displayName = `Responsive${ComposedComponent.displayName}`;
    return ResponsiveComponent;
  };
}
responsiviser.mqwatcher = new MediaQueryWatcher();  // create the one and only one (for now)


export default responsiviser;
