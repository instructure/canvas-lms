define([], () => {

  /**
  * This utilty function will take a jQuery node and a module id then
  * mutate the $module node to put the appropriate ids in the related
  * module's content elements.
  */
  const setupContentIds = ($module, id) => {
    const newVal = `context_module_content_${id}`;
    $module.find('#context_module_content_').attr('id', newVal);
    $module.find('[aria-controls="context_module_content_"]').attr('aria-controls', newVal);
  };

  return setupContentIds;
});
