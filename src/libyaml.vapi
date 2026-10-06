/* libyaml.vapi - Vala bindings for libyaml (yaml.h, 0.2.x)
 *
 * Build:  valac --vapidir=. --pkg libyaml -X -lyaml -X -Wno-pointer-sign app.vala
 *
 * Notes
 *  - yaml_char_t (unsigned char *) is bound as `string` for convenience, which makes
 *    gcc emit -Wpointer-sign warnings; -X -Wno-pointer-sign silences them.
 *  - Parser, Emitter and Document free themselves at scope exit (destroy_function).
 *  - Event and Token must be freed manually with @delete() after parse()/scan().
 *    Do NOT call @delete() on an event you passed to Emitter.emit(): the emitter
 *    takes ownership of it.
 *  - set_input_string() / set_output_string() do not copy the buffer; keep it alive.
 *  - Event.data / Node.data are C unions. They are bound as structs holding every
 *    member, so access fields directly (ev.data.scalar.value) and never copy the
 *    nested sub-structs into locals.
 *  - The scanner token `data` union is not bound (only type and marks).
 */

[CCode (cheader_filename = "yaml.h", cprefix = "yaml_", lower_case_cprefix = "yaml_")]
namespace Yaml {

	public void get_version (out int major, out int minor, out int patch);
	[CCode (cname = "yaml_get_version_string")]
	public unowned string get_version_string ();

	/* ---- Standard tags ---- */
	[CCode (cname = "YAML_NULL_TAG")] public const string NULL_TAG;
	[CCode (cname = "YAML_BOOL_TAG")] public const string BOOL_TAG;
	[CCode (cname = "YAML_STR_TAG")] public const string STR_TAG;
	[CCode (cname = "YAML_INT_TAG")] public const string INT_TAG;
	[CCode (cname = "YAML_FLOAT_TAG")] public const string FLOAT_TAG;
	[CCode (cname = "YAML_TIMESTAMP_TAG")] public const string TIMESTAMP_TAG;
	[CCode (cname = "YAML_SEQ_TAG")] public const string SEQ_TAG;
	[CCode (cname = "YAML_MAP_TAG")] public const string MAP_TAG;
	[CCode (cname = "YAML_DEFAULT_SCALAR_TAG")] public const string DEFAULT_SCALAR_TAG;
	[CCode (cname = "YAML_DEFAULT_SEQUENCE_TAG")] public const string DEFAULT_SEQUENCE_TAG;
	[CCode (cname = "YAML_DEFAULT_MAPPING_TAG")] public const string DEFAULT_MAPPING_TAG;

	/* ---- Enumerations ---- */

	[CCode (cname = "yaml_encoding_t", cprefix = "YAML_", has_type_id = false)]
	public enum Encoding {
		ANY_ENCODING,
		UTF8_ENCODING,
		UTF16LE_ENCODING,
		UTF16BE_ENCODING
	}

	[CCode (cname = "yaml_break_t", cprefix = "YAML_", has_type_id = false)]
	public enum Break {
		ANY_BREAK,
		CR_BREAK,
		LN_BREAK,
		CRLN_BREAK
	}

	[CCode (cname = "yaml_error_type_t", cprefix = "YAML_", has_type_id = false)]
	public enum ErrorType {
		NO_ERROR,
		MEMORY_ERROR,
		READER_ERROR,
		SCANNER_ERROR,
		PARSER_ERROR,
		COMPOSER_ERROR,
		WRITER_ERROR,
		EMITTER_ERROR
	}

	[CCode (cname = "yaml_scalar_style_t", cprefix = "YAML_", has_type_id = false)]
	public enum ScalarStyle {
		ANY_SCALAR_STYLE,
		PLAIN_SCALAR_STYLE,
		SINGLE_QUOTED_SCALAR_STYLE,
		DOUBLE_QUOTED_SCALAR_STYLE,
		LITERAL_SCALAR_STYLE,
		FOLDED_SCALAR_STYLE
	}

	[CCode (cname = "yaml_sequence_style_t", cprefix = "YAML_", has_type_id = false)]
	public enum SequenceStyle {
		ANY_SEQUENCE_STYLE,
		BLOCK_SEQUENCE_STYLE,
		FLOW_SEQUENCE_STYLE
	}

