define ([], () => {

  const Actions = {
    setModalVisibility (showModal) {
      return {
        type: 'MODAL_VISIBILITY',
        payload: {
          showModal
        }
      };
    }
  };

  return Actions;
});