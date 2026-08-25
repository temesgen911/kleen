"""Intelligent Cleaning Plan Scheduler Service.

Provides AI-driven and rule-based multi-week task scheduling, load balancing,
room grouping, flexible recurrence management (daily, twice-weekly, weekly,
bi-weekly, twice-monthly, monthly, quarterly), user cleaning speed adaptation,
and automated missed-day rescheduling.
"""

import json
import logging
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any, Dict, List, Optional
import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


class TaskFrequency:
    DAILY = "daily"
    TWICE_WEEKLY = "twice_weekly"
    WEEKLY = "weekly"
    BI_WEEKLY = "bi_weekly"
    TWICE_MONTHLY = "twice_monthly"
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"

    FREQUENCY_INTERVAL_DAYS = {
        DAILY: 1,
        TWICE_WEEKLY: 3,
        WEEKLY: 7,
        BI_WEEKLY: 14,
        TWICE_MONTHLY: 15,
        MONTHLY: 30,
        QUARTERLY: 90,
    }

    @classmethod
    def parse(cls, val: str) -> str:
        s = str(val).lower().strip()
        if "bi" in s or "every 2" in s or "14" in s or "2 wks" in s or "2 weeks" in s:
            return cls.BI_WEEKLY
        if "twice" in s and "month" in s or "2x/month" in s or "2x a month" in s or "2 times a month" in s or "15" in s:
            return cls.TWICE_MONTHLY
        if ("2" in s or "twice" in s) and ("week" in s or "day" in s) and "month" not in s:
            return cls.TWICE_WEEKLY
        if "daily" in s or "every day" in s:
            return cls.DAILY
        if "month" in s or "30" in s:
            return cls.MONTHLY
        if "quarter" in s or "90" in s:
            return cls.QUARTERLY
        return cls.WEEKLY


@dataclass
class InputItem:
    id: str
    name: str
    room_name: str
    category: str
    cleaning_action: str
    frequency: str = "weekly"
    dirty_level: int = 1
    estimated_minutes: int = 5
    priority: str = "medium"


