/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

plugins {
  id("com.mkobit.jenkins.pipelines.shared-library") version "0.10.1"
  id("com.github.ben-manes.versions") version "0.21.0"
  java
}

java {
  sourceCompatibility = JavaVersion.VERSION_1_8
  targetCompatibility = JavaVersion.VERSION_1_8
}

tasks.withType<Test> {
  this.testLogging {
    this.showStandardStreams = true
  }
}

val log4jVersion = "2.11.2"
val slf4jVersion = "1.7.26"
val declarativePluginsVersion = "1.3.9"

dependencies {
  testImplementation("org.assertj:assertj-core:3.4.1")
  testImplementation("com.lesfurets:jenkins-pipeline-unit:1.8")
  testImplementation("junit:junit:4.12")
}

sharedLibrary {
  pluginDependencies {
    dependency("com.lesfurets","jenkins-pipeline-unit","1.8")
  }
}
