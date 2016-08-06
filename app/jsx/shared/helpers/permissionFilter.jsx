define([

], () => {

  function permissionFilter(items, perms) {
    return items.filter(item => {
      let keep = true;

      if (item.permissions && item.permissions.length) {
        keep = item.permissions.reduce((prevPerm, curPerm) => {
          return prevPerm && perms[curPerm];
        }, keep);
      }

      return keep;
    });
  };

  return permissionFilter;
});
