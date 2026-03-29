# Advertising Funnel Analysis

**End-to-end data analytics project** — database design, ETL, SQL analysis, Power BI dashboards, and a written insights report.

---

## The problem

A digital marketing agency runs paid campaigns across Facebook and Instagram. Users move through a funnel:  
**Impression → Click → Engagement → Purchase**

The business question: *where does the funnel break, and how do we fix it?*

---

## Key findings

- **18.53% overall conversion rate** (impression to purchase)
- **77.91% drop-off** at Engagement → Purchase — the critical bottleneck
- Facebook converts ~50% better than Instagram
- Stories ads outperform all formats at 6.6% vs 3.4% for video
- 35–54 age group + Technology/Gaming interests = highest-converting audience
- Thursday mornings are the best time slot for conversion-focused ads
- Average time to purchase: **43 days** — campaigns need long retargeting windows
- Engaged users (likes/comments/shares) barely outconvert non-engaged users (18.60% vs 18.20%)

---

## Project structure

```
advertising-funnel-analysis/
│
├── dashboards/
│   └── funnel_dashboard.pbix
│
├── data/
│   ├── raw/
│   └── cleaned/
│
├── etl/
│   └── etl_pipeline.py
│
├── sql/
│   └── analysis_queries.sql
│
├── report/
│   └── insights_report.pdf
│
├── use_case/
│   └── use_case.md
│
└── README.md
```



---

## Why this project

I wanted to build something that mirrors what a data analyst actually does in a business — not just explore a dataset, but model a process, ask real business questions, and turn query results into decisions.

Funnel analysis was chosen because every insight directly impacts revenue and marketing performance.

---

## Skills demonstrated

`MySQL` `Star Schema Design` `CTEs` `Window Functions` `ETL` `Power BI` `Data Analysis` `Data Storytelling`


