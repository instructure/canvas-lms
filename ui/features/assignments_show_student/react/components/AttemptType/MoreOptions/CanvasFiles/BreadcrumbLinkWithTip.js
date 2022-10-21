/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {omitProps} from '@instructure/ui-react-utils'
import {Tooltip} from '@instructure/ui-tooltip'

class BreadcrumbLinkWithTip extends Breadcrumb.Link {
  renderLink = () => {
    const {children, href, icon, iconPlacement, onClick} = this.props
    // eslint-disable-next-line react/forbid-foreign-prop-types
    const props = omitProps(this.props, Breadcrumb.Link.propTypes)

    return (
      <Link
        as={this.element}
        {...props}
        href={href}
        icon={icon}
        iconPlacement={iconPlacement}
        onClick={onClick}
      >
        <TruncateText>{children}</TruncateText>
      </Link>
    )
  }

  render() {
    const {onClick} = this.props
    // eslint-disable-next-line react/forbid-foreign-prop-types
    const props = omitProps(this.props, Breadcrumb.Link.propTypes)

    return (
      <Tooltip color="primary" as="div" renderTip={props.tip}>
        {onClick ? this.renderLink() : <Text>{this.renderLink()}</Text>}
      </Tooltip>
    )
  }
}

export default BreadcrumbLinkWithTip
