import "@typespec/openapi";
using TypeSpec.OpenAPI;
namespace Azure.AI.Projects;

// Foundry-owned Live voice-agent configuration. Deliberately does not import the entire
// OpenAI Live transport/event API. Shapes follow the supplied Live startup specification.

/** Native startup audio settings shared by both directions of a primary WebSocket. */
model LiveInitialSessionAudioParam {
  /** Startup-only wire format. Omission uses native PCM16 at 24 kHz. */
  format?: LiveAudioFormat;

  /** Startup-only speech output settings. */
  output?: LiveInitialSessionAudioOutputParam;
}

/** Native output voice, selected before the session starts. */
model LiveInitialSessionAudioOutputParam {
  /** Built-in voice name, or a custom voice ID. Not an Azure speech-provider object. */
  @oneOf
  voice?: string | LiveCustomVoiceParam;
}

/** A custom native Live voice. */
model LiveCustomVoiceParam {
  /** Voice identifier. */
  @minLength(1)
  @maxLength(128)
  id: string;
}

/** Bidirectional native audio format. The sample rate depends on the format subtype. */
@discriminator("type")
model LiveAudioFormat {
  /** Native media type. */
  type: string;
}

/** Mono, little-endian signed 16-bit PCM audio. */
model LiveSessionAudioFormatPCMParam extends LiveAudioFormat {
  type: "audio/pcm";

  /** PCM sample rate in Hz. */
  rate: 16000 | 24000;
}

/** G.711 mu-law audio. */
model LiveSessionAudioFormatPCMUParam extends LiveAudioFormat {
  type: "audio/pcmu";

  /** Mu-law sample rate in Hz. */
  rate: 8000;
}

/** G.711 A-law audio. */
model LiveSessionAudioFormatPCMAParam extends LiveAudioFormat {
  type: "audio/pcma";

  /** A-law sample rate in Hz. */
  rate: 8000;
}

/** The owner of work delegated by the Live frontend. */
@discriminator("type")
model LiveDelegation {
  /** Delegation owner. */
  type: string;
}

/** The application receives delegation events and supplies approved context. */
model LiveClientDelegationParam extends LiveDelegation {
  type: "client";
}

/** Live manages a Responses backend for delegated work. */
model LiveResponsesDelegationParam extends LiveDelegation {
  type: "responses";

  /** Backend deployment, instructions, and tool configuration. */
  responses: LiveResponsesDelegationSettingsInputParam;
}

/** The supported subset of Responses configuration for native Live delegation. */
model LiveResponsesDelegationSettingsInputParam {
  /** Backend Responses deployment name, distinct from the frontend Live deployment. */
  @minLength(1)
  `model`: string;

  /** Business rules and tool workflows for the backend, not the frontend prompt. */
  instructions?: string | null;

  /** Maximum backend output-token count. */
  max_output_tokens?: int32 | null;

  /** Backend scheduling tier. */
  service_tier?: LiveResponsesServiceTier | null;

  /** Backend reasoning configuration. */
  reasoning?: LiveDelegationReasoningInputParam | null;

  /** Backend text configuration. */
  text?: LiveDelegationTextInputParam | null;

  /** Tools available to the delegated backend. */
  tools?: LiveBackendTool[];

  /** Automatic policy or a named function/MCP selection. */
  @oneOf
  tool_choice?: LiveToolChoiceEnum | LiveNamedToolChoice;

  /** Whether independent tools may be called in parallel. */
  parallel_tool_calls?: boolean | null;
}

/** Native backend service tiers. */
enum LiveResponsesServiceTier {
  auto,
  default,
  fast_tier_temp_pilot,
  flex,
  priority,
  ultrafast,
}
/** Native backend reasoning efforts. */
enum LiveReasoningEffort {
  none,
  minimal,
  low,
  medium,
  high,
  xhigh,
}
/** Native backend reasoning summary modes. */
enum LiveReasoningSummary {
  concise,
  detailed,
  auto,
}
/** Native backend output verbosity. */
enum LiveTextVerbosity {
  low,
  medium,
  high,
}
/** Backend tool-choice policies. */
enum LiveToolChoiceEnum {
  auto,
  none,
  required,
}

