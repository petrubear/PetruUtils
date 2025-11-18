# PetruUtils App Icon Specification

## Overview
The app icon should represent a developer toolbox - modern, clean, and professional.

## Design Concept

### Primary Concept: Developer Toolbox
- Central icon: Wrench + Code Brackets
- Color scheme: Blue/Purple gradient (tech-focused)
- Style: Modern, flat design with subtle depth
- Mood: Professional, trustworthy, developer-friendly

### Alternative Concepts
1. **Swiss Army Knife**: Multiple tools folded into one
2. **Hex Nut with Code**: Hardware/software fusion
3. **Terminal Window with Tools**: Direct dev reference

## Technical Requirements

### Required Sizes (macOS)
- 16x16 (@1x, @2x)
- 32x32 (@1x, @2x)
- 128x128 (@1x, @2x)
- 256x256 (@1x, @2x)
- 512x512 (@1x, @2x)
- 1024x1024 (@1x, @2x)

### Format
- PNG with transparency
- Retina-ready (@2x, @3x variants)
- Follow Apple Human Interface Guidelines

## Color Palette

### Primary Colors
- **Primary Blue**: `#007AFF` (iOS/macOS system blue)
- **Dark Blue**: `#0051D5`
- **Purple Accent**: `#5856D6`
- **Background**: White or light gray gradient

### Dark Mode Variant
- Adjust colors for dark mode visibility
- Use lighter shades for better contrast

## Design Guidelines

### Do's
✅ Keep it simple and recognizable at small sizes  
✅ Use clear, bold shapes  
✅ Maintain visual consistency with macOS design language  
✅ Test at all sizes (especially 16x16)  
✅ Ensure good contrast in both light and dark modes  

### Don'ts
❌ Don't use too much detail (won't scale down well)  
❌ Avoid text or small typography  
❌ Don't use more than 3-4 colors  
❌ Avoid photorealistic effects  

## Implementation Steps

### 1. Design Phase
- Create mockups in design tool (Figma, Sketch, or Illustrator)
- Test at multiple sizes
- Get feedback from potential users
- Create light and dark mode variants

### 2. Export Assets
Export all required sizes from your design tool:
```
AppIcon.appiconset/
├── icon_16x16.png
├── icon_16x16@2x.png
├── icon_32x32.png
├── icon_32x32@2x.png
├── icon_128x128.png
├── icon_128x128@2x.png
├── icon_256x256.png
├── icon_256x256@2x.png
├── icon_512x512.png
├── icon_512x512@2x.png
├── icon_1024x1024.png
└── Contents.json
```

### 3. Add to Xcode
1. Open `Assets.xcassets`
2. Select `AppIcon`
3. Drag and drop each size into the appropriate slot
4. Verify all slots are filled

### 4. Test
- Build and run app
- Check Dock icon
- Verify Finder display
- Test in both light and dark modes
- Check at different display resolutions

## Placeholder Icon (Current)

Currently using Xcode's default app icon. To be replaced with custom icon.

## Design Tools Recommendations

- **Figma** (Free, web-based) - https://figma.com
- **Sketch** (macOS, paid) - https://sketch.com
- **SF Symbols** (macOS, free) - For icon inspiration
- **Icon Slate** (macOS, paid) - Icon generator for macOS

## Icon Generator Services

If design skills are limited, consider these services:
- **Icon8** - https://icons8.com/app-icon
- **App Icon Generator** - Various online tools
- **Hire a designer** - Fiverr, Upwork, Dribbble

## Future Enhancements

- Animated icon for updates/processing (optional)
- Multiple icon variants (holiday themes, etc.)
- User-selectable icons (Pro feature idea)

---

**Status**: Placeholder - needs custom design  
**Priority**: Medium (functional but not polished)  
**Next Steps**: Create or commission custom icon design
