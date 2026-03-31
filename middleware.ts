import { authMiddleware } from "@clerk/nextjs";

export default authMiddleware({
  publicRoutes:["/", "/api/webhooks/stripe", "/api/health"],
});

export const config = {
  matcher: ["/((?!.+.[w]+$|_next).*)", "/", "/(api|trpc)(.*)"],
};