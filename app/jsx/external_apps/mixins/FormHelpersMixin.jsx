/** @jsx React.DOM */

define([
  'underscore',
  'old_unsupported_dont_use_react'
], function(_, React) {

  function $c(staticClassName, conditionalClassNames) {
    var classNames = [];
    if (typeof conditionalClassNames == 'undefined') {
      conditionalClassNames = staticClassName;
    } else {
      classNames.push(staticClassName);
    }
    for (var className in conditionalClassNames) {
      if (!!conditionalClassNames[className]) {
        classNames.push(className);
      }
    }
    return classNames.join(' ');
  }

  return {
    renderTextInput(id, defaultValue, label, hintText, required) {
      return this.renderField(id, label,
        <input type="text" defaultValue={defaultValue}
                className="form-control input-block-level"
                placeholder={label}
                ref={id}
                required={required ? "required" : null} />
      , hintText)
    },

    renderTextarea(id, defaultValue, label, hintText, rows, required) {
      return this.renderField(id, label,
        <textarea rows={rows || 3} defaultValue={defaultValue}
                  className="form-control input-block-level"
                  placeholder={label} id={id} ref={id}
                  required={required ? "required" : null} />
        , hintText);
    },

    renderSelect(id, defaultValue, label, values, hintText, required) {
      var options = _.map(values, function(v, k) {
        return <option value={k}>{v}</option>
      });
      return this.renderField(id, label,
        <select className="form-control input-block-level"
                ref={id}
                selected={defaultValue}
                required={required ? "required" : null}>
        {options}
        </select>
      , hintText)
    },

    renderRadioInlines(id, label, kwargs, hintText) {
      var radios = kwargs.values.map(function(value) {
        var defaultChecked = (value == kwargs.defaultCheckedValue);
        return (
          <label className="radio-inline">
            <input type="radio" ref={id + value} name={id} value={value} defaultChecked={defaultChecked}/>
            {value}
          </label>
        );
      });
      return this.renderField(id, label, radios, hintText);
    },

    renderField(id, label, field, hintText) {
      if (this.state.errors[id]) {
        hintText = this.state.errors[id];
      }
      var hint = hintText ? <span className="hint-text">{hintText}</span> : '';
      return <div className={$c('control-group', {'error': id in this.state.errors})}>
        <label>
          {label}
          {field}
          {hint}
        </label>
      </div>
    }
  };
});