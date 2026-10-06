/* test-libyaml.vala - GLib.Test suite for libyaml.vapi
 *
 * Build:
 *   valac --vapidir=. --pkg libyaml -X -lyaml -X -Wno-pointer-sign \
 *         test-libyaml.vala -o test-libyaml
 * Run:
 *   ./test-libyaml
 */

namespace LibyamlTest {

	/* Collect "TYPE[:value]" strings for every event in a YAML string. */
	string[] collect_events (string yaml) {
		string[] result = {};

		Yaml.Parser parser = {};
		assert (parser.initialize ());
		parser.set_input_string (yaml.data);

		Yaml.Event ev = {};
		bool done = false;
		while (!done) {
			if (!parser.parse (out ev)) {
				result += "ERROR";
				return result;
			}
			switch (ev.type) {
			case Yaml.EventType.STREAM_START_EVENT:   result += "+STR"; break;
			case Yaml.EventType.STREAM_END_EVENT:     result += "-STR"; done = true; break;
			case Yaml.EventType.DOCUMENT_START_EVENT: result += "+DOC"; break;
			case Yaml.EventType.DOCUMENT_END_EVENT:   result += "-DOC"; break;
			case Yaml.EventType.SEQUENCE_START_EVENT: result += "+SEQ"; break;
			case Yaml.EventType.SEQUENCE_END_EVENT:   result += "-SEQ"; break;
			case Yaml.EventType.MAPPING_START_EVENT:  result += "+MAP"; break;
			case Yaml.EventType.MAPPING_END_EVENT:    result += "-MAP"; break;
			case Yaml.EventType.ALIAS_EVENT:
				result += "ALIAS:" + ev.data.alias.anchor;
				break;
			case Yaml.EventType.SCALAR_EVENT:
				result += "=" + ev.data.scalar.value;
				break;
			default:
				result += "?";
				break;
			}
			ev.@delete ();
		}
		return result;
	}

	/* Emit a fixed document {name: libyaml, tags: [a, b]} to a string. */
	string emit_sample (bool flow, bool canonical = false) {
		uint8[] buf = new uint8[512];
		size_t written = 0;

		Yaml.Emitter emitter = {};
		assert (emitter.initialize ());
		emitter.set_output_string (buf, &written);
		emitter.set_canonical (canonical);

		Yaml.Event ev = {};
		assert (ev.stream_start_init (Yaml.Encoding.UTF8_ENCODING));
		assert (emitter.emit (ref ev));
		assert (ev.document_start_init (null, null, null, true));
		assert (emitter.emit (ref ev));

		assert (ev.mapping_start_init (null, null, true,
			flow ? Yaml.MappingStyle.FLOW_MAPPING_STYLE
			     : Yaml.MappingStyle.BLOCK_MAPPING_STYLE));
		assert (emitter.emit (ref ev));

		assert (ev.scalar_init (null, null, "name", -1, true, true,
			Yaml.ScalarStyle.PLAIN_SCALAR_STYLE));
		assert (emitter.emit (ref ev));
		assert (ev.scalar_init (null, null, "libyaml", -1, true, true,
			Yaml.ScalarStyle.PLAIN_SCALAR_STYLE));
		assert (emitter.emit (ref ev));

		assert (ev.scalar_init (null, null, "tags", -1, true, true,
			Yaml.ScalarStyle.PLAIN_SCALAR_STYLE));
		assert (emitter.emit (ref ev));
		assert (ev.sequence_start_init (null, null, true,
			flow ? Yaml.SequenceStyle.FLOW_SEQUENCE_STYLE
			     : Yaml.SequenceStyle.BLOCK_SEQUENCE_STYLE));
		assert (emitter.emit (ref ev));
		assert (ev.scalar_init (null, null, "a", -1, true, true,
			Yaml.ScalarStyle.PLAIN_SCALAR_STYLE));
		assert (emitter.emit (ref ev));
		assert (ev.scalar_init (null, null, "b", -1, true, true,
			Yaml.ScalarStyle.PLAIN_SCALAR_STYLE));
		assert (emitter.emit (ref ev));
		assert (ev.sequence_end_init ());
		assert (emitter.emit (ref ev));

		assert (ev.mapping_end_init ());
		assert (emitter.emit (ref ev));
		assert (ev.document_end_init (true));
		assert (emitter.emit (ref ev));
		assert (ev.stream_end_init ());
		assert (emitter.emit (ref ev));
		assert (emitter.flush ());

		return ((string) buf).substring (0, (long) written);
	}

