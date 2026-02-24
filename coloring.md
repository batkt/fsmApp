# 🎨 Project Coloring Guide

> Complete color reference for the **appweb** project.

---

## 1. Design System – CSS Custom Properties (HSL)

All core colors are defined as HSL values in `app/globals.css` and consumed via Tailwind in `tailwind.config.ts`.

### ☀️ Light Mode (`:root`)

| Token                      | HSL Value              | Preview (approx HEX) | Usage               |
| -------------------------- | ---------------------- | --------------------- | -------------------- |
| `--background`             | `0 0% 100%`           | `#FFFFFF`             | Page background      |
| `--foreground`             | `222.2 84% 4.9%`      | `#020817`             | Primary text         |
| `--card`                   | `0 0% 100%`           | `#FFFFFF`             | Card background      |
| `--card-foreground`        | `222.2 84% 4.9%`      | `#020817`             | Card text            |
| `--popover`                | `0 0% 100%`           | `#FFFFFF`             | Popover background   |
| `--popover-foreground`     | `222.2 84% 4.9%`      | `#020817`             | Popover text         |
| `--primary`                | `222.2 47.4% 11.2%`   | `#0F172A`             | Primary actions      |
| `--primary-foreground`     | `210 40% 98%`         | `#F8FAFC`             | Text on primary      |
| `--secondary`              | `210 40% 96.1%`       | `#F1F5F9`             | Secondary surfaces   |
| `--secondary-foreground`   | `222.2 47.4% 11.2%`   | `#0F172A`             | Text on secondary    |
| `--muted`                  | `210 40% 96.1%`       | `#F1F5F9`             | Muted surfaces       |
| `--muted-foreground`       | `215.4 16.3% 46.9%`   | `#64748B`             | Muted/placeholder    |
| `--accent`                 | `210 40% 96.1%`       | `#F1F5F9`             | Accent surfaces      |
| `--accent-foreground`      | `222.2 47.4% 11.2%`   | `#0F172A`             | Accent text          |
| `--destructive`            | `0 84.2% 60.2%`       | `#EF4444`             | Destructive/Error    |
| `--destructive-foreground` | `210 40% 98%`         | `#F8FAFC`             | Text on destructive  |
| `--border`                 | `214.3 31.8% 91.4%`   | `#E2E8F0`             | Borders              |
| `--input`                  | `214.3 31.8% 91.4%`   | `#E2E8F0`             | Input borders        |
| `--ring`                   | `222.2 84% 4.9%`      | `#020817`             | Focus rings          |
| `--radius`                 | `0.5rem`              | —                     | Border radius        |

### 🌙 Dark Mode (`.dark`)

| Token                      | HSL Value              | Preview (approx HEX) | Usage               |
| -------------------------- | ---------------------- | --------------------- | -------------------- |
| `--background`             | `222.2 84% 4.9%`      | `#020817`             | Page background      |
| `--foreground`             | `210 40% 98%`         | `#F8FAFC`             | Primary text         |
| `--card`                   | `222.2 84% 4.9%`      | `#020817`             | Card background      |
| `--card-foreground`        | `210 40% 98%`         | `#F8FAFC`             | Card text            |
| `--dialog`                 | `222.2 84% 4.9%`      | `#020817`             | Dialog background    |
| `--dialog-foreground`      | `210 40% 98%`         | `#F8FAFC`             | Dialog text          |
| `--popover`                | `222.2 84% 4.9%`      | `#020817`             | Popover background   |
| `--popover-foreground`     | `210 40% 98%`         | `#F8FAFC`             | Popover text         |
| `--primary`                | `210 40% 98%`         | `#F8FAFC`             | Primary actions      |
| `--primary-foreground`     | `222.2 47.4% 11.2%`   | `#0F172A`             | Text on primary      |
| `--secondary`              | `217.2 32.6% 17.5%`   | `#1E293B`             | Secondary surfaces   |
| `--secondary-foreground`   | `210 40% 98%`         | `#F8FAFC`             | Text on secondary    |
| `--muted`                  | `217.2 32.6% 17.5%`   | `#1E293B`             | Muted surfaces       |
| `--muted-foreground`       | `215 20.2% 65.1%`     | `#94A3B8`             | Muted/placeholder    |
| `--accent`                 | `217.2 32.6% 17.5%`   | `#1E293B`             | Accent surfaces      |
| `--accent-foreground`      | `210 40% 98%`         | `#F8FAFC`             | Accent text          |
| `--destructive`            | `0 62.8% 30.6%`       | `#7F1D1D`             | Destructive/Error    |
| `--destructive-foreground` | `210 40% 98%`         | `#F8FAFC`             | Text on destructive  |
| `--border`                 | `217.2 32.6% 17.5%`   | `#1E293B`             | Borders              |
| `--input`                  | `217.2 32.6% 17.5%`   | `#1E293B`             | Input borders        |
| `--ring`                   | `212.7 26.8% 83.9%`   | `#CBD5E1`             | Focus rings          |

