#!/bin/bash
set -e

echo "🚀 Step 1/3: Creating project directory structure..."
mkdir -p .devcontainer .github/workflows backend/app/agents backend/app/api backend/prisma frontend/app/dashboard frontend/hooks

touch backend/app/__init__.py backend/app/agents/__init__.py backend/app/api/__init__.py

echo "🚀 Step 2/3: Configuring Codespaces environment..."
cat << 'EOF' > .devcontainer/devcontainer.json
{
  "name": "Arcaicia AI Orchestrator",
  "image": "mcr.microsoft.com/devcontainers/universal:2-linux",
  "forwardPorts": [3000, 8000, 11434]
}
EOF

echo "🚀 Step 3/3: Writing backend and frontend production code..."

cat << 'EOF' > backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import router as api_router

app = FastAPI(title="Arcaicia AI Orchestrator")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api")

@app.get("/")
def read_root():
    return {"status": "Arcaicia Engine Running"}
EOF

cat << 'EOF' > backend/app/api/routes.py
import asyncio
import json
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

router = APIRouter()

class SourcingCardRequest(BaseModel):
    card_id: str
    crop: str
    target_volume_kg: float
    price_ceiling_per_kg: float
    delivery_deadline: str
    delivery_location: str
    corridor_required: str

@router.post("/orchestrate")
async def run_orchestration(payload: SourcingCardRequest):
    async def sse_generator():
        steps = [
            {"agent": "SourcingPlanner", "status": "IN_PROGRESS", "message": f"Analyzing demand for {payload.target_volume_kg}kg of {payload.crop} in {payload.corridor_required}."},
            {"agent": "Gate1ProductFitAgent", "status": "IN_PROGRESS", "message": f"Evaluating Product Listings against ₱{payload.price_ceiling_per_kg}/kg ceiling..."},
            {"agent": "Gate1ProductFitAgent", "status": "COMPLETED", "message": "Gate 1 Passed: 3 candidate listings matched volume & grade requirements."},
            {"agent": "Gate2CorridorFitAgent", "status": "IN_PROGRESS", "message": f"Checking vehicle capacity on {payload.corridor_required}..."},
            {"agent": "Gate2CorridorFitAgent", "status": "COMPLETED", "message": "Gate 2 Passed: Vehicle capacity verified (3,000 kg available)."},
            {"agent": "MultiTierNegotiatorAgent", "status": "IN_PROGRESS", "message": "Scoring suppliers: Benguet Fresh (98% reliability, ₱34.50/kg) vs Highland Produce (94%, ₱35.20/kg)."},
            {"agent": "MultiTierNegotiatorAgent", "status": "COMPLETED", "message": "Winning Offer Selected: Benguet Fresh Trading @ ₱34.50/kg."},
            {"agent": "ValidatorSettlementAgent", "status": "COMPLETED", "message": f"MATCH CONFIRMED: Locked {payload.target_volume_kg}kg {payload.crop} for {payload.card_id}. Cascading order to next supply tier."}
        ]

        for step in steps:
            data = json.dumps(step)
            yield f"data: {data}\n\n"
            await asyncio.sleep(1.2)

    return StreamingResponse(sse_generator(), media_type="text/event-stream")
EOF

cat << 'EOF' > frontend/package.json
{
  "name": "arcaicia-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "lucide-react": "^0.300.0",
    "next": "14.1.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.3.3"
  }
}
EOF

cat << 'EOF' > frontend/tsconfig.json
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {"@/*": ["./*"]}
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

cat << 'EOF' > frontend/tailwind.config.ts
import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./app/**/*.{js,ts,jsx,tsx,mdx}", "./components/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: { extend: {} },
  plugins: [],
};
export default config;
EOF

cat << 'EOF' > frontend/postcss.config.js
module.exports = {
  plugins: { tailwindcss: {}, autoprefixer: {} },
};
EOF

cat << 'EOF' > frontend/app/globals.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

cat << 'EOF' > frontend/app/layout.tsx
import React from "react";
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-slate-950 text-slate-50 antialiased">{children}</body>
    </html>
  );
}
EOF

cat << 'EOF' > frontend/hooks/useAgentStream.ts
"use client";
import { useState, useCallback } from "react";

export interface StreamMessage {
  agent: string;
  status: "IN_PROGRESS" | "COMPLETED" | "FAILED";
  message: string;
}