	[CCode (cname = "yaml_mapping_style_t", cprefix = "YAML_", has_type_id = false)]
	public enum MappingStyle {
		ANY_MAPPING_STYLE,
		BLOCK_MAPPING_STYLE,
		FLOW_MAPPING_STYLE
	}

	[CCode (cname = "yaml_token_type_t", cprefix = "YAML_", has_type_id = false)]
	public enum TokenType {
		NO_TOKEN,
		STREAM_START_TOKEN,
		STREAM_END_TOKEN,
		VERSION_DIRECTIVE_TOKEN,
		TAG_DIRECTIVE_TOKEN,
		DOCUMENT_START_TOKEN,
		DOCUMENT_END_TOKEN,
		BLOCK_SEQUENCE_START_TOKEN,
		BLOCK_MAPPING_START_TOKEN,
		BLOCK_END_TOKEN,
		FLOW_SEQUENCE_START_TOKEN,
		FLOW_SEQUENCE_END_TOKEN,
		FLOW_MAPPING_START_TOKEN,
		FLOW_MAPPING_END_TOKEN,
		BLOCK_ENTRY_TOKEN,
		FLOW_ENTRY_TOKEN,
		KEY_TOKEN,
		VALUE_TOKEN,
		ALIAS_TOKEN,
		ANCHOR_TOKEN,
		TAG_TOKEN,
		SCALAR_TOKEN
	}

	[CCode (cname = "yaml_event_type_t", cprefix = "YAML_", has_type_id = false)]
	public enum EventType {
		NO_EVENT,
		STREAM_START_EVENT,
		STREAM_END_EVENT,
		DOCUMENT_START_EVENT,
		DOCUMENT_END_EVENT,
		ALIAS_EVENT,
		SCALAR_EVENT,
		SEQUENCE_START_EVENT,
		SEQUENCE_END_EVENT,
		MAPPING_START_EVENT,
		MAPPING_END_EVENT
	}

	[CCode (cname = "yaml_node_type_t", cprefix = "YAML_", has_type_id = false)]
	public enum NodeType {
		NO_NODE,
		SCALAR_NODE,
		SEQUENCE_NODE,
		MAPPING_NODE
	}

	/* ---- Basic structures ---- */

	[CCode (cname = "yaml_version_directive_t", has_type_id = false)]
	public struct VersionDirective {
		public int major;
		public int minor;
	}

	[CCode (cname = "yaml_tag_directive_t", has_type_id = false)]
	public struct TagDirective {
		public unowned string handle;
		public unowned string prefix;
	}

	[CCode (cname = "yaml_mark_t", has_type_id = false)]
	public struct Mark {
		public size_t index;
		public size_t line;
		public size_t column;
	}

