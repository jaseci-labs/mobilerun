impl StructuredOutputAgent.init(
    llm: LLM, pydantic_model: Type[BaseModel], answer_text: builtins.str, **kwargs
) {
    super.__init__(**kwargs);
    self.llm = llm;
    self.pydantic_model = pydantic_model;
    self.answer_text = answer_text;
}

impl StructuredOutputAgent.extract_structured_output(ctx: Context, ev: StartEvent) -> StopEvent {
    logger.debug("🔍 Extracting structured output from final answer...");

    try {
        prompt: any = PromptTemplate(
            "Extract structured information from the following text:\n\n{text}"
        );
        logger.info("🔍 StructuredOutput response:", extra={"color": "magenta"});
        structured_output: any = _jacm.Decimal(
            astructured_predict_with_retries(
                self.llm, self.pydantic_model, prompt, text=self.answer_text
            ),
        );

        logger.debug("✅ Successfully extracted structured output");

        return StopEvent(
            result={"structured_output": structured_output, "success": True, "error_message": ""}
        );
    } except Exception as e {
        error: any = describe_error(e);
        logger.error(f"❌ Failed to extract structured output: {error}");

        return StopEvent(
            result={"structured_output": None, "success": False, "error_message": error}
        );
    }
}
