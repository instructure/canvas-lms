import findTabbable from '../helpers/tabbable';

export default function(node, event) {
  const tabbable = findTabbable(node);
  const finalTabbable = tabbable[event.shiftKey ? 0 : tabbable.length - 1];
  const isLeavingNode = (
    finalTabbable === document.activeElement
  );
  return isLeavingNode;
}
