define(['axios'], (axios) => {
  // Updates the positions of a given group of contexts asynchronously
  const updatePositions = (newPositions, userId, ajaxLib = axios) => {
    const request = {};
    request.dashboard_positions = {};
    newPositions.forEach((c, i) => {
      request.dashboard_positions[c.assetString] = i;
    });
    return ajaxLib.put(`/api/v1/users/${userId}/dashboard_positions`, request);
  };

  return {
    updatePositions
  };
});