	/* ---- Tests ---- */

	void test_version () {
		int major, minor, patch;
		Yaml.get_version (out major, out minor, out patch);
		assert (major == 0);
		assert (minor >= 1);
		assert (patch >= 0);

		unowned string s = Yaml.get_version_string ();
		assert (s == "%d.%d.%d".printf (major, minor, patch));
	}

	void test_constants () {
		assert (Yaml.STR_TAG == "tag:yaml.org,2002:str");
		assert (Yaml.INT_TAG == "tag:yaml.org,2002:int");
		assert (Yaml.SEQ_TAG == "tag:yaml.org,2002:seq");
		assert (Yaml.MAP_TAG == "tag:yaml.org,2002:map");
		assert (Yaml.DEFAULT_SCALAR_TAG == Yaml.STR_TAG);
	}

	void test_parse_scalar () {
		string[] ev = collect_events ("hello\n");
		string[] expected = { "+STR", "+DOC", "=hello", "-DOC", "-STR" };
		assert (ev.length == expected.length);
		for (int i = 0; i < ev.length; i++)
			assert (ev[i] == expected[i]);
	}

	void test_parse_structure () {
		string[] ev = collect_events ("a: [1, 2]\nb: hello\n");
		string[] expected = {
			"+STR", "+DOC", "+MAP",
			"=a", "+SEQ", "=1", "=2", "-SEQ",
			"=b", "=hello",
			"-MAP", "-DOC", "-STR"
		};
		assert (ev.length == expected.length);
		for (int i = 0; i < ev.length; i++)
			assert (ev[i] == expected[i]);
	}

	void test_parse_anchor_alias () {
		string[] ev = collect_events ("- &x foo\n- *x\n");
		string[] expected = {
			"+STR", "+DOC", "+SEQ", "=foo", "ALIAS:x", "-SEQ", "-DOC", "-STR"
		};
		assert (ev.length == expected.length);
		for (int i = 0; i < ev.length; i++)
			assert (ev[i] == expected[i]);
	}

	void test_scalar_details () {
		Yaml.Parser parser = {};
		assert (parser.initialize ());
		parser.set_input_string ("\"quoted\"\n".data);

		Yaml.Event ev = {};
		bool found = false;
		while (parser.parse (out ev)) {
			var t = ev.type;
			if (t == Yaml.EventType.SCALAR_EVENT) {
				found = true;
				assert (ev.data.scalar.value == "quoted");
				assert (ev.data.scalar.length == 6);
				assert (ev.data.scalar.style == Yaml.ScalarStyle.DOUBLE_QUOTED_SCALAR_STYLE);
				assert (ev.start_mark.line == 0);
				assert (ev.start_mark.column == 0);
			}
			ev.@delete ();
			if (t == Yaml.EventType.STREAM_END_EVENT)
				break;
		}
		assert (found);
	}

	void test_parse_error () {
		Yaml.Parser parser = {};
		assert (parser.initialize ());
		parser.set_input_string ("a: [1, 2\nb: : :\n".data);

		Yaml.Event ev = {};
		bool failed = false;
		while (true) {
			if (!parser.parse (out ev)) {
				failed = true;
				break;
			}
			var t = ev.type;
			ev.@delete ();
			if (t == Yaml.EventType.STREAM_END_EVENT)
				break;
		}
		assert (failed);
		assert (parser.error == Yaml.ErrorType.PARSER_ERROR
		        || parser.error == Yaml.ErrorType.SCANNER_ERROR);
		assert (parser.problem != null);
		assert (parser.problem_mark.line >= 0);
	}

