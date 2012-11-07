require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')

unless defined? BASE_FIXTURE_DIR
  BASE_FIXTURE_DIR = File.expand_path(File.dirname(__FILE__)) + '/fixtures/'
  CANVAS_FIXTURE_DIR = BASE_FIXTURE_DIR + 'canvas/'
  VISTA_FIXTURE_DIR = BASE_FIXTURE_DIR + 'bb_vista/'
  BB8_FIXTURE_DIR = BASE_FIXTURE_DIR + 'bb8/'
  BB9_FIXTURE_DIR = BASE_FIXTURE_DIR + 'bb9/'
  RESPONDUS_FIXTURE_DIR = BASE_FIXTURE_DIR + 'respondus/'
  ANGEL_FIXTURE_DIR = BASE_FIXTURE_DIR + 'angel/'
  CENGAGE_FIXTURE_DIR = BASE_FIXTURE_DIR + 'cengage/'
  D2L_FIXTURE_DIR = BASE_FIXTURE_DIR + 'd2l/'
  HTML_SANITIZATION_FIXTURE_DIR = BASE_FIXTURE_DIR + 'html_sanitization/'
end
require 'pp'

def get_question_hash(dir, name, delete_answer_ids=true, opts={})
  hash = get_quiz_data(dir, name, opts).first.first
  hash[:answers].each {|a|a.delete(:id)} if delete_answer_ids
  hash
end

def get_quiz_data(dir, name, opts={})
  File.open(File.join(dir, '%s.xml' % name), 'r') do |file|
    Qti.convert_xml(file.read, opts)
  end
end

def get_manifest_node(question, opts={})
  manifest_node = {'identifier'=>nil, 'href'=>"#{question}.xml"}
  manifest_node.stubs(:at_css).returns(nil)
  manifest_node.stubs(:at_css).with('instructureMetadata').returns(manifest_node)

  t = Object.new
  t.stubs(:text).returns(opts[:title])
  manifest_node.stubs(:at_css).with('title langstring').returns(t)

  s = {}
  s.stubs(:text).returns('237.0')
  s["value"] = '237.0'
  manifest_node.stubs(:at_css).with('instructureField[name=max_score]').returns(s)
  
  it = nil
  if opts[:interaction_type]
    it = Object.new
    it.stubs(:text).returns(opts[:interaction_type])
  end
  manifest_node.stubs(:at_css).with(('interactionType')).returns(it)
  
  bbqt = nil
  if opts[:bb_question_type]
    bbqt = {}
    bbqt.stubs(:text).returns(opts[:bb_question_type])
    bbqt["value"] = opts[:bb_question_type]
  end
  manifest_node.stubs(:at_css).with(('instructureMetadata instructureField[name=bb_question_type]')).returns(bbqt)

  qt = nil
  if opts[:question_type]
    qt = {}
    qt.stubs(:text).returns(opts[:question_type])
    qt["value"] = opts[:question_type]
  end
  manifest_node.stubs(:at_css).with(('instructureMetadata instructureField[name=question_type]')).returns(qt)
  
  bb8a = nil
  if opts[:quiz_type]
    bb8a = {}
    bb8a.stubs(:text).returns(opts[:quiz_type])
    bb8a["value"] = opts[:quiz_type]
  end
  manifest_node.stubs(:at_css).with(('instructureField[name=bb8_assessment_type]')).returns(bb8a)
  
  manifest_node
end

def file_as_string(*args)
  File.read File.join(args)
end

def vista_question_dir
  File.join(VISTA_FIXTURE_DIR, "questions")
end

def bb8_question_dir
  File.join(BB8_FIXTURE_DIR, "questions")
end

def bb9_question_dir
  File.join(BB9_FIXTURE_DIR, "questions")
end

def respondus_question_dir
  File.join(RESPONDUS_FIXTURE_DIR, "questions")
end

def angel_question_dir
  File.join(ANGEL_FIXTURE_DIR, "questions")
end

def cengage_question_dir
  File.join(CENGAGE_FIXTURE_DIR, "questions")
end

def d2l_question_dir
  D2L_FIXTURE_DIR
end

def html_sanitization_question_dir(type)
  File.join(HTML_SANITIZATION_FIXTURE_DIR, "questions", type)
end