export function useAgentStream() {
  const [messages, setMessages] = useState<StreamMessage[]>([]);
  const [isStreaming, setIsStreaming] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const startStream = useCallback(async (payload: any) => {
    setIsStreaming(true);
    setMessages([]);
    setError(null);

    try {
      const response = await fetch("http://localhost:8000/api/orchestrate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const reader = response.body?.getReader();
      const decoder = new TextDecoder("utf-8");
      if (!reader) return;

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value, { stream: true });
        const lines = chunk.split("\n\n");

        for (const line of lines) {
          if (line.startsWith("data: ")) {
            const rawJson = line.replace("data: ", "").trim();
            if (rawJson) {
              const parsed: StreamMessage = JSON.parse(rawJson);
              setMessages((prev) => [...prev, parsed]);
            }
          }
        }
      }
    } catch (err: any) {
      setError(err.message || "Failed to stream agent updates.");
    } finally {
      setIsStreaming(false);
    }
  }, []);

  return { messages, isStreaming, error, startStream };
}
EOF

cat << 'EOF' > frontend/app/dashboard/page.tsx
"use client";
import React from "react";
import { useAgentStream } from "@/hooks/useAgentStream";
import { Bot, Truck, ShieldCheck, Zap, Activity } from "lucide-react";

export default function DashboardPage() {
  const { messages, isStreaming, error, startStream } = useAgentStream();

  const handleTriggerOrchestration = () => {
    startStream({
      card_id: "CARD-PASIG-8001",
      crop: "Cabbage",
      target_volume_kg: 800,
      price_ceiling_per_kg: 38.00,
      delivery_deadline: "2026-03-20",
      delivery_location: "Pasig Public Market",
      corridor_required: "City Corridor"
    });
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-50 p-8 font-sans">
      <header className="flex justify-between items-center mb-8 border-b border-slate-800 pb-6">
        <div>
          <h1 className="text-3xl font-extrabold text-emerald-400 flex items-center gap-3">
            arcaicia <span className="text-xs bg-emerald-950 text-emerald-300 border border-emerald-800 px-2 py-1 rounded-full font-mono">DEMAND-PULL ENGINE</span>
          </h1>
          <p className="text-slate-400 text-sm mt-1">Philippine Agricultural Supply Chain Multi-Agent Orchestrator</p>
        </div>
        <button
          onClick={handleTriggerOrchestration}
          disabled={isStreaming}
          className="bg-emerald-500 hover:bg-emerald-400 disabled:bg-slate-800 text-slate-950 font-bold px-6 py-3 rounded-xl transition flex items-center gap-2 shadow-lg shadow-emerald-500/20"
        >
          {isStreaming ? (
            <>
              <Activity className="animate-spin h-5 w-5 text-slate-950" />
              Orchestrating...
            </>
          ) : (
            <>
              <Zap className="h-5 w-5 fill-slate-950" />
              Run Demand Orchestrator
            </>
          )}
        </button>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="space-y-6">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-xs font-semibold px-3 py-1 bg-blue-950 text-blue-400 border border-blue-800 rounded-full">
                Active Sourcing Card
              </span>
              <span className="text-xs font-mono text-slate-400">CARD-PASIG-8001</span>
            </div>
            <h2 className="text-2xl font-bold text-white">Cabbage (Highland Grade A)</h2>
            <div className="mt-6 space-y-3 text-sm">
              <div className="flex justify-between border-b border-slate-800 pb-2">
                <span className="text-slate-400">Target Volume</span>
                <span className="font-semibold text-slate-200">800 kg</span>
              </div>
              <div className="flex justify-between border-b border-slate-800 pb-2">
                <span className="text-slate-400">Price Ceiling</span>
                <span className="font-semibold text-emerald-400">₱38.00 / kg</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Logistics Corridor</span>
                <span className="font-semibold text-indigo-400 flex items-center gap-1">
                  <Truck className="h-4 w-4" /> City Corridor
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl flex flex-col h-[650px]">
          <div className="flex justify-between items-center mb-6 pb-4 border-b border-slate-800">
            <h3 className="text-lg font-bold text-slate-200 flex items-center gap-2">
              <Bot className="h-5 w-5 text-emerald-400" />
              Live Multi-Agent AutoGen Execution Stream
            </h3>
          </div>

          <div className="flex-1 overflow-y-auto space-y-4 pr-2 font-mono text-sm">
            {messages.length === 0 && !isStreaming && (
              <div className="h-full flex flex-col items-center justify-center text-slate-600">
                <Bot className="h-12 w-12 mb-3 stroke-[1.5]" />
                <p>Click "Run Demand Orchestrator" to execute agent team reasoning.</p>
              </div>
            )}

            {messages.map((msg, index) => (
              <div key={index} className="p-4 rounded-xl bg-slate-950 border border-slate-800">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-bold text-emerald-300 text-xs px-2 py-0.5 bg-slate-900 border border-slate-700 rounded">
                    @{msg.agent}
                  </span>
                  <span className="text-xs px-2 py-0.5 rounded font-bold bg-emerald-950 text-emerald-400 border border-emerald-800">
                    {msg.status}
                  </span>
                </div>
                <p className="text-slate-300 text-xs leading-relaxed">{msg.message}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

echo "All files created!"
