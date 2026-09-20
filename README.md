# Prism

**Save what inspires you. Work toward what matters.**

Prism is an intentional-spending assistant that turns social-media inspiration into clear priorities, achievable goals, and informed spending decisions.

> From “I want this” to “I’m making it happen.”

Core loop:

> **Save → Sort into collections → Reflect → Review (buy or let go) → Set a goal → Make progress → Learn (Money Story)**

See [docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md) for the full product direction.

---

## Problem statement

Social media has become a shopping and lifestyle discovery engine, especially for Gen Z. People constantly save products, restaurants, trips, events, and experiences across Instagram, TikTok, Pinterest, and YouTube, but those saves remain fragmented, unstructured, and disconnected from their financial goals.

This creates a gap between inspiration and intentional action. Users know what catches their attention, but not:

- what they genuinely value;
- what they can realistically afford;
- which ideas deserve to become goals;
- what they would have to trade off; or
- whether social media is producing short-lived impulses or meaningful aspirations.

Existing bookmarking tools help people remember what they saw, while budgeting apps explain what they already spent. Neither helps users evaluate a desire before the money leaves their account.

This is a meaningful and growing problem. In a 2025 survey, 41% of Gen Z respondents said they turn to social platforms first when searching for information, ahead of traditional search engines. Numerator also reports that 44% of Gen Z shoppers made a purchase through social media in the previous month and that Gen Z shoppers are 82% more likely than the average consumer to say social media and digital advertising influence their purchasing decisions.

