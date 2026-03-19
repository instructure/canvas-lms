/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

package instructure

class FilesChangedDetector implements Serializable {
  private static final long serialVersionUID = 1L

  private Boolean bundleFiles = false
  private Boolean dockerDevFiles = false
  private Boolean groovyFiles = false
  private Boolean specFiles = false
  private Boolean yarnFiles = false
  private Boolean graphqlFiles = false
  private Boolean erbFiles = false
  private Boolean jsFiles = false

  // Getters
  Boolean hasBundleFiles() { return this.bundleFiles }
  Boolean hasDockerDevFiles() { return this.dockerDevFiles }
  Boolean hasGroovyFiles() { return this.groovyFiles }
  Boolean hasSpecFiles() { return this.specFiles }
  Boolean hasYarnFiles() { return this.yarnFiles }
  Boolean hasGraphqlFiles() { return this.graphqlFiles }
  Boolean hasErbFiles() { return this.erbFiles }
  Boolean hasJsFiles() { return this.jsFiles }

  // Setters for internal use
  void setBundleFiles(Boolean value) { this.bundleFiles = value }
  void setDockerDevFiles(Boolean value) { this.dockerDevFiles = value }
  void setGroovyFiles(Boolean value) { this.groovyFiles = value }
  void setSpecFiles(Boolean value) { this.specFiles = value }
  void setYarnFiles(Boolean value) { this.yarnFiles = value }
  void setGraphqlFiles(Boolean value) { this.graphqlFiles = value }
  void setErbFiles(Boolean value) { this.erbFiles = value }
  void setJsFiles(Boolean value) { this.jsFiles = value }
}