	void test_emit_block () {
		string out_text = emit_sample (false);
		assert (out_text == "name: libyaml\ntags:\n- a\n- b\n");
	}

	void test_emit_flow () {
		string out_text = emit_sample (true);
		assert (out_text.contains ("name: libyaml"));
		assert (out_text.contains ("tags: [a, b]"));
		assert (out_text.has_prefix ("{"));
	}

	void test_emit_canonical () {
		string out_text = emit_sample (false, true);
		assert (out_text.has_prefix ("---"));
		/* canonical style: explicit keys and quoted scalars */
		assert (out_text.contains ("? \"name\""));
		assert (out_text.contains (": \"libyaml\""));
		assert (out_text.contains ("\"a\""));
	}

	void test_roundtrip () {
		string a = emit_sample (false);
		string[] ev = collect_events (a);
		string[] expected = {
			"+STR", "+DOC", "+MAP",
			"=name", "=libyaml",
			"=tags", "+SEQ", "=a", "=b", "-SEQ",
			"-MAP", "-DOC", "-STR"
		};
		assert (ev.length == expected.length);
		for (int i = 0; i < ev.length; i++)
			assert (ev[i] == expected[i]);
	}

	void test_load_document () {
		Yaml.Parser parser = {};
		assert (parser.initialize ());
		parser.set_input_string ("name: libyaml\nitems: [x, y, z]\n".data);

		Yaml.Document doc = {};
		assert (parser.load (out doc));

		Yaml.Node* root = doc.get_root_node ();
		assert (root != null);
		assert (root->type == Yaml.NodeType.MAPPING_NODE);

		Yaml.NodePair* pair = root->data.mapping.pairs.start;
		Yaml.NodePair* end = root->data.mapping.pairs.top;
		assert (end - pair == 2);

		/* first pair: name -> libyaml */
		Yaml.Node* k = doc.get_node (pair[0].key);
		Yaml.Node* v = doc.get_node (pair[0].value);
		assert (k->type == Yaml.NodeType.SCALAR_NODE);
		assert (k->data.scalar.value == "name");
		assert (v->data.scalar.value == "libyaml");
		assert (v->tag == Yaml.STR_TAG);

		/* second pair: items -> sequence of 3 scalars */
		k = doc.get_node (pair[1].key);
		v = doc.get_node (pair[1].value);
		assert (k->data.scalar.value == "items");
		assert (v->type == Yaml.NodeType.SEQUENCE_NODE);

		int* item = v->data.sequence.items.start;
		int* item_end = v->data.sequence.items.top;
		assert (item_end - item == 3);

		string[] expected = { "x", "y", "z" };
		for (int i = 0; i < 3; i++) {
			Yaml.Node* n = doc.get_node (item[i]);
			assert (n->type == Yaml.NodeType.SCALAR_NODE);
			assert (n->data.scalar.value == expected[i]);
		}

		/* out-of-range index returns null */
		assert (doc.get_node (9999) == null);
	}

	void test_load_empty_stream () {
		Yaml.Parser parser = {};
		assert (parser.initialize ());
		parser.set_input_string ("".data);

		Yaml.Document doc = {};
		assert (parser.load (out doc));
		assert (doc.get_root_node () == null);
	}

