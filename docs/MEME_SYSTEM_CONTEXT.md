# Meme Generation System — Project Context (Mobile + Web + Backend)

This document defines, clearly and permanently, the **product mission, main flow, conceptual chain, principles, technical boundaries, and development rules** for the meme generation system. All technical decisions on the mobile side must align with this framework.

---

## 1. Project mission

We are building a **single unified system** with:

1. **Mobile app** — current focus  
2. **Website / web panel**  
3. **Shared backend, data, and AI pipeline**

The mobile app and web must operate on **the same backend logic and data contracts** (API models, field names, states). Today the focus is **mobile**, but architecture and contracts must be chosen so future **web integration is not blocked**.

---

## 2. Core product flow

The main user journey is:

1. The user opens the app.  
2. The user pastes a **Telegram channel link**.  
3. The system **ingests** content from that channel.  
4. AI analyzes the content:  
   - which **topics** appear,  
   - **recurring themes**,  
   - **emotional tone**,  
   - **audience signals** (who it speaks to),  
   - **visual patterns**,  
   - **image / media types**,  
   - **potential viral angles**.  
5. The system turns raw channel content into **MEMOTYPE**:  
   - core meaning,  
   - hook,  
   - topic,  
   - cultural angle,  
   - emotional trigger.  
6. The system generates **meme ideas** from those memotypes.  
7. The system maps ideas to **PHENOTYPE**:  
   - meme **caption**,  
   - **image prompt** (for generation),  
   - **short post text**,  
   - **short video idea**,  
   - **platform-specific format** (e.g. aspect ratio, duration, style notes).  
8. The system prepares outputs for **multiple social platforms**.  
9. Over time, the system collects **analytics**:  
   - views, likes, shares, comments, saves, engagement patterns.  
10. The system supports **iteration**:  
    - what worked,  
    - what failed,  
    - what should be **regenerated**.

Anything that does not break this chain but only adds “decoration” or UI convenience is acceptable if it aligns with the product vision. The **core product value** comes from this flow.

---

## 3. Conceptual rule (chain)

The product must always follow this **single chain**:

```
SOURCE CONTENT
  → ANALYSIS
  → MEMOTYPE
  → MEME IDEA
  → PHENOTYPE
  → PLATFORM ADAPTATION
  → DISTRIBUTION
  → ANALYTICS
  → ITERATION
```

Canonical English reference (for shared contracts):

`SOURCE CONTENT → ANALYSIS → MEMOTYPE → MEME IDEA → PHENOTYPE → PLATFORM ADAPTATION → DISTRIBUTION → ANALYTICS → ITERATION`

Without a **clear user or team request**, do not design or implement “random screens”, ad-hoc features, or standalone modules **outside** this chain.

---

## 4. Non-negotiable product principles

### 4.1 Audience-first

Every generated output must tie to a **target audience**, not context-free “generic jokes”. The **audience signal** from channel + analysis must be respected.

### 4.2 Emotion-first

High-virality content usually carries a **strong emotional trigger**: surprise, absurdity, recognition, tension, irony, delight, etc. The system must not ignore this dimension.

### 4.3 Platform-native adaptation

The same text / same image must not be presented identically everywhere. **Telegram, TikTok, Instagram, X, Threads, VK**, etc. imply different **format, length, tone, and CTA** expectations. Even with a shared meme idea, **visible expression (phenotype)** should diverge by platform.

### 4.4 Meme = meaning + form

- **MEMOTYPE**: the **abstract** layer carrying idea, meaning, hook, and cultural angle.  
- **PHENOTYPE**: **visible** expression — caption, image, video script, platform-specific format.

Mixing both in one undifferentiated data shape will complicate web and A/B testing later. Prefer **separate but linked** models when possible.

### 4.5 Iterative system

This is not “generate once and finish”. Architecture must be able to grow with **versioning, retries, partial success, and analytics feedback**.

### 4.6 Ethics and safety

- Do not promote hate speech, discrimination, targeted harassment, or illegal incitement.  
- **Plagiarism** and verbatim source copying are not the value proposition; transformation and original output are the goal.  
- AI and content policies may expand later; the mobile client should leave room for **moderation / safety signals** aligned with the backend.

---

## 5. Technical architecture rules

### 5.1 Mobile now, shared later

Modules should assume the **same backend** will eventually serve the web. Avoid narrowing contracts under “as long as it works on mobile”.

### 5.2 Separation of concerns

Where possible, keep these layers distinct:

- **Presentation (UI)**  
- **Application / use-cases** (orchestration, single steps)  
- **Domain / models** (memotype, phenotype, platform adaptation)  
- **Infrastructure** (API client, storage, tokens)  
- **AI orchestration** (prompt chains, stepwise results)

In a small MVP some layers may live in the same file; still maintain a **conscious conceptual boundary**.

### 5.3 Reusable contracts

JSON field names, enums, error codes, and “pipeline step” fields should be clear enough for **web consumption**. Otherwise you get duplicate APIs and divergent error handling.

### 5.4 No hardcoded chaos

Avoid embedding business rules, prompt templates, or “on this platform always do X” logic **directly in UI components**. At least colocate them in use-case or domain code.

### 5.5 State clarity

For **every asynchronous AI step**, define meaningful states that can surface to the user (or logs):

- idle  
- loading  
- success  
- partial success  
- empty result  
- error  
- retryable error  

### 5.6 Traceable pipeline

The app should eventually expose a progress model so the user understands **where they are**. Example stages:

`link received → channel analyzed → ideas generated → assets prepared → ready to publish → analytics received`

This helps UX, debugging, and “where did we get stuck?” analysis.

---

## 6. Current functional scope for the app (context only)

The following are **expected future** areas for the app; **this document is not an automatic build order:**

- Telegram channel link input  
- Channel analysis result  
- Extracted topic / media overview  
- Generated meme ideas  
- Generated meme asset preview  
- Per-platform adaptation preview  
- Publishing / export preparation  
- Analytics overview  
- Iteration / regeneration actions  

**Guidance:** Do not proactively implement these modules until a feature is requested; keep the context in mind and leave room in the architecture.

---

## 7. Development behavior rules for future tasks

For each coding / refactor task, preferably:

1. **Restate the requested work** in one or two sentences.  
2. **Name files or directories** you plan to touch upfront.  
3. Keep changes **minimal and scoped**.  
4. Preserve **compatibility** with the overall pipeline and shared contracts.  
5. Do not **invent** unsolicited product features.  
6. Prefer **extensible** structure (without bloat) over quick hacks.  
7. If you make a decision that affects **web** or shared APIs, briefly explain why.

---

## 8. Related project files

- Short mandatory agent rule: **`.cursor/rules/00_meme_system_context.mdc`**  
- This detailed document: **`docs/MEME_SYSTEM_CONTEXT.md`**

If the rule and this document conflict, **product mission and chain (sections 2–3)** take precedence; then update the architecture sections for consistency.

---

*Last update: created as a fixed context file alongside project setup.*
