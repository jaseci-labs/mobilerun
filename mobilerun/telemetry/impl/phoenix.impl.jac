impl arize_phoenix_callback_handler(**kwargs: Any) -> BaseCallbackHandler {
    import from openinference.instrumentation.llama_index { LlamaIndexInstrumentor }
    import from openinference.semconv.resource { ResourceAttributes }
    import from opentelemetry.exporter.otlp.proto.http.trace_exporter { OTLPSpanExporter }
    import from opentelemetry.sdk { trace as trace_sdk }
    import from opentelemetry.sdk.resources { Resource }
    import from opentelemetry.sdk.trace.export { SimpleSpanProcessor }

    endpoint: any = kwargs.get("endpoint", os.getenv("phoenix_url", "http://0.0.0.0:6006"))
        + "/v1/traces";

    resource_attributes: any = {};
    phoenix_project_name: any = os.getenv("phoenix_project_name", "");
    if phoenix_project_name.strip() {
        resource_attributes[ResourceAttributes.PROJECT_NAME] = phoenix_project_name;
    }
    resource: any = Resource(attributes=resource_attributes);

    tracer_provider: any = trace_sdk.TracerProvider(resource=resource);
    tracer_provider.add_span_processor(SimpleSpanProcessor(OTLPSpanExporter(endpoint)));
    config: any = TraceConfig(base64_image_max_length=64000000);

    return LlamaIndexInstrumentor().instrument(
        tracer_provider=kwargs.get("tracer_provider", tracer_provider),
        separate_trace_from_runtime_context=kwargs.get("separate_trace_from_runtime_context"),
        config=config,
    );
}

impl _clean_span_async(
    span_name: builtins.str, func: Callable, args: builtins.tuple, kwargs: builtins.dict
) -> any {
    import from llama_index_instrumentation.dispatcher { active_instrument_tags }
    import from llama_index_instrumentation.span { active_span_id }

    span_id: any = f"{span_name}-{uuid.uuid4()}";
    bound_args: any = inspect.signature(func).bind(*args, **kwargs);
    is_method: any = "." in getattr(func, "__qualname__", "");
    instance: any = args[0] if args and is_method else None;

    tags: any = active_instrument_tags.get();
    token: any = active_span_id.set(span_id);
    parent_id: any = None if token.old_value is Token.MISSING else token.old_value;

    dispatcher.span_enter(
        id_=span_id, bound_args=bound_args, instance=instance, parent_id=parent_id, tags=tags
    );
    try {
        result: any = await func(*args, **kwargs);
    } except BaseException as e {
        dispatcher.span_drop(id_=span_id, bound_args=bound_args, instance=instance, err=e);
        raise;
    } else {
        dispatcher.span_exit(id_=span_id, bound_args=bound_args, instance=instance, result=result);
        return result;
    } finally {
        active_span_id.reset(token);
    }
}

impl clean_span(span_name: builtins.str) -> any {
    def decorator(func: Callable) -> Callable {
        if inspect.iscoroutinefunction(func) {
            @functools.wraps(func)
            def async_wrapper(*args_, **kwargs) -> any {
                args: any = tuple(args_);
                return _clean_span_async(span_name, func, args, kwargs);
            }

            return inspect.markcoroutinefunction(async_wrapper);
        }
        @functools.wraps(func)
        def wrapper(*args__, **kwargs) -> any {
            args: any = tuple(args__);
            import from llama_index_instrumentation.dispatcher { active_instrument_tags }
            import from llama_index_instrumentation.span { active_span_id }

            span_id = f"{span_name}-{uuid.uuid4()}";
            bound_args = inspect.signature(func).bind(*args, **kwargs);
            is_method: any = "." in getattr(func, "__qualname__", "");
            instance = args[0] if args and is_method else None;

            tags: any = active_instrument_tags.get();
            context = copy_context();
            token = active_span_id.set(span_id);
            parent_id: any = None if token.old_value is Token.MISSING else token.old_value;

            dispatcher.span_enter(
                id_=span_id,
                bound_args=bound_args,
                instance=instance,
                parent_id=parent_id,
                tags=tags,
            );
            result: any = None;
            try {
                result = func(*args, **kwargs);
                if isinstance(result, asyncio.Future) {
                    new_future: any = asyncio.ensure_future(result);

                    def _on_done(fut: asyncio.Future) -> None {
                        try {
                            fut_result: any = None if fut.exception() else fut.result();
                            dispatcher.span_exit(
                                id_=span_id,
                                bound_args=bound_args,
                                instance=instance,
                                result=fut_result,
                            );
                        } except Exception as e2 {
                            dispatcher.span_drop(
                                id_=span_id, bound_args=bound_args, instance=instance, err=e2
                            );
                            raise;
                        } finally {
                            try {
                                context.run(active_span_id.reset, token);
                            } except ValueError {}
                        }
                    }

                    new_future.add_done_callback(_on_done);
                    return new_future;
                }
            } except Exception as e {
                dispatcher.span_drop(id_=span_id, bound_args=bound_args, instance=instance, err=e);
                raise;
            } else {
                dispatcher.span_exit(
                    id_=span_id, bound_args=bound_args, instance=instance, result=result
                );
                return result;
            } finally {
                if not isinstance(result, asyncio.Future) {
                    active_span_id.reset(token);
                }
            }
        }

        return wrapper;
    }

    return decorator;
}
