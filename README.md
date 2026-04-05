# 📊 Advertising Funnel Analysis

> Identifying conversion bottlenecks and actionable growth levers across a paid social media campaign dataset of 300,000+ ad events.

---

## Problem Statement

A digital marketing agency running paid campaigns on Facebook and Instagram needed to understand **where users drop off** in the conversion funnel — and why. With budgets spread across platforms, ad formats, and audience segments, the key question was: *what's actually driving purchases, and what's wasting spend?*

---
## Approach

Built a star-schema relational database in MySQL from a synthetic dataset of 10,000+ events, then answered 14 analytical questions covering the full user journey (Impression → Click → Engagement → Purchase). Results were visualized in Power BI across four thematic dashboards.

**Tools & Techniques**
`MySQL` · `Power BI` · `Python (Pandas, NumPy)` · `CTEs` · `Window Functions` · `Star Schema`

---

## Key Findings
| Area | Finding |
|---|---|
| 🔻 Critical bottleneck | 77.9% of engaged users never purchase |
| 📱 Best platform | Facebook converts at ~10.5% vs Instagram's ~7% |
| 🎯 Best ad format | Stories (6.6%) outperform Video (3.4%) by nearly 2x |
| 👥 Highest-value audience | Ages 35–54 + Technology/Gaming interests (~20% conversion) |
| 📅 Best timing | Thursday mornings (13.1% conversion) |
| ⏱ Purchase window | 43-day average — short campaigns miss most converters |

---
## Business Recommendations

1. **Launch retargeting** for users who engaged but didn't purchase — this single lever targets the 77.9% drop-off
2. **Reallocate budget toward Facebook** — ~50% higher conversion ROI
3. **Shift video spend to Stories format** — +3.2pp conversion lift, lower production cost
4. **Set 45–90 day retargeting windows** to align with the actual purchase journey

---

## Project Structure

```
├── use_case/       project brief and business context
├── data/
│   ├── raw/        original uncleaned dataset
│   └── cleaned/    processed data ready for analysis
├── etl/            data cleaning and transformation scripts (Python)
├── sql/            14 analytical queries with CTEs
├── dashboards/     both Power BI (.pbix) file and (PDF)
└── report/         full insights report (PDF)
```

---
*Dataset is synthetic, generated with Faker + NumPy to simulate realistic campaign behavior without personal data.*