/** Reasoning settings for delegated work. */
model LiveDelegationReasoningInputParam {
  /** Backend reasoning effort. */
  effort?: LiveReasoningEffort | null;

  /** Backend reasoning summary. */
  summary?: LiveReasoningSummary | null;
}
/** Text settings for delegated work. */
model LiveDelegationTextInputParam {
  /** Backend output verbosity. */
  verbosity?: LiveTextVerbosity | null;
}

/** Tools supported by the Live-managed Responses backend. */
@discriminator("type")
model LiveBackendTool {
  /** Tool kind. */
  type: string;
}
/** A function that can be called by the backend model. */
model LiveFunctionToolInputParam extends LiveBackendTool {
  type: "function";

  /** Function name. */
  name: string;

  /** Function description. */
  description?: string | null;

  /** Customer-provided JSON Schema. This field is intentionally open. */
  parameters?: Record<unknown> | null;

  /** Whether schema adherence is strict. */
  strict?: boolean | null;
}
/** The native web-search tool. */
model LiveWebSearchToolInputParam extends LiveBackendTool {
  type: "web_search";
}

/** A specific backend tool selection. */
@discriminator("type")
model LiveNamedToolChoice {
  /** Tool kind. */
  type: string;

  /** Selected tool name. */
  name: string;
}
/** Select one function. */
model LiveFunctionToolChoiceParam extends LiveNamedToolChoice {
  type: "function";
}
/** Select one MCP server/tool. */
model LiveMCPToolChoiceParam extends LiveNamedToolChoice {
  type: "mcp";

  /** Selected MCP server label. */
  server_label: string;
}

/** Optional status of an initial message. */
enum LiveInitialMessageStatus {
  incomplete,
  completed,
}

/** A text-only message used as initial Live context. */
@discriminator("role")
model LiveInitialItem {
  /** Message author. */
  role: string;

  /** Optional message identifier. */
  id?: string;

  /** Optional message type; defaults to message when omitted. */
  type?: "message";

  /** Optional message status. */
  status?: LiveInitialMessageStatus;
}
/** Initial developer instructions. */
model LiveInitialDeveloperMessageItemParam extends LiveInitialItem {
  role: "developer";

  /** Exactly one input-text content part. */
  @minItems(1)
  @maxItems(1)
  content: LiveInitialInputTextContentPartParam[];
}
/** Initial user context. */
model LiveInitialUserMessageItemParam extends LiveInitialItem {
  role: "user";

  /** Exactly one input-text content part. */
  @minItems(1)
  @maxItems(1)
  content: LiveInitialInputTextContentPartParam[];
}
/** Initial assistant context. */
model LiveInitialAssistantMessageItemParam extends LiveInitialItem {
  role: "assistant";

  /** Exactly one assistant text part. */
  @minItems(1)
  @maxItems(1)
  content: LiveInitialAssistantTextContentPart[];
}
/** An initial developer/user text part. */
model LiveInitialInputTextContentPartParam {
  /** Optional input-text discriminator. */
  type?: "input_text";

  /** Text content. */
  text: string;
}
/** An initial assistant text part. */
model LiveInitialAssistantTextContentPart {
  /** Optional text discriminator; omission uses text. */
  type?: "text" | "output_text";

  /** Text content. */
  text: string;
}

/** Frontend connection settings. */
model LiveClientConfigParam {
  /** Data-channel permission configuration. */
  data_channel: LiveDataChannelConfigParam;
}
/** Native data-channel event permissions. */
model LiveDataChannelConfigParam {
  /** All events or an explicit allowlist of client event names. */
  @oneOf
  allowed_client_events?: "all" | string[];

  /** All events or an explicit allowlist of server event selectors. */
  @oneOf
  allowed_server_events?: "all" | LiveAllowedServerEventParam[];
}
/** A server event selector, optionally narrowed to a nested Responses event. */
model LiveAllowedServerEventParam {
  /** Native server event name. */
  type: string;

  /** Required for response.event; not applicable to other native event types. */
  response_event?: string;
}
