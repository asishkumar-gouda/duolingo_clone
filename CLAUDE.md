# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev          # Start dev server (localhost:3000)
npm run build        # Production build
npm run lint         # ESLint
npm run db:push      # Push schema changes to database (npx drizzle-kit push)
npm run db:studio    # Open Drizzle Studio GUI
npm run db:seed      # Seed database with sample data (tsx ./scripts/seed.ts)
npm run db:reset     # Reset database (tsx ./scripts/reset.ts)
npm run db:prod      # Production seed (tsx ./scripts/prod.ts)
```

Docker: `docker-compose up --build` runs the app (port 3000), Postgres, and Caddy reverse proxy.

## Architecture

Next.js 14 App Router with Clerk auth, Drizzle ORM on Neon Postgres, Stripe subscriptions, and Zustand for client state.

### Route Groups

- **`app/(marketing)/`** — Public landing page with Clerk sign-in/sign-up modals
- **`app/(main)/`** — Authenticated shell with sidebar. Contains `/learn`, `/courses`, `/shop`, `/quests`, `/learderboard` (note: typo in folder name)
- **`app/lesson/`** — Full-screen quiz experience. `quiz.tsx` is the main client component. `/lesson/[lessonId]` for specific lessons, `/lesson` for the current active lesson
- **`app/admin/`** — react-admin dashboard (client-only, dynamically imported). Gated by `lib/admin.ts` which checks Clerk userId against a hardcoded allowlist
- **`app/api/`** — REST CRUD endpoints for admin panel + Stripe webhook at `/api/webhooks/stripe`

### Data Model (db/schema.ts)

Hierarchy: **courses → units → lessons → challenges → challengeOptions**

Parallel tracking tables:
- **challengeProgress** — per-user completion of individual challenges
- **userProgress** — hearts (max 5), points (XP), active course link. Primary key is Clerk `userId`
- **userSubscription** — Stripe subscription data; active = `stripePriceId` exists and `stripeCurrentPeriodEnd + 1 day > now`

### Data Access (db/queries.ts)

All queries are wrapped in React `cache()` for request-level deduplication. Key queries:
- `getUserProgress` / `getUserSubscription` — used on nearly every authenticated page
- `getUnits` — loads full unit→lesson→challenge→progress tree for the active course
- `getCourseProgress` — finds the first uncompleted lesson to determine `activeLesson`
- `getLesson(id?)` — loads a specific lesson with challenges, options, and completion status

Pages use `Promise.all` to run multiple cached queries in parallel before rendering.

### Server Actions (actions/)

- **`upsertUserProgress(courseId)`** — sets active course, creates or updates user record
- **`upsertChallengeProgress(challengeId)`** — records correct answer (+10 XP; +1 heart if practicing)
- **`reduceHearts(challengeId)`** — wrong answer (-1 heart; skipped for practice/subscribers)
- **`refillHearts()`** — spend 10 points to restore hearts to 5
- **`createStripeUrl()`** — creates Stripe checkout ($20/mo) or billing portal session

All actions call `revalidatePath()` on affected routes after mutations.

### Hearts & Subscription System

Users start with 5 hearts. Wrong answers cost 1 heart. At 0 hearts, the lesson blocks (unless subscribed). Hearts can be refilled for 10 XP in the shop, or bypassed entirely with a Stripe subscription. Practicing already-completed lessons earns +1 heart per correct answer.

### Client State (store/)

Three Zustand stores control modal visibility: `useExitModal`, `useHeartsModal`, `usePracticeModal`. These are rendered at the root layout level and triggered from the quiz component.

### Middleware

Clerk's `authMiddleware` protects all routes except `/` and `/api/webhooks/stripe`.

## Environment Variables

Required in `.env` (see `.env.example`): `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`, `DATABASE_URL`, `STRIPE_API_KEY`, `STRIPE_WEBHOOK_SECRET`, `NEXT_PUBLIC_APP_URL`. Docker Compose also uses `DB_USER`, `DB_PASSWORD`, `DB_NAME`.

## Key Conventions

- Database connection uses `@neondatabase/serverless` with `drizzle-orm/neon-http` (db/drizzle.ts)
- UI components from shadcn/ui live in `components/ui/`; app-level components in `components/`
- Admin API routes check `isAdmin()` from `lib/admin.ts` — hardcoded Clerk user ID allowlist
- The `next.config.mjs` sets CORS headers on `/api/*` and uses `output: "standalone"` for Docker
- Font: Nunito (Google Fonts, loaded in root layout)
