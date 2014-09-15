module Qti
class AssessmentItemConverter
  include Canvas::Migration::XMLHelper
  DEFAULT_CORRECT_WEIGHT = 100
  DEFAULT_INCORRECT_WEIGHT = 0
  DEFAULT_POINTS_POSSIBLE = 1
  UNSUPPORTED_TYPES = ['File Upload', 'Hot Spot', 'Quiz Bowl', 'WCT_JumbledSentence']
  WEBCT_REL_REGEX = "/webct/RelativeResourceManager/Template/"

  attr_reader :base_dir, :identifier, :href, :interaction_type, :title, :question

  def initialize(opts)
    @log = Canvas::Migration::logger
    reset_local_ids
    @manifest_node = opts[:manifest_node]
    @migration_type = opts[:interaction_type]
    @doc = nil
    @flavor = opts[:flavor]
    @opts = opts
    if @path_map = opts[:file_path_map]
      @sorted_paths = opts[:sorted_file_paths]
      @sorted_paths ||= @path_map.keys.sort_by { |v| v.length }
    end
    
    if @manifest_node
      @base_dir = opts[:base_dir]
      @identifier = @manifest_node['identifier']
      @href = File.join(@base_dir, @manifest_node['href'])
      if title = @manifest_node.at_css('title langstring') || title = @manifest_node.at_css('xmlns|title xmlns|langstring', 'xmlns' => Qti::Converter::IMS_MD)
        @title = title.text
      end
    else
      @qti_data = opts[:qti_data]
    end

    @question = {:answers=>[],
                 :correct_comments=>"",
                 :incorrect_comments=>"",
                 :points_possible=>AssessmentItemConverter::DEFAULT_POINTS_POSSIBLE,
                 :question_text=>""}
  end

  #This should be implemented in the children classes to do the type-specific parsing
  def parse_question_data
    @log.error "No question type used..."
    raise "No question type used when trying to parse a qti question"
  end

  def create_doc
    create_xml_doc
  end

  def create_xml_doc
    if @manifest_node
      @doc = Nokogiri::XML(open(@href))
    else
      @doc = Nokogiri::XML(@qti_data)
    end
  end

  EXCLUDED_QUESTION_TEXT_CLASSES = ["RESPONSE_BLOCK", "RIGHT_MATCH_BLOCK"]

  def create_instructure_question
    begin
      create_doc
      @question[:question_name] = @title || get_node_att(@doc, 'assessmentItem', 'title')
      # The colons are replaced with dashes in the conversion from QTI 1.2
      @question[:migration_id] = get_node_att(@doc, 'assessmentItem', 'identifier')
      @question[:migration_id] = @question[:migration_id].gsub(/:/, '-').gsub('identifier=', '') if @question[:migration_id]

      if @flavor == Qti::Flavors::D2L
        # In D2L-generated QTI the assessments reference the items by the label instead of the identifier
        # also, the identifier is not always unique, so we use the label as the migration id
        @question[:migration_id] = get_node_att(@doc, 'assessmentItem', 'label')
      end

      if @type == 'text_entry_interaction'
        @doc.css('textEntryInteraction').each do |node|
          node.inner_html = "[#{node['responseIdentifier']}]"
        end
      end

      parse_instructure_metadata

      selectors = ['itemBody > div', 'itemBody > p']
      type = @opts[:custom_type] || @migration_type || @type
      unless ['fill_in_multiple_blanks_question', 'canvas_matching', 'matching_question',
              'multiple_dropdowns_question', 'respondus_matching'].include?(type)
        selectors << 'itemBody > choiceInteraction > prompt'
      end

      text_nodes = @doc.css(selectors.join(','))
      text_nodes = text_nodes.reject{|node| node.inner_html.strip.empty? ||
        EXCLUDED_QUESTION_TEXT_CLASSES.any?{|c| c.casecmp(node['class'].to_s) == 0}}

      if text_nodes.length > 0
        @question[:question_text] = ''
        text_nodes.each_with_index do |node, i|
          @question[:question_text] += "\n<br/>\n" if i > 0
          if ['html', 'text'].include?(node['class'])
            @question[:question_text] += sanitize_html_string(node.text)
          else
            @question[:question_text] += sanitize_html!(node)
          end
        end
      elsif text = @doc.at_css('itemBody div:first-child') || @doc.at_css('itemBody p:first-child') || @doc.at_css('itemBody div') || @doc.at_css('itemBody p')
        @question[:question_text] = sanitize_html!(text)
      elsif @doc.at_css('itemBody')
        if text = @doc.at_css('itemBody').children.find{|c|c.text.strip != ''}
          @question[:question_text] = sanitize_html_string(text.text)
        end
      end

      if @migration_type and UNSUPPORTED_TYPES.member?(@migration_type)
        @question[:question_type] = @migration_type
        @question[:unsupported] = true
      elsif !%w(text_only_question file_upload_question).include?(@migration_type)
        self.parse_question_data
      else
        @question[:question_type] ||= @migration_type
      end
    rescue => e
      message = "There was an error exporting an assessment question"
      @question[:qti_error] = "#{message} - #{e.to_s}"
      @question[:question_type] = "Error"
      @log.error "#{e.to_s}: #{e.backtrace}"
    end
    
    @question
  end

  QUESTION_TYPE_MAPPING = {
    /matching/i => 'matching_question',
    'textInformation' => 'text_only_question',
    'trueFalse' => 'true_false_question',
    'multiple_dropdowns' => 'multiple_dropdowns_question'
  }
  
  def parse_instructure_metadata
    if meta = @doc.at_css('instructureMetadata')
      if bank =  get_node_att(meta, 'instructureField[name=question_bank]',  'value')
        @question[:question_bank_name] = bank
      end
      if bank =  get_node_att(meta, 'instructureField[name=question_bank_iden]', 'value')
        @question[:question_bank_id] = bank
      end
      if score =  get_node_att(meta, 'instructureField[name=max_score]', 'value')
        @question[:points_possible] = score.to_f
      end
      if score = get_node_att(meta, 'instructureField[name=points_possible]', 'value')
        @question[:points_possible] = score.to_f
      end
      if ref = get_node_att(meta, 'instructureField[name=assessment_question_identifierref]', 'value')
        @question[:assessment_question_migration_id] = ref
      end
      if type =  get_node_att(meta, 'instructureField[name=bb_question_type]', 'value')
        @migration_type = type
        case @migration_type
          when 'True/False'
            @question[:question_type] = 'true_false_question'
          when 'Short Response'
            @question[:question_type] = 'essay_question'
          when 'Fill in the Blank Plus'
            @question[:question_type] = 'fill_in_multiple_blanks_question'
          when 'WCT_FillInTheBlank'
            @question[:question_type] = 'fill_in_multiple_blanks_question'
            @question[:is_vista_fib] = true
          when 'WCT_ShortAnswer'
            if @doc.css("responseDeclaration[baseType=\"string\"]").count > 1
              @question[:question_type] = 'fill_in_multiple_blanks_question'
              @question[:is_vista_fib] = true
            end
          when 'Jumbled Sentence'
            @question[:question_type] = 'multiple_dropdowns_question'
          when 'Essay'
            @question[:question_type] = 'essay_question'
        end
      elsif type =  get_node_att(meta, 'instructureField[name=question_type]', 'value')
        @migration_type = type
        QUESTION_TYPE_MAPPING.each do |k,v|
          @migration_type = v if k === @migration_type
        end
        if AssessmentQuestion::ALL_QUESTION_TYPES.member?(@migration_type)
          @question[:question_type] = @migration_type
        end
      end
    end
  end

  def unique_local_id
    @@ids ||= {}
    id = rand(100_000)
    while @@ids[id]
      id = rand(100_000)
    end
    @@ids[id] = true
    id
  end

  def reset_local_ids
    @@ids = {}
  end

  def get_feedback
    @doc.search('modalFeedback[outcomeIdentifier=FEEDBACK]').each do |f|
      id = f['identifier']
      if id =~ /wrong|incorrect|(_IC$)/i
        extract_feedback!(@question, :incorrect_comments, f)
      elsif id =~ /correct|(_C$)/i
        if f.at_css('div.solution')
          @question[:example_solution] = clear_html(f.text.strip.gsub(/\s+/, " "))
        else
          extract_feedback!(@question, :correct_comments, f)
        end
      elsif id =~ /solution/i
        @question[:example_solution] = clear_html(f.text.strip.gsub(/\s+/, " "))
      elsif id =~ /general|all/i
        extract_feedback!(@question, :neutral_comments, f)
      elsif id =~ /feedback_(\d*)_fb/i
        if answer = @question[:answers].find{|a|a[:migration_id]== "RESPONSE_#{$1}"}
          extract_feedback!(answer, :comments, f)
        end
      end
    end
  end

  # returns a tuple of [text, html]
  # html is null if it's not an html blob
  def detect_html(node)
    text = clear_html(node.text.gsub(/\s+/, " ")).strip
    html_node = node.at_css('div.html') || (node.name.downcase == 'div' && node['class'] =~ /\bhtml\b/)
    is_html = false
    # heuristic for detecting html: the sanitized html node is more than just a container for a single text node
    sanitized = sanitize_html!(html_node ? Nokogiri::HTML::DocumentFragment.parse(node.text) : node, true) { |s| is_html = !(s.children.size == 1 && s.children.first.is_a?(Nokogiri::XML::Text)) }
    if is_html && sanitized.present?
      html = sanitized
    end
    [text, html]
  end

  def extract_feedback!(hash, field, node)
    text, html = detect_html(node)
    hash[field] = text
    if html
      hash["#{field}_html".to_sym] = html
    end
  end

  def clear_html(text)
    text.gsub(/<\/?[^>\n]*>/, "").gsub(/&#\d+;/) {|m| m[2..-1].to_i.chr(text.encoding) rescue '' }.gsub(/&\w+;/, "").gsub(/(?:\\r\\n)+/, "\n")
  end

  # try to escape unmatched '<' and '>' characters because some people don't format their QTI correctly...
  def escape_unmatched_brackets(string)
    string.split(/(\<[^\<\>]*\>)/).map do |sub|
      if sub.start_with?("<") && sub.end_with?(">")
        sub
      else
        sub.gsub("<", "&lt;").gsub(">", "&gt;")
      end
    end.join
  end

  def sanitize_html_string(string, remove_extraneous_nodes=false)
    string = escape_unmatched_brackets(string)
    sanitize_html!(Nokogiri::HTML::DocumentFragment.parse(string), remove_extraneous_nodes)
  end

  def find_best_path_match(path)
    @path_map[path] || @path_map[@sorted_paths.find{|k| k.end_with?(path)}]
  end

  def sanitize_html!(node, remove_extraneous_nodes=false)
    # root may not be an html element, so we just sanitize its children so we
    # don't blow away the whole thing
    node.children.each do |child|
      Sanitize.clean_node!(child, CanvasSanitize::SANITIZE)
    end

    # replace any file references with the migration id of the file
    if @path_map
      attrs = ['rel', 'href', 'src', 'data', 'value']
      node.search("*").each do |subnode|
        attrs.each do |attr|
          if subnode[attr]
            val = URI.unescape(subnode[attr])
            if val.start_with?(WEBCT_REL_REGEX)
              # It's from a webct package so the references may not be correct
              # Take a path like: /webct/RelativeResourceManager/Template/Imported_Resources/qti web/f11g3_r.jpg
              # Reduce to: Imported_Resources/qti web/f11g3_r.jpg
              val.gsub!(WEBCT_REL_REGEX, '')
              val.gsub!("RelativeResourceManager/Template/", "")

              # Sometimes that path exists, sometimes the desired file is just in the top-level with the .xml files
              # So check for the file starting with the full relative path, going down to just the file name
              paths = val.split("/")
              paths.length.times do |i|
                if mig_id = find_best_path_match(paths[i..-1].join('/'))
                  subnode[attr] = "#{CC::CCHelper::OBJECT_TOKEN}/attachments/#{mig_id}"
                  break
                end
              end
            else
              val.gsub!(/\$[A-Z_]*\$/, '') # remove any path tokens like $TOKEN_EH$
              # try to find the file by exact path match. If not found, try to find best match
              if mig_id = find_best_path_match(val)
                subnode[attr] = "#{CC::CCHelper::OBJECT_TOKEN}/attachments/#{mig_id}"
              end
            end
          end
        end
      end
    end

    if remove_extraneous_nodes
      while true
        node.children.each do |child|
          break unless child.text? && child.text =~ /\A\s+\z/ || child.element? && child.name.downcase == 'br'
          child.remove
        end
  
        node.children.reverse.each do |child|
          break unless child.text? && child.text =~ /\A\s+\z/ || child.element? && child.name.downcase == 'br'
          child.remove
        end
        break unless node.children.size == 1 && ['p', 'div', 'span'].include?(node.child.name)
        break if !node.child.attributes.empty? && !has_known_meta_class(node.child)

        node = node.child
      end
    end
    yield node if block_given?

    text = node.inner_html.strip
    # Clear WebCT-specific relative paths
    text.gsub!(WEBCT_REL_REGEX, '')
    text.gsub(%r{/?webct/urw/[^/]+/RelativeResourceManager\?contentID=(\d*)}, "$CANVAS_OBJECT_REFERENCE$/attachments/\\1")
  end

  KNOWN_META_CLASSES = ['FORMATTED_TEXT_BLOCK', 'flow_1']
  def has_known_meta_class(node)
    return false unless node.attributes['class']
    KNOWN_META_CLASSES.member?(node.attributes['class'].value)
  end
  
  def self.get_interaction_type(manifest_node)
    manifest_node.at_css('interactionType') || 
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_1_URL) || 
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_0_URL) || 
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_1_ITEM_URL) || 
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_0_ITEM_URL)
  end

  def self.create_instructure_question(opts)
    extend Canvas::Migration::XMLHelper
    q = nil
    manifest_node = opts[:manifest_node]

    if manifest_node
      if type = get_interaction_type(manifest_node)
        opts[:interaction_type] ||= type.text.downcase
      end
      if type = get_node_att(manifest_node,'instructureMetadata instructureField[name=bb_question_type]', 'value')
        opts[:custom_type] ||= type.downcase
      end
      if type = get_node_att(manifest_node,'instructureMetadata instructureField[name=question_type]', 'value')
        type = type.downcase
        opts[:custom_type] ||= type
        if type == 'matching_question'
          opts[:interaction_type] = 'choiceinteraction'
          opts[:custom_type] = 'canvas_matching'
        elsif type == 'matching'
          opts[:custom_type] = 'respondus_matching'
        elsif type =~ /fillInMultiple|fill_in_multiple_blanks_question|fill in the blanks/i
          opts[:interaction_type] = 'fill_in_multiple_blanks_question'
        elsif type == 'multiple_dropdowns_question'
          opts[:interaction_type] = 'multiple_dropdowns_question'
        else
          opts[:custom_type] = type
        end
      end
    end

    unless opts[:interaction_type]
      guesser = QuestionTypeEducatedGuesser.new(opts)
      opts[:interaction_type], opts[:custom_type] = guesser.educatedly_guess_type
    end

    case opts[:interaction_type]
      when /choiceinteraction|multiple_choice_question|multiple_answers_question|true_false_question|stupid_likert_scale_question/i
        if opts[:custom_type] and opts[:custom_type] == "matching"
          q = AssociateInteraction.new(opts)
        elsif opts[:custom_type] && opts[:custom_type] =~ /respondus_matching|canvas_matching/
          q = AssociateInteraction.new(opts)
        else
          q = ChoiceInteraction.new(opts)
        end
      when /associateinteraction|matching_question|matchinteraction/i
        q = AssociateInteraction.new(opts)
      when /extendedtextinteraction|textinteraction|essay_question|short_answer_question/i
        if opts[:custom_type] and opts[:custom_type] =~ /calculated/i
          q = CalculatedInteraction.new(opts)
        elsif opts[:custom_type] and opts[:custom_type] =~ /numeric|numerical_question/
          q = NumericInteraction.new(opts)
        else
          q = ExtendedTextInteraction.new(opts)
        end
      when /orderinteraction|ordering_question/i
        q = OrderInteraction.new(opts)
      when /fill_in_multiple_blanks_question|multiple_dropdowns_question/i
        q = FillInTheBlank.new(opts)
      when /textentryinteraction/i
        q = FillInTheBlank.new(opts)
      when nil
        q = AssessmentItemConverter.new(opts)
      else
        Canvas::Migration::logger.warn "Unknown QTI question type: #{opts[:interaction_type]}"
        q = AssessmentItemConverter.new(opts)
    end

    q.create_instructure_question if q
  end
  
  # Sets the actual feedback values and clears the feedback ids
  def attach_feedback_values(answers)
    feedback_hash = {}
    @doc.search('modalFeedback[outcomeIdentifier=FEEDBACK]').each do |feedback|
      id = feedback['identifier']
      node = feedback.at_css('p') || feedback.at_css('div')
      feedback_hash[id] = node if node
    end
    
    #clear extra entries
    @question.delete :feedback_id
    answers.each do |answer|
      if feedback_hash.has_key? answer[:feedback_id]
        extract_feedback!(answer, :comments, feedback_hash[answer[:feedback_id]])
      end
      answer.delete :feedback_id
    end
  end

  # pulls the feedback id from the condition
  def get_feedback_id(cond)
    id = nil

    if feedback = cond.at_css('setOutcomeValue[identifier=FEEDBACK]')
      if feedback.at_css('variable[identifier=FEEDBACK]')
        if feedback = feedback.at_css('baseValue[baseType=identifier]')
          id = feedback.text.strip
        end
      end
    end
    # Sometimes individual answers are assigned general feedback, don't return
    # the identifier if that's the case
    id =~ /general|all|wrong|incorrect|correct|(_IC$)|(_C$)/i ? nil : id
  end

end
end
