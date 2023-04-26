# frozen_string_literal: true

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

unless defined? BASE_FIXTURE_DIR
  BASE_FIXTURE_DIR = __dir__ + "/fixtures/"
  CANVAS_FIXTURE_DIR = BASE_FIXTURE_DIR + "canvas/"
  VISTA_FIXTURE_DIR = BASE_FIXTURE_DIR + "bb_vista/"
  BB8_FIXTURE_DIR = BASE_FIXTURE_DIR + "bb8/"
  BB9_FIXTURE_DIR = BASE_FIXTURE_DIR + "bb9/"
  BBULTRA_FIXTURE_DIR = BASE_FIXTURE_DIR + "bbultra/"
  RESPONDUS_FIXTURE_DIR = BASE_FIXTURE_DIR + "respondus/"
  ANGEL_FIXTURE_DIR = BASE_FIXTURE_DIR + "angel/"
  CENGAGE_FIXTURE_DIR = BASE_FIXTURE_DIR + "cengage/"
  D2L_FIXTURE_DIR = BASE_FIXTURE_DIR + "d2l/"
  HTML_SANITIZATION_FIXTURE_DIR = BASE_FIXTURE_DIR + "html_sanitization/"
end

def get_question_hash(dir, name, delete_answer_ids: true, **opts)
  hash = get_quiz_data(dir, name, **opts).first.first
  hash[:answers].each { |a| a.delete(:id) } if delete_answer_ids
  hash
end

def get_quiz_data(dir, name, **opts)
  File.open(File.join(dir, "%s.xml" % name), "r") do |file|
    Qti.convert_xml(file.read, **opts)
  end
end

def get_manifest_node(question, opts = {})
  manifest_node = { "identifier" => nil, "href" => "#{question}.xml" }
  allow(manifest_node).to receive(:at_css).and_return(nil)
  allow(manifest_node).to receive(:at_css).with("instructureMetadata").and_return(manifest_node)

  t = Object.new
  allow(t).to receive(:text).and_return(opts[:title])
  allow(manifest_node).to receive(:at_css).with("title langstring").and_return(t)

  s = {}
  allow(s).to receive(:text).and_return("237.0")
  s["value"] = "237.0"
  allow(manifest_node).to receive(:at_css).with("instructureField[name=max_score]").and_return(s)

  it = nil
  if opts[:interaction_type]
    it = Object.new
    allow(it).to receive(:text).and_return(opts[:interaction_type])
  end
  allow(manifest_node).to receive(:at_css).with("interactionType").and_return(it)

  bbqt = nil
  if opts[:bb_question_type]
    bbqt = {}
    allow(bbqt).to receive(:text).and_return(opts[:bb_question_type])
    bbqt["value"] = opts[:bb_question_type]
  end
  allow(manifest_node).to receive(:at_css).with("instructureMetadata instructureField[name=bb_question_type]").and_return(bbqt)

  qt = nil
  if opts[:question_type]
    qt = {}
    allow(qt).to receive(:text).and_return(opts[:question_type])
    qt["value"] = opts[:question_type]
  end
  allow(manifest_node).to receive(:at_css).with("instructureMetadata instructureField[name=question_type]").and_return(qt)

  bb8a = nil
  if opts[:quiz_type]
    bb8a = {}
    allow(bb8a).to receive(:text).and_return(opts[:quiz_type])
    bb8a["value"] = opts[:quiz_type]
  end
  allow(manifest_node).to receive(:at_css).with("instructureField[name=bb8_assessment_type]").and_return(bb8a)

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

def bbultra_question_dir
  File.join(BBULTRA_FIXTURE_DIR, "questions")
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
