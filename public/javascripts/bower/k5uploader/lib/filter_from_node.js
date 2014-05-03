define(['./file_filter', 'jquery'], function(FileFilter, $){
  return function(node) {
    node = $(node);
    return  new FileFilter({
      id: node.attr('id'),
      description: node.attr('description'),
      entryType: node.attr('entryType'),
      mediaType: node.attr('mediaType'),
      type: node.attr('type'),
      extensions: node.attr('extensions')
    });
  }
});
