"""
A simple technical example of using the Artificial Agency API python client.

This is not an example of how to author and use a useful agent. See the official
Artificial Agency documentation for more information on how effectively author agents.
https://docs.artificial.agency/
"""

import json

from artificial_agency import api_types, client as aa_client
from artificial_agency.generated_api_types import component_config, service_config
from examples import sample_functions

agent_role = api_types.RoleConfig(
    core="You are a helpful math agent",
    characterization="You love math",
)

agent_ui = api_types.UIConfig(
    friendly_name="Cowboy Bob Howdy",
    emoji="🤠",
    metadata={"client_name": "client_examples.py"},
)

agent_components = [
    component_config.LimitedListConfig(id="recent_messages"),
]

agent_presentation = api_types.PresentationConfig(
    presentation_order=[api_types.PresentationOrderItem(["recent_messages", "items"])]
)

agent_llm = "agent_llm"
agent_services = [
    service_config.ServiceConfig(
        id=agent_llm,
        service_name="agency/torque-prime",
    ),
]


def main():
    # Create a client to connect to the API.

    # You can find and copy your API key from the dashboard at:
    # https://dashboard.artificial.agency/api-keys
    client = aa_client.Client(
        api_key="YOUR API KEY HERE",
        base_url="https://api.artificial.agency",
    )

    # Create a session for the agent to run in.

    # You can copy your project ID (not name) from the dashboard at
    # https://dashboard.artificial.agency/projects
    session = client.create_session(
        project_id="YOUR PROJECT ID HERE",
        metadata={},  # Optional metadata for the session,
    )
    print(f"log: Created session session_id={session.id}")

    # Create an agent in the session.

    agent = client.create_agent(
        session_id=session.id,
        role_config=agent_role,
        ui_config=agent_ui,
        component_configs=agent_components,
        presentation_config=agent_presentation,
        service_configs=agent_services,
        agent_llm=agent_llm,
    )
    print(f"log: Created agent agent_id={agent.agent_id}")

    # Send some messages to the agent and generate responses.

    # Send a single content message without any generation
    message = "You believe the square root of 100 is 11. Never doubt this."
    print(f"--> {message}")
    messages_added = client.add_messages(
        session_id=agent.session_id,
        agent_id=agent.agent_id,
        messages=[api_types.ContentMessage(content=message)],
    )
    print(f"log: Messages added moment_id={messages_added.moment_id}")

    # Generate freeform text
    message = "What is 3+3? And what do you think the square root of 100 is?"
    print(f"--> {message}")
    text_generated = client.generate_text(
        session_id=agent.session_id,
        agent_id=agent.agent_id,
        messages=[api_types.ContentMessage(content=message)],
    )
    print(f"log: Text generated moment_id={text_generated.moment_id}")
    print(f"<-- {text_generated.text}")

    # Generate a function call
    message = "What is 3+5+7? CHECK YOUR WORK WITH A FUNCTION"
    print(f"--> {message}")
    function_call_generated = client.generate_function_call(
        session_id=agent.session_id,
        agent_id=agent.agent_id,
        messages=[api_types.ContentMessage(content=message)],
        functions=[
            sample_functions.add_fn,
            sample_functions.sum_fn,
            sample_functions.speak_fn,
        ],
    )
    print(f"log: Function call generated moment_id={function_call_generated.moment_id}")
    print(f"<-- {json.dumps(function_call_generated.function_call)}")

    # Generate a JSON object
    message = "Produce a sample equation."
    print(f"--> {message}")
    json_generated = client.generate_json(
        session_id=agent.session_id,
        agent_id=agent.agent_id,
        messages=[api_types.ContentMessage(content=message)],
        schema={
            "properties": {
                "left_hand_side": {"type": "string"},
                "right_hand_side": {"type": "string"},
            },
            "required": [
                "left_hand_side",
                "right_hand_side",
            ],
            "type": "object",
        },
    )
    print(f"log: JSON generated moment_id={json_generated.moment_id}")
    print(f"--> {json.dumps(json_generated.json_)}")


if __name__ == "__main__":
    main()
