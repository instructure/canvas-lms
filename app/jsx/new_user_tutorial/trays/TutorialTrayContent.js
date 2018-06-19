/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Image from '@instructure/ui-core/lib/components/Image'
import SVGWrapper from '../../shared/SVGWrapper'

const TutorialTrayContent = props => (
  <div className={props.name}>
    <Heading level="h2" as="h2" ellipsis>{props.heading}</Heading>
    <div className="NewUserTutorialTray__Subheading">
      <Heading level="h3" as="h3">{props.subheading}</Heading>
    </div>
    {props.children}
    {
      props.image
      ? <div className="NewUserTutorialTray__ImageContainer" aria-hidden="true">
        {/\.svg$/.test(props.image)
        ? <SVGWrapper url={props.image} />
        : <Image src={props.image} />}
      </div>
      : null
    }
  </div>
)

TutorialTrayContent.propTypes = {
  name: PropTypes.string.isRequired,
  heading: PropTypes.string.isRequired,
  subheading: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.node),
    PropTypes.node
  ]),
  image: PropTypes.string
};
TutorialTrayContent.defaultProps = {
  children: [],
  image: null,
  name: ''
}

export default TutorialTrayContent
