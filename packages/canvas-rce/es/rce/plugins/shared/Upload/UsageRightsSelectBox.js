import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";
import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React from 'react';
import PropTypes from 'prop-types';
import formatMessage from "../../../../format-message.js";
import { SimpleSelect } from '@instructure/ui-simple-select';
import { View } from '@instructure/ui-view';
import { TextInput } from '@instructure/ui-text-input';
const CONTENT_OPTIONS = [{
  display: formatMessage('Choose usage rights...'),
  value: 'choose'
}, {
  display: formatMessage('I hold the copyright'),
  value: 'own_copyright'
}, {
  display: formatMessage('I have obtained permission to use this file.'),
  value: 'used_by_permission'
}, {
  display: formatMessage('The material is in the public domain'),
  value: 'public_domain'
}, {
  display: formatMessage('The material is subject to an exception - e.g. fair use, the right to quote, or others under applicable copyright laws'),
  value: 'fair_use'
}, {
  display: formatMessage('The material is licensed under Creative Commons'),
  value: 'creative_commons'
}];

const ShowCreativeCommonsOptions = ({
  ccLicense,
  setCCLicense,
  licenseOptions
}) => {
  const onlyCC = licenseOptions.filter(license => license.id.indexOf('cc') === 0);
  return /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "medium 0"
  }, /*#__PURE__*/React.createElement(SimpleSelect, {
    renderLabel: formatMessage('Creative Commons License:'),
    assistiveText: formatMessage('Use arrow keys to navigate options.'),
    value: ccLicense,
    onChange: (e, {
      id
    }) => setCCLicense(id)
  }, onlyCC.map(license => /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    key: license.id,
    id: license.id,
    value: license.id
  }, license.name))));
};

const ShowMessage = () => {
  return /*#__PURE__*/React.createElement("div", {
    className: "alert"
  }, /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("i", {
    className: "icon-warning"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      paddingLeft: '10px'
    }
  }, formatMessage("If you do not select usage rights now, this file will be unpublished after it's uploaded."))));
};

const UsageRightsSelectBox = ({
  contextType,
  contextId,
  showMessage: showMessageProp,
  usageRightsState,
  setUsageRightsState
}) => {
  const usageRight = usageRightsState.usageRight,
        ccLicense = usageRightsState.ccLicense,
        copyrightHolder = usageRightsState.copyrightHolder;

  const _React$useState = React.useState([]),
        _React$useState2 = _slicedToArray(_React$useState, 2),
        licenseOptions = _React$useState2[0],
        setLicenseOptions = _React$useState2[1];

  const _React$useState3 = React.useState(showMessageProp),
        _React$useState4 = _slicedToArray(_React$useState3, 2),
        showMessage = _React$useState4[0],
        setShowMessage = _React$useState4[1];

  React.useEffect(() => {
    function apiUrl() {
      const context = contextType.replace(/([^s])$/, '$1s'); // pluralize

      return `/api/v1/${context}/${contextId}/content_licenses`;
    }

    (function () {
      fetch(apiUrl()).then(res => res.text()).then(res => setLicenseOptions(JSON.parse(res))).catch(() => {});
    })();
  }, [contextType, contextId]);

  function handleChange(value) {
    setUsageRightsState(state => _objectSpread(_objectSpread({}, state), {}, {
      usageRight: value
    }));
    setShowMessage(showMessageProp && value === 'choose');
  }

  return /*#__PURE__*/React.createElement(View, {
    as: "div"
  }, /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "medium 0"
  }, /*#__PURE__*/React.createElement(SimpleSelect, {
    renderLabel: formatMessage('Usage Right:'),
    assistiveText: formatMessage('Use arrow keys to navigate options.'),
    onChange: (e, {
      id
    }) => {
      handleChange(id);
    },
    value: usageRight
  }, CONTENT_OPTIONS.map(contentOption => /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    key: contentOption.value,
    id: contentOption.value,
    value: contentOption.value
  }, contentOption.display)))), usageRight === 'creative_commons' && /*#__PURE__*/React.createElement(ShowCreativeCommonsOptions, {
    ccLicese: ccLicense,
    setCCLicense: license => setUsageRightsState(state => _objectSpread(_objectSpread({}, state), {}, {
      ccLicense: license
    })),
    licenseOptions: licenseOptions
  }), /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "medium 0"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: formatMessage('Copyright Holder:'),
    value: copyrightHolder,
    onChange: (e, value) => setUsageRightsState(state => _objectSpread(_objectSpread({}, state), {}, {
      copyrightHolder: value
    })),
    placeholder: formatMessage('(c) 2001 Acme Inc.')
  })), /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "medium 0"
  }, showMessage && /*#__PURE__*/React.createElement(ShowMessage, null)));
};

UsageRightsSelectBox.propTypes = {
  usageRightsState: PropTypes.shape({
    ccLicense: PropTypes.string,
    usageRight: PropTypes.oneOf(Object.values(CONTENT_OPTIONS).map(o => o.value)),
    copyrightHolder: PropTypes.string
  }),
  setUsageRightsState: PropTypes.func,
  showMessage: PropTypes.bool,
  contextType: PropTypes.string,
  contextId: PropTypes.oneOfType([PropTypes.string, PropTypes.number])
};
export default UsageRightsSelectBox;