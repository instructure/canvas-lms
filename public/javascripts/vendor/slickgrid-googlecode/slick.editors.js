define(['jquery', 'vendor/jquery.template'], function($) {

window.requiredFieldValidator = function(value) {
  if (value == null || value == undefined || !$.trim(value+"").length)
    return {valid:false, msg:"This is a required field"};
  else
    return {valid:true, msg:null};
}


window.TextCellEditor = function($container, columnDef, value, dataContext) {
    var $input;
    var defaultValue = value;
    var scope = this;
    
    this.init = function() {
        $input = $("<INPUT type=text class='editor-text' />");
        
        if (value != null) 
        {
            $input[0].defaultValue = value;
            $input.val(defaultValue);
        }
        
        $input.appendTo($container);
        $input.focus().select();
    }
    
    this.destroy = function() {
        $input.remove();
    }
    
    this.focus = function() {
        $input.focus();
    }
    
    this.setValue = function(value) {
        $input.val(value);
        defaultValue = value;
    }
    
    this.getValue = function() {
        return $input.val();
    }
    
    this.isValueChanged = function() {
        return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
    }
    
    this.validate = function() {
        if (columnDef.validator) 
        {
            var validationResults = columnDef.validator(scope.getValue());
            if (!validationResults.valid) 
                return validationResults;
        }
        
        return {
            valid: true,
            msg: null
        };
    }
    
    this.init();
}

window.GradeCellEditor = function($container, columnDef, value, dataContext) {

  if (dataContext.active) {
    value = value || {};
    var $input;
    var defaultValue = value.grade;
    var scope = this;

    this.init = function() {
      switch(columnDef._uploaded.grading_type){
      
      case "letter_grade":
        var letterGrades = [
          { text: "--", value: ""},
          { text: "A",  value: "A"},
          { text: "A-", value: "A-"},
          { text: "B+", value: "B+"},
          { text: "B",  value: "B"},
          { text: "B-", value: "B-"},
          { text: "C+", value: "C+"},
          { text: "C-", value: "C-"},
          { text: "D+", value: "D+"},
          { text: "D",  value: "D"},
          { text: "D-", value: "D-"},
          { text: "F",  value: "F"}
        ];
        var outputString = "";
        $.each(letterGrades, function() {
          outputString += '<option value="' + this.value + '" ' + (this.value == value.grade ? "selected": "") + '>' + this.text + '</option>';
        });
        $input = $("<select>" + outputString + "</select>");
        break;
        
      default:
        $input = $("<INPUT type=text class='editor-text' />");
      }
      
      //if there is something typed in to the grade, 
      //can't do if (value.grade) because if they had a grade of 0 it would break.
      if (typeof(value.grade) != "undefined" && value.grade+"" != "" ) {
        $input[0].defaultValue = value.grade;
        $input.val(defaultValue);
      }

      $input.appendTo($container);
      $input.focus().select();

      var scores = {
        originalScore: value._original && value._original.grade || "--",
        uploadedScore: value._uploaded && value._uploaded.grade || "--"
      };


      var helperTemplate = '' + 
      '<div class="grade-helper-wrapper">' + 
        '<span class="ui-icon ui-icon-triangle-1-w"/>' + 
        '<div class="grade-helper-inner ui-widget-content ui-corner-all">' + 
        '  <table>' + 
            '<tr><th>Original Score</th><th>Uploaded Score</th></tr>' + 
            '<tr><td>#{originalScore}</td><td>#{uploadedScore}</td></tr>' + 
          '</table>' + 
        '</div> ' + 
      '</div>';
      $($.template(helperTemplate, scores)).appendTo($container);
    }

    this.destroy = function() {
      $input.remove();
    }

    this.focus = function() {
      $input.focus();
    }

    this.setValue = function(value) {
      $input.val(value.grade);
      defaultValue = value.grade;
    }

    this.getValue = function() {
      return $input.val();
    }

    this.isValueChanged = function() {
      return (! ($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
    }

    this.validate = function() {
      if (columnDef.validator) {
        var validationResults = columnDef.validator(scope.getValue());
        if (!validationResults.valid)
        return validationResults;
      }

      return {
        valid: true,
        msg: null
      };
    }

    this.init();
  }
  else {
    var $input;
    this.init = function() {
      var html = value ? value.grade: "";
      $container.removeClass("selected editable").html(html);
    }

    this.destroy = function() {}

    this.focus = function() {}

    this.setValue = function(value) {}

    this.getValue = function() {
      return value;
    }

    this.isValueChanged = function() {
      return false;
    }

    this.validate = function() {
      return {
        valid: true,
        msg: null
      };
    }

    this.init();
  }
}

window.StudentNameEditor = function($container, columnDef, value, dataContext) {
  var $input;
  this.init = function() {
    var html = value ? value.name: "";
    $container.removeClass("selected editable").html(html);
  }

  this.destroy = function() {}

  this.focus = function() {}

  this.setValue = function(value) {}

  this.getValue = function() {
    return value;
  }

  this.isValueChanged = function() {
    return false;
  }

  this.validate = function() {
    return {
      valid: true,
      msg: null
    };
  }

  this.init();
}

window.StudentNameFormatter = function(row, cell, value, columnDef, dataContext) {
  return value ? value.name : "";
};


window.NullEditor = function($container, columnDef, value, dataContext) {
    var $input;
    var defaultValue = value;
    var scope = this;
    
    this.init = function() {
      $container.removeClass("selected editable").html(value);
    }
    
    this.destroy = function() {

    }
    
    this.focus = function() {
        
    }
    
    this.setValue = function(value) {
       
    }
    
    this.getValue = function() {
        return value;
    }
    
    this.isValueChanged = function() {
        return false;
    }
    
    this.validate = function() {

        
        return {
            valid: true,
            msg: null
        };
    }
    
    this.init();
}

window.NullGradeEditor = function($container, columnDef, value, dataContext) {
    var $input;
    
    this.init = function() {
      var html = value ? value.grade : ""; 
      $container.removeClass("selected editable").html(html);
    }
    
    this.destroy = function() {}
    
    this.focus = function() {}
    
    this.setValue = function(value) {}
    
    this.getValue = function() {
        return value;
    }
    
    this.isValueChanged = function() {
        return false;
    }
    
    this.validate = function() {
        return {
            valid: true,
            msg: null
        };
    }
    
    this.init();
}

window.simpleGradeCellFormatter = function(row, cell, value, columnDef, dataContext) {
    return value ? value.grade : "";
};

window.PassFailCellFormatter = function(row, cell, value, columnDef, dataContext) {
  value = value || {};
  switch(value.grade){
  case "pass":
    return "<span class='pass_fail pass' />";
  case "fail":
    return "<span class='pass_fail fail' />";
  default:
    return ""; 
  }
};

window.PassFailSelectCellEditor = function($container, columnDef, value, dataContext) {
    value = value || {};
    var $select;
    var defaultValue = value;
    var scope = this;
    
    this.init = function() {
        $select = $("<SELECT tabIndex='0' class='editor-yesno'><OPTION value=''>---</OPTION><OPTION value='pass'>Pass</OPTION><OPTION value='fail'>Fail</OPTION></SELECT>");
        
        $select.val(defaultValue.grade);
        
        $select.appendTo($container);
        
        $select.focus();
        $select.change(function () {
          value.grade = $(this).val();
        });
                
        var helperTemplate = ''+
          '<div class="grade-helper-wrapper">' +
            '<span class="ui-icon ui-icon-triangle-1-w"/>' +
            '<div class="grade-helper-inner ui-widget-content ui-corner-all">' +
              '<table>' +
                '<tr><th>Original Score</th><th>Uploaded Score</th></tr>' +
                '<tr><td>#{originalScore}</td><td>#{uploadedScore}</td></tr>' +
              '</tbody></table>' +
            '</div> ' +
          '</div>';
        $($.template(helperTemplate, {originalScore:10, uploadedScore:15})).appendTo($container);
        
    }
    
    
    this.destroy = function() {
        $select.remove();
    }
    
    
    this.focus = function() {
        $select.focus();
    }
    
    this.setValue = function(value) {
        $select.val(value.grade);
        defaultValue = value;
    }
    
    this.getValue = function() {
        return (value);
    }
    
    this.isValueChanged = function() {
        return ($select.val() != defaultValue);
    }
    
    this.validate = function() {
        return {
            valid: true,
            msg: null
        };
    }
    
    this.init();
}
});
