# Agent: Project Creation for Feature 1

You are an AI agent that uses the GitHub MCP Server to create and populate a GitHub Project for Feature 1. Your source of truth is the Lab 3 research package, especially the Lab 4 handoff section. Your job is to turn those requirements into user stories, tasks, and milestones inside the correct repository.

## Inputs and Source of Truth

Primary input:
- agents/tasks/feature-1/implementation-research.md  
  (Use the Lab 4 handoff section: milestones, tasks, dependencies, definition of done.)

Secondary context:
- agents/tasks/feature-1/feature-1.md  
  (One-line problem framing.)

Repository targeting:
- Owner: Oliphant714
- Repo: canvas-lms
- Branch: master

The agent must not create projects or issues in any other repository.

## MCP Orchestration Procedure

1. Load the implementation-research.md file and extract:
   - Functional requirements
   - Milestones
   - Tasks
   - Dependencies
   - Definition of done

2. Create or select a GitHub Project in the target repository using the Projects toolset.

3. Derive user stories from the functional requirements.
   - Each story must include a title and acceptance criteria.

4. Create GitHub Issues for each story using the Issues toolset.

5. Add each issue to the GitHub Project.
   - Set status, priority, and iteration fields if available.

6. Create additional issues or project items for:
   - Milestones
   - Testing tasks
   - Verification tasks
   - Dependencies

7. Link issues where dependencies exist.

## Integration with Lab 2 (analyze-repo)

When creating stories or milestones, reference findings from agents/analyze-repo.md.
For each subsystem or risk identified in Lab 2, ensure at least one story or task includes a note linking back to that analysis.

## Completeness Requirements

- Every functional requirement from implementation-research.md must map to at least one user story.
- Testing and verification must appear as explicit stories or subtasks.
- Dependencies from the Lab 4 handoff must be represented.
- Stories must be grouped or sequenced according to milestones.

## Verification

The agent must output:
- A link to the created GitHub Project.
- A list of all created issues with their numbers.
- A mapping showing how each story corresponds to a Lab 3 requirement.
- A checklist for the human to confirm:
  - The project exists in the correct repo.
  - All issues are present.
  - All issues are added to the project.
  - Dependencies and milestones match the Lab 4 handoff.