# High-Impact Features Implementation Plan

## 1. FLASHCARD/SPACED REPETITION UI

### Files to Create:
- `FlashcardView.swift` - Main flashcard study view
- `FlashcardCardView.swift` - Individual card display

### Implementation:
1. Create FlashcardView with:
   - Due cards fetched from AppState.progress.flashcardStates (filter isDueForReview)
   - Card display showing question only (answer hidden)
   - 6-button quality selector (0-5 scale) matching SM-2
   - Automatic scheduling update on button press

2. Quality buttons: "Again (0)" "Hard (2)" "Good (3)" "Easy (4)" "Perfect (5)"
3. Show progress: "12 cards due, 5 completed today"
4. Update `progress.flashcardStates[questionId].update(quality:)` on each rating

### Integration:
- Add "Flashcards" tab to AppTab in AppState
- Add navigation in ContentView/TabBar
- Hook QuizView to auto-add mastered questions to flashcard deck

---

## 2. PERFORMANCE ANALYTICS DASHBOARD

### Files to Create:
- `AnalyticsView.swift` - Main dashboard (already referenced in HomeView)
- `PerformanceChartsView.swift` - Chart components

### Implementation:
1. **Per-Domain Breakdown**:
   - 4 cards showing domain accuracy over time
   - Use `appState.progress.domainScores[domain.rawValue]`
   - Show trend (↑ ↓ →)

2. **Sub-Objective Performance**:
   - Table: sub-objective | accuracy | attempts
   - Color: green (>75%), amber (65-75%), red (<65%)
   - Sort by weakest first
   - Tap to drill weak sub-objectives

3. **Time-Spent Analysis**:
   - Average seconds per question
   - Breakdown by difficulty
   - Identify bottleneck question types

4. **Overall Trends**:
   - Line chart: accuracy over last 20 quizzes
   - Show rolling 5-quiz average
   - Prediction line showing current trajectory

### Key Calculations (add to AppState):
```swift
func subObjectiveBreakdown() -> [(subObj: String, accuracy: Double, attempts: Int)]
func domainAccuracyTrend(domain: ExamDomain) -> [(date: Date, accuracy: Double)]
func averageTimePerQuestion() -> TimeInterval
```

---

## 3. STUDY ROADMAP / SMART GUIDANCE

### Files to Create:
- `StudyRoadmapView.swift` - Personalized study plan
- `StudyRecommendationView.swift` - Daily/next-step recommendations

### Implementation:
1. **Study Timeline**:
   - Days until exam (from AppState.examDate)
   - Domains in exam weight order (33%, 30%, 19%, 18%)
   - Calculate: days per domain = (daysUntilExam) / 4
   - Show: "Finish Domain 1 by Day 7 → Domain 2 by Day 14 → etc"

2. **Progress Tracker**:
   - % of questions attempted per domain
   - % of questions mastered per domain
   - Show pace: "At this rate, Domain 1 in X days"

3. **Daily Recommendation**:
   - If ahead on Domain 1: "Move to Domain 2"
   - If behind: "Focus on Domain X (you're at 40%, need 65%)"
   - Show weak sub-objectives: "Priority: 1.4, 2.1, 3.2"
   - Suggest quiz type: "Do 15 Hard Qs on Domain 1" or "Drill weak areas"

4. **Readiness Gauge**:
   - Combine accuracy % + completion %
   - "65% ready overall, on track to finish in time"
   - Visual: circle progress × 4 domains

### Key Calculations (add to AppState):
```swift
func daysPerDomain() -> Int
func projectedCompletionDate(for domain: ExamDomain) -> Date
func readinessPercentage() -> Double
func recommendedDomain() -> ExamDomain
func recommendedAction() -> String
```

---

## EXECUTION ORDER (Next Session)

1. **Session 1**: Flashcard UI + data hookups
2. **Session 2**: Analytics dashboard + charts
3. **Session 3**: Study roadmap + recommendations
4. Commit after each session

---

## QUICK WINS TO ADD WHILE YOU'RE AT IT

- Add FlashcardView to HomeView bottom section: "5 cards due today"
- Add quick link to StudyRoadmapView from exam countdown card
- Add "Recommended next action" banner on HomeView
- Wire up QuizView to add passed questions to flashcard deck

---

## Files Modified vs. Created

**New Files (7)**:
- FlashcardView.swift
- FlashcardCardView.swift
- AnalyticsView.swift
- PerformanceChartsView.swift
- StudyRoadmapView.swift
- StudyRecommendationView.swift
- IMPLEMENTATION_PLAN.md (this file)

**Modified Files (2)**:
- AppState.swift (add helper calculations)
- HomeView.swift (add quick links)

---

## Context For Next Session

Use this command to start fresh:
```bash
cd /home/user/john-project-vault
git pull origin claude/question-json-schema-rBkeX
```

Then reference this file for implementation details.
