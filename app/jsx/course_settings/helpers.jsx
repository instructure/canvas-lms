define ([], () => {

  const Helpers = {
    isValidImageType (mimeType) {
      switch (mimeType) {
        case 'image/jpeg':
        case 'image/gif':
        case 'image/png':
          return true;
          break;
        default:
          return false;
          break;
      }
    },

    createFormData (uploadParams) {
      const formData = new FormData();
      Object.keys(uploadParams).forEach((key) => {
        formData.append(key, uploadParams[key]);
      });
      return formData;
    },

    extractInfoFromEvent (event) {
      let file = '';
      let type = '';
      if (event.type === 'change') {
        file = event.target.files[0];
        type = file.type;
      } else {
        type = event.dataTransfer.files[0].type;
        file = event.dataTransfer.files[0];
      }

      return {file, type};
    }
  };

  return Helpers;

});