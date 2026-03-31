# DuoLingo Clone with TypeScript, Tailwind, PostgresDB, Drizzle ORM & Stripe

### The Duolingo Clone is now Dockerized. You can use it in Docker via the instructions provided in the [Docker README](Docker-Readme.md).

### Tag-Based Deploy Pipeline with Jenkins, Kubernetes & ArgoCD. See the [Deploy README](Deploy-Readme.md).


https://github.com/ASISHGOUDA/duolingo_clone/assets/94213250/0890410d-0681-4342-9d96-cbb5999201c3
### Database Schema

```bash
https://github.com/ASISHGOUDA/duolingo_clone/blob/main/db/schema.ts
```
![diagram-export-5-27-2024-5_54_33-PM](https://github.com/ASISHGOUDA/duolingo_clone/assets/94213250/a410c373-ef76-4c2e-88ee-3f17fd67119c)


## Environment Variables

| Variable Name                  | Description                                      | Example Value                                                                                     |
|--------------------------------|--------------------------------------------------|---------------------------------------------------------------------------------------------------|
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | Clerk's publishable API key for public access   | `pk_test_1234567`                                   |
| `CLERK_SECRET_KEY`             | Clerk's secret API key for server-side access    | `sk_test_45433454651`                                              |
| `DATABASE_URL`                 | Connection URL for the PostgreSQL database       | `postgresql://Duolingo_owner:54654546352654165465` |
| `STRIPE_API_KEY`               | Stripe's secret API key                          | `sk_test_444564645654685`       |
| `NEXT_PUBLIC_APP_URL`          | URL where the Next.js app is hosted              | `http://localhost:3000`                                                                            |
| `STRIPE_WEBHOOK_SECRET`        | Stripe webhook secret for verifying events       | `whsec_455436565`                          |

## Setup Instructions

1. Clone the repository.
2. Create a `.env` file in the root directory of the project.
3. Copy the environment variables from the table above or from `.env.example` and paste them into the `.env ` file.
4. Replace the example values with your actual keys and URLs.
5. Run the project using `npm run dev` or your preferred command.

### Cloning the repository

```bash
https://github.com/ASISHGOUDA/duolingo_clone.git
```