	void test_build_and_dump_document () {
		uint8[] buf = new uint8[256];
		size_t written = 0;

		Yaml.Emitter emitter = {};
		assert (emitter.initialize ());
		emitter.set_output_string (buf, &written);

		assert (emitter.open ());

		Yaml.Document doc = {};
		assert (doc.initialize (null, null, null, true, true));

		int map = doc.add_mapping (null, Yaml.MappingStyle.BLOCK_MAPPING_STYLE);
		assert (map > 0);
		int key = doc.add_scalar (null, "greeting", -1, Yaml.ScalarStyle.PLAIN_SCALAR_STYLE);
		int val = doc.add_scalar (null, "hello", -1, Yaml.ScalarStyle.PLAIN_SCALAR_STYLE);
		int seq = doc.add_sequence (null, Yaml.SequenceStyle.BLOCK_SEQUENCE_STYLE);
		int key2 = doc.add_scalar (null, "list", -1, Yaml.ScalarStyle.PLAIN_SCALAR_STYLE);
		int one = doc.add_scalar (null, "1", -1, Yaml.ScalarStyle.PLAIN_SCALAR_STYLE);
		int two = doc.add_scalar (null, "2", -1, Yaml.ScalarStyle.PLAIN_SCALAR_STYLE);
		assert (key > 0 && val > 0 && seq > 0 && key2 > 0 && one > 0 && two > 0);

		assert (doc.append_mapping_pair (map, key, val));
		assert (doc.append_mapping_pair (map, key2, seq));
		assert (doc.append_sequence_item (seq, one));
		assert (doc.append_sequence_item (seq, two));

		assert (emitter.dump (ref doc));
		assert (emitter.close ());
		assert (emitter.flush ());

		string text = ((string) buf).substring (0, (long) written);
		assert (text == "greeting: hello\nlist:\n- 1\n- 2\n");
	}

	/* ---- Callback-based I/O ---- */

	class Source {
		public string text;
		public size_t pos = 0;
		public Source (string text) { this.text = text; }
	}

	/* hands out at most 3 bytes per call to exercise buffering */
	int read_cb (void* data, uint8* buffer, size_t size, out size_t size_read) {
		Source src = (Source) data;
		size_t remaining = src.text.length - src.pos;
		size_t n = size_t.min (size_t.min (remaining, size), 3);
		for (size_t i = 0; i < n; i++)
			buffer[i] = (uint8) src.text[(long) (src.pos + i)];
		src.pos += n;
		size_read = n;
		return 1;
	}

	void test_read_handler () {
		var src = new Source ("- one\n- two\n");

		Yaml.Parser parser = {};
		assert (parser.initialize ());
		parser.set_input (read_cb, (void*) src);

		string[] scalars = {};
		Yaml.Event ev = {};
		while (true) {
			assert (parser.parse (out ev));
			var t = ev.type;
			if (t == Yaml.EventType.SCALAR_EVENT)
				scalars += ev.data.scalar.value;
			ev.@delete ();
			if (t == Yaml.EventType.STREAM_END_EVENT)
				break;
		}
		assert (scalars.length == 2);
		assert (scalars[0] == "one");
		assert (scalars[1] == "two");
	}

	int write_cb (void* data, uint8* buffer, size_t size) {
		StringBuilder* sb = (StringBuilder*) data;
		for (size_t i = 0; i < size; i++)
			sb->append_c ((char) buffer[i]);
		return 1;
	}

	void test_write_handler () {
		var sb = new StringBuilder ();

		Yaml.Emitter emitter = {};
		assert (emitter.initialize ());
		emitter.set_output (write_cb, (void*) sb);

		Yaml.Event ev = {};
		assert (ev.stream_start_init (Yaml.Encoding.UTF8_ENCODING));
		assert (emitter.emit (ref ev));
		assert (ev.document_start_init (null, null, null, true));
		assert (emitter.emit (ref ev));
		assert (ev.scalar_init (null, null, "callback", -1, true, true,
			Yaml.ScalarStyle.PLAIN_SCALAR_STYLE));
		assert (emitter.emit (ref ev));
		assert (ev.document_end_init (true));
		assert (emitter.emit (ref ev));
		assert (ev.stream_end_init ());
		assert (emitter.emit (ref ev));
		assert (emitter.flush ());

		/* a bare plain scalar document is terminated with "..." */
		assert (sb.str.has_prefix ("callback"));
	}

