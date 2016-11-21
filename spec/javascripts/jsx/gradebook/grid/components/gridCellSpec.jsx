define([
  'react',
  'react-dom',
  'jsx/gradebook/grid/components/gridCell',
  'jsx/gradebook/grid/components/column_types/assignmentPoints'
], (React, ReactDOM, GridCell, AssignmentPointsColumn) => {
  const wrapper = document.getElementById('fixtures');

  const buildComponent = (props = {}) => {
    const defaultProps = {
      renderer: AssignmentPointsColumn,
      columnData: {
        columnType: 'points',
        assignment: {
          point_possible: 10
        }
      },
      rowData: {},
      activeCell: -1,
      cellIndex: -1
    };
    const deep = true;
    $.extend(deep, props, defaultProps);
    const componentFactory = React.createFactory(GridCell);
    return ReactDOM.render(componentFactory(props), wrapper);
  };

  test('mounts', () => {
    ok(buildComponent().isMounted());
  });

  test('isConcluded false', () => {
    const gridCell = buildComponent({rowData: {isConcluded: false}});
    notOk(gridCell.isConcluded());
  });

  test('isConcluded true', () => {
    const gridCell = buildComponent({rowData: {isConcluded: true}});
    ok(gridCell.isConcluded());
  });

  test('isInactive false', () => {
    const gridCell = buildComponent({rowData: {isInactive: false}});
    notOk(gridCell.isInactive());
  });

  test('isInactive true', () => {
    const gridCell = buildComponent({rowData: {isInactive: true}});
    ok(gridCell.isInactive());
  });

  module('getClassName');

  test('adds grayed-out when inactive or concluded', () => {
    const gridCell = buildComponent({rowData: {isConcluded: true}});
    const classNames = gridCell.getClassName();
    notEqual(classNames.indexOf("grayed-out"), -1);
  });

  test('adds grayed-out when inactive or concluded', () => {
    const gridCell = buildComponent({rowData: {isInactive: true}});
    const classNames = gridCell.getClassName();
    notEqual(classNames.indexOf("grayed-out"), -1);
  });

  test('does not add grayed-out when not inactive or concluded', () => {
    const gridCell = buildComponent();
    const classNames = gridCell.getClassName();
    equal(classNames.indexOf("grayed-out"), -1);
  });
});
