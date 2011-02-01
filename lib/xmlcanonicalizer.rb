#
# Written by Roland Schmitt, roland.schmitt@web.de, from the WSS4R project.
# WSS4R is licensed under the standard Ruby dual license (GPLv2 and Ruby's
# custom license): http://www.ruby-lang.org/en/LICENSE.txt
# with modifications by Instructure, Inc.
#

require "rexml/document"
require "base64"

module XML
  module Util
      
      class REXML::Instruction
        def write(writer, indent=-1, transitive=false, ie_hack=false)
          indent(writer, indent)
          writer << START.sub(/\\/u, '')
          writer << @target
          writer << ' '
          writer << @content if @content != nil
          writer << STOP.sub(/\\/u, '')
        end
      end
      
      class REXML::Attribute
        def <=>(a2)
          if (self === a2)
            return 0
          elsif (self == nil)
            return -1
          elsif (a2 == nil)
            return 1
          elsif (self.prefix() == a2.prefix())
            return self.name()<=>a2.name()
          end
          if (self.prefix() == nil)
            return -1
          elsif (a2.prefix() == nil)
            return 1
          end
          ret = self.namespace()<=>a2.namespace()
          if (ret == 0)
            ret = self.prefix()<=>a2.prefix()
          end
          return ret
        end
      end
      
      class REXML::Element
        def search_namespace(prefix)
          if (self.namespace(prefix) == nil)
            return (self.parent().search_namespace(prefix)) if (self.parent() != nil)
          else
            return self.namespace(prefix)
          end
        end
      def rendered=(rendered)
      @rendered = rendered
    end
    def rendered?()
      return @rendered
    end
        def node_namespaces()
          ns = Array.new()
          ns.push(self.prefix())
          self.attributes().each_attribute{|a|
            if (a.prefix() != nil)
              ns.push(a.prefix())
            end
            if (a.prefix() == "" && a.local_name() == "xmlns")
              ns.push("xmlns")
            end
          }
          ns
        end
      end
      
      class NamespaceNode
        attr_reader :prefix, :uri 
        def initialize(prefix, uri)
          @prefix = prefix
          @uri = uri
        end
      end
      
      class XmlCanonicalizer
        attr_accessor :prefix_list, :logger
        
        BEFORE_DOC_ELEMENT = 0
        INSIDE_DOC_ELEMENT = 1
        AFTER_DOC_ELEMENT  = 2
        
        NODE_TYPE_ATTRIBUTE  = 3
        NODE_TYPE_WHITESPACE = 4
        NODE_TYPE_COMMENT    = 5
        NODE_TYPE_PI         = 6
        NODE_TYPE_TEXT       = 7
        
        
        def initialize(with_comments, excl_c14n)
          @with_comments = with_comments
          @exclusive = excl_c14n
          @res = ""
          @state = BEFORE_DOC_ELEMENT
          @xnl = Array.new()
          @prevVisibleNamespacesStart = 0
          @prevVisibleNamespacesEnd = 0
          @visibleNamespaces = Array.new()
       @inclusive_namespaces = Array.new()
          @prefix_list = nil
       @rendered_prefixes = Array.new()
        end
        
        def add_inclusive_namespaces(prefix_list, element, visible_namespaces)
          namespaces = element.attributes()
          namespaces.each_attribute{|ns|
            if (ns.prefix=="xmlns")
              if (prefix_list.include?(ns.local_name()))
                visible_namespaces.push(NamespaceNode.new("xmlns:"+ns.local_name(), ns.value()))
              end
            end
          }
          parent = element.parent()
          add_inclusive_namespaces(prefix_list, parent, visible_namespaces) if (parent)
          visible_namespaces
        end
        
        def canonicalize(document)
          write_document_node(document)
          @res
        end
        
        def canonicalize_element(element, logging = true)
        logging=(true) if logging
        @logger.debug("Canonicalize element:\n " + element.to_s()) if @logger
          @inclusive_namespaces = add_inclusive_namespaces(@prefix_list, element, @inclusive_namespaces) if (@prefix_list)
          @preserve_document = element.document()
          tmp_parent = element.parent()
          body_string = remove_whitespace(element.to_s().gsub("\n","").gsub("\t","").gsub("\r",""))
          document = Document.new(body_string)
          tmp_parent.delete_element(element)
          element = tmp_parent.add_element(document.root())
          @preserve_element = element
          document = Document.new(element.to_s())
          ns = element.namespace(element.prefix())
          document.root().add_namespace(element.prefix(), ns)
          write_document_node(document)
       @logger.debug("Canonicalized result:\n " + @res.to_s()) if @logger
          @res
        end
        
        def write_document_node(document)
          @state = BEFORE_DOC_ELEMENT
          if (document.class().to_s() == "REXML::Element")
            write_node(document)
          else
            document.each_child{|child|
              write_node(child)
            }
          end
          @res
        end
        
        def write_node(node)
          visible = is_node_visible(node)
          if ((node.node_type() == :text) && white_text?(node.value()))
            res = node.value()
            res.gsub("\r\n","\n")
            #res = res.delete(" ").delete("\t")
            res.delete("\r")
            @res = @res + res
            #write_text_node(node,visible) if (@state == INSIDE_DOC_ELEMENT)
            return
          end
          if (node.node_type() == :text)
            write_text_node(node, visible)
            return
          end   
          if (node.node_type() == :element)
            write_element_node(node, visible) if (!node.rendered?())
        node.rendered=(true)
          end
          if (node.node_type() == :processing_instruction)
          end
          if (node.node_type() == :comment)
          end
        end
        
        def write_element_node(node, visible)
          savedPrevVisibleNamespacesStart = @prevVisibleNamespacesStart
          savedPrevVisibleNamespacesEnd = @prevVisibleNamespacesEnd
          savedVisibleNamespacesSize = @visibleNamespaces.size()
          state = @state
          state = INSIDE_DOC_ELEMENT if (visible && state == BEFORE_DOC_ELEMENT)
          @res = @res + "<" + node.expanded_name() if (visible)
          write_namespace_axis(node, visible)
          write_attribute_axis(node)
          @res = @res + ">" if (visible)
          node.each_child{|child|
        write_node(child)
       }
          @res = @res + "</" +node.expanded_name() + ">" if (visible)
          @state = AFTER_DOC_ELEMENT if (visible && state == BEFORE_DOC_ELEMENT)
          @prevVisibleNamespacesStart = savedPrevVisibleNamespacesStart
          @prevVisibleNamespacesEnd = savedPrevVisibleNamespacesEnd
          @visibleNamespaces.slice!(savedVisibleNamespacesSize, @visibleNamespaces.size() - savedVisibleNamespacesSize)     if (@visibleNamespaces.size() > savedVisibleNamespacesSize)
        end
        
        def write_namespace_axis(node, visible)
          doc = node.document()
          has_empty_namespace = false
          list = Array.new()
          cur = node
          #while ((cur != nil) && (cur != doc) && (cur.node_type() != :document)) 
          namespaces = cur.node_namespaces()
          namespaces.each{|prefix|
            next if ((prefix == "xmlns") && (node.namespace(prefix) == "")) 
            namespace = cur.namespace(prefix)
            next if (is_namespace_node(namespace))
            next if (node.namespace(prefix) != cur.namespace(prefix))
            next if (prefix == "xml" && namespace == "http://www.w3.org/XML/1998/namespace")
            next if (!is_node_visible(cur))
            rendered = is_namespace_rendered(prefix, namespace)
            @visibleNamespaces.push(NamespaceNode.new("xmlns:"+prefix,namespace)) if (visible)
            if ((!rendered) && !list.include?(prefix))
              list.push(prefix)
            end
            has_empty_namespace = true if (prefix == nil)
          }
          if (visible && !has_empty_namespace && !is_namespace_rendered(nil, nil)) 
            @res = @res + ' xmlns=""'
          end
          #TODO: ns of inclusive_list