	/* Sub-structures used inside the Event/Node unions (access fields directly) */

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.document_start.tag_directives)", has_type_id = false)]
	public struct EventTagDirectives {
		public TagDirective* start;
		public TagDirective* end;
	}

	[CCode (cname = "__typeof__(((yaml_document_t*)0)->tag_directives)", has_type_id = false)]
	public struct DocumentTagDirectives {
		public TagDirective* start;
		public TagDirective* end;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.stream_start)", has_type_id = false)]
	public struct EventStreamStart {
		public Encoding encoding;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.document_start)", has_type_id = false)]
	public struct EventDocumentStart {
		public VersionDirective* version_directive;
		public EventTagDirectives tag_directives;
		public bool implicit;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.document_end)", has_type_id = false)]
	public struct EventDocumentEnd {
		public bool implicit;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.alias)", has_type_id = false)]
	public struct EventAlias {
		public unowned string anchor;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.scalar)", has_type_id = false)]
	public struct EventScalar {
		public unowned string? anchor;
		public unowned string? tag;
		public unowned string value;
		public size_t length;
		public bool plain_implicit;
		public bool quoted_implicit;
		public ScalarStyle style;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.sequence_start)", has_type_id = false)]
	public struct EventSequenceStart {
		public unowned string? anchor;
		public unowned string? tag;
		public bool implicit;
		public SequenceStyle style;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data.mapping_start)", has_type_id = false)]
	public struct EventMappingStart {
		public unowned string? anchor;
		public unowned string? tag;
		public bool implicit;
		public MappingStyle style;
	}

	[CCode (cname = "__typeof__(((yaml_event_t*)0)->data)", has_type_id = false)]
	public struct EventData {
		public EventStreamStart stream_start;
		public EventDocumentStart document_start;
		public EventDocumentEnd document_end;
		public EventAlias alias;
		public EventScalar scalar;
		public EventSequenceStart sequence_start;
		public EventMappingStart mapping_start;
	}

	/* ---- Tokens (data union not bound) ---- */

	[CCode (cname = "yaml_token_t", has_type_id = false, lower_case_cprefix = "yaml_token_")]
	public struct Token {
		public TokenType type;
		public Mark start_mark;
		public Mark end_mark;

		[CCode (cname = "yaml_token_delete")]
		public void @delete ();
	}

	/* ---- Events ---- */

	[CCode (cname = "yaml_event_t", has_type_id = false, lower_case_cprefix = "yaml_event_")]
	public struct Event {
		public EventType type;
		public EventData data;
		public Mark start_mark;
		public Mark end_mark;

		[CCode (cname = "yaml_event_delete")]
		public void @delete ();

		[CCode (cname = "yaml_stream_start_event_initialize")]
		public bool stream_start_init (Encoding encoding);

		[CCode (cname = "yaml_stream_end_event_initialize")]
		public bool stream_end_init ();

		[CCode (cname = "yaml_document_start_event_initialize")]
		public bool document_start_init (VersionDirective* version_directive,
		                                 TagDirective* tag_directives_start,
		                                 TagDirective* tag_directives_end,
		                                 bool implicit);

		[CCode (cname = "yaml_document_end_event_initialize")]
		public bool document_end_init (bool implicit);

		[CCode (cname = "yaml_alias_event_initialize")]
		public bool alias_init (string anchor);

		/* pass length = -1 for a NUL-terminated value */
		[CCode (cname = "yaml_scalar_event_initialize")]
		public bool scalar_init (string? anchor, string? tag, string value, int length,
		                         bool plain_implicit, bool quoted_implicit,
		                         ScalarStyle style);

		[CCode (cname = "yaml_sequence_start_event_initialize")]
		public bool sequence_start_init (string? anchor, string? tag, bool implicit,
		                                 SequenceStyle style);

		[CCode (cname = "yaml_sequence_end_event_initialize")]
		public bool sequence_end_init ();

		[CCode (cname = "yaml_mapping_start_event_initialize")]
		public bool mapping_start_init (string? anchor, string? tag, bool implicit,
		                                MappingStyle style);

		[CCode (cname = "yaml_mapping_end_event_initialize")]
		public bool mapping_end_init ();
	}

	/* ---- Document / nodes ---- */

	[CCode (cname = "yaml_node_item_t", has_type_id = false)]
	[SimpleType]
	public struct NodeItem : int {
	}

	[CCode (cname = "yaml_node_pair_t", has_type_id = false)]
	public struct NodePair {
		public int key;
		public int value;
	}

	[CCode (cname = "__typeof__(((yaml_node_t*)0)->data.sequence.items)", has_type_id = false)]
	public struct NodeItemStack {
		public int* start;
		public int* end;
		public int* top;
	}

	[CCode (cname = "__typeof__(((yaml_node_t*)0)->data.mapping.pairs)", has_type_id = false)]
	public struct NodePairStack {
		public NodePair* start;
		public NodePair* end;
		public NodePair* top;
	}

	[CCode (cname = "__typeof__(((yaml_node_t*)0)->data.scalar)", has_type_id = false)]
	public struct NodeScalar {
		public unowned string value;
		public size_t length;
		public ScalarStyle style;
	}

	[CCode (cname = "__typeof__(((yaml_node_t*)0)->data.sequence)", has_type_id = false)]
	public struct NodeSequence {
		public NodeItemStack items;
		public SequenceStyle style;
	}

	[CCode (cname = "__typeof__(((yaml_node_t*)0)->data.mapping)", has_type_id = false)]
	public struct NodeMapping {
		public NodePairStack pairs;
		public MappingStyle style;
	}

	[CCode (cname = "__typeof__(((yaml_node_t*)0)->data)", has_type_id = false)]
	public struct NodeData {
		public NodeScalar scalar;
		public NodeSequence sequence;
		public NodeMapping mapping;
	}

	[CCode (cname = "yaml_node_t", has_type_id = false)]
	public struct Node {
		public NodeType type;
		public unowned string? tag;
		public NodeData data;
		public Mark start_mark;
		public Mark end_mark;
	}

	[CCode (cname = "__typeof__(((yaml_document_t*)0)->nodes)", has_type_id = false)]
	public struct NodeStack {
		public Node* start;
		public Node* end;
		public Node* top;
	}

	[CCode (cname = "yaml_document_t", has_type_id = false,
	        destroy_function = "yaml_document_delete",
	        lower_case_cprefix = "yaml_document_")]
	public struct Document {
		public NodeStack nodes;
		public VersionDirective* version_directive;
		public DocumentTagDirectives tag_directives;
		public bool start_implicit;
		public bool end_implicit;
		public Mark start_mark;
		public Mark end_mark;

		[CCode (cname = "yaml_document_initialize")]
		public bool initialize (VersionDirective* version_directive,
		                        TagDirective* tag_directives_start,
		                        TagDirective* tag_directives_end,
		                        bool start_implicit, bool end_implicit);

		/* node indices are 1-based; returns null if out of range */
		public Node* get_node (int index);
		public Node* get_root_node ();

		/* each add_* returns the new node's index, or 0 on error */
		public int add_scalar (string? tag, string value, int length, ScalarStyle style);
		public int add_sequence (string? tag, SequenceStyle style);
		public int add_mapping (string? tag, MappingStyle style);

		public bool append_sequence_item (int sequence, int item);
		public bool append_mapping_pair (int mapping, int key, int value);
	}

	/* ---- Parser ---- */

	[CCode (cname = "yaml_read_handler_t", has_target = false)]
	public delegate int ReadHandler (void* data, uint8* buffer, size_t size,
	                                 out size_t size_read);

	[CCode (cname = "yaml_parser_t", has_type_id = false,
	        destroy_function = "yaml_parser_delete",
	        lower_case_cprefix = "yaml_parser_")]
	public struct Parser {
		public ErrorType error;
		public unowned string? problem;
		public size_t problem_offset;
		public int problem_value;
		public Mark problem_mark;
		public unowned string? context;
		public Mark context_mark;

		public bool initialize ();

		public void set_input_string ([CCode (array_length_type = "size_t")] uint8[] input);
		public void set_input_file (GLib.FileStream file);
		public void set_input (ReadHandler handler, void* data);
		public void set_encoding (Encoding encoding);

		public bool scan (out Token token);
		public bool parse (out Event event);
		public bool load (out Document document);
	}

	/* ---- Emitter ---- */

	[CCode (cname = "yaml_write_handler_t", has_target = false)]
	public delegate int WriteHandler (void* data, uint8* buffer, size_t size);

	[CCode (cname = "yaml_emitter_t", has_type_id = false,
	        destroy_function = "yaml_emitter_delete",
	        lower_case_cprefix = "yaml_emitter_")]
	public struct Emitter {
		public ErrorType error;
		public unowned string? problem;

		public bool initialize ();

		public void set_output_string ([CCode (array_length_type = "size_t")] uint8[] output,
		                               size_t* size_written);
		public void set_output_file (GLib.FileStream file);
		public void set_output (WriteHandler handler, void* data);

		public void set_encoding (Encoding encoding);
		public void set_canonical (bool canonical);
		public void set_indent (int indent);
		public void set_width (int width);
		public void set_unicode (bool unicode);
		public void set_break (Break line_break);

		/* takes ownership of the event, even on failure */
		public bool emit (ref Event event);

		public bool open ();
		public bool close ();
		/* takes ownership of the document */
		public bool dump (ref Document document);
		public bool flush ();
	}
}
