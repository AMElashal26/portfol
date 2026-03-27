# Template: resume-bullet

## Your Identity Context
Name: {{config.name}}
Profile: {{config.profile_summary}}
Target roles: {{config.target_roles}}
Tone: {{config.tone}}

## The Build Entry
Title: {{build.title}}
Description: {{build.description}}
Skills: {{build.skills_demonstrated}}
Source files: {{build.source_files}}

## Actual Code Context
{{source_code_snippets}}

## Quality Standards (few-shot examples)

### GOOD bullets (study these patterns):
{{examples/good-bullets.md}}

### BAD bullets (avoid these anti-patterns):
{{examples/bad-bullets.md}}

## Instructions
Generate 3 resume bullet variations for this build.

Each bullet MUST:
1. Start with a strong ACTION VERB (Built, Designed, Automated, Reduced, Engineered, etc.)
2. Name the SPECIFIC TOOLS used (not "various tools")
3. Include a QUANTIFIED OUTCOME or SCOPE (time saved, files processed, frequency, users affected)
4. Connect to a BUSINESS VALUE (efficiency, cost reduction, reliability, scalability)

Format: [Action Verb] + [What You Built] + [Using What] + [Measurable Impact]

If you cannot determine exact numbers from the code, provide realistic estimates
based on the code's actual behavior and mark them with ~.

Return as JSON:
{
  "bullets": [
    {"text": "...", "strength": "strong|good|stretch", "notes": "why this works"}
  ]
}