---

## 2. Chart Colors

### ☀️ Light Mode Charts

| Token       | HSL Value         | Approx HEX  |
| ----------- | ----------------- | ------------ |
| `--chart-1` | `12 76% 61%`     | `#E37A4A`    |
| `--chart-2` | `173 58% 39%`    | `#2A9D8F`    |
| `--chart-3` | `197 37% 24%`    | `#264653`    |
| `--chart-4` | `43 74% 66%`     | `#E9C46A`    |
| `--chart-5` | `27 87% 67%`     | `#F4A261`    |

### 🌙 Dark Mode Charts

| Token       | HSL Value         | Approx HEX  |
| ----------- | ----------------- | ------------ |
| `--chart-1` | `220 70% 50%`    | `#2663D9`    |
| `--chart-2` | `160 60% 45%`    | `#2EB88A`    |
| `--chart-3` | `30 80% 55%`     | `#E09333`    |
| `--chart-4` | `280 65% 60%`    | `#A855F7`    |
| `--chart-5` | `340 75% 55%`    | `#E03670`    |

---

## 3. Hardcoded HEX Colors

Colors used directly in components (not via CSS variables).

### Login & Branding (`login-form.tsx`)

| Color       | HEX         | Usage                                   |
| ----------- | ----------- | --------------------------------------- |
| Green       | `#059669`   | Brand green — headings, buttons, borders |
| Slate       | `#64748B`   | Labels, input borders                   |
| Light BG    | `#F5F9FC`   | Login card background                   |

### Charts (`homeChart.tsx`, `homeChart2.tsx`)

| Color       | HEX         | Usage                                  |
| ----------- | ----------- | -------------------------------------- |
| Red         | `#F44336`   | Penalty / Алданги slice                |
| Teal        | `#00C49F`   | Paid / Нийт дүн slice                  |
| Orange      | `#FF8042`   | Secondary chart color                  |
| Red         | `#EF4444`   | Contract expiring ≤ 30 days            |
| Yellow      | `#FACC15`   | Contract expiring 31-90 days           |
| Green       | `#10B981`   | Contract > 90 days remaining           |
| Gray        | `#9CA3AF`   | No contract data                       |
| Orange      | `#F97316`   | Highlighted text (style attribute)     |

### Dark-mode Surfaces (`guest/`, `components/`)

| Color       | HEX         | Usage                                  |
| ----------- | ----------- | -------------------------------------- |
| Dark Navy   | `#0b1a2b`   | Modal backgrounds (dark mode)          |
| Dark Slate  | `#1a2332`   | Form backgrounds (dark mode)           |

### Financial Chart Section (globals.css)

