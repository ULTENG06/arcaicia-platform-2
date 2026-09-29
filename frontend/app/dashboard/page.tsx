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
