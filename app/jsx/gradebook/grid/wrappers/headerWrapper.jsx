/** @jsx React.DOM */
define([
  'react',
  '../components/column_types/headerRenderer'
], function(React, HeaderRenderer) {

  var getHeader = function(label, cellDataKey, columnData, _, width) {
    return (
      <HeaderRenderer key={cellDataKey + '_header'} label={label}
        columnData={columnData} width={width}/>
    );
  };

  return { getHeader: getHeader };
})
