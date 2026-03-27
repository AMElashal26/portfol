# Template: linkedin-post

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
Generate a LinkedIn post announcing this build. The post should:

1. HOOK: Open with a relatable problem or insight (not "I'm excited to share...")
2. STORY: Briefly describe what you built and why, in plain language
3. OUTCOME: What changed? What's the measurable result?
4. TOOLS: Naturally mention the technologies used (builds credibility)
5. TAKEAWAY: End with an insight others can learn from
6. CTA: Close with a question or invitation to engage

Tone: Builder sharing real work, not corporate announcement.
Length: 150-250 words (LinkedIn sweet spot for engagement).
DO NOT use: "I'm thrilled", "excited to announce", "proud to share" or any generic AI opener.

Return as JSON:
{
  "post": "...",
  "hashtags": ["#tag1", "#tag2"],
  "best_time_to_post": "Tuesday-Thursday, 8-10am"
}
