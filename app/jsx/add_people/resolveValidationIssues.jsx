define([], () => {
  function resolveValidationIssues (duplicates, missings) {
    const usersToBeEnrolled = [];
    const usersToBeCreated = [];

    Object.keys(duplicates).forEach((addr) => {
      const dupeSet = duplicates[addr];
      if (dupeSet.createNew && dupeSet.newUserInfo.name && dupeSet.newUserInfo.email) {
        usersToBeCreated.push(dupeSet.newUserInfo);
      } else if (dupeSet.selectedUserId >= 0) {
        const selectedUser = dupeSet.userList.find(u => u.user_id === dupeSet.selectedUserId);
        usersToBeEnrolled.push(selectedUser);
      }
    });
    Object.keys(missings).forEach((addr) => {
      const missing = missings[addr];
      if (missing.createNew && missing.newUserInfo.name && missing.newUserInfo.email) {
        usersToBeCreated.push(missing.newUserInfo);
      }
    });

    return {usersToBeEnrolled, usersToBeCreated};
  }

  return resolveValidationIssues;
});
