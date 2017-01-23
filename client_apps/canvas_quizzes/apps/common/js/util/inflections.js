define(() => ({
  camelize (str, lowerFirst) {
    return (str || '').replace(/(?:^|[-_])(\w)/g, (_, c, index) => {
      if (index === 0 && lowerFirst) {
        return c ? c.toLowerCase() : '';
      }

      return c ? c.toUpperCase() : '';
    });
  },

  underscore (str) {
    return str.replace(/([A-Z])/g, $1 => `_${$1.toLowerCase()}`);
  }
}));
