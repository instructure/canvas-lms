define([
  'jquery'
], function ($) {
  /* This file contains code specific to weird edge cases that can be removed later. For instance, if you
   * are writing some weird code around something that is broken in Jaws, it can live here 
   */ 

  var codeToRemoveLater = {
    hideFileTreeFromPreviewInJaws () {
      $("aside ul[role='tree']").attr('role', 'presentation');
    },
    revertJawsChangesBackToNormal () {
      $("aside ul[role='presentation']").attr('role', 'tree');
    }
  }

  return codeToRemoveLater;
});
