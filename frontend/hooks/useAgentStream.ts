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
