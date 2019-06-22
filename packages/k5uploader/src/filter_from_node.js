import FileFilter from "./file_filter";

export default function(node) {
  return  new FileFilter({
    id: node.getAttribute('id'),
    description: node.getAttribute('description'),
    entryType: node.getAttribute('entryType'),
    mediaType: node.getAttribute('mediaType'),
    type: node.getAttribute('type'),
    extensions: node.getAttribute('extensions')
  });
};