#=begin
          if ((@prefix_list) && (node.to_s() == node.parent().to_s()))
            #list.push(node.prefix())
            @inclusive_namespaces.each{|ns|
              prefix = ns.prefix().split(":")[1]
              list.push(prefix) if (!list.include?(prefix) && (!node.attributes.prefixes.include?(prefix))) 
            }
        @prefix_list = nil
          end
#=end
          list.sort!()
          list.each{|prefix|
            next if (prefix == "")
        #next if (@rendered_prefixes.include?(prefix))
        @rendered_prefixes.push(prefix)
            ns = node.namespace(prefix)
            ns = @preserve_element.namespace(prefix) if (ns == nil)
            @res = @res + normalize_string(" " + prefix + '="' + ns + '"', NODE_TYPE_TEXT) if (prefix == "xmlns")
            @res = @res + normalize_string(" xmlns:" + prefix + '="' + ns + '"', NODE_TYPE_TEXT) if (prefix != nil && prefix != "xmlns")
          }
          if (visible)
            @prevVisibleNamespacesStart = @prevVisibleNamespacesEnd
            @prevVisibleNamespacesEnd = @visibleNamespaces.size() 
          end
        end
        
        def write_attribute_axis(node)
          list = Array.new()
          #Sorting-Bug
          #node.attributes().each_attribute{|attr|
          #  list.push(attr) if (!is_namespace_node(attr.value()) && !is_namespace_decl(attr)) # && is_node_visible(
          #}
          node.attributes().sort().each{|key,attr|
            list.push(attr) if (!is_namespace_node(attr.value()) && !is_namespace_decl(attr)) # && is_node_visible(
          }
          if (!@exclusive && node.parent() != nil && node.parent().parent() != nil)
            cur = node.parent()
            while (cur != nil)
              #next if (cur.attributes() == nil)
              cur.each_attribute{|attribute|
                next if (attribute.prefix() != "xml")
                next if (attribute.prefix().index("xmlns") == 0)
                next if (node.namespace(attribute.prefix()) == attribute.value())
                found = true
                list.each{|n|
                  if (n.prefix() == "xml" && n.value() == attritbute.value())
                    found = true
                    break
                  end
                }
                next if (found)
                list.push(attribute)
              }
            end
          end
          list.each{|attribute|
            if (attribute != nil)
              if (attribute.name() != "xmlns")
                @res = @res + " " + normalize_string(attribute.to_string(), NODE_TYPE_ATTRIBUTE).gsub("'",'"')
              end
              # else
              # @res = @res + " " + normalize_string(attribute.name()+'="'+attribute.to_s()+'"', NODE_TYPE_ATTRIBUTE).gsub("'",'"')
              #end
            end
          }
        end
        
        def is_namespace_node(namespace_uri)
          return (namespace_uri == "http://www.w3.org/2000/xmlns/")
        end
        
        def is_namespace_rendered(prefix, uri)
          is_empty_ns = prefix == nil && uri == nil
          if (is_empty_ns)
            start = 0
          else
            start = @prevVisibleNamespacesStart
          end
          @visibleNamespaces.each{|ns|
            if (ns.prefix() == "xmlns:"+prefix.to_s() && ns.uri() == uri)
              return true
            end
          }
          return is_empty_ns
          #(@visibleNamespaces.size()-1).downto(start) {|i|
          #   ns = @visibleNamespaces[i]
          # return true if (ns.prefix() == "xmlns:"+prefix.to_s() && ns.uri() == uri)
          # #p = ns.prefix() if (ns.prefix().index("xmlns") == 0) 
          # #return ns.uri() == uri if (p == prefix) 
          #}
          #return is_empty_ns
        end
        
        def is_node_visible(node)
          return true if (@xnl.size() == 0)
          @xnl.each{|element|
            return true if (element == node)
          }
          return false
        end
        
        def normalize_string(input, type)
          sb = ""
          return input
        end
        #input.each_byte{|b|
        # if (b ==60 && (type == NODE_TYPE_ATTRIBUTE || is_text_node(type)))
        #   sb = sb + "&lt;"
        # elsif (b == 62 && is_text_node(type))
        #   sb = sb + "&gt;"
        # elsif (b == 38 && (is_text_node(type) || is_text_node(type))) #Ampersand
        #   sb = sb + "&amp;"
        # elsif (b == 34 && is_text_node(type)) #Quote
        #   sb = sb + "&quot;"
        # elsif (b == 9 && is_text_node(type)) #Tabulator
        #   sb = sb + "&#x9;"
        # elsif (b == 11 && is_text_node(type)) #CR
        #   sb = sb + "&#xA;"
        # elsif (b == 13 && (type == NODE_TYPE_ATTRIBUTE || (is_text_node(type) && type != NODE_TYPE_WHITESPACE) || type == NODE_TYPE_COMMENT || type == NODE_TYPE_PI))
        #   sb = sb + "&#xD;"
        # elsif (b == 13)
        #   next
        # else
        #   sb = sb.concat(b)
        # end
        #}
        #sb
        #end
        
        def write_text_node(node, visible)
          if (visible)
            @res = @res + normalize_string(node.value(), node.node_type())
          end
        end
        
        def white_text?(text)
          return true if ((text.strip() == "") || (text.strip() == nil))
          return false
        end
        
        def is_namespace_decl(attribute)
          #return true if (attribute.name() == "xmlns")
          return true if (attribute.prefix().index("xmlns") == 0)
          return false
        end
        
        def is_text_node(type)
          return true if (type == NODE_TYPE_TEXT || type == NODE_TYPE_CDATA || type == NODE_TYPE_WHITESPACE)
          return false
        end
        
        def remove_whitespace(string)
          new_string = ""
          in_white = false
          string.each_byte{|b|
            #if (in_white && b == 32)
            #else
            if !(in_white && b == 32)
              new_string = new_string + b.chr()
            end
            if (b == 62) #>
              in_white = true
            end
            if (b == 60) #<
              in_white = false
            end
          }
          new_string
        end
      end
    
      def logging=(state)
      if (state)
       @logger = Logger.new("xmlcanonicalizer")
       @logger.level = DEBUG
       @logger.trace = false
       p = PatternFormatter.new(:pattern => "[%l] %d :: %.100m %15t")
       @logger.add(FileOutputter.new("wss4r", {:filename => "xmlcanonicalizer.log", :formatter => BasicFormatter}))
      else
        @logger = nil
      end
    end
    end #Util
end #XML


if __FILE__ == $0
  document = Document.new(File.new(ARGV[0]))
  body = nil
  c = WSS4R::Security::Util::XmlCanonicalizer.new(false, true)
  
  if (ARGV.size() == 3) 
    body = ARGV[2]
    if (body == "true")
      element = XPath.match(document, "/soap:Envelope/soap:Body")[0]
      element = XPath.first(document, "/soap:Envelope/soap:Header/wsse:Security/Signature/SignedInfo")
      result = c.canonicalize_element(element)
      puts("-----")
      puts(result)
      puts("-----")
      puts(result.size())     
      puts("-----")
      puts(CryptHash.new().digest_b64(result))
    end
  else 
    result = c.canonicalize(document)
  end
  
  file = File.new(ARGV[1], "wb")
  file.write(result)
  file.close()
end


