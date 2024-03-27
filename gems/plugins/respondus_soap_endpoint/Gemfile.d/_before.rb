# frozen_string_literal: true

# Force soap4r to use the (slower, pure ruby) rexml parser because nokogiri can't
# handle null characters in the xml (which aren't allowed by the XML specification
# but our specs test for and are maybe used in the real usage of this endpoint)
ENV["SOAP4R_PARSERS"] = "rexmlparser"
