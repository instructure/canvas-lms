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
    }
  };

  return Helpers;

});