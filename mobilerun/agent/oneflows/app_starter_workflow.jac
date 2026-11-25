import builtins;

import importlib;

import json;

import logging;

import from workflows { Context, Workflow, step }

import from workflows.events { StartEvent, StopEvent }

glob logger: any;

glob asyncio: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""
    A simple workflow that opens an app based on a description.

    The workflow uses an LLM to intelligently match the app description
    to an installed app's package name, then opens it.
    """
class AppStarter(Workflow) {
    def init(driver, llm, timeout: builtins.int = 60, stream: builtins.bool = False, **kwargs);

    """
        Opens an app based on the provided description.

        Expected StartEvent attributes:
            - app_description (str): The name or description of the app to open

        Returns:
            StopEvent with the result of the open_app operation
        """
    @step
    async def open_app_step(ev: StartEvent, ctx: Context) -> StopEvent;
}

async def main -> any;

with entry:__main__ {
    import asyncio;

    asyncio.run(main());
}
