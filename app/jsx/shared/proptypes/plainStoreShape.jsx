define(['react'], (React) => {
  const plainStoreShape = {
    getState: React.PropTypes.func,
    addChangeListener: React.PropTypes.func,
    removeChangeListener: React.PropTypes.func,
    setState: React.PropTypes.func
  };

  return plainStoreShape;
});
