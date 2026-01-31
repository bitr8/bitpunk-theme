# Lessons Learned

## Wallpaper Generation
- Cannot effectively darken a bright image after generation (ImageMagick creates artifacts)
- Must generate dark from the start with explicit prompts including exact hex codes
- Prompts: "CRITICAL: 70% pure black void (#000000)", "Neon as accent lighting", "Deep shadows dominate"

## Gemini Image Generation Workflow
- Don't display images with Read tool - wastes context
- List filenames only; user views in file manager
- Run generations with `run_in_background: true`
- Launch multiple generations in parallel