Sources: [Sprout Social](https://investors.sproutsocial.com/news/news-details/2025/New-Research-from-Sprout-Social-Finds-Social-Media-is-the-Top-Place-Gen-Z-Turns-to-for-Search-Surpassing-Traditional-Search-Engines/default.aspx) and [Numerator](https://www.numerator.com/gen-z-consumer-behavior/).

---

## Solution

Prism provides a decision layer between social-media discovery and financial action.

Users share or paste a link into Prism. Prism turns that unstructured post into a structured aspiration with:

- an image, title, and description (MVP: local mock AI text; real generation is planned);
- source attribution and tags;
- a classification such as Product, Experience, Trip, Place, or Event;
- an estimated or manually entered cost; and
- the user’s priority, timing, motivation, notes, and feeling attached.

Users can keep an aspiration as inspiration or convert it into an actionable goal. Prism then helps them:

1. Define a target amount and date.
2. Plan contributions and milestones.
3. Track financial, planning, and behavioral progress.
4. Attach additional saves to the goal.
5. Understand how a potential purchase would affect active goals.
6. Choose whether to purchase, defer, find an alternative, or redirect money toward a goal.

**My Money Story** turns these decisions into a personalized Weekly / Monthly / Over time narrative — what caught attention, what stayed meaningful, how goals progressed, and whether choices aligned with stated priorities. (MVP ships the full recreation layout; some sections still use demo narrative data — see [docs/MONEY_STORY_REAL_DATA.md](docs/MONEY_STORY_REAL_DATA.md).)

### What makes Prism different

> Pinterest knows what users like. Social platforms know what captures their attention. Banks know what they purchased. Prism understands the journey between attention, intention, and spending.

Prism is not a budgeting app with a saving feature. It is an intentional-shopping and goal-planning assistant with financial context.

### What Prism deliberately does not do

- Connect bank accounts or request balances
- Calculate disposable income or affordability
- Provide financial advice
- Scrape Instagram, TikTok, Pinterest, or retailer pages
- Treat estimated prices of let-go items as “money saved”
- Move or manage money
- Decide what you can afford

All money figures are **user-entered** and labeled **confirmed** or **estimated**.

### Spending pocket

Optionally set how much you are comfortable spending on wants this month. Prism can preview how an estimate fits that guardrail. Confirmed purchases reduce remaining for the calendar month. You can change, pause, or ignore the pocket anytime.

---

## Ideal customer profile

Prism’s initial customer is a U.S.-based Gen Z adult, approximately 18–29 years old, who frequently discovers products and experiences through social media and wants to make more intentional spending decisions.

They are likely to:

- save posts from Instagram, TikTok, Pinterest, or YouTube several times per week;
- save a mixture of products, restaurants, activities, events, and travel ideas;
- maintain scattered wishlists or collections across multiple platforms;
- have limited discretionary income or several competing goals;
- want to travel, attend events, improve their lifestyle, or make meaningful purchases;
- find traditional budgeting apps reactive, restrictive, or disconnected from their aspirations;
- be comfortable using AI for organization and recommendations but cautious about sharing financial data; and
- prefer visual, personalized guidance over spreadsheets and rigid budgets.

### Core customer need

> “I see things I want all day, but I need help deciding what is actually worth my money and how to make the important ones happen.”

### Initial early-adopter segment

The strongest early adopter is a socially influenced, goal-oriented Gen Z woman aged 18–27 who saves travel, fashion, wellness, restaurant, and lifestyle content; has a moderate but limited discretionary budget; and is already balancing everyday spending with larger goals.

### Current alternatives and their limitations

| Alternative | Limitation |
| --- | --- |
| Instagram and TikTok saves | Fragmented by platform and disconnected from cost or goals |
| Pinterest | Strong for inspiration but offers limited financial context |
| Notes and spreadsheets | Manual, high-effort, and disconnected from discovery |
| Retailer wishlists | Product-focused and typically limited to one retailer |
| Budgeting apps | Explain spending after it occurs instead of evaluating desires beforehand |
| “Save for later” carts | Designed to increase conversion rather than support intentional decisions |

---

## Total addressable market estimate

For a transparent bottom-up estimate, Prism focuses on U.S. Gen Z consumers whose shopping behavior is influenced by social media.

The United States has approximately **70 million Gen Z consumers**. Numerator reports that **44% of Gen Z shoppers made a social-media purchase in the previous month**. Using that percentage as a proxy for Prism’s most relevant audience:

```
70 million × 44% = 30.8 million potential users
```

At a hypothetical Prism Plus subscription price of **$5 per month**, or **$60 per year**:

```
30.8 million × $60 = $1.848 billion annually
```

### Market summary

| Market | Assumption | Potential users | Annual revenue opportunity |
| --- | --- | ---: | ---: |
| TAM | U.S. Gen Z social shoppers | 30.8 million | $1.85 billion |
| SAM | Initial early-adopter segment, estimated as 10% of TAM | 3.08 million | $184.8 million |
| Illustrative SOM | 50,000 paying users | 50,000 | $3 million |

This estimate is directional. The 44% figure measures recent social-media purchasers, not confirmed willingness to pay for Prism. It also excludes potential affiliate revenue, financial-institution partnerships, workplace financial-wellness programs, international expansion, and users outside Gen Z.

Population and behavior sources: [Annie E. Casey Foundation](https://www.aecf.org/blog/generation-z-statistics) and [Numerator](https://www.numerator.com/gen-z-consumer-behavior/).

### Business model (planned)

- **Free:** Save and organize inspiration, create a limited number of goals, and receive basic insights.
- **Prism Plus:** Unlimited goals, advanced Money Stories, goal forecasting, collaborative planning, price updates, and optional account-linked insights.
- **Affiliate revenue:** Earn a commission when a user intentionally books or purchases through Prism.
- **Future partnerships:** Contextual pre-purchase guidance through financial institutions, employee financial-wellness programs, or commerce platforms.

StoreKit / premium is **not** in the current local MVP.

---

## How to access the app (local MVP)

The shipping prototype is a **native iOS app** (SwiftUI + SwiftData). It runs entirely on-device. Sign in with Apple and Supabase are stubbed for a later phase.

### Requirements

- macOS with **Xcode 16+**
- **iOS 17+** Simulator (or a physical iPhone)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### 1. Clone and generate the project

```bash
git clone https://github.com/jasminekaur/prism.git
cd prism

# Regenerate the Xcode project and ensure Assets ship in the bundle
xcodegen generate && python3 scripts/ensure-resources.py

open Prism.xcodeproj
```

If `Prism.xcodeproj` already exists and builds cleanly, you can open it directly; regenerating with `xcodegen` is still recommended after pulling `project.yml` changes.

### 2. Select the scheme and destination

In Xcode:

1. Scheme: **Prism**
2. Destination: an **iPhone 16** (or any iOS 17+) Simulator, or your physical device
3. Product → Run (`⌘R`)

Optional CLI build:

```bash
xcodebuild -scheme Prism -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' build

# Unit tests
xcodebuild -scheme Prism -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' test -only-testing:PrismTests
```

### 3. First launch — explore locally

1. Complete onboarding (brand + intro pages).
2. Tap **Explore locally** to enter **demo mode** (no account required).
3. Demo data may seed sample saves and goals so the Home / Goals / Money Story tabs are populated.

### 4. Walk the core loop

| Tab / surface | What to try |
| --- | --- |
| **Home** | Browse saves; open an item; edit why / feeling attached; paste a new link via **+** |
| **Collections** | Create a collection; **Sort** (swipe keep/delete); open **Review** |
| **Goals** | Open the lead goal; **Add progress**; start **New goal** |
| **Money Story** | Switch Weekly / Monthly / Over time |
| **Settings** | From the Home profile control — export / delete local data |

### 5. Share Extension (optional)

Target `PrismShareExtension` is scaffolded.

- Bundle IDs: `com.jasminekaur.prism` / `com.jasminekaur.prism.share`
- Configure App Group `group.com.jasminekaur.prism` on both targets before expecting Share → Prism to work on a physical device

See [TESTFLIGHT_CHECKLIST.md](TESTFLIGHT_CHECKLIST.md) for signing, App Groups, and TestFlight steps.

### Physical device (free Apple ID)

With a free Apple ID you can sideload from Xcode onto your phone (signing expires ~7 days). Paid Apple Developer Program is required for TestFlight / remote beta links.

1. Xcode → Prism target → Signing & Capabilities → select your **Team**
2. Plug in the iPhone, trust the computer, enable Developer Mode if prompted
3. Run on the device; on first launch, Settings → General → VPN & Device Management → trust the developer

---

## Technical approach (current MVP)

| Layer | Choice |
| --- | --- |
| UI | SwiftUI |
| Persistence | SwiftData (on-device) |
| Architecture | MVVM + repository protocols + domain services |
| Design | Prism tokens (Fraunces / Figtree / Encode Sans / Inter), glass UI, atmospheric backdrop |
| IA | 4 tabs: Home · Collections · Goals · Money Story; Review & Settings off-tab |
| AI descriptions | Local mock for MVP; real generation is Future |
| Cloud | Supabase + Sign in with Apple stubbed — see [SUPABASE_SETUP.md](SUPABASE_SETUP.md) |

UI source of truth for screens: `Prism App Screens Recreation/`.

Project layout: [ARCHITECTURE.md](ARCHITECTURE.md). Scope: [docs/MVP_SCOPE.md](docs/MVP_SCOPE.md).

### Configuration

Copy [`.env.example`](.env.example) when cloud is enabled. Never commit service-role keys.

---

## Documentation

| Doc | Purpose |
| --- | --- |
| [docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md) | Positioning, IA, Money Story rules |
| [docs/MVP_SCOPE.md](docs/MVP_SCOPE.md) | Must / nice / skipped / implemented |
| [docs/MONEY_STORY_REAL_DATA.md](docs/MONEY_STORY_REAL_DATA.md) | Wiring Money Story aggregates |
| [docs/HANDOFF_FEATURES.md](docs/HANDOFF_FEATURES.md) | Feature handoff notes |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layers, sync policy |
| [SECURITY.md](SECURITY.md) | Security practices |
| [PRIVACY.md](PRIVACY.md) | Privacy & retention |
| [SUPABASE_SETUP.md](SUPABASE_SETUP.md) | Deferred backend |
| [TESTFLIGHT_CHECKLIST.md](TESTFLIGHT_CHECKLIST.md) | Shipping checklist |

---

## Known limitations (local MVP)

- No cloud sync or Sign in with Apple (UI stub only)
- Share Extension needs App Group provisioning to work on device
- Images only (no in-app video playback)
- AI item descriptions are **mock**, not live model calls
- Money Story UI is complete; some narrative sections still use **demo** aggregates
- StoreKit / premium not implemented
