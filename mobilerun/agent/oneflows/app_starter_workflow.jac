import builtins;

import importlib;

import json;

import logging;

import from workflows { Context, Workflow, step }

import from workflows.events { StartEvent, StopEvent }

glob logger: any = logging.getLogger("mobilerun");

glob asyncio: any;

"""
    A simple workflow that opens an app based on a description.

    The workflow uses an LLM to intelligently match the app description
    to an installed app's package name, then opens it.
    """
class AppStarter(Workflow) {
    def init(driver, llm, timeout: builtins.int = 60, stream: builtins.bool = False, **kwargs) {
        getattr(Workflow, "__init__")(self, timeout=timeout, **kwargs);
        self.driver = driver;
        self.llm = llm;
        self.stream = stream;
    }

    """
        Opens an app based on the provided description.

        Expected StartEvent attributes:
            - app_description (str): The name or description of the app to open

        Returns:
            StopEvent with the result of the open_app operation
        """
    @step
    async def open_app_step(ev: StartEvent, ctx: Context) -> StopEvent {
        app_description: any = ev.app_description;
        apps: any = (await self.driver.get_apps(include_system=True));
        apps_list: any = "\n".join([
            "- "
                + format(app["label"], "")
                + " (package: "
                + format(app["package_name"] if "package_name" in app else app["package"], "")
                + ")"
            for app in apps
        ]);
        prompt: any = f"Given the following list of installed apps and a user's description, determine which app package name to open.\n\nInstalled Apps:\n{apps_list}\n\nUser's Request: \"{app_description}\"\n\nReturn ONLY a JSON object with the following structure:\n{{\n    \"package\": \"com.example.package\"\n}}\n\nIf no app matches the user's request, return:\n{{\n    \"package\": null\n}}\n\nChoose the most appropriate app based on the description. Return the package name of the best match, or null if no app matches.";
        logger.info("📱 AppOpener response:", extra={"color": "blue"});
        response: any = (await acomplete_with_retries(self.llm, prompt, stream=self.stream));
        response_text: any = response.text.strip();
        try {
            start: any = response_text.find("{");
            end: any = response_text.rfind("}") + 1;
            json_str: any = response_text[start:end];
            result_json: any = json.loads(json_str);
            package_name: any = result_json["package"];
        } except (json.JSONDecodeError, KeyError, ValueError) as e {
            return StopEvent(result=f"Error parsing LLM response: {e}. Response: {response_text}");
        }

        if not package_name {
            logger.warning(f"No matching app found for: {app_description}");
            return StopEvent(
                result=f"Could not open app: no installed app matches '{app_description}'"
            );
        }

        logger.info(f"Starting app {package_name}");
        result: any = (await self.driver.start_app(package_name));

        return StopEvent(result=result);
    }
}

async def main -> any {
    import from mobilerun_core_local.driver.android { AndroidDriver }

    load_llm: any = importlib.import_module("mobilerun.agent.utils.llm_picker").load_llm;
    driver: any = AndroidDriver(serial=None);
    await driver.connect();
    llm: any = load_llm("OpenAIResponses", model="gpt-6.1-sol");
    workflow: any = AppStarter(driver=driver, llm=llm, timeout=60, verbose=True);
    result: any = await workflow.run(app_description="Settings");

    print(f"Result: {result}");
}

with entry:__main__ {
    import asyncio;

    asyncio.run(main());
}
