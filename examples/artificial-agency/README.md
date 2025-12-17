# Artificial Agency Python Client

A Python client library for the [Artificial.Agency API](https://docs.artificial.agency/), enabling you to create and interact with AI agents programmatically.

## Installation

```bash
uv add artificial-agency
```

## Quick Start

### Basic Setup

```python
from artificial_agency import client as aa_client, api_types
from artificial_agency.generated_api_types import component_config, service_config

# Initialize the client with your API key
client = aa_client.Client(
    api_key="YOUR_API_KEY_HERE",
    base_url="https://api.artificial.agency"
)

# Create a session
session = client.create_session(
    project_id="YOUR_PROJECT_ID_HERE",
    metadata={"example": "quick_start"}
)

# Configure your agent
agent_role = api_types.RoleConfig(
    core="You are a helpful assistant",
    characterization="You are friendly and knowledgeable"
)

agent_ui = api_types.UIConfig(
    friendly_name="My Agent",
    emoji="🤖"
)

agent_components = [
    component_config.LimitedListConfig(id="recent_messages")
]

agent_presentation = api_types.PresentationConfig(
    presentation_order=[api_types.PresentationOrderItem(["recent_messages", "items"])]
)

agent_services = [
    service_config.OpenAILLMConfig(
        id="agent_llm",
        model=service_config.OpenAILLMVersions.gpt_4o_mini
    )
]

# Create the agent
agent = client.create_agent(
    session_id=session.id,
    role_config=agent_role,
    ui_config=agent_ui,
    component_configs=agent_components,
    presentation_config=agent_presentation,
    service_configs=agent_services,
    agent_llm="agent_llm"
)

# Generate a response
response = client.generate_text(
    session_id=agent.session_id,
    agent_id=agent.agent_id,
    messages=[api_types.ContentMessage(content="Hello! How are you?")]
)

print(response.text)
```

## API Reference

### Client Classes

#### `Client`

Synchronous client for the Artificial Agency API.

```python
from artificial_agency import client

client = client.Client(
    api_key="your_api_key",
    base_url="https://api.artificial.agency",  # optional, defaults to production
    timeout=45.0  # optional, defaults to 45 seconds
)
```

#### `AsyncClient`

Asynchronous client for the Artificial Agency API.

```python
from artificial_agency import async_client

async_client = async_client.AsyncClient(
    api_key="your_api_key",
    base_url="https://api.artificial.agency",  # optional, defaults to production
    timeout=45.0  # optional, defaults to 45 seconds
)
```

### Core Methods

#### Session Management

##### `create_session()`

Create a new session for agent interactions.

```python
session = client.create_session(
    project_id="your_project_id",
    metadata={"key": "value"},  # optional
    expires_in=3600,  # optional, seconds
    max_requests=100  # optional
)
```

##### `clone_session()`

Create a new session from an existing session at a specific moment.

```python
new_session = client.clone_session(
    session_id="existing_session_id",
    moment_id="specific_moment_id",  # optional, defaults to latest
    project_id="new_project_id",  # optional
    metadata={"cloned_from": "original_session"}
)
```

#### Agent Management

##### `create_agent()`

Create a new agent within a session.

```python
agent = client.create_agent(
    session_id=session.id,
    role_config=role_config,
    presentation_config=presentation_config,
    component_configs=component_configs,
    service_configs=service_configs,
    agent_llm="llm_service_id",
    ui_config=ui_config  # optional
)
```

#### Interaction Methods

##### `add_messages()`

Send messages to the agent without generating a response.

```python
messages_added = client.add_messages(
    session_id=agent.session_id,
    agent_id=agent.agent_id,
    messages=[
        api_types.ContentMessage(content="User message"),
        api_types.KVMessage(key="context", value="additional_info")
    ]
)
```

##### `generate_text()`

Generate a freeform text response from the agent.

```python
text_response = client.generate_text(
    session_id=agent.session_id,
    agent_id=agent.agent_id,
    messages=[api_types.ContentMessage(content="What is 2+2?")],
    cue="Please be helpful",  # optional
    service_id="specific_service",  # optional
    presentation_config=custom_presentation  # optional
)
```

##### `generate_function_call()`

Generate a function call that the agent wants to execute.

```python
function_call = client.generate_function_call(
    session_id=agent.session_id,
    agent_id=agent.agent_id,
    messages=[api_types.ContentMessage(content="Calculate 5+3")],
    functions=[
        api_types.FunctionDescription(
            name="add",
            docs="Add two numbers",
            parameters={
                "x": api_types.SimpleParameter(value_type="integer", docs="first number"),
                "y": api_types.SimpleParameter(value_type="integer", docs="second number")
            },
            required=["x", "y"]
        )
    ]
)
```

##### `generate_json()`

Generate a structured JSON response according to a schema.

```python
json_response = client.generate_json(
    session_id=agent.session_id,
    agent_id=agent.agent_id,
    messages=[api_types.ContentMessage(content="Create a user profile")],
    schema={
        "type": "object",
        "properties": {
            "name": {"type": "string"},
            "age": {"type": "integer"},
            "email": {"type": "string"}
        },
        "required": ["name", "age"]
    }
)
```

### Configuration Types

#### `RoleConfig`

Defines the agent's personality and behavior.

```python
role_config = api_types.RoleConfig(
    core="You are a helpful math tutor",
    characterization="You love explaining complex concepts simply"
)
```

#### `UIConfig`

Defines how the agent appears in user interfaces.

```python
ui_config = api_types.UIConfig(
    friendly_name="Math Tutor",
    emoji="🧮",
    metadata={"specialty": "calculus"}
)
```

#### `PresentationConfig`

Defines how information is presented to the agent.

```python
presentation_config = api_types.PresentationConfig(
    presentation_order=[
        api_types.PresentationOrderItem(["recent_messages", "items"]),
        api_types.PresentationOrderItem(["user_context", "data"])
    ]
)
```

#### Component Configurations

Various component types for storing and managing agent state:

- `LimitedListConfig` - Maintains a list of recent items
- `KVStoreConfig` - Key-value storage
- `TextBlockConfig` - Freeform text content
- `StaticTextConfig` - Immutable freeform text content

#### Service Configurations

LLM service configurations:

```python
# OpenAI Configuration
openai_config = service_config.OpenAILLMConfig(
    id="gpt4",
    model=service_config.OpenAILLMVersions.gpt_4o_mini
)

# Agency LLM Configuration
agency_config = service_config.AgencyLLMConfig(
    id="agency_llm",
    model="your_agency_model"
)
```

### Message Types

#### `ContentMessage`

Unstructured text messages.

```python
message = api_types.ContentMessage(content="Hello, agent!")
```

#### `KVMessage`

Key-value data messages.

```python
kv_message = api_types.KVMessage(key="user_id", value="12345")
```

#### `KVDelTreeMessage`

Delete a subtree of hierarchical key-value data

```python
delete_message = api_types.KVDelTreeMessage(key="user_data")
```

## Examples

### Complete Agent Example

See `examples/client_example.py` for a complete working example that demonstrates:

- Creating sessions and agents
- Sending messages
- Generating text responses
- Making function calls
- Generating structured JSON

### Function Definitions

See `examples/sample_functions.py` for examples of how to define functions that agents can call, including:

- Simple parameter functions
- Array parameter functions
- Optional parameters
- Enumeration parameters

## Error Handling

The client raises specific exception types for different error conditions:

```python
from artificial_agency import errors

try:
    response = client.generate_text(...)
except errors.APIError as e:
    print(f"API Error: {e.message}")
except errors.APITimeoutError as e:
    print(f"Request timed out: {e.message}")
except errors.APIResponseValidationError as e:
    print(f"Invalid response format: {e.message}")
```

## Getting API Credentials

1. Visit [https://dashboard.artificial.agency/api-keys](https://dashboard.artificial.agency/api-keys) to get your API key
2. Visit [https://dashboard.artificial.agency/projects](https://dashboard.artificial.agency/projects) to get your project ID

## Requirements

- Python 3.11+
- httpx >= 0.27.2
- pydantic

## Development

For development dependencies:

```bash
uv add --dev artificial-agency
```

This includes:
- respx (for testing)
- pytest

## License

This library is part of the Artificial Agency platform. See the main project documentation for licensing information.
