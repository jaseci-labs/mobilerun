"""
Manager Agent - Planning and reasoning workflow.

Two variants available:
- ManagerAgent: Stateful, maintains chat history
- StatelessManagerAgent: Stateless, rebuilds context each turn
"""

glob __all__: any = [
    "ManagerAgent",
    "StatelessManagerAgent",
    "ManagerInputEvent",
    "ManagerPlanEvent",
    "ManagerContextEvent",
    "ManagerResponseEvent",
    "ManagerPlanDetailsEvent",
    "parse_manager_response",
];
