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

end
end
