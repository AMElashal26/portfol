# Template: upwork-gig

## Your Identity Context
Name: {{config.name}}
Profile: {{config.profile_summary}}
Target roles: {{config.target_roles}}
Tone: {{config.tone}}

## The Build Entry
Title: {{build.title}}
Description: {{build.description}}
Skills: {{build.skills_demonstrated}}

## Actual Code Context
{{source_code_snippets}}

## Instructions
Transform this build into an Upwork service offering. Generate:

1. GIG TITLE: Clear, searchable, client-outcome-focused (not "I will do X")
2. DESCRIPTION:
   - Open with the client's pain point this solves
   - Describe what you deliver (specific deliverables, not vague promises)
   - Include a brief "how it works" section (3 steps max)
   - Mention tools/tech used (builds credibility)
   - End with scope/timeline expectation
3. KEY SKILLS: Tags that match Upwork's skill taxonomy
4. PRICING: Suggest hourly range based on skill complexity

Tone: Professional but approachable. Show expertise through specificity, not jargon.

Return as JSON:
{
  "title": "...",
  "description": "...",
  "deliverables": ["..."],
  "skills_tags": ["..."],
  "hourly_range": {"low": 50, "high": 85},
  "estimated_duration": "..."
}
