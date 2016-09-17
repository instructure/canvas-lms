// Adapted from https://github.com/react-bootstrap/react-prop-types/blob/master/src/isRequiredForA11y.js
export function a11yFunction(props, propName, componentName) {
  if ((!props[propName]) || (typeof props[propName] !== 'function')) {
    return new Error(
      `The prop '${propName}' is required to make '${componentName}' fully accessible. ` +
      `This will greatly improve the experience for users of assistive technologies. ` +
      `You should provide a function that returns a DOM node.`
    );
  }
}
