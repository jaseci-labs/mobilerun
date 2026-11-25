impl PromptLoader._get_environment -> ImmutableSandboxedEnvironment {
    if cls._env is None {
        cls._env = ImmutableSandboxedEnvironment(
            trim_blocks=True, lstrip_blocks=True, keep_trailing_newline=False
        );
    }

    return cls._env;
}

impl PromptLoader.load_prompt(
    file_path: builtins.str, variables: Dict[builtins.str, Any] = None
) -> builtins.str {
    path: any = Path(file_path);

    if not path.exists() {
        raise FileNotFoundError(f"Prompt file not found: {file_path}");
    }
    f: any;
    async with (aiofiles.open(path, mode="r", encoding="utf-8")) as f {
        template_content: any = (await f.read());
    }
    return PromptLoader.render_template(template_content, variables);
}

impl PromptLoader.render_template(
    template_string: builtins.str, variables: Dict[builtins.str, Any] = None
) -> builtins.str {
    env: any = PromptLoader._get_environment();
    template: any = env.from_string(template_string);
    return template.render(**(variables or {}));
}
