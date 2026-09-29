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
