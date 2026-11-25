"""
StructuredOutputAgent - Extract structured data from final answers.

Takes a raw text answer and a Pydantic model, uses structured_predict()
to extract structured data from the text.
"""

import builtins;

import decimal as _jacm;

import logging;

import from typing { Type }

import from llama_index.core.llms.llm { LLM }

import from llama_index.core.prompts { PromptTemplate }

import from llama_index.core.workflow { Context, StartEvent, StopEvent, Workflow, step }

import from pydantic { BaseModel }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""
    Agent that extracts structured output from text answers.

    Uses LLM.structured_predict() to parse text into Pydantic models.
    """
class StructuredOutputAgent(Workflow) {
    def init(llm: LLM, pydantic_model: Type[BaseModel], answer_text: builtins.str, **kwargs);

    """
        Extract structured output using structured_predict().
        """
    @step
    def extract_structured_output(ctx: Context, ev: StartEvent) -> StopEvent;
}
