# Template: reverse-project

## Your Identity Context
Name: {{config.name}}
Profile: {{config.profile_summary}}
Target roles: {{config.target_roles}}

## Your Existing Builds
{{all_builds_from_jsonl}}

## Job Description
{{job_description_content}}

## Instructions

1. EXTRACT from the job description:
   - Required skills (list each)
   - Desired outcomes (what they want accomplished)
   - Industry/domain context
   - Seniority signals (junior/mid/senior/lead)

2. MATCH against existing builds:
   - Which builds already demonstrate required skills?
   - Rate match: direct (exact skill match) / adjacent (related skill) / stretch (transferable)

3. For GAPS (required skills with no matching build):
   - Generate 1-2 PROJECT IDEAS that:
     a) Use tools already known (from existing builds)
     b) Demonstrate the missing skill convincingly
     c) Can be built in 2-4 hours (weekend project size)
     d) Produce a tangible, demo-able artifact

4. For ALL matched and gap skills, generate:
   - A tailored resume section (3-5 STAR-format bullets)
   - A LinkedIn post angle
   - An Upwork proposal draft addressing this specific job

Return as JSON:
{
  "job_analysis": {
    "required_skills": [],
    "desired_outcomes": [],
    "seniority": "",
    "domain": ""
  },
  "matches": [
    {"build_id": "", "match_type": "direct|adjacent|stretch", "relevance_note": ""}
  ],
  "gaps": [
    {"skill": "", "project_idea": {"title": "", "description": "", "hours": 0, "deliverable": ""}}
  ],
  "generated_content": {
    "resume_bullets": [],
    "linkedin_post": "",
    "upwork_proposal": ""
  }
}
