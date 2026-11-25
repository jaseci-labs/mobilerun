import builtins;

import from typing { Any, Dict }

glob VERSION: any = 6;

glob _OLD_DEFAULT: any = {"click_at", "click_area", "long_press_at"};

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
