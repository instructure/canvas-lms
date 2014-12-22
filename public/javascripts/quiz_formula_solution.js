/**
 * Copyright (C) 2014 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
define([], function(){

  function QuizFormulaSolution(result){
    this.result = result;
  }

  QuizFormulaSolution.prototype.rawValue = function(){
    return parseFloat(this.rawText(), 10);
  };

  QuizFormulaSolution.prototype.rawText = function(){
    if(this.result === null || this.result === undefined){
      return "NaN";
    }
    return this.result.substring(1).trim();
  };

  QuizFormulaSolution.prototype.isValid = function(){
    return !!(this._wellFormedString() && this._appropriateSolutionValue())
  };

  //private
  QuizFormulaSolution.prototype._wellFormedString = function(){
    var result = this.result;
    return !!(result.match(/^=/) && result != "= NaN" && result != "= Infinity")
  };

  QuizFormulaSolution.prototype._appropriateSolutionValue = function(){
    rawVal = this.rawValue();
    return !!(rawVal == 0 || rawVal);
  };

  return QuizFormulaSolution;

})