class PlanSchedulerService:
    """Service to schedule, adapt, and recalculate cleaning plans using Gemini AI with rule-based fallback."""

    def __init__(self, gemini_api_key: Optional[str] = None):
        self.gemini_api_key = gemini_api_key or settings.GEMINI_API_KEY

    async def generate_plan(
        self,
        items: List[Dict[str, Any]],
        start_date: Optional[date] = None,
        target_weeks: int = 4,
        user_pacing_factor: float = 1.0,
    ) -> Dict[str, Any]:
        """Generates an intelligent multi-week cleaning plan adapted to user speed."""
        parsed_items = [
            InputItem(
                id=str(item.get("id", f"item_{idx}")),
                name=item.get("name", "Unknown Item"),
                room_name=item.get("room_name", item.get("roomName", "General")),
                category=item.get("category", "other"),
                cleaning_action=item.get("cleaning_action", item.get("cleaningAction", "Clean")),
                frequency=item.get("frequency", "weekly"),
                dirty_level=int(item.get("dirty_level", item.get("dirtyLevel", 1))),
                estimated_minutes=max(1, round(int(item.get("estimated_minutes", item.get("estimatedMinutes", 5))) * user_pacing_factor)),
                priority=item.get("priority", "medium"),
            )
            for idx, item in enumerate(items)
        ]

        if not start_date:
            start_date = date.today()
            start_date -= timedelta(days=start_date.weekday())

        if self.gemini_api_key:
            try:
                ai_plan = await self._generate_with_gemini(parsed_items, start_date, target_weeks, user_pacing_factor)
                if ai_plan:
                    logger.info("Successfully generated cleaning plan using Gemini AI.")
                    return ai_plan
            except Exception as e:
                logger.warning(f"Gemini AI plan generation fallback to rule engine: {e}")

        return self._generate_rule_based(parsed_items, start_date, target_weeks)

    async def reschedule_missed_days(
        self,
        tasks: List[Dict[str, Any]],
        missed_day_indices: List[int],
        start_date: Optional[date] = None,
        user_pacing_factor: float = 1.0,
    ) -> Dict[str, Any]:
        """Recalculates & redistributes tasks from missed days across remaining available days."""
        if not start_date:
            start_date = date.today()
            start_date -= timedelta(days=start_date.weekday())

        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        if self.gemini_api_key:
            try:
                ai_rescheduled = await self._reschedule_with_gemini(tasks, missed_day_indices, start_date, user_pacing_factor)
                if ai_rescheduled:
                    return ai_rescheduled
            except Exception as e:
                logger.warning(f"Gemini AI rescheduling fallback to algorithmic engine: {e}")

        # Algorithmic Fallback Engine
        return self._reschedule_rule_based(tasks, missed_day_indices, start_date, user_pacing_factor)

    def _generate_rule_based(
        self,
        items: List[InputItem],
        start_date: date,
        target_weeks: int,
    ) -> Dict[str, Any]:
        """Rule-based load balancing and multi-week frequency distribution engine."""
        scheduled_tasks: List[Dict[str, Any]] = []
        unique_rooms = list(set(i.room_name for i in items))
        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        room_anchor_days: Dict[str, List[int]] = {}
        for r_idx, room in enumerate(unique_rooms):
            primary_day = (r_idx * 2) % 6
            secondary_day = (primary_day + 3) % 7
            room_anchor_days[room] = [primary_day, secondary_day]

        for week in range(target_weeks):
            week_start = start_date + timedelta(weeks=week)
            daily_minutes = [0] * 7

            for item in items:
                freq = TaskFrequency.parse(item.frequency)
                should_schedule = False
                target_day_indices: List[int] = []

                if freq == TaskFrequency.DAILY:
                    should_schedule = True
                    target_day_indices = list(range(7))
                elif freq == TaskFrequency.TWICE_WEEKLY:
                    should_schedule = True
                    anchors = room_anchor_days.get(item.room_name, [0, 3])
                    target_day_indices = anchors[:2]
                elif freq == TaskFrequency.WEEKLY:
                    should_schedule = True
                    anchors = room_anchor_days.get(item.room_name, [0])
                    target_day_indices = [anchors[0]]
                elif freq in (TaskFrequency.BI_WEEKLY, TaskFrequency.TWICE_MONTHLY):
                    if (week % 2) == (hash(item.id) % 2):
                        should_schedule = True
                        anchors = room_anchor_days.get(item.room_name, [1])
                        target_day_indices = [anchors[0]]
                elif freq == TaskFrequency.MONTHLY:
                    if week == (hash(item.id) % 4):
                        should_schedule = True
                        anchors = room_anchor_days.get(item.room_name, [2])
                        target_day_indices = [anchors[0]]
                elif freq == TaskFrequency.QUARTERLY:
                    if week == 0:
                        should_schedule = True
                        anchors = room_anchor_days.get(item.room_name, [5])
                        target_day_indices = [anchors[0]]

                if not should_schedule:
                    continue

                for day_idx in target_day_indices:
                    chosen_day = day_idx
                    if daily_minutes[chosen_day] > 25:
                        chosen_day = daily_minutes.index(min(daily_minutes))

                    daily_minutes[chosen_day] += item.estimated_minutes
                    task_date = week_start + timedelta(days=chosen_day)

                    scheduled_tasks.append({
                        "id": f"task_{item.id}_w{week}_d{chosen_day}",
                        "item_id": item.id,
                        "title": f"{item.cleaning_action} {item.name}",
                        "room_name": item.room_name,
                        "cleaning_action": item.cleaning_action,
                        "scheduled_day_index": chosen_day,
                        "scheduled_day_name": day_names[chosen_day],
                        "scheduled_date": task_date.isoformat(),
                        "week_number": week + 1,
                        "estimated_minutes": item.estimated_minutes,
                        "frequency": freq,
                        "priority": item.priority,
                        "status": "pending",
                        "ai_tip": f"Scheduled for optimal efficiency in {item.room_name}."
                    })

        total_mins = sum(t["estimated_minutes"] for t in scheduled_tasks)
        return {
            "status": "success",
            "generation_method": "rule_engine",
            "start_date": start_date.isoformat(),
            "target_weeks": target_weeks,
            "total_tasks": len(scheduled_tasks),
            "total_estimated_minutes": total_mins,
            "tasks": scheduled_tasks,
        }

    def _reschedule_rule_based(
        self,
        tasks: List[Dict[str, Any]],
        missed_day_indices: List[int],
        start_date: date,
        user_pacing_factor: float,
    ) -> Dict[str, Any]:
        """Redistributes tasks from missed days evenly into remaining days of the week."""
        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        available_days = [d for d in range(7) if d not in missed_day_indices]
        if not available_days:
            available_days = [6]  # Fallback to Sunday if all days missed

        daily_mins = {d: 0 for d in range(7)}
        updated_tasks: List[Dict[str, Any]] = []

        for task in tasks:
            day_idx = task.get("scheduled_day_index", 0)
            status = task.get("status", "pending")
            est_mins = max(1, round(task.get("estimated_minutes", 5) * user_pacing_factor))
            task["estimated_minutes"] = est_mins

            if day_idx in missed_day_indices and status != "completed":
                # Find lightest available future day
                chosen_day = min(available_days, key=lambda d: daily_mins[d])
                daily_mins[chosen_day] += est_mins
                task_date = start_date + timedelta(days=chosen_day)

                updated = dict(task)
                updated["scheduled_day_index"] = chosen_day
                updated["scheduled_day_name"] = day_names[chosen_day]
                updated["scheduled_date"] = task_date.isoformat()
                updated["status"] = "rescheduled"
                updated["ai_tip"] = f"Rescheduled automatically from missed {day_names[day_idx]}."
                updated_tasks.append(updated)
            else:
                daily_mins[day_idx] += est_mins
                updated_tasks.append(task)

        return {
            "status": "success",
            "generation_method": "rule_rescheduler",
            "missed_days": [day_names[d] for d in missed_day_indices if d < 7],
            "total_tasks": len(updated_tasks),
            "tasks": updated_tasks,
        }

    async def _generate_with_gemini(
        self,
        items: List[InputItem],
        start_date: date,
        target_weeks: int,
        user_pacing_factor: float,
    ) -> Optional[Dict[str, Any]]:
        """Invokes Gemini AI to build personalized task distributions."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={self.gemini_api_key}"

        prompt = f"""
        You are KleenAI, an advanced housekeeping AI. Generate an optimized cleaning plan:
        Items: {json.dumps([item.__dict__ for item in items], indent=2)}
        User Pacing Speed Factor: {user_pacing_factor} (e.g. <1.0 is faster, >1.0 is slower).
        Start Date: {start_date.isoformat()} (Monday).
        Target Weeks: {target_weeks}.

        Distribute tasks so daily time is balanced (<25 mins/day).
        Frequencies: daily, twice_weekly, weekly, bi_weekly, twice_monthly, monthly, quarterly.

        Return JSON ONLY:
        {{
          "tasks": [
            {{
              "id": "string",
              "item_id": "string",
              "title": "string",
              "room_name": "string",
              "cleaning_action": "string",
              "scheduled_day_index": 0-6,
              "scheduled_day_name": "Monday-Sunday",
              "scheduled_date": "YYYY-MM-DD",
              "week_number": 1-4,
              "estimated_minutes": int,
              "frequency": "string",
              "priority": "low|medium|high",
              "status": "pending",
              "ai_tip": "Short actionable tip"
            }}
          ]
        }}
        """

        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(
                url,
                json={"contents": [{"parts": [{"text": prompt}]}]},
                headers={"Content-Type": "application/json"},
            )
            if res.status_code == 200:
                data = res.json()
                text = data["candidates"][0]["content"]["parts"][0]["text"]
                if "```json" in text:
                    text = text.split("```json")[1].split("```")[0].strip()
                elif "```" in text:
                    text = text.split("```")[1].strip()

                parsed = json.loads(text)
                parsed["status"] = "success"
                parsed["generation_method"] = "gemini_ai"
                parsed["start_date"] = start_date.isoformat()
                parsed["target_weeks"] = target_weeks
                parsed["total_tasks"] = len(parsed.get("tasks", []))
                parsed["total_estimated_minutes"] = sum(t.get("estimated_minutes", 0) for t in parsed.get("tasks", []))
                return parsed

        return None

    async def _reschedule_with_gemini(
        self,
        tasks: List[Dict[str, Any]],
        missed_day_indices: List[int],
        start_date: date,
        user_pacing_factor: float,
    ) -> Optional[Dict[str, Any]]:
        """Invokes Gemini AI to reschedule missed days intelligently."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={self.gemini_api_key}"
        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        prompt = f"""
        User missed these days: {[day_names[d] for d in missed_day_indices if d < 7]}.
        Recalculate and redistribute all pending/missed tasks across remaining available days.
        Current Tasks: {json.dumps(tasks, indent=2)}
        User Pacing Factor: {user_pacing_factor}.
        Start Date: {start_date.isoformat()} (Monday).

        Return JSON ONLY in format:
        {{
          "tasks": [
            ... (updated task list with new scheduled_day_index 0-6, scheduled_date YYYY-MM-DD, status, and ai_tip)
          ]
        }}
        """

        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(
                url,
                json={"contents": [{"parts": [{"text": prompt}]}]},
                headers={"Content-Type": "application/json"},
            )
            if res.status_code == 200:
                data = res.json()
                text = data["candidates"][0]["content"]["parts"][0]["text"]
                if "```json" in text:
                    text = text.split("```json")[1].split("```")[0].strip()
                elif "```" in text:
                    text = text.split("```")[1].strip()

                parsed = json.loads(text)
                parsed["status"] = "success"
                parsed["generation_method"] = "gemini_ai_rescheduler"
                parsed["missed_days"] = [day_names[d] for d in missed_day_indices if d < 7]
                parsed["total_tasks"] = len(parsed.get("tasks", []))
                return parsed

        return None
