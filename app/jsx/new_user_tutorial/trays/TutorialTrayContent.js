import React from 'react'
import Heading from 'instructure-ui/lib/components/Heading'
import Image from 'instructure-ui/lib/components/Image'
import SVGWrapper from 'jsx/shared/SVGWrapper'

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
  name: React.PropTypes.string.isRequired,
  heading: React.PropTypes.string.isRequired,
  subheading: React.PropTypes.string.isRequired,
  children: React.PropTypes.oneOfType([
    React.PropTypes.arrayOf(React.PropTypes.node),
    React.PropTypes.node
  ]),
  image: React.PropTypes.string
};
TutorialTrayContent.defaultProps = {
  children: [],
  image: null,
  name: ''
}

export default TutorialTrayContent
