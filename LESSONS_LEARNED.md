# Lessons Learned

## Wallpaper Generation

### OLED/Dark Wallpapers
- Cannot effectively darken a bright image after generation (ImageMagick creates artifacts)
- Must generate dark from the start with explicit prompts:
  - "CRITICAL: 70% pure black void (#000000)"
  - "Neon as accent lighting, not overwhelming"
  - "Deep shadows dominate, high contrast"
- Include exact hex codes for theme colors in prompts

### Gemini Image Generation Context Optimization
- Don't display images with Read tool in terminal - wastes context
- Just list filenames; user views in Dolphin/file manager
- Run image generation with `run_in_background: true`, don't block waiting
- Launch multiple generations in parallel in single message
