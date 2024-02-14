/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export type PageBreadcrumb = {
  text: string
  url?: string
}

export interface AchievementData {
  id: string
  isNew: boolean
  title: string
  type: string | null
  criteria: string | null
  issuer: {
    name: string
    url?: string
    iconUrl?: string
  }
  issuedOn: string
  expiresOn: string | null
  imageUrl: string | null
  skills: SkillData[]
  verifiedBy: string | null
}

// ----------------- portfolios -----------------
export interface PortfolioData {
  id: string
  title: string
  heroImageUrl: string | null
}

export interface PortfolioDetailData extends PortfolioData {
  blurb: string
  city: string
  state: string
  phone: string
  email: string
  about: string
  skills: SkillData[]
  links: string[]
  education: EducationData[]
  experience: ExperienceData[]
  projects: ProjectDetailData[]
  achievements: AchievementData[]
}

export interface SkillData {
  name: string
  verified: boolean
  url?: string
}

export interface EducationData {
  id: string
  title: string
  institution: string
  city: string
  state: string
  from_date: string
  to_date: string
  gpa: string
}

export interface ExperienceData {
  id: string
  where: string
  title: string
  from_date: string
  to_date: string
  description: string
}

export interface PortfolioEditData {
  portfolio: PortfolioDetailData
  achievements: AchievementData[]
  projects: ProjectData[]
}

// ----------------- projects -----------------
export interface ProjectData {
  id: string
  title: string
  heroImageUrl: string | null
  skills: SkillData[]
  attachments: AttachmentData[]
  achievements: AchievementData[]
}

export interface AttachmentData {
  id: string
  filename: string
  display_name: string
  size: string | number
  contentType: string
  url: string
}

export interface ProjectDetailData extends ProjectData {
  description: string
  links: string[]
}

export interface ProjectEditData {
  project: ProjectDetailData
  achievements: AchievementData[]
}

// ---------- pathways ----------

export type PathwayBadgeType = {
  id: string
  title: string
  image: string | null
  issuer: {
    name: string
    url: string
  }
  type: string
  criteria: string
  skills: string[]
}

export type LearnerGroupType = {
  id: string
  name: string
  memberCount: number
}

export type RequirementType =
  | 'assessment'
  | 'assignment'
  | 'course'
  | 'module'
  | 'earned_achievement'
  | 'experience'
  | 'project'

type RequirementTypesType = {
  [Key in RequirementType]: string
}

export const RequirementTypes: RequirementTypesType = {
  assessment: 'Assessment',
  assignment: 'Assignment',
  course: 'Course',
  module: 'Module',
  earned_achievement: 'Achievement',
  experience: 'Experience',
  project: 'Project',
}

export type CanvasRequirementType = 'assignment' | 'course' | 'module'
type CanvasRequirementTypesType = {
  [Key in CanvasRequirementType]: string
}

export const CanvasRequirementTypes: CanvasRequirementTypesType = {
  assignment: 'assignments',
  course: 'courses',
  module: 'modules',
}

export type CanvasRequirementSearchResultType = {
  id: string
  name: string
  url: string
  learning_outcome_count: number
}

export interface RequirementData {
  id: string
  name: string
  description: string
  learning_outcome_count?: number
  required?: boolean
  type: RequirementType
  canvas_content?: CanvasRequirementSearchResultType
}

export interface CanvasUserSearchResultType {
  id: string
  name: string
  sortable_name: string
  avatar_url: string
}

export type PathwayUserShareRoleType = 'collaborator' | 'reviewer' | 'viewer'

export interface PathwayUserShareType extends CanvasUserSearchResultType {
  role: PathwayUserShareRoleType
}

// this is a node in the pathway tree
export interface MilestoneData {
  id: string
  title: string
  description: string
  required?: boolean
  requirements: RequirementData[]
  completion_award: string | PathwayBadgeType | null
  next_milestones: string[] // ids of this milestone's children
}

// this is the root of the pathway tree
export interface PathwayData {
  id: string
  title: string
  milestoneCount: number
  requirementCount: number
  published?: string // iso8601 date
  enrolled_student_count: number
  started_count: number
  completed_count: number
}

export interface PathwayDetailData extends PathwayData {
  description: string
  image_url: string | null
  is_private?: boolean
  learning_outcomes: SkillData[]
  completion_award: string | PathwayBadgeType | null
  learner_groups: string[] | LearnerGroupType[]
  shares: PathwayUserShareType[]
  first_milestones: string[] // ids of the milestone children of the root pathway
  milestones: MilestoneData[] // all the milestones in the pathway
}

export function isPathwayBadgeType(badge: string | PathwayBadgeType): badge is PathwayBadgeType {
  return (badge as PathwayBadgeType).id !== undefined
}

export function isLearnerGroupType(group: string | LearnerGroupType): group is LearnerGroupType {
  return (group as LearnerGroupType).id !== undefined
}

export interface DraftPathway extends PathwayDetailData {
  timestamp: number
}

export interface PathwayEditData {
  pathway: PathwayDetailData
  badges: PathwayBadgeType[]
  learner_groups: LearnerGroupType[]
}
