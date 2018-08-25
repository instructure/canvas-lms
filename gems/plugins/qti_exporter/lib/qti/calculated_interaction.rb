#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'cgi'
module Qti
class CalculatedInteraction < AssessmentItemConverter
  def initialize(opts)
    super(opts)
    @question[:answers] = []
    @question[:variables] = []
    @question[:question_type] = 'calculated_question'
  end

  def parse_question_data
    imported_formula = @doc.at_css('calculated formula')
    @question[:imported_formula] = CGI.unescape(imported_formula.text) if imported_formula
    get_calculated_property('answer_tolerance')
    if @question[:answer_tolerance] && !@question[:answer_tolerance].to_s.match(/[^\d\.]/)
      @question[:answer_tolerance] = @question[:answer_tolerance].to_f
    end

    get_calculated_property('unit_points_percent')
    @question[:unit_points_percent] = @question[:unit_points_percent].to_f if @question[:unit_points_percent]
    get_calculated_property('unit_value')
    get_calculated_property('unit_required', true)
    get_calculated_property('unit_case_sensitive', true)
    get_calculated_property('partial_credit_points_percent')
    @question[:partial_credit_points_percent] = @question[:partial_credit_points_percent].to_f if @question[:partial_credit_points_percent]
    get_calculated_property('partial_credit_tolerance')
    @question[:partial_credit_tolerance] = @question[:partial_credit_tolerance].to_f if @question[:partial_credit_tolerance]

    get_variables()
    get_answer_sets()
    get_feedback()
    get_formulas()

    if !@question[:answer_tolerance] && tolerance = get_node_att(@doc, 'instructureMetadata instructureField[name=formula_tolerance]', 'value')
      @question[:answer_tolerance] = tolerance
    end
    if !@question[:formula_decimal_places] && precision = get_node_att(@doc, 'instructureMetadata instructureField[name=formula_precision]', 'value')
      @question[:formula_decimal_places] = precision.to_i
    end

    apply_d2l_fixes if @flavor == Qti::Flavors::D2L

    if @question[:formulas]&.empty? && @question[:imported_formula]
      @question[:formulas] << {:formula => @question[:imported_formula]}
    end
    @question
  end

  def get_calculated_property(prop_name, is_true_false=false)
    @question[:"#{prop_name}"] = @doc.at_css("calculated #{prop_name}").text if @doc.at_css("calculated #{prop_name}")
    if is_true_false and @question[:"#{prop_name}"]
      @question[:"#{prop_name}"] = @question[:"#{prop_name}"] == 'true' ? true : false
    end
  end

  def get_variables
    @doc.css('calculated vars var').each do |v|
      var = {}
      @question[:variables] << var
      var[:name] = v['name']
      var[:scale] = v['scale'].to_i
      var[:min] = v.at_css('min').text.to_f if v.at_css('min')
      var[:max] = v.at_css('max').text.to_f if v.at_css('max')
    end
  end

  def get_answer_sets
    @doc.css('calculated var_sets var_set').each do |vs|
      set = {:variables=>[], :id=>unique_local_id, :weight=>100}
      @question[:answers] << set
      set[:answer] = vs.at_css('answer').text.to_f if vs.at_css('answer')

      vs.css('var').each do |v|
        var = {}
        set[:variables] << var
        var[:name] = v['name']
        var[:value] = v.text.to_f
      end
    end
  end

  def get_formulas
    @question[:formulas] = []
    if formulas_node = @doc.at_css('formulas')
      @question[:formula_decimal_places] = formulas_node['decimal_places'].to_i
      formulas_node.css('formula').each do |f_node|
        formula = {}
        formula[:formula] = f_node.text
        @question[:formulas] << formula
      end
    end
    @question[:formulas]
  end

  def apply_d2l_fixes
    @question[:variables].each do |v|
      v_name = v[:name]
      # substitute {var} for [var]
      @question[:question_text].gsub!("{#{v_name}}", "[#{v_name}]") if @question[:question_text]
      # substitute {var} for var
      @question[:imported_formula].gsub!("{#{v_name}}", "#{v_name}") if @question[:imported_formula]
    end
    if @question[:imported_formula]
      method_substitutions = {"sqr" => "sqrt", "Factorial" => "fact", "exp" => "e"}
      method_substitutions.each do |orig_method, new_method|
        @question[:imported_formula].gsub!("#{orig_method}(", "#{new_method}(")
      end
    end
    if @question[:variables].count == 1
      # is this secretly a simple numeric question in disguise
      var = @question[:variables].first
      if (var[:min] == var[:max]) && (@question[:imported_formula] == var[:name]) # yup the formula for the answer is "x" and there's only one possible value
        [:variables, :formulas, :imported_formula, :formula_decimal_places, :answer_tolerance].each{|k| @question.delete(k)}
        @question[:question_type] = 'numerical_question'
        @question[:answers] = [
          {:weight => 100, :id => unique_local_id, :text => 'answer_text',
            :numerical_answer_type => "exact_answer", :exact => var[:min]}
        ]
      end
    end
  end

end
end
