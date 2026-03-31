import { Button } from "@/components/ui/button";
import { 
    ClerkLoaded,
    ClerkLoading,
    SignInButton,
    SignUpButton,
    SignedIn,
    SignedOut,
    
  } from "@clerk/nextjs";
import { Loader } from "lucide-react";
import Link from "next/link";
import Image from "next/image";



export default function Home() {
  return (
    <>
    <div className="max-w-[988px] mx-auto flex-1 w-full flex flex-col lg:flex-row items-center justify-center p-4 gap-2">
      <div className="relative w-[240px] h-[240px] lg:w-[424px] lg:h-[424px] mb-8  lg-mb-0">
        <Image
          src="/duo.svg"
          fill 
          alt="Hero"
          // width={424}
          // height={424}
        />
      </div>
      <div className="flex flex-col items-center gap-y-8">
        <h1 className="text-xl lg:text-3xl font-bold text-neutral-600 max-w-[480px] text-center">
          Learn, Practice, and master new languages with Duo 🐥 !!
        </h1>
        <div className="flex flex-col items-center gap-y-3 max-w-[330px] w-full">
          <ClerkLoading>
            <Loader className="h-5 w-5 text-muted-foreground animate-spin"/>
          </ClerkLoading>
          <ClerkLoaded>
              <SignedOut>
                <SignUpButton 
                mode="modal"
                afterSignInUrl="/learn"
                afterSignUpUrl="/learn">
                  <Button size="lg" variant="secondary" className="w-full">
                    Get Started
                  </Button>
                </SignUpButton>
                <SignInButton 
                mode="modal"
                afterSignInUrl="/learn"
                afterSignUpUrl="/learn">
                  <Button size="lg" variant="primaryOutline" className="w-full">
                      I already have an account
                  </Button>
                </SignInButton>
              </SignedOut>
              <SignedIn>
                <Button size="lg" variant="secondary" className="w-full" asChild>
                  <Link href="/learn">
                  Continue Learning
                  </Link>
                </Button>
              </SignedIn>
            </ClerkLoaded>
          
        </div>
      </div>
    </div>
    <div className="absolute bottom-4 right-4">
        <span className="text-xs text-neutral-400 bg-neutral-100 px-2 py-1 rounded-full">
          v1.0.1
        </span>
      </div>
    </>
  );
}