| Color       | HEX         | Usage                                  |
| ----------- | ----------- | -------------------------------------- |
| Dark Blue   | `#2c3e50`   | Subtotal text                          |
| Blue        | `#1e88e5`   | Grand total & percentage text          |
| Light Blue  | `#e1f5fe`   | Subtotal background                    |
| Blue Tint   | `#bbdefb`   | Grand total background                 |
| Light Gray  | `#f0f0f0`   | Individual amount background           |
| Gray        | `#f5f5f5`   | Breakdown item background              |

---

## 4. Tailwind Utility Colors Used

### Semantic Status Colors (used across components)

| Tailwind Class            | Purpose                          |
| ------------------------- | -------------------------------- |
| `text-red-400/500`        | Error, urgent, expiring soon     |
| `bg-red-500`              | Notification dot, alert badge    |
| `text-orange-400/500`     | Warning, medium urgency          |
| `bg-orange-100/800`       | Warning badges                   |
| `text-green-400/500/600`  | Success, active, available       |
| `bg-green-50/500`         | Success backgrounds              |
| `text-blue-400/500/600`   | Info, links, active theme        |
| `bg-blue-50/500/900`      | Info backgrounds, active buttons |
| `text-purple-200`         | Notification bell icon           |
| `text-gray-400-800`       | Muted text, borders, secondary   |
| `bg-gray-50-950`          | Neutral backgrounds              |
| `text-amber-600`          | Warning (light mode)             |
| `bg-amber-50/500`         | Warning backgrounds              |
| `bg-slate-800-950`        | Dark mode surfaces               |

### Call Service Status Colors (`callService/page.tsx`)

| Status      | Text Color                          | BG Color                            | Dot Color                       |
| ----------- | ----------------------------------- | ----------------------------------- | ------------------------------- |
| Active      | `text-blue-600` / `text-blue-400`   | `bg-blue-50` / `bg-blue-500/10`    | `bg-blue-500`                   |
| Completed   | `text-green-600` / `text-green-400` | `bg-green-50` / `bg-green-500/10`  | `bg-green-500`                  |
| Cancelled   | `text-amber-600` / `text-red-400`   | `bg-amber-50` / `bg-red-500/10`    | `bg-amber-500` / `bg-red-500`   |
| Default     | `text-gray-600` / `text-gray-400`   | `bg-gray-50` / `bg-gray-500/10`    | `bg-gray-500`                   |

### Guest Time Remaining (`timeCalculations.ts`)

| Condition           | Class              |
| ------------------- | ------------------ |
| ≤ 30 min remaining  | `text-red-400`     |
| ≤ 60 min remaining  | `text-orange-400`  |
| > 60 min remaining  | `text-green-400`   |

---

## 5. Tailwind Config Color Map

Defined in `tailwind.config.ts` — all map to CSS custom properties above:

```
background  → hsl(var(--background))
foreground  → hsl(var(--foreground))
primary     → hsl(var(--primary))         + foreground
secondary   → hsl(var(--secondary))       + foreground
destructive → hsl(var(--destructive))     + foreground
muted       → hsl(var(--muted))           + foreground
accent      → hsl(var(--accent))          + foreground
popover     → hsl(var(--popover))         + foreground
card        → hsl(var(--card))            + foreground
border      → hsl(var(--border))
input       → hsl(var(--input))
ring        → hsl(var(--ring))
```

---

## 6. Color Usage Summary

| Category        | Source                          | Location                |
| --------------- | ------------------------------- | ----------------------- |
| Design System   | CSS custom properties (HSL)     | `app/globals.css`       |
| Tailwind Config | Token → CSS variable mapping    | `tailwind.config.ts`    |
| Charts          | Hardcoded HEX + CSS variables   | `homeChart.tsx`, `homeChart2.tsx`, `globals.css` |
| Login/Brand     | Hardcoded HEX                   | `login-form.tsx`        |
| Status colors   | Tailwind utility classes        | Various components      |
| Dark surfaces   | Hardcoded HEX (arbitrary)       | `guest/` modals         |
| Financial UI    | Hardcoded HEX                   | `globals.css`           |