	void test_file_io () {
		string path = Path.build_filename (Environment.get_tmp_dir (),
			"libyaml-vapi-test-%d.yaml".printf ((int) Posix.getpid ()));

		/* write */
		{
			var f = FileStream.open (path, "w");
			assert (f != null);

			Yaml.Emitter emitter = {};
			assert (emitter.initialize ());
			emitter.set_output_file (f);

			Yaml.Event ev = {};
			assert (ev.stream_start_init (Yaml.Encoding.UTF8_ENCODING));
			assert (emitter.emit (ref ev));
			assert (ev.document_start_init (null, null, null, true));
			assert (emitter.emit (ref ev));
			assert (ev.sequence_start_init (null, null, true,
				Yaml.SequenceStyle.BLOCK_SEQUENCE_STYLE));
			assert (emitter.emit (ref ev));
			assert (ev.scalar_init (null, null, "file", -1, true, true,
				Yaml.ScalarStyle.PLAIN_SCALAR_STYLE));
			assert (emitter.emit (ref ev));
			assert (ev.sequence_end_init ());
			assert (emitter.emit (ref ev));
			assert (ev.document_end_init (true));
			assert (emitter.emit (ref ev));
			assert (ev.stream_end_init ());
			assert (emitter.emit (ref ev));
			assert (emitter.flush ());
			f.flush ();
		}

		/* read back */
		{
			var f = FileStream.open (path, "r");
			assert (f != null);

			Yaml.Parser parser = {};
			assert (parser.initialize ());
			parser.set_input_file (f);

			string[] scalars = {};
			Yaml.Event ev = {};
			while (true) {
				assert (parser.parse (out ev));
				var t = ev.type;
				if (t == Yaml.EventType.SCALAR_EVENT)
					scalars += ev.data.scalar.value;
				ev.@delete ();
				if (t == Yaml.EventType.STREAM_END_EVENT)
					break;
			}
			assert (scalars.length == 1);
			assert (scalars[0] == "file");
		}

		FileUtils.unlink (path);
	}

	void test_scanner_tokens () {
		Yaml.Parser parser = {};
		assert (parser.initialize ());
		parser.set_input_string ("[a, b]\n".data);

		Yaml.Token tok = {};
		int scalars = 0;
		bool saw_flow_start = false;
		while (true) {
			assert (parser.scan (out tok));
			var t = tok.type;
			if (t == Yaml.TokenType.FLOW_SEQUENCE_START_TOKEN)
				saw_flow_start = true;
			if (t == Yaml.TokenType.SCALAR_TOKEN)
				scalars++;
			tok.@delete ();
			if (t == Yaml.TokenType.STREAM_END_TOKEN)
				break;
		}
		assert (saw_flow_start);
		assert (scalars == 2);
	}

	void test_unicode_scalar () {
		string[] ev = collect_events ("héllo: wörld ✓\n");
		assert (ev.length == 8);
		assert (ev[3] == "=héllo");
		assert (ev[4] == "=wörld ✓");
	}

	public int main (string[] args) {
		Test.init (ref args);

		Test.add_func ("/libyaml/version",           test_version);
		Test.add_func ("/libyaml/constants",         test_constants);

		Test.add_func ("/libyaml/parser/scalar",     test_parse_scalar);
		Test.add_func ("/libyaml/parser/structure",  test_parse_structure);
		Test.add_func ("/libyaml/parser/anchor",     test_parse_anchor_alias);
		Test.add_func ("/libyaml/parser/details",    test_scalar_details);
		Test.add_func ("/libyaml/parser/error",      test_parse_error);
		Test.add_func ("/libyaml/parser/unicode",    test_unicode_scalar);
		Test.add_func ("/libyaml/parser/scanner",    test_scanner_tokens);
		Test.add_func ("/libyaml/parser/handler",    test_read_handler);

		Test.add_func ("/libyaml/emitter/block",     test_emit_block);
		Test.add_func ("/libyaml/emitter/flow",      test_emit_flow);
		Test.add_func ("/libyaml/emitter/canonical", test_emit_canonical);
		Test.add_func ("/libyaml/emitter/handler",   test_write_handler);
		Test.add_func ("/libyaml/emitter/roundtrip", test_roundtrip);

		Test.add_func ("/libyaml/document/load",     test_load_document);
		Test.add_func ("/libyaml/document/empty",    test_load_empty_stream);
		Test.add_func ("/libyaml/document/dump",     test_build_and_dump_document);

		Test.add_func ("/libyaml/io/file",           test_file_io);

		return Test.run ();
	}
}
