#
# Copyright (C) 2011 Instructure, Inc.
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
#

def collaboration_model(opts={})
  @collaboration = factory_with_protected_attributes(Collaboration, valid_collaboration_attributes.merge(opts))
end

def google_docs_collaboration_model(opts={})
  @collaboration = factory_with_protected_attributes(GoogleDocsCollaboration, valid_collaboration_attributes.merge(opts))
end

def valid_collaboration_attributes
  {
    :collaboration_type => "value for collaboration_type",
    :document_id => "document:dc3pjs4r_3hhc6fvcc",
    :user_id => User.create!.id,
    :context => @course || course_model,
    :url => "value for url",
    :title => "My Collaboration",
    :data => %{<?xml version="1.0" encoding="UTF-8"?>
    <entry xmlns="http://www.w3.org/2005/Atom" xmlns:ns1="http://schemas.google.com/g/2005" xmlns:ns2="http://schemas.google.com/docs/2007">
      <title>Biology 100 Collaboration</title>
      <id>http://docs.google.com/feeds/documents/private/full/document%3Adc3pjs4r_3hhc6fvcc</id>
      <updated>2009-05-28T23:12:49Z</updated>
      <published>2009-05-28T23:12:49Z</published>
      <link href="http://docs.google.com/Doc?id=dc3pjs4r_3hhc6fvcc" rel="alternate" type="tex/html"/>
      <link href="http://docs.google.com/feeds/documents/private/full/document%3Adc3pjs4r_3hhc6fvcc" rel="self" type="application/atom+xml"/>
      <link href="http://docs.google.com/feeds/documents/private/full/document%3Adc3pjs4r_3hhc6fvcc/fva2z1b2" rel="edit" type="application/atom+xml"/>
      <link href="http://docs.google.com/feeds/media/private/full/document%3Adc3pjs4r_3hhc6fvcc/fva2z1b2" rel="edit-media" type="text/html"/>
      <author>
        <name>davidlamontrichards</name>
        <email>davidlamontrichards@gmail.com</email>
      </author>
      <category label="document" scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/docs/2007#document"/>
      <content/>
      <ns1:lastModifiedBy>&lt;name xmlns="http://www.w3.org/2005/Atom"&gt;davidlamontrichards&lt;/name&gt;&lt;email xmlns="http://www.w3.org/2005/Atom"&gt;davidlamontrichards@gmail.com&lt;/email&gt;</ns1:lastModifiedBy>
      <ns1:feedLink/>
      <ns1:resourceId>document:dc3pjs4r_3hhc6fvcc</ns1:resourceId>n  <ns2:writersCanInvite/>
    </entry>}
  }
end
