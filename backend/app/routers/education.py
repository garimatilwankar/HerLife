from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.education import EducationArticle
from app.schemas.education import EducationResponse

router = APIRouter(
    prefix="/api/education",
    tags=["Education"],
)


def seed_education_data(db: Session):
    """Seed initial educational content if the education table is empty."""
    existing_count = db.scalar(select(EducationArticle).limit(1))
    if existing_count is not None:
        return

    articles = [
        EducationArticle(
            title="Understanding Puberty & Body Changes",
            summary="Key physical and hormonal developments during adolescence.",
            content=(
                "During adolescence, your body produces increasing levels of hormones that trigger development. "
                "Growth spurts, body shape changes, and initial menstrual cycles (menarche) are expected. "
                "Building consistent tracking habits early helps foster lifelong health awareness."
            ),
            category="Life stages",
            lifecycle_stage="Adolescence",
            source_name="ACOG Adolescent Health Guidelines",
            source_url="https://www.acog.org",
        ),
        EducationArticle(
            title="Cycle Basics & Phase Navigation",
            summary="How your menstrual cycle functions across its four distinct phases.",
            content=(
                "A typical menstrual cycle lasts between 21 and 35 days, counted from day 1 of bleeding to day 1 of the next period. "
                "It progresses through four main phases: Menstrual (bleeding), Follicular (egg maturation), Ovulation (egg release), "
                "and Luteal (pre-period transition)."
            ),
            category="Cycle",
            lifecycle_stage="Reproductive Years",
            source_name="WomensHealth.gov Cycle Overview",
            source_url="https://www.womenshealth.gov",
        ),
        EducationArticle(
            title="Cycle Basics & Phase Navigation",
            summary="How your menstrual cycle functions across its four distinct phases.",
            content=(
                "A typical menstrual cycle lasts between 21 and 35 days, counted from day 1 of bleeding to day 1 of the next period. "
                "It progresses through four main phases: Menstrual (bleeding), Follicular (egg maturation), Ovulation (egg release), "
                "and Luteal (pre-period transition)."
            ),
            category="Cycle",
            lifecycle_stage="Menstruation",
            source_name="WomensHealth.gov Cycle Overview",
            source_url="https://www.womenshealth.gov",
        ),
        EducationArticle(
            title="Cycle Basics & Phase Navigation",
            summary="How your menstrual cycle functions across its four distinct phases.",
            content=(
                "A typical menstrual cycle lasts between 21 and 35 days, counted from day 1 of bleeding to day 1 of the next period. "
                "It progresses through four main phases: Menstrual (bleeding), Follicular (egg maturation), Ovulation (egg release), "
                "and Luteal (pre-period transition)."
            ),
            category="Cycle",
            lifecycle_stage="Reproductive Health",
            source_name="WomensHealth.gov Cycle Overview",
            source_url="https://www.womenshealth.gov",
        ),
        EducationArticle(
            title="Pregnancy Wellbeing & Essential Care",
            summary="Monitoring physical health and important red-flag symptoms during pregnancy.",
            content=(
                "Pregnancy involves significant physiological adaptations. Regular prenatal check-ups monitor fetal growth and maternal wellness. "
                "Key symptoms requiring provider consultation include severe headaches, vision changes, unexpected bleeding, or decreased movement."
            ),
            category="Life stages",
            lifecycle_stage="Pregnancy",
            source_name="Mayo Clinic Pregnancy Care Guide",
            source_url="https://www.mayoclinic.org",
        ),
        EducationArticle(
            title="Postpartum Recovery & Wellbeing",
            summary="Physical healing, hormonal shifts, and emotional care after childbirth.",
            content=(
                "The postpartum period involves uterine contraction, lochia discharge, and major hormonal shifts as milk production begins. "
                "Gentle rest, hydration, nutrition, and mental health monitoring are key components of recovery."
            ),
            category="Life stages",
            lifecycle_stage="Postpartum",
            source_name="NHS Postpartum Health",
            source_url="https://www.nhs.uk",
        ),
        EducationArticle(
            title="Navigating Perimenopause",
            summary="Recognizing hormonal fluctuations, hot flashes, and cycle changes.",
            content=(
                "Perimenopause is the natural transition leading up to menopause, often beginning in a woman's 40s. "
                "Estrogen and progesterone levels fluctuate, leading to irregular cycle lengths, hot flashes, night sweats, and sleep changes."
            ),
            category="Life stages",
            lifecycle_stage="Perimenopause",
            source_name="The Menopause Society Guidelines",
            source_url="https://www.menopause.org",
        ),
        EducationArticle(
            title="Post-Menopausal Health & Bone Care",
            summary="Maintaining heart and bone health in the years following menopause.",
            content=(
                "Menopause is confirmed after 12 consecutive months without a period. Lower estrogen levels affect bone density and cardiovascular health. "
                "Regular weight-bearing exercise, calcium/Vitamin D intake, and routine screenings support ongoing vitality."
            ),
            category="Life stages",
            lifecycle_stage="Menopause",
            source_name="Endocrine Society Guidelines",
            source_url="https://www.endocrine.org",
        ),
        EducationArticle(
            title="Managing Menstrual Cramps & Pain",
            summary="Practical strategies for easing menstrual discomfort.",
            content=(
                "Primary dysmenorrhea (cramping) is caused by uterine contractions triggered by prostaglandins. "
                "Heat therapy, warm baths, light stretching, and adequate rest frequently reduce discomfort. "
                "Severe pain interfering with daily activities warrants medical evaluation."
            ),
            category="Symptoms",
            lifecycle_stage=None,
            source_name="PubMed Clinical Summary",
            source_url="https://pubmed.ncbi.nlm.org",
        ),
    ]

    db.add_all(articles)
    db.commit()


@router.get("", response_model=list[EducationResponse])
def get_education_articles(
    lifecycle_stage: str | None = Query(None),
    category: str | None = Query(None),
    db: Session = Depends(get_db),
):
    # Ensure seed content is initialized
    seed_education_data(db)

    query = select(EducationArticle)

    if lifecycle_stage:
        # Match user's stage or general (lifecycle_stage IS NULL)
        query = query.where(
            (EducationArticle.lifecycle_stage == lifecycle_stage)
            | (EducationArticle.lifecycle_stage == None)
        )

    if category and category.strip().lower() != "all":
        query = query.where(EducationArticle.category == category.strip())

    query = query.order_by(EducationArticle.id.asc())

    return list(db.scalars(query).all())


@router.get("/{content_id}", response_model=EducationResponse)
def get_education_article(
    content_id: int,
    db: Session = Depends(get_db),
):
    # Ensure seed content is initialized
    seed_education_data(db)

    article = db.scalar(
        select(EducationArticle).where(EducationArticle.id == content_id)
    )

    if article is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Educational content not found.",
        )

    return article
