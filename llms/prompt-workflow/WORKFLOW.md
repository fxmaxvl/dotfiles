PROMPT_WORKFLOW
1. Brainstorm: initial + finalization (Use a conversational LLM to hone in on an idea (I use ChatGPT 4o / o3 for this))
   output: spec.md
2. Planing:Take the spec and pass it to a proper reasoning model (o1*, o3*, r1):
   output: prompt_plan.md and todo.md - todo md is ready for codegen.

3. Execution: use prompt_plan.md and todo.md as inputs to a code generation mode
