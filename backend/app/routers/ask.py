import re
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.gemini_service import generate_conversational_answer
from app.core.question_safety import (
    INTENT_GENERAL_KNOWLEDGE,
    INTENT_GREETING,
    INTENT_IDENTITY,
    SAFETY_URGENT,
    classify_question,
)
from app.core.security import get_current_user
from app.database import get_db
from app.models.education import EducationArticle
from app.models.profile import Profile
from app.models.user import User
from app.routers.education import seed_education_data
from app.schemas.ask import AskRequest, AskResponse, AskSourceSchema

router = APIRouter(
    prefix="/api/ask",
    tags=["Ask"],
)

STOP_WORDS = {
    "what", "is", "a", "an", "the", "how", "can", "i", "my", "why", "does", "do",
    "to", "in", "of", "and", "or", "for", "with", "about", "me", "you", "your",
    "are", "be", "have", "has", "should", "when", "where", "tell", "help", "ease",
    "counts", "as", "cause", "causes", "happen", "happening"
}

DISCLAIMER = "This information is for education and awareness only and is not a medical diagnosis."


@router.post("", response_model=AskResponse)
def ask_question(
    data: AskRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Safety-first conversational Ask endpoint with multi-turn conversation memory,
    intent classification, and context-aware grounding retrieval.
    """
    seed_education_data(db)

    question_text = data.question.strip()
    if not question_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Question cannot be empty.",
        )

    # 1. Deterministic safety classification evaluated on CURRENT question
    classification = classify_question(question_text)

    # 2. Fetch user profile lifecycle stage
    profile = db.scalar(select(Profile).where(Profile.user_id == current_user.id))
    user_stage = profile.lifecycle_stage.strip().lower() if (profile and profile.lifecycle_stage) else None

    # 3. Context-aware keyword extraction & retrieval (skip for greetings/identity/unrelated)
    non_retrieval_intents = {INTENT_GREETING, INTENT_IDENTITY, INTENT_GENERAL_KNOWLEDGE}

    top_articles = []
    if classification.intent not in non_retrieval_intents:
        # Build context search string from current question + recent user messages
        context_user_msgs = [m.content for m in data.conversation_history if m.role == "user"][-2:]
        context_search_text = " ".join(context_user_msgs + [question_text]).lower()

        clean_context = re.sub(r"[^\w\s]", " ", context_search_text)
        words = [w for w in clean_context.split() if w not in STOP_WORDS and len(w) > 1]

        clean_current = re.sub(r"[^\w\s]", " ", question_text.lower())
        current_words = set(clean_current.split()) - STOP_WORDS

        articles = list(db.scalars(select(EducationArticle)).all())
        scored_articles = []
        for art in articles:
            art_title = (art.title or "").lower()
            art_summary = (art.summary or "").lower()
            art_category = (art.category or "").lower()
            art_content = (art.content or "").lower()
            art_stage = (art.lifecycle_stage or "").lower()

            keyword_score = 0
            # Higher weight for current question words
            for word in current_words:
                if len(word) <= 1:
                    continue
                if word in art_title:
                    keyword_score += 6
                if word in art_summary:
                    keyword_score += 4
                if word in art_category:
                    keyword_score += 4
                if word in art_content:
                    keyword_score += 2

            # Additional weight for previous context words
            for word in words:
                if word in art_title:
                    keyword_score += 3
                if word in art_summary:
                    keyword_score += 2

            if len(clean_current) > 3 and (clean_current in art_title or clean_current in art_summary):
                keyword_score += 10

            if keyword_score > 0:
                score = keyword_score
                if user_stage and art_stage:
                    if user_stage in art_stage or art_stage in user_stage:
                        score += 4
                scored_articles.append((score, art))

        scored_articles.sort(key=lambda x: x[0], reverse=True)
        top_articles = [art for _, art in scored_articles[:3]]

    sources = [AskSourceSchema.model_validate(art) for art in top_articles] if top_articles else []

    # 4. Handle response generation
    # EMERGENCY / URGENT: Skip Gemini for instant safety guidance
    if classification.safety_level == SAFETY_URGENT:
        answer = classification.override_answer or (
            "If you are experiencing severe symptoms such as heavy bleeding, severe pain, or feeling faint, "
            "please seek immediate emergency medical care right away."
        )
    else:
        # Generate conversational AI answer with Gemini using conversation history and grounding
        ai_answer = generate_conversational_answer(
            question=question_text,
            conversation_history=data.conversation_history,
            retrieved_articles=top_articles,
            intent=classification.intent,
            safety_level=classification.safety_level,
        )

        if ai_answer:
            answer = ai_answer
        else:
            # Deterministic conversational fallback if Gemini service is unavailable
            if classification.override_answer:
                answer = classification.override_answer
            elif classification.intent == INTENT_GREETING:
                answer = (
                    "Hi! I'm HerLife, your women's health chatbot. "
                    "I can help you understand your cycle, symptoms, reproductive health, and other women's health topics. "
                    "What would you like to know?"
                )
            elif classification.intent == INTENT_IDENTITY:
                answer = (
                    "I am HerLife, a supportive and informative women's health education chatbot. "
                    "I'm here to help you learn about your cycle, reproductive health, and wellness."
                )
            elif classification.intent == INTENT_GENERAL_KNOWLEDGE:
                answer = (
                    "I'm primarily designed to help with women's health education, so I might not have full details on that general topic. "
                    "Feel free to ask me anything about your cycle, symptoms, or health!"
                )
            elif top_articles:
                art = top_articles[0]
                summary_text = (art.summary or art.content or "").strip()
                if len(summary_text) > 250:
                    summary_text = summary_text[:247].rsplit(" ", 1)[0] + "..."
                answer = f"{art.title}: {summary_text}"
            else:
                answer = (
                    "I am HerLife, your women's health chatbot. "
                    "I can help explain menstrual cycles, symptoms, and reproductive health. "
                    "What health question can I help answer for you?"
                )

    return AskResponse(
        question=question_text,
        intent=classification.intent,
        safety_level=classification.safety_level,
        answer=answer,
        sources=sources,
        disclaimer=DISCLAIMER,
    )
