/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

def buildRegistryFQDN() {
  return findVariable('BUILD_REGISTRY_FQDN', true)
}

def fscPropagate() {
  def raw = findVariable('FSC_PROPAGATE', false)
  return raw != null && raw == '1'
}

def publishableTagSuffix() {
  return findVariable('PUBLISHABLE_TAG_SUFFIX', true)
}

def rubyPassenger() {
  return findVariable('RUBY_PASSENGER', true)
}

def postgres() {
  return findVariable('POSTGRES', true)
}

def node() {
  return findVariable('NODE', true)
}

/**
 * this is a standard way of finding configuration from different places.
 * the checks happen in this order:
 *   - check if the name exists in the env
 *   - checks if a folder config file exists by this name. if so, return the file contents
 *   - throws error if required, else returns null
 *
 * @name: the name of the variable to search for
 * @required: required if we want to throw an exception if not found
 * @returns: the value or null if not required
 */
def findVariable(name, required) {
  if (env."$name") {
    return env."$name"
  }
  // TODO: add commit flag check here
  def result = null
  try {
    configFileProvider([configFile(fileId: name, variable: '__TARGET')]) {
      result = readFile(env.__TARGET)
    }
  }
  catch (hudson.AbortException ex) {
    if (!ex.message.contains('not able to provide the file')) {
      throw ex
    }
    if (required) {
      throw new Exception("unable to find configuration value: $name")
    }
  }
  return result
}

return this
