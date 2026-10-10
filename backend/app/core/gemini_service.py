import os
import logging
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("herlife.gemini")

# Attempt to load google-genai SDK
try:
    from google import genai
    from google.genai import types
    SDK_AVAILABLE = True
except ImportError:
    SDK_AVAILABLE = False
    logger.warning("google-genai package is not installed. Gemini AI will be disabled.")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

_client = None
if SDK_AVAILABLE and GEMINI_API_KEY:
    try:
        _client = genai.Client(api_key=GEMINI_API_KEY)
    except Exception as e:
        logger.error(f"Failed to initialize Gemini client: {e}")


def generate_conversational_answer(
    question: str,
    conversation_history: list = None,
    retrieved_articles: list = None,
    intent: str = "GENERAL_INFORMATION",
    safety_level: str = "INFORMATIONAL",
) -> str | None:
    """
    Generates a natural conversational answer grounded in retrieved HerLife educational articles
    and informed by recent conversation history. Returns None if Gemini fails/unavailable.
    """
    if not _client:
        return None

    # Format recent conversation history (max 10 items)
    history_blocks = []
    if conversation_history:
        recent_history = conversation_history[-10:]
        for item in recent_history:
            if hasattr(item, "role"):
                role = item.role
                content = item.content
            elif isinstance(item, dict):
                role = item.get("role", "")
                content = item.get("content", "")
            else:
                continue

            role_label = "User" if role == "user" else "HerLife"
            if content:
                history_blocks.append(f"{role_label}: {content}")

    history_str = "\n".join(history_blocks) if history_blocks else "None"

    # Format retrieved HerLife articles into grounding context
    context_blocks = []
    if retrieved_articles:
        for art in retrieved_articles:
            title = getattr(art, "title", "") or ""
            summary = getattr(art, "summary", "") or ""
            content = getattr(art, "content", "") or ""
            category = getattr(art, "category", "") or ""
            stage = getattr(art, "lifecycle_stage", "") or ""
            context_blocks.append(
                f"--- Article: {title} ---\nCategory: {category} | Stage: {stage}\nSummary: {summary}\nContent: {content}\n"
            )

    context_str = "\n".join(context_blocks) if context_blocks else "No specific HerLife database articles retrieved for this question. Use your general knowledge while strictly adhering to HerLife's women's-health persona and safety rules."

    models_to_try = [
        "gemini-3.5-flash-lite",
        "gemini-flash-lite-latest",
        "gemini-3.5-flash",
        "gemini-3.8-flash",
    ]

    # Build system instructions based on safety rules & identity
    system_instruction = (
        "You are HerLife, a supportive, warm, clear, and intelligent women's health education chatbot.\n"
        "Your primary purpose is to help users understand women's health topics, including menstrual cycles, symptoms, reproductive health, and lifecycle stages.\n\n"
        "RESPONSE STYLE & ADAPTIVE LENGTH:\n"
        "1. DIRECT & HELPFUL FIRST: Give a clear, warm, direct answer immediately.\n"
        "2. ADAPTIVE LENGTH: Give the shortest complete answer appropriate for the user's question. For simple questions, give 2 to 4 clear sentences. For complex, multi-part, or personal context questions, provide a thorough, supportive, structured explanation. Do NOT write unnecessary essays.\n"
        "3. SIMPLE HUMAN LANGUAGE: Use clear, everyday language meant for normal people (e.g., 'the lining of your uterus sheds as period blood' instead of 'endometrial lining shedding'). If a medical term is necessary, briefly explain it in plain language.\n"
        "4. PLAIN TEXT ONLY: Do NOT output raw Markdown bold (**text**), headers (#), or code blocks. Use simple plain text paragraphs and dashes (-) for bullet lists if needed.\n"
        "5. COMPLETE RESPONSES: Always complete your sentences and complete any bullet lists you start. Never end mid-sentence.\n\n"
        "PERSONAL HEALTH & SITUATION HANDLING:\n"
        "6. PERSONAL CONTEXT: When a user describes their specific situation or symptoms (e.g. 'my period came 10 days early because I've been dancing a lot and feeling tired...'):\n"
        "   - Provide a warm, empathetic, cautious educational explanation.\n"
        "   - Do NOT diagnose or claim certainty about the cause.\n"
        "   - Explain general factors that can affect cycles or symptoms (such as stress, significant physical exertion/exercise, fatigue, illness, sleep, or natural hormonal variations).\n"
        "   - Distinguish common normal variations from situations or 'red flags' that warrant consulting a healthcare professional.\n\n"
        "CONVERSATIONAL CONTEXT & MEMORY:\n"
        "7. RESOLVE CONTEXT DYNAMICALLY: Use previous conversation history dynamically to understand references like 'it', 'they', 'that', 'this', 'the second phase', 'why does that happen?', 'what about if I feel tired too?'. Do NOT ask the user to repeat previous information.\n"
        "8. FLEXIBLE KNOWLEDGE GROUNDING: Use retrieved HerLife educational articles as grounding context when available. If no articles are provided, answer using your general knowledge while adhering to HerLife's persona and safety rules. NEVER state 'No articles found' or mention 'articles', 'database', 'retrieval', or 'context' to the user.\n"
        "9. NO INVENTED MEMORY: Do not claim personal memory outside the provided conversation history.\n\n"
        "DOMAIN & INTENT RULES:\n"
        "- Greetings ('hi', 'hello', 'thanks'): Respond warmly with a short greeting and ask how you can help.\n"
        "- Identity ('who are you?', 'what can you do?'): State briefly that you are HerLife, a women's health education chatbot.\n"
        "- Unrelated general knowledge ('capital of France', 'photosynthesis', jokes): Answer the question naturally/briefly if known, then politely note that you are primarily a women's health assistant.\n"
        "- Real-time/Live data (weather, live news): Politely state you do not have access to live real-time information.\n"
    )

    if safety_level == "CAUTION":
        system_instruction += (
            "\nSAFETY REMINDER: This question involves a medical diagnosis or medication inquiry. "
            "Provide general educational principles only, do NOT diagnose or prescribe, "
            "and warmly suggest consulting a qualified healthcare professional for medical decisions."
        )

    prompt = (
        f"PREVIOUS CONVERSATION HISTORY:\n{history_str}\n\n"
        f"HERLIFE EDUCATIONAL GROUNDING KNOWLEDGE:\n{context_str}\n\n"
        f"CURRENT USER QUESTION: {question}\n\n"
        f"Please provide a complete, plain-text, adaptive conversational response:"
    )

    for model_name in models_to_try:
        try:
            response = _client.models.generate_content(
                model=model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    temperature=0.4,
                    max_output_tokens=750,
                ),
            )

            if response and response.text:
                cleaned_text = response.text.strip().replace("**", "")
                if cleaned_text:
                    return cleaned_text

        except Exception as e:
            logger.warning(f"Gemini API request failed for model {model_name}: {e}")

    return None
