# Loading Components Usage Guide

## Quick Reference for OptiFit Loading Indicators

### Import Statement
```dart
import '../widgets/loading_overlay.dart';
```

## Components Overview

### 1. LoadingWidget
**Use when:** You need a simple centered loading indicator with optional message.

```dart
LoadingWidget(
  message: 'Loading data...',
  size: 40,  // Optional, default is 40
  color: AppTheme.primary,  // Optional
  showMessage: true,  // Optional, default is true
)
```

**Example:**
```dart
FutureBuilder(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingWidget(
        message: 'Loading your data...',
      );
    }
    // ... rest of code
  },
)
```

---

### 2. ShimmerStatCard
**Use when:** Loading stat cards in grid layouts.

```dart
const ShimmerStatCard()
```

**Example:**
```dart
Row(
  children: [
    const Expanded(child: ShimmerStatCard()),
    const SizedBox(width: 16),
    const Expanded(child: ShimmerStatCard()),
  ],
)
```

---

### 3. ShimmerWorkoutCard
**Use when:** Loading workout cards in lists.

```dart
const ShimmerWorkoutCard()
```

**Example:**
```dart
LoadingListSkeleton(
  itemCount: 3,
  itemBuilder: () => const ShimmerWorkoutCard(),
)
```

---

### 4. ShimmerProgressChart
**Use when:** Loading progress charts or graphs.

```dart
const ShimmerProgressChart()
```

**Example:**
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: _isLoading
      ? const ShimmerProgressChart()
      : ActualChartWidget(),
)
```

---

### 5. LoadingListSkeleton
**Use when:** Loading multiple list items with shimmer effect.

```dart
LoadingListSkeleton(
  itemCount: 3,  // Number of skeleton items to show
  itemBuilder: () => const ShimmerWorkoutCard(),
)
```

---

### 6. FullScreenLoading
**Use when:** Loading entire screen content.

```dart
FullScreenLoading(
  message: 'Loading your progress data...',
  showProgress: true,  // Optional, default is true
)
```

**Example:**
```dart
FutureBuilder(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const FullScreenLoading(
        message: 'Loading your progress data...',
      );
    }
    return Scaffold(...);
  },
)
```

---

### 7. VideoUploadLoading
**Use when:** Uploading or processing videos.

```dart
VideoUploadLoading(
  message: 'Analyzing your squat form...',
  progress: 0.75,  // Optional, shows progress bar if provided
)
```

**Example:**
```dart
if (_isUploading) {
  return const VideoUploadLoading(
    message: 'Processing video...',
  );
}
```

---

### 8. LoadingOverlay
**Use when:** You need to overlay loading on top of existing content.

```dart
LoadingOverlay(
  isLoading: _isProcessing,
  message: 'Processing data...',
  child: YourContentWidget(),
)
```

**Example:**
```dart
@override
Widget build(BuildContext context) {
  return LoadingOverlay(
    isLoading: _isUploading,
    message: 'Processing video analysis...',
    child: Scaffold(
      // ... your scaffold content
    ),
  );
}
```

---

### 9. ShimmerLoading (Generic Wrapper)
**Use when:** You want to add shimmer effect to any custom widget.

```dart
ShimmerLoading(
  isLoading: true,
  child: YourCustomWidget(),
)
```

---

## Best Practices

### FutureBuilder Pattern
Always check all connection states:

```dart
FutureBuilder<DataType>(
  future: _futureData,
  builder: (context, snapshot) {
    // 1. Check if still loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingWidget(
        message: 'Loading data...',
      );
    }
    
    // 2. Check for errors
    if (snapshot.hasError) {
      return ErrorWidget(
        message: 'Failed to load data',
        actionText: 'Retry',
        onAction: () => setState(() => _futureData = fetchData()),
      );
    }
    
    // 3. Check if data exists
    if (!snapshot.hasData) {
      return const EmptyStateWidget(
        title: 'No data available',
        message: 'There is no data to display',
        icon: Icons.inbox,
      );
    }
    
    // 4. Display data
    final data = snapshot.data!;
    return YourDataWidget(data: data);
  },
)
```

### AnimatedSwitcher for Smooth Transitions
Use AnimatedSwitcher to smoothly transition between loading and content:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: _isRefreshing
      ? const ShimmerStatCard()
      : _StatCard(data: data),
)
```

### Loading Messages
Keep messages:
- **Concise:** 2-5 words
- **Descriptive:** Tell users what's happening
- **Friendly:** Use "your" instead of "the"

**Good examples:**
- "Loading your fitness data..."
- "Analyzing your video..."
- "Preparing your dashboard..."

**Bad examples:**
- "Loading..." (not descriptive)
- "Please wait" (not informative)
- "Data is being fetched from server" (too technical/long)

### Error Handling
Always provide error states with retry options:

```dart
ErrorWidget(
  message: 'Failed to load workout stats',
  actionText: 'Retry',
  onAction: () {
    setState(() {
      _futureStats = DataService().getWorkoutStats();
    });
  },
)
```

## Common Patterns

### Pattern 1: Grid Loading
```dart
if (_isLoading) {
  return Row(
    children: [
      const Expanded(child: ShimmerStatCard()),
      const SizedBox(width: 16),
      const Expanded(child: ShimmerStatCard()),
    ],
  );
}
```

### Pattern 2: List Loading
```dart
if (_isLoading) {
  return LoadingListSkeleton(
    itemCount: 3,
    itemBuilder: () => const ShimmerWorkoutCard(),
  );
}
```

### Pattern 3: Full Screen Loading
```dart
return FutureBuilder(
  future: _futureData,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const FullScreenLoading(
        message: 'Loading data...',
      );
    }
    return Scaffold(...);
  },
);
```

### Pattern 4: Inline Loading
```dart
FutureBuilder(
  future: fetchInsights(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingWidget(
        message: 'Generating insights...',
        size: 30,
      );
    }
    return InsightWidget(data: snapshot.data);
  },
)
```

## Color Customization

All components use AppTheme colors by default:
- **Base color:** `AppTheme.divider`
- **Highlight color:** `AppTheme.divider.withOpacity(0.3)`
- **Primary color:** `AppTheme.primary`

To customize colors, modify the AppTheme in `lib/theme/theme.dart`.

## Performance Tips

1. **Use shimmer sparingly:** Only for visible content during loading
2. **Limit item count:** For LoadingListSkeleton, show 3-5 items max
3. **Avoid nested shimmers:** Don't nest shimmer effects
4. **Use const constructors:** When widget doesn't change (e.g., `const ShimmerStatCard()`)

## Troubleshooting

### Shimmer not appearing?
- Check if shimmer package is installed: `flutter pub get`
- Verify import: `import 'package:shimmer/shimmer.dart';`

### Loading never stops?
- Check if you're updating state properly
- Verify FutureBuilder is receiving new Future
- Ensure error handling is in place

### Layout shifts during loading?
- Use shimmer components that match final widget size
- Set explicit heights for containers
- Use AnimatedSwitcher for smooth transitions

## Summary

Choose the right component for your use case:
- **Simple loading:** `LoadingWidget`
- **Stat cards:** `ShimmerStatCard`
- **Workout lists:** `ShimmerWorkoutCard` with `LoadingListSkeleton`
- **Charts:** `ShimmerProgressChart`
- **Full screen:** `FullScreenLoading`
- **Video upload:** `VideoUploadLoading`
- **Overlay:** `LoadingOverlay`
- **Custom shimmer:** `ShimmerLoading`

All components are designed to work together and provide a consistent loading experience throughout the app.

