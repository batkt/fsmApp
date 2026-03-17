# Frontend Implementation Guide: Task Scheduling

This document details how to integrate the new task scheduling features (`startDate`, `endDate`, `isDay`, `isLoop`) into the mobile or web frontend.

## API Schema Updates

When creating or updating a task, the following new fields should be included in the request body:

| Field | Type | Description |
| :--- | :--- | :--- |
| `ekhlekhOgnoo` | `Date` (ISO) | The starting date of the task. |
| `duusakhOgnoo` | `Date` (ISO) | The ending date of the task. |
| `isDay` | `Boolean` | Set to `true` if the task spans the full day(s). |
| `isLoop` | `Boolean` | Set to `true` if the task repeats daily within the date range. |

## Feature Logic

### 1. Full Day Mode (`isDay`)
When the user toggles **"Full Day"** on:
- The Time Pickers for "Start Time" and "End Time" should be disabled or hidden.
- The frontend should send the selected dates in `ekhlekhOgnoo` and `duusakhOgnoo`.
- The backend will automatically normalize the hours to `00:00` and `23:59`.

### 2. Looping Tasks (`isLoop`)
- **Continuous (Off)**: The task is a single block from start date/time to end date/time.
- **Daily Loop (On)**: The task represents a specific work window (e.g., 09:00 - 10:00) that repeats every day between the `startDate` and `endDate`.

---

## Suggested UI Design

### Scheduling Section Mockup
> [!TIP]
> Use a clean, card-based layout for the scheduling section to group these related controls.

```text
[📅 Click to select Date Range ]
(Shows a calendar picker for Start and End dates)

[ 🔘 Full Day ] —————— (Switch/Toggle)
   (If OFF: Show Time Pickers)
   [ 🕒 Start Time ] [ 🕒 End Time ]

[ 🔁 Repeat Daily ] ——— (Switch/Toggle)
   (Help text: "Task occurs every day within this range")
```

### Visual Feedback
- **Expired State**: If the current date is past `duusakhOgnoo` (for loops) or `duusakhTsag` (for continuous), the UI should clearly mark the task status as "Time Expired" (Хугацаа хэтэрсэн) with a **red** indicator.
- **Active State**: Use a **green** or **blue** indicator if the task is currently within its scheduled window.

---

## Implementation Checklist
- [ ] Update Task Model/Interface in frontend code.
- [ ] Add Date Range Picker to Task Creation/Edit screen.
- [ ] Add "Full Day" and "Daily Repeat" toggles.
- [ ] Handle conditional visibility of Time Pickers based on `isDay` state.
- [ ] Ensure ISO strings are sent to the backend.
