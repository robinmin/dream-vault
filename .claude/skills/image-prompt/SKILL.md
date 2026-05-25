---
name: image-prompt
description: Generate optimized AI image prompts for Midjourney, DALL-E 3, Flux.1, and Stable Diffusion from note content or concept descriptions. Handles prompt generation, image file management, and markdown embedding.
---

# Image Prompt Generator Skill

Generates optimized prompts for AI image generation tools from Obsidian note content, with proper file management and embedding syntax.

## Activation

User asks to "generate image prompt", "create illustration", "make cover image", or provides a concept for visual content.

## Supported Tools

| Tool | Style | Strengths |
|------|-------|-----------|
| **Midjourney** | Artistic, cinematic, photorealistic | High-quality illustrations, mood pieces |
| **DALL-E 3** | Clean, descriptive, naturalistic | Literal interpretations, diagrams |
| **Flux.1** | Open source, high fidelity | Customizable, reproducible |
| **Stable Diffusion** | Flexible, highly customizable | Local generation, fine control |
| **Adobe Firefly** | Creative, commercial-safe | Licensed training data |

## Prompt Template

```
[Subject] in [setting/environment], [style descriptor], [lighting], [camera angle], [resolution hint]
```

## Workflow

### Step 1: Analyze Input

- Read the note content or concept description
- Extract key visual themes, colors, mood, subject matter
- Identify the purpose: cover image, inline illustration, diagram, or hero

### Step 2: Generate Prompts

For each target tool, generate a prompt following these guidelines:

- **Midjourney**: Add `--ar 16:9` for cover images, `--ar 1:1` for inline. Include style tags: `cinematic, ultra detailed, 4K`
- **DALL-E 3**: Use natural language descriptions. Be specific about composition.
- **Flux.1**: Include technical quality tags: `highly detailed, sharp focus, professional`
- **Stable Diffusion**: Include negative prompts for quality: `blurry, low quality, watermark`

### Step 3: Output

Provide the prompt for each tool in a structured format:

```
### Midjourney
```
[full prompt here] --ar 16:9 --v 6
```

### DALL-E 3
```
[full prompt here]
```
```

### Step 4: Image Placement

After generation, save to the correct location and embed:

```markdown
<!-- Cover image -->
![Article cover](../98_attachments/_generated/article-slug-cover.png)

<!-- Inline illustration -->
![Description of image](../98_attachments/_generated/article-slug-illustration-01.png)
```

## File Naming Convention

```
98_attachments/_generated/
├── {article-slug}-cover.png          # Cover/hero image
├── {article-slug}-illustration-01.png # First inline illustration
├── {article-slug}-illustration-02.png # Second inline illustration
└── {article-slug}-diagram-01.png      # Diagrams and charts
```

## Quality Checklist

- [ ] Prompt includes subject, setting, style, lighting
- [ ] Aspect ratio matches intended use (16:9 cover, 4:3 inline, 1:1 social)
- [ ] No copyrighted character names or brand references
- [ ] Image saved to `vault/98_attachments/_generated/`
- [ ] Embedded in note with relative path

## References

- PRD §6.2: Image Generation Pipeline
- ARCH §5: Management CLI
- Vault convention: `98_attachments/_generated/` for AI images
