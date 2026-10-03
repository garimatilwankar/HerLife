import re
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.question_safety import classify_question
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
    Safety-first educational question matching endpoint.
    Performs deterministic safety classification before keyword retrieval.
    """
    seed_education_data(db)

    question_text = data.question.strip()
    if not question_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Question cannot be empty.",
        )

    # 1. Deterministic safety classification
    classification = classify_question(question_text)

    # 2. Fetch user profile lifecycle stage
    profile = db.scalar(select(Profile).where(Profile.user_id == current_user.id))
    user_stage = profile.lifecycle_stage.strip().lower() if (profile and profile.lifecycle_stage) else None

    # 3. Extract keywords from question
    clean_question = re.sub(r"[^\w\s]", " ", question_text.lower())
    words = [w for w in clean_question.split() if w not in STOP_WORDS and len(w) > 1]

    # 4. Fetch all articles & score them
    articles = list(db.scalars(select(EducationArticle)).all())

    scored_articles = []
    for art in articles:
        art_title = (art.title or "").lower()
        art_summary = (art.summary or "").lower()
        art_category = (art.category or "").lower()
        art_content = (art.content or "").lower()
        art_stage = (art.lifecycle_stage or "").lower()

        keyword_score = 0
        for word in words:
            if word in art_title:
                keyword_score += 5
            if word in art_summary:
                keyword_score += 3
            if word in art_category:
                keyword_score += 3
            if word in art_content:
                keyword_score += 1

        if len(clean_question) > 3 and (clean_question in art_title or clean_question in art_summary):
            keyword_score += 10

        if keyword_score > 0:
            score = keyword_score
            if user_stage and art_stage:
                if user_stage in art_stage or art_stage in user_stage:
                    score += 4
            scored_articles.append((score, art))

    # Sort by score descending and pick top 3
    scored_articles.sort(key=lambda x: x[0], reverse=True)
    top_articles = [art for _, art in scored_articles[:3]]

    # 5. Format response text & sources
    if classification.override_answer:
        answer = classification.override_answer
    elif top_articles:
        answer = "Here are some educational resources that may help with your question."
    else:
        answer = "No matching educational content was found for your question."

    sources = [AskSourceSchema.model_validate(art) for art in top_articles] if top_articles else []

    return AskResponse(
        question=question_text,
        intent=classification.intent,
        safety_level=classification.safety_level,
        answer=answer,
        sources=sources,
        disclaimer=DISCLAIMER,
    )
