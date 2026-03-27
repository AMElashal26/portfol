# Template: linkedin-profile

## Your Identity Context
Name: {{config.name}}
Profile: {{config.profile_summary}}
Target roles: {{config.target_roles}}
Tone: {{config.tone}}

## All Your Builds
{{all_builds_from_jsonl}}

## Instructions
Analyze all logged builds and generate a complete LinkedIn profile rewrite:

1. HEADLINE (120 chars max):
   - Lead with what you DO, not your title
   - Include 1-2 key technologies
   - Example: "I automate workflows with AI | Claude API, Python, Shell | Building tools that eliminate busywork"

2. ABOUT SECTION (2000 chars max):
   - Opening hook: Start with a specific result or insight
   - Your thesis: What you believe about automation/AI/tools
   - Evidence: Reference 2-3 of your strongest builds
   - What you're looking for: Target role framing
   - CTA: How to reach you or work together

3. EXPERIENCE BULLETS:
   - Group builds by theme (not chronologically)
   - Use STAR format for each bullet
   - Lead with outcomes, not responsibilities

4. FEATURED SECTION RECOMMENDATIONS:
   - Which 3 builds to showcase
   - Suggested title/description for each

5. SKILLS TO ADD:
   - Based on frequency analysis of your builds

Return as JSON:
{
  "headline": "",
  "about": "",
  "experience_groups": [{"theme": "", "bullets": []}],
  "featured": [{"build_id": "", "title": "", "description": ""}],
  "skills_to_add": []
}
