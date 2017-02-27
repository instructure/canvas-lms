define([], () => {
  const DOMElement = (props, propName, componentName) => {
    if (props[propName] && props[propName] instanceof Element === false) {
      return new Error(
      `Invalid prop \`${propName}\` supplied to` +
      ` \`${componentName}\`. Expected a DOMElement.`
    );
    }
    return null;
  }

  return DOMElement;
})
