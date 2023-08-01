/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class XmlUtils {

        public static string strip_trailing_rss_chars (string rss) {
            // If there is a feed tag , it is atom file, else a rss one.
            if (rss.last_index_of ("</feed>") > 0) {
                return rss.substring (0, rss.last_index_of ("</feed>") + "</feed>".length);
            } else {
                return rss.substring (0, rss.last_index_of ("</rss>") + "</rss>".length);
            }
        }

        public static unowned Xml.Doc parse_string (string? input_string) throws Error {
            if (input_string == null || input_string.length == 0) {
                throw new PublishingError.MALFORMED_RESPONSE ("Empty XML string");
            }

            var rss = strip_trailing_rss_chars (input_string);

            // Don't want blanks to be included as text nodes, and want the XML parser to tolerate
            // tolerable XML
            Xml.Doc *doc = Xml.Parser.read_memory (rss, (int) rss.length, null, null,
            Xml.ParserOption.NOBLANKS | Xml.ParserOption.RECOVER);
            if (doc == null) {
                throw new PublishingError.MALFORMED_RESPONSE ("Unable to parse XML document 2");
            }
            // Since 'doc' is the top level, if it has no children, something is wrong
            // with the XML; we cannot continue normally here.
            if (doc->children == null) {
                throw new PublishingError.MALFORMED_RESPONSE ("Unable to parse XML document 3");
            }

            return doc;
        }
    }
}
